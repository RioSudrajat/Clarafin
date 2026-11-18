package gemini

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"sort"
	"strings"
	"sync"
	"syscall"
	"time"

	"go.uber.org/zap"
	"google.golang.org/genai"

	"github.com/clarafin/api/internal/ai"
)

const defaultCacheTTL = 60 * time.Minute
const failedCacheRetryCooldown = 5 * time.Minute
const defaultPrimaryModel = "gemini-3.5-flash"

// ErrGeminiUnavailable indicates the Gemini adapter has no API key or failed initialization.
var ErrGeminiUnavailable = errors.New("gemini client unavailable")

// Config configures the Google Gemini SDK adapter.
type Config struct {
	APIKey              string
	DefaultModel        string
	FallbackModels      []string
	ContextCacheEnabled bool
	CacheTTL            time.Duration
	HTTPClient          *http.Client
	Logger              *zap.Logger
}

// ClientConfig is an alias for Config.
type ClientConfig = Config

type cachedEntry struct {
	model     string
	name      string
	expiresAt time.Time
}

// Client implements ai.LLMClient backed by the official google.golang.org/genai SDK.
type Client struct {
	apiKey              string
	defaultModel        string
	fallbackModels      []string
	contextCacheEnabled bool
	cacheTTL            time.Duration
	logger              *zap.Logger
	genaiClient         *genai.Client
	nowFn               func() time.Time

	cacheMu       sync.RWMutex
	cacheCreateMu sync.Mutex
	caches        map[string]cachedEntry
	cacheCooldown map[string]time.Time

	unavailableMu     sync.RWMutex
	unavailableModels map[string]error
}

// NewClient initializes the Google Gemini adapter. An empty APIKey yields a safe unconfigured client
// so non-LLM routes and pre-filtered greetings still operate in local development.
func NewClient(ctx context.Context, cfg Config) (*Client, error) {
	logger := cfg.Logger
	if logger == nil {
		logger = zap.NewNop()
	}
	model := strings.TrimSpace(cfg.DefaultModel)
	if model == "" {
		model = defaultPrimaryModel
	}
	cacheTTL := cfg.CacheTTL
	if cacheTTL <= 0 {
		cacheTTL = defaultCacheTTL
	}

	c := &Client{
		apiKey:              strings.TrimSpace(cfg.APIKey),
		defaultModel:        model,
		fallbackModels:      normalizeFallbackSlice(cfg.FallbackModels, model),
		contextCacheEnabled: cfg.ContextCacheEnabled,
		cacheTTL:            cacheTTL,
		logger:              logger,
		nowFn:               time.Now,
		caches:              make(map[string]cachedEntry),
		cacheCooldown:       make(map[string]time.Time),
		unavailableModels:   make(map[string]error),
	}

	if c.apiKey == "" {
		return c, nil
	}

	clientCfg := &genai.ClientConfig{
		APIKey:     c.apiKey,
		Backend:    genai.BackendGeminiAPI,
		HTTPClient: cfg.HTTPClient,
	}
	sdkClient, err := genai.NewClient(ctx, clientCfg)
	if err != nil {
		return nil, fmt.Errorf("create google genai client: %w", err)
	}
	c.genaiClient = sdkClient
	return c, nil
}

// IsConfigured reports whether the Gemini client holds a live API key and initialized SDK client.
func (c *Client) IsConfigured() bool {
	return c != nil && c.genaiClient != nil && c.apiKey != ""
}

// GenerateContent executes one Gemini generation turn with strict tool/schema separation,
// model-isolated context caching, and ordered model failover on 404/429/5xx/network errors.
func (c *Client) GenerateContent(ctx context.Context, req ai.GenerateRequest) (*ai.GenerateResponse, error) {
	if !c.IsConfigured() {
		return nil, fmt.Errorf("%w: GEMINI_API_KEY is not configured", ErrGeminiUnavailable)
	}

	primaryModel := strings.TrimSpace(req.Model)
	if primaryModel == "" {
		primaryModel = c.defaultModel
	}

	contents, err := toGenaiContents(req.Contents)
	if err != nil {
		return nil, err
	}

	baseCfg, err := BuildGenaiConfig(req)
	if err != nil {
		return nil, err
	}

	savedSys := baseCfg.SystemInstruction
	savedTools := baseCfg.Tools
	candidates := c.candidateModels(primaryModel)
	searchGroundingDisabled := false

	var lastErr error
	for idx, candidateModel := range candidates {
		if memoErr, unavailable := c.unavailableModelError(candidateModel); unavailable {
			lastErr = memoErr
			continue
		}

		attemptCfg := *baseCfg
		attemptCfg.CachedContent = ""
		attemptCfg.SystemInstruction = savedSys
		attemptCfg.Tools = savedTools
		if req.EnableGoogleSearch && searchGroundingDisabled {
			attemptCfg.Tools = nil
		}
		attemptCacheName := ""

		// Explicit CachedContent is strictly bound to the model that created it.
		// Fallback models (idx > 0) always receive inline SystemInstruction and Tools.
		if idx == 0 && c.shouldAttemptExplicitCache(req, baseCfg) {
			cacheKey := buildExplicitCacheKey(candidateModel, req.CacheKey, req.ToolDeclarations)
			if name, ok := c.resolveOrCreateExplicitCache(ctx, candidateModel, cacheKey, savedSys, savedTools); ok {
				attemptCacheName = name
				attemptCfg.CachedContent = name
				// Gemini rejects duplicate systemInstruction or tools alongside CachedContent.
				attemptCfg.SystemInstruction = nil
				attemptCfg.Tools = nil
			}
		}

		rawResp, callErr := c.genaiClient.Models.GenerateContent(ctx, candidateModel, contents, &attemptCfg)
		if callErr != nil && attemptCacheName != "" && ctx.Err() == nil {
			shouldFailover, _ := classifyGeminiError(ctx, callErr)
			c.invalidateExplicitCache(buildExplicitCacheKey(candidateModel, req.CacheKey, req.ToolDeclarations))
			if !shouldFailover {
				c.logger.Warn(
					"gemini cached generation failed; falling back to implicit prefix caching",
					zap.String("model", candidateModel),
					zap.String("cache_name", attemptCacheName),
					zap.Error(callErr),
				)
				attemptCacheName = ""
				attemptCfg.CachedContent = ""
				attemptCfg.SystemInstruction = savedSys
				attemptCfg.Tools = savedTools
				rawResp, callErr = c.genaiClient.Models.GenerateContent(ctx, candidateModel, contents, &attemptCfg)
			}
		}

		if callErr != nil && req.EnableGoogleSearch && !searchGroundingDisabled && ctx.Err() == nil {
			_, isModelNotFound := classifyGeminiError(ctx, callErr)
			if !isModelNotFound {
				searchGroundingDisabled = true
				c.logger.Warn(
					"gemini google_search grounding failed; falling back to ungrounded model synthesis",
					zap.String("model", candidateModel),
					zap.Error(callErr),
				)
				attemptCfg.Tools = nil
				rawResp, callErr = c.genaiClient.Models.GenerateContent(ctx, candidateModel, contents, &attemptCfg)
			}
		}

		if callErr == nil {
			return fromGenaiResponse(rawResp, candidateModel, attemptCacheName), nil
		}

		lastErr = callErr
		shouldFailover, isModelNotFound := classifyGeminiError(ctx, callErr)
		if isModelNotFound {
			c.markModelUnavailable(candidateModel, callErr)
		}
		if !shouldFailover {
			return nil, fmt.Errorf("gemini generate content (%s): %w", req.Pass, callErr)
		}
		if idx < len(candidates)-1 {
			c.logger.Warn(
				"gemini model call failed; failing over to next candidate model",
				zap.String("pass", req.Pass),
				zap.String("failed_model", candidateModel),
				zap.String("next_model", candidates[idx+1]),
				zap.Bool("memoized_404", isModelNotFound),
				zap.Error(callErr),
			)
		}
	}

	if lastErr == nil {
		lastErr = ErrGeminiUnavailable
	}
	return nil, fmt.Errorf("gemini generate content (%s): %w", req.Pass, lastErr)
}

// BuildGenaiConfig translates an SDK-agnostic ai.GenerateRequest into *genai.GenerateContentConfig
// while enforcing Clarafin safety, parameter, and tool/JSON mutual exclusion invariants.
func BuildGenaiConfig(req ai.GenerateRequest) (*genai.GenerateContentConfig, error) {
	if req.EnableGoogleSearch && len(req.ToolDeclarations) > 0 {
		return nil, errors.New("gemini adapter: cannot mix google_search with custom function declarations in one request")
	}
	if req.Params.ResponseMIMEType == "application/json" && (req.EnableGoogleSearch || len(req.ToolDeclarations) > 0) {
		return nil, errors.New("gemini adapter: cannot mix application/json responseMimeType with tools or google_search")
	}

	temp := req.Params.Temperature
	cfg := &genai.GenerateContentConfig{
		Temperature: &temp,
	}

	if req.Params.TopP > 0 {
		topP := req.Params.TopP
		cfg.TopP = &topP
	}
	if req.Params.TopK > 0 {
		topK := float32(req.Params.TopK)
		cfg.TopK = &topK
	}
	if req.Params.MaxOutputTokens > 0 {
		cfg.MaxOutputTokens = int32(req.Params.MaxOutputTokens)
	}
	if req.Pass == ai.Pass2StructuredJSON || req.Pass == ai.PassExtraction {
		pp := req.Params.PresencePenalty
		fp := req.Params.FrequencyPenalty
		cfg.PresencePenalty = &pp
		cfg.FrequencyPenalty = &fp
	}
	if req.Params.ThinkingBudget >= 0 {
		budget := int32(req.Params.ThinkingBudget)
		cfg.ThinkingConfig = &genai.ThinkingConfig{
			ThinkingBudget: &budget,
		}
	}

	if req.Params.SafetyThreshold == "" || req.Params.SafetyThreshold == ai.SafetyBlockMediumAndAbove {
		cfg.SafetySettings = []*genai.SafetySetting{
			{Category: genai.HarmCategoryHarassment, Threshold: genai.HarmBlockThresholdBlockMediumAndAbove},
			{Category: genai.HarmCategoryHateSpeech, Threshold: genai.HarmBlockThresholdBlockMediumAndAbove},
			{Category: genai.HarmCategorySexuallyExplicit, Threshold: genai.HarmBlockThresholdBlockMediumAndAbove},
			{Category: genai.HarmCategoryDangerousContent, Threshold: genai.HarmBlockThresholdBlockMediumAndAbove},
		}
	}

	if strings.TrimSpace(req.SystemInstruction) != "" {
		cfg.SystemInstruction = &genai.Content{
			Parts: []*genai.Part{genai.NewPartFromText(req.SystemInstruction)},
		}
	}

	if req.EnableGoogleSearch {
		cfg.Tools = []*genai.Tool{
			{GoogleSearch: &genai.GoogleSearch{}},
		}
	} else if len(req.ToolDeclarations) > 0 {
		decls := make([]*genai.FunctionDeclaration, 0, len(req.ToolDeclarations))
		for _, td := range req.ToolDeclarations {
			decls = append(decls, &genai.FunctionDeclaration{
				Name:        td.Name,
				Description: td.Description,
				Parameters:  ToGenaiSchema(td.Parameters),
			})
		}
		cfg.Tools = []*genai.Tool{
			{FunctionDeclarations: decls},
		}
	}

	if req.Params.ResponseMIMEType != "" {
		cfg.ResponseMIMEType = req.Params.ResponseMIMEType
	}
	if req.Params.ResponseSchema != nil {
		cfg.ResponseSchema = optimizeGenaiResponseSchema(ToGenaiSchema(req.Params.ResponseSchema))
	}

	return cfg, nil
}

func optimizeGenaiResponseSchema(s *genai.Schema) *genai.Schema {
	if s == nil {
		return nil
	}
	s.Nullable = nil
	if len(s.Enum) > 10 {
		s.Enum = nil
	}
	if s.Items != nil {
		optimizeGenaiResponseSchema(s.Items)
	}
	if len(s.Properties) > 0 {
		reqSet := make(map[string]struct{}, len(s.Required))
		ordering := make([]string, 0, len(s.Properties))
		for _, rk := range s.Required {
			if _, exists := s.Properties[rk]; exists {
				if _, seen := reqSet[rk]; !seen {
					reqSet[rk] = struct{}{}
					ordering = append(ordering, rk)
				}
			}
		}
		optKeys := make([]string, 0, len(s.Properties)-len(ordering))
		for k, prop := range s.Properties {
			optimizeGenaiResponseSchema(prop)
			if _, isReq := reqSet[k]; !isReq {
				optKeys = append(optKeys, k)
			}
		}
		sort.Strings(optKeys)
		ordering = append(ordering, optKeys...)
		if len(s.PropertyOrdering) == 0 {
			s.PropertyOrdering = ordering
		}
	}
	return s
}

// ToGenaiSchema converts an ai.ToolParameterSchema tree into *genai.Schema.
func ToGenaiSchema(s *ai.ToolParameterSchema) *genai.Schema {
	if s == nil {
		return nil
	}
	resolvedType := toGenaiType(s.Type)
	if resolvedType == genai.TypeUnspecified {
		switch {
		case len(s.Properties) > 0:
			resolvedType = genai.TypeObject
		case s.Items != nil:
			resolvedType = genai.TypeArray
		default:
			resolvedType = genai.TypeString
		}
	}
	out := &genai.Schema{
		Type:             resolvedType,
		Description:      s.Description,
		Enum:             append([]string(nil), s.Enum...),
		Format:           s.Format,
		Nullable:         s.Nullable,
		Items:            ToGenaiSchema(s.Items),
		Required:         append([]string(nil), s.Required...),
		PropertyOrdering: append([]string(nil), s.PropertyOrdering...),
	}
	if len(s.Properties) > 0 {
		out.Properties = make(map[string]*genai.Schema, len(s.Properties))
		for k, v := range s.Properties {
			out.Properties[k] = ToGenaiSchema(v)
		}
	}
	return out
}

func toGenaiType(raw string) genai.Type {
	switch strings.ToUpper(strings.TrimSpace(raw)) {
	case "STRING":
		return genai.TypeString
	case "NUMBER":
		return genai.TypeNumber
	case "INTEGER":
		return genai.TypeInteger
	case "BOOLEAN":
		return genai.TypeBoolean
	case "ARRAY":
		return genai.TypeArray
	case "OBJECT":
		return genai.TypeObject
	case "NULL":
		return genai.TypeNULL
	default:
		return genai.TypeUnspecified
	}
}

func toGenaiContents(msgs []ai.LLMMessage) ([]*genai.Content, error) {
	contents := make([]*genai.Content, 0, len(msgs))
	for _, m := range msgs {
		role := genai.RoleUser
		if strings.EqualFold(strings.TrimSpace(m.Role), "model") {
			role = genai.RoleModel
		}
		parts := make([]*genai.Part, 0, len(m.Parts))
		for _, p := range m.Parts {
			switch {
			case p.FunctionCall != nil:
				part := genai.NewPartFromFunctionCall(p.FunctionCall.Name, p.FunctionCall.Args)
				if p.FunctionCall.ID != "" {
					part.FunctionCall.ID = p.FunctionCall.ID
				}
				if len(p.FunctionCall.ThoughtSignature) > 0 {
					part.ThoughtSignature = p.FunctionCall.ThoughtSignature
				}
				parts = append(parts, part)

			case p.FunctionResponse != nil:
				part := genai.NewPartFromFunctionResponse(p.FunctionResponse.Name, p.FunctionResponse.Response)
				if p.FunctionResponse.ID != "" {
					part.FunctionResponse.ID = p.FunctionResponse.ID
				}
				parts = append(parts, part)

			case len(p.InlineBytes) > 0:
				if strings.TrimSpace(p.MIMEType) == "" {
					return nil, errors.New("gemini adapter: inline binary part requires mime_type")
				}
				parts = append(parts, genai.NewPartFromBytes(p.InlineBytes, p.MIMEType))

			default:
				parts = append(parts, genai.NewPartFromText(p.Text))
			}
		}
		contents = append(contents, genai.NewContentFromParts(parts, genai.Role(role)))
	}
	return contents, nil
}

func fromGenaiResponse(resp *genai.GenerateContentResponse, modelName, explicitCacheName string) *ai.GenerateResponse {
	out := &ai.GenerateResponse{
		Model:            modelName,
		UsedContextCache: explicitCacheName != "",
		CacheName:        explicitCacheName,
	}
	if resp == nil {
		return out
	}
	if resp.UsageMetadata != nil && resp.UsageMetadata.CachedContentTokenCount > 0 {
		out.UsedContextCache = true
	}

	var textBuf strings.Builder
	seenSources := make(map[string]struct{})

	for _, cand := range resp.Candidates {
		if cand == nil {
			continue
		}
		if cand.Content != nil {
			for _, part := range cand.Content.Parts {
				if part == nil {
					continue
				}
				if part.FunctionCall != nil {
					out.FunctionCalls = append(out.FunctionCalls, ai.ToolCall{
						ID:               part.FunctionCall.ID,
						Name:             part.FunctionCall.Name,
						Args:             part.FunctionCall.Args,
						ThoughtSignature: part.ThoughtSignature,
					})
					continue
				}
				if !part.Thought && part.Text != "" {
					textBuf.WriteString(part.Text)
				}
			}
		}
		if cand.GroundingMetadata != nil {
			for _, chunk := range cand.GroundingMetadata.GroundingChunks {
				if chunk != nil && chunk.Web != nil && strings.TrimSpace(chunk.Web.URI) != "" {
					uri := strings.TrimSpace(chunk.Web.URI)
					if _, dup := seenSources[uri]; !dup {
						seenSources[uri] = struct{}{}
						out.GroundingSources = append(out.GroundingSources, uri)
					}
				}
			}
		}
	}

	out.Text = textBuf.String()
	return out
}

func (c *Client) shouldAttemptExplicitCache(req ai.GenerateRequest, cfg *genai.GenerateContentConfig) bool {
	if !c.contextCacheEnabled || req.CacheKey == "" || cfg.SystemInstruction == nil || req.EnableGoogleSearch {
		return false
	}
	return req.Pass == ai.Pass1ToolPlanning || req.Pass == ai.Pass2StructuredJSON
}

func (c *Client) resolveOrCreateExplicitCache(
	ctx context.Context,
	model string,
	fullKey string,
	sysInst *genai.Content,
	tools []*genai.Tool,
) (string, bool) {
	now := c.nowFn()

	c.cacheMu.RLock()
	if entry, ok := c.caches[fullKey]; ok && entry.model == model && entry.expiresAt.After(now.Add(2*time.Minute)) {
		c.cacheMu.RUnlock()
		return entry.name, true
	}
	if cooldownUntil, cooled := c.cacheCooldown[fullKey]; cooled && cooldownUntil.After(now) {
		c.cacheMu.RUnlock()
		return "", false
	}
	c.cacheMu.RUnlock()

	c.cacheCreateMu.Lock()
	defer c.cacheCreateMu.Unlock()

	now = c.nowFn()
	c.cacheMu.RLock()
	if entry, ok := c.caches[fullKey]; ok && entry.model == model && entry.expiresAt.After(now.Add(2*time.Minute)) {
		c.cacheMu.RUnlock()
		return entry.name, true
	}
	if cooldownUntil, cooled := c.cacheCooldown[fullKey]; cooled && cooldownUntil.After(now) {
		c.cacheMu.RUnlock()
		return "", false
	}
	c.cacheMu.RUnlock()

	created, err := c.genaiClient.Caches.Create(ctx, model, &genai.CreateCachedContentConfig{
		DisplayName:       fullKey,
		TTL:               c.cacheTTL,
		SystemInstruction: sysInst,
		Tools:             tools,
	})
	if err != nil || created == nil || strings.TrimSpace(created.Name) == "" {
		c.cacheMu.Lock()
		c.cacheCooldown[fullKey] = now.Add(failedCacheRetryCooldown)
		c.cacheMu.Unlock()
		c.logger.Debug("explicit gemini cache skipped; using implicit prefix caching", zap.String("cache_key", fullKey), zap.Error(err))
		return "", false
	}

	expiresAt := created.ExpireTime
	if expiresAt.IsZero() {
		expiresAt = now.Add(c.cacheTTL)
	}
	c.cacheMu.Lock()
	c.caches[fullKey] = cachedEntry{model: model, name: created.Name, expiresAt: expiresAt}
	delete(c.cacheCooldown, fullKey)
	c.cacheMu.Unlock()

	return created.Name, true
}

func (c *Client) invalidateExplicitCache(fullKey string) {
	c.cacheMu.Lock()
	delete(c.caches, fullKey)
	c.cacheCooldown[fullKey] = c.nowFn().Add(failedCacheRetryCooldown)
	c.cacheMu.Unlock()
}

func (c *Client) candidateModels(primaryModel string) []string {
	primary := strings.TrimSpace(primaryModel)
	if primary == "" {
		primary = c.defaultModel
	}
	seen := make(map[string]struct{}, 1+len(c.fallbackModels))
	out := make([]string, 0, 1+len(c.fallbackModels))
	if primary != "" {
		seen[primary] = struct{}{}
		out = append(out, primary)
	}
	for _, fb := range c.fallbackModels {
		if fb == "" {
			continue
		}
		if _, dup := seen[fb]; dup {
			continue
		}
		seen[fb] = struct{}{}
		out = append(out, fb)
	}
	return out
}

func (c *Client) unavailableModelError(model string) (error, bool) {
	c.unavailableMu.RLock()
	err, ok := c.unavailableModels[model]
	c.unavailableMu.RUnlock()
	return err, ok
}

func (c *Client) markModelUnavailable(model string, err error) {
	if model == "" {
		return
	}
	c.unavailableMu.Lock()
	c.unavailableModels[model] = err
	c.unavailableMu.Unlock()
}

func normalizeFallbackSlice(raw []string, primaryModel string) []string {
	primary := strings.TrimSpace(primaryModel)
	seen := make(map[string]struct{}, len(raw))
	out := make([]string, 0, len(raw))
	for _, item := range raw {
		trimmed := strings.TrimSpace(item)
		if trimmed == "" || strings.EqualFold(trimmed, "none") || trimmed == primary {
			continue
		}
		if _, dup := seen[trimmed]; dup {
			continue
		}
		seen[trimmed] = struct{}{}
		out = append(out, trimmed)
	}
	return out
}

func classifyGeminiError(ctx context.Context, err error) (shouldFailover bool, isModelNotFound bool) {
	if err == nil {
		return false, false
	}
	if ctx != nil && ctx.Err() != nil {
		return false, false
	}
	if errors.Is(err, context.Canceled) {
		return false, false
	}

	if apiErr, ok := extractAPIError(err); ok {
		status := strings.ToUpper(strings.TrimSpace(apiErr.Status))
		switch apiErr.Code {
		case http.StatusNotFound:
			return true, true
		case http.StatusTooManyRequests,
			http.StatusInternalServerError,
			http.StatusBadGateway,
			http.StatusServiceUnavailable,
			http.StatusGatewayTimeout:
			return true, false
		case http.StatusBadRequest,
			http.StatusUnauthorized,
			http.StatusForbidden:
			return false, false
		}
		switch status {
		case "NOT_FOUND":
			return true, true
		case "RESOURCE_EXHAUSTED", "INTERNAL", "BAD_GATEWAY", "UNAVAILABLE", "DEADLINE_EXCEEDED":
			return true, false
		case "INVALID_ARGUMENT", "UNAUTHENTICATED", "PERMISSION_DENIED":
			return false, false
		}
		if apiErr.Code >= 500 && apiErr.Code < 600 {
			return true, false
		}
		return false, false
	}

	var netErr net.Error
	if errors.As(err, &netErr) {
		return true, false
	}
	if errors.Is(err, io.EOF) || errors.Is(err, io.ErrUnexpectedEOF) || errors.Is(err, syscall.ECONNRESET) || errors.Is(err, syscall.ECONNREFUSED) {
		return true, false
	}

	lower := strings.ToLower(err.Error())
	if strings.Contains(lower, "invalid_argument") ||
		strings.Contains(lower, "unauthenticated") ||
		strings.Contains(lower, "permission_denied") ||
		strings.Contains(lower, "status 400") ||
		strings.Contains(lower, "code 400") ||
		strings.Contains(lower, "status 401") ||
		strings.Contains(lower, "status 403") {
		return false, false
	}
	if strings.Contains(lower, "not_found") || strings.Contains(lower, "status 404") || strings.Contains(lower, "code 404") || strings.Contains(lower, "error 404") {
		return true, true
	}
	if strings.Contains(lower, "resource_exhausted") ||
		strings.Contains(lower, "unavailable") ||
		strings.Contains(lower, "deadline_exceeded") ||
		strings.Contains(lower, "bad_gateway") ||
		strings.Contains(lower, "status 429") ||
		strings.Contains(lower, "status 500") ||
		strings.Contains(lower, "status 502") ||
		strings.Contains(lower, "status 503") ||
		strings.Contains(lower, "status 504") ||
		strings.Contains(lower, "error 429") ||
		strings.Contains(lower, "error 500") ||
		strings.Contains(lower, "error 502") ||
		strings.Contains(lower, "error 503") ||
		strings.Contains(lower, "error 504") ||
		strings.Contains(lower, "connection reset") ||
		strings.Contains(lower, "timeout") {
		return true, false
	}

	return false, false
}

func extractAPIError(err error) (genai.APIError, bool) {
	if err == nil {
		return genai.APIError{}, false
	}
	var valErr genai.APIError
	if errors.As(err, &valErr) {
		return valErr, true
	}
	var ptrErr *genai.APIError
	if errors.As(err, &ptrErr) && ptrErr != nil {
		return *ptrErr, true
	}
	return genai.APIError{}, false
}

func buildExplicitCacheKey(model, reqKey string, decls []ai.ToolDeclaration) string {
	h := sha256.New()
	_, _ = h.Write([]byte(model))
	_, _ = h.Write([]byte{0})
	_, _ = h.Write([]byte(reqKey))
	if len(decls) > 0 {
		raw, _ := json.Marshal(decls)
		_, _ = h.Write([]byte{0})
		_, _ = h.Write(raw)
	}
	return "clarafin_" + hex.EncodeToString(h.Sum(nil))[:24]
}
