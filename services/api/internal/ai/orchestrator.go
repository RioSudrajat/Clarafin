package ai

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
	"go.uber.org/zap"

	"github.com/clarafin/api/internal/ai/prompts"
	"github.com/clarafin/api/internal/domain"
	"github.com/clarafin/api/internal/repository"
	"github.com/clarafin/api/internal/service"
)

const (
	// Pass1ToolPlanning runs deterministic function declarations at low temperature without JSON mime constraints.
	Pass1ToolPlanning = "pass1_tool_planning"
	// Pass1SearchGround runs Google Search grounding in an isolated sub-call with zero custom function declarations.
	Pass1SearchGround = "pass1_search_grounding"
	// Pass2StructuredJSON runs structured synthesis with responseSchema and zero tools.
	Pass2StructuredJSON = "pass2_structured_json"
	// PassExtraction runs structured extraction for quick-add and OCR receipt drafts.
	PassExtraction = "extraction"

	// SafetyBlockMediumAndAbove configures balanced moderation that avoids false positives on debt stories.
	SafetyBlockMediumAndAbove = "BLOCK_MEDIUM_AND_ABOVE"

	// SSEEventThinkingStep streams live process steps to AiThinkingTraceWidget.
	SSEEventThinkingStep = "thinking_step"
	// SSEEventFinalResponse streams the final structured response and quota snapshot.
	SSEEventFinalResponse = "final_response"
	// SSEEventError streams terminal processing failures over an active SSE channel.
	SSEEventError = "error"

	maxPass1ToolIterations = 5
	maxOCRImageBytes       = 8 << 20
)

var (
	// ErrInvalidChatRequest indicates malformed chat, quick-add, or OCR request fields.
	ErrInvalidChatRequest = errors.New("invalid AI request")
	// ErrOrchestratorUnavailable indicates missing LLM or downstream provider wiring.
	ErrOrchestratorUnavailable = errors.New("AI orchestrator unavailable")
)

// LLMClient abstracts Gemini API calls so unit and eval tests run deterministically without network I/O.
type LLMClient interface {
	GenerateContent(ctx context.Context, req GenerateRequest) (*GenerateResponse, error)
}

// QuotaManager abstracts atomic quota reservation, commit, compensation, and status reads.
type QuotaManager interface {
	ReserveAction(ctx context.Context, userID uuid.UUID, requestID, actionType, surfaceMode string) (*service.QuotaReservation, error)
	CommitSuccess(ctx context.Context, requestID string) error
	CompensateFailure(ctx context.Context, requestID string) error
	GetQuotaStatus(ctx context.Context, userID uuid.UUID) (*service.QuotaStatus, error)
}

// FinancialToolProvider exposes JWT-scoped read-only SQL financial queries.
type FinancialToolProvider interface {
	GetUserWallets(ctx context.Context, userID uuid.UUID) (*WalletsToolOutput, error)
	GetCashflowSummary(ctx context.Context, userID uuid.UUID, input CashflowQueryInput) (*CashflowSummaryOutput, error)
	GetBudgetAndBillsStatus(ctx context.Context, userID uuid.UUID) (*BudgetBillsOutput, error)
}

// ActionToolProvider exposes deterministic draft preparation tools without mutating ledger tables.
type ActionToolProvider interface {
	CheckAndPrepareTransaction(ctx context.Context, userID uuid.UUID, input PrepareTransactionInput) (*PrepareTransactionResult, error)
	ProposeGoalDraft(ctx context.Context, userID uuid.UUID, input GoalDraftInput) (*GoalDraftPayload, error)
	ProposeBudgetDraft(ctx context.Context, userID uuid.UUID, input BudgetDraftInput) (*BudgetDraftPayload, error)
	ProposeBillDraft(ctx context.Context, userID uuid.UUID, input BillDraftInput) (*BillDraftPayload, error)
}

// MatchingToolProvider exposes the 6-step deterministic practitioner and package matching engine.
type MatchingToolProvider interface {
	MatchExpertsAndPackage(ctx context.Context, userID uuid.UUID, signals MatchSignals) (*MatchingOutput, error)
}

// AIDraftRepository persists extracted quick-add and OCR transaction drafts into ai_drafts.
type AIDraftRepository interface {
	CreateAIDraft(ctx context.Context, arg repository.CreateAIDraftParams) (repository.AiDraft, error)
	ListPendingAIDraftsByUser(ctx context.Context, userID uuid.UUID) ([]repository.AiDraft, error)
}

// GenerationParams configures Gemini decoding, thinking budget, safety, and structured schema settings.
type GenerationParams struct {
	Temperature      float32
	TopP             float32
	TopK             int
	PresencePenalty  float32
	FrequencyPenalty float32
	MaxOutputTokens  int
	ThinkingBudget   int
	SafetyThreshold  string
	ResponseMIMEType string
	ResponseSchema   *ToolParameterSchema
}

// ToolCall represents a single model function call returned during Pass 1 planning.
type ToolCall struct {
	ID               string         `json:"id,omitempty"`
	Name             string         `json:"name"`
	Args             map[string]any `json:"args,omitempty"`
	ThoughtSignature []byte         `json:"-"`
}

// ToolResponse carries deterministic backend tool output back to the Pass 1 conversation.
type ToolResponse struct {
	ID       string         `json:"id,omitempty"`
	Name     string         `json:"name"`
	Response map[string]any `json:"response"`
}

// LLMPart represents one multimodal, text, function-call, or function-response unit inside LLMMessage.
type LLMPart struct {
	Text             string
	MIMEType         string
	InlineBytes      []byte
	FunctionCall     *ToolCall
	FunctionResponse *ToolResponse
}

// LLMMessage represents one chronological turn in the LLM conversation.
type LLMMessage struct {
	Role  string
	Parts []LLMPart
}

// GenerateRequest carries all pass-specific instructions, tools, caching keys, and parameters to LLMClient.
type GenerateRequest struct {
	Model              string
	Pass               string
	SystemInstruction  string
	Contents           []LLMMessage
	ToolDeclarations   []ToolDeclaration
	EnableGoogleSearch bool
	CacheKey           string
	Params             GenerationParams
}

// GenerateResponse represents normalized output returned by LLMClient.
type GenerateResponse struct {
	Text             string
	FunctionCalls    []ToolCall
	GroundingSources []string
	UsedContextCache bool
	CacheName        string
}

// SSEEvent wraps one Server-Sent Event frame emitted by ChatStream.
type SSEEvent struct {
	Type string `json:"type"`
	Data any    `json:"data"`
}

// SSEThinkingStepEvent represents a live processing trace update streamed during Pass 1 and Pass 2.
type SSEThinkingStepEvent struct {
	StepNumber      int    `json:"step_number"`
	Title           string `json:"title"`
	Detail          string `json:"detail"`
	Status          string `json:"status"`
	SessionID       string `json:"session_id"`
	ClientRequestID string `json:"client_request_id"`
}

// SSEFinalResponseEvent represents the terminal structured AI payload streamed over SSE.
type SSEFinalResponseEvent struct {
	SessionID       string `json:"session_id"`
	ClientRequestID string `json:"client_request_id"`
	RequestID       string `json:"request_id"`
	SurfaceMode     string `json:"surface_mode"`
	IsPrefiltered   bool   `json:"is_prefiltered"`
	PlanType        string `json:"plan_type"`
	QuotaTotal      int    `json:"quota_total"`
	QuotaUsed       int    `json:"quota_used"`
	QuotaRemaining  int    `json:"quota_remaining"`
	AiStructuredResponse
}

// SSEErrorEvent represents a terminal error frame emitted after an SSE stream has started.
type SSEErrorEvent struct {
	Code            string `json:"code"`
	Message         string `json:"message"`
	RequestID       string `json:"request_id,omitempty"`
	SessionID       string `json:"session_id,omitempty"`
	ClientRequestID string `json:"client_request_id,omitempty"`
}

// ChatRequest captures POST /v1/ai/chat inputs.
type ChatRequest struct {
	SessionID       string           `json:"session_id"`
	ClientRequestID string           `json:"client_request_id"`
	RequestID       string           `json:"-"`
	Message         string           `json:"message"`
	SurfaceMode     string           `json:"surface_mode"`
	SessionHistory  []RawHistoryTurn `json:"session_history,omitempty"`
}

// ChatResult summarizes the completed chat turn and updated quota state.
type ChatResult struct {
	SessionID       string               `json:"session_id"`
	ClientRequestID string               `json:"client_request_id"`
	RequestID       string               `json:"request_id,omitempty"`
	SurfaceMode     string               `json:"surface_mode"`
	IsPrefiltered   bool                 `json:"is_prefiltered"`
	Response        AiStructuredResponse `json:"response"`
	QuotaStatus     service.QuotaStatus  `json:"quota_status"`
}

// QuickAddRequest captures POST /v1/ai/quick-add text or voice transcript extraction inputs.
type QuickAddRequest struct {
	ClientRequestID   string `json:"client_request_id"`
	Text              string `json:"text"`
	Source            string `json:"source"`
	DefaultWalletHint string `json:"default_wallet_hint,omitempty"`
}

// OCRRequest captures POST /v1/ai/ocr receipt image extraction inputs.
type OCRRequest struct {
	ClientRequestID   string `json:"client_request_id"`
	MIMEType          string `json:"mime_type"`
	ImageBytes        []byte `json:"-"`
	DefaultWalletHint string `json:"default_wallet_hint,omitempty"`
	Caption           string `json:"caption,omitempty"`
}

// DraftExtractionResult returns staged ai_drafts rows or missing_wallet guidance for quick-add and OCR.
type DraftExtractionResult struct {
	Status              string                   `json:"status"`
	BatchID             *uuid.UUID               `json:"batch_id,omitempty"`
	Drafts              []service.AIDraftDTO     `json:"drafts"`
	WalletCreationDraft *WalletCreationDraft     `json:"wallet_creation_draft,omitempty"`
	PendingItems        []PendingTransactionItem `json:"pending_items,omitempty"`
	QuotaStatus         service.QuotaStatus      `json:"quota_status"`
}

// OrchestratorConfig configures Strict Two-Pass orchestration dependencies.
type OrchestratorConfig struct {
	Model      string
	LLM        LLMClient
	Quota      QuotaManager
	Financial  FinancialToolProvider
	Actions    ActionToolProvider
	Matching   MatchingToolProvider
	DraftRepo  AIDraftRepository
	Logger     *zap.Logger
	NowFunc    func() time.Time
	JakartaLoc *time.Location
}

// Orchestrator executes pre-filtering, quota accounting, Strict Two-Pass LLM calls, and draft extraction.
type Orchestrator struct {
	model      string
	llm        LLMClient
	quota      QuotaManager
	financial  FinancialToolProvider
	actions    ActionToolProvider
	matching   MatchingToolProvider
	draftRepo  AIDraftRepository
	logger     *zap.Logger
	nowFn      func() time.Time
	jakartaLoc *time.Location
}

// NewOrchestrator constructs a Strict Two-Pass AI Orchestrator.
func NewOrchestrator(cfg OrchestratorConfig) *Orchestrator {
	loc := cfg.JakartaLoc
	if loc == nil {
		var err error
		loc, err = time.LoadLocation("Asia/Jakarta")
		if err != nil {
			loc = time.FixedZone("WIB", 7*3600)
		}
	}
	nowFn := cfg.NowFunc
	if nowFn == nil {
		nowFn = time.Now
	}
	logger := cfg.Logger
	if logger == nil {
		logger = zap.NewNop()
	}
	model := strings.TrimSpace(cfg.Model)
	if model == "" {
		model = "gemini-2.5-flash"
	}

	return &Orchestrator{
		model:      model,
		llm:        cfg.LLM,
		quota:      cfg.Quota,
		financial:  cfg.Financial,
		actions:    cfg.Actions,
		matching:   cfg.Matching,
		draftRepo:  cfg.DraftRepo,
		logger:     logger,
		nowFn:      nowFn,
		jakartaLoc: loc,
	}
}

// ChatStream runs pre-filter/history checks, reserves quota, executes Pass 1 & Pass 2, and emits SSE events.
func (o *Orchestrator) ChatStream(
	ctx context.Context,
	userID uuid.UUID,
	req ChatRequest,
	emit func(SSEEvent) error,
) (*ChatResult, error) {
	if o == nil || o.llm == nil || o.quota == nil {
		return nil, ErrOrchestratorUnavailable
	}
	if userID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrInvalidChatRequest)
	}

	msg := strings.TrimSpace(req.Message)
	if msg == "" {
		return nil, fmt.Errorf("%w: message is required", ErrInvalidChatRequest)
	}

	surfaceMode, err := normalizeSurfaceMode(req.SurfaceMode)
	if err != nil {
		return nil, err
	}

	history, err := SanitizeSessionHistory(req.SessionHistory)
	if err != nil {
		return nil, err
	}

	sessionID := strings.TrimSpace(req.SessionID)
	if sessionID == "" {
		sessionID = "sess_" + uuid.NewString()
	}
	clientReqID := normalizeClientRequestID(req.ClientRequestID)
	if len(clientReqID) > 128 {
		return nil, fmt.Errorf("%w: client_request_id exceeds 128 characters", service.ErrInvalidQuotaRequest)
	}
	traceReqID := strings.TrimSpace(req.RequestID)
	if traceReqID == "" {
		traceReqID = clientReqID
	}

	if emit == nil {
		emit = func(SSEEvent) error { return nil }
	}

	// Pure greetings bypass LLM and consume 0 AI quota.
	if reply, matched := MatchPureGreeting(msg); matched {
		qStatus, qErr := o.quota.GetQuotaStatus(ctx, userID)
		if qErr != nil {
			return nil, qErr
		}
		structured := AiStructuredResponse{
			Narrative:       sanitizeNoEmDash(reply),
			ThinkingSummary: []ThinkingStep{},
		}
		finalEvent := SSEFinalResponseEvent{
			SessionID:            sessionID,
			ClientRequestID:      clientReqID,
			RequestID:            traceReqID,
			SurfaceMode:          surfaceMode,
			IsPrefiltered:        true,
			PlanType:             qStatus.PlanType,
			QuotaTotal:           qStatus.QuotaTotal,
			QuotaUsed:            qStatus.QuotaUsed,
			QuotaRemaining:       qStatus.QuotaRemaining,
			AiStructuredResponse: structured,
		}
		if err := emit(SSEEvent{Type: SSEEventFinalResponse, Data: finalEvent}); err != nil {
			return nil, err
		}
		return &ChatResult{
			SessionID:       sessionID,
			ClientRequestID: clientReqID,
			RequestID:       traceReqID,
			SurfaceMode:     surfaceMode,
			IsPrefiltered:   true,
			Response:        structured,
			QuotaStatus:     *qStatus,
		}, nil
	}

	reservation, err := o.quota.ReserveAction(ctx, userID, clientReqID, "chat", surfaceMode)
	if err != nil {
		return nil, err
	}
	if reservation.Reused {
		return nil, fmt.Errorf("%w: duplicate client_request_id %q", service.ErrReservationFinalized, clientReqID)
	}

	committed := false
	compensated := false
	compensateOnce := func() {
		if committed || compensated {
			return
		}
		compensated = true
		compCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if compErr := o.quota.CompensateFailure(compCtx, clientReqID); compErr != nil {
			o.logger.Error("failed to compensate quota reservation", zap.String("request_id", clientReqID), zap.Error(compErr))
		}
	}
	failWithSSE := func(code, message string, cause error) (*ChatResult, error) {
		compensateOnce()
		_ = emit(SSEEvent{
			Type: SSEEventError,
			Data: SSEErrorEvent{
				Code:            code,
				Message:         sanitizeNoEmDash(message),
				RequestID:       traceReqID,
				SessionID:       sessionID,
				ClientRequestID: clientReqID,
			},
		})
		return nil, cause
	}

	stepNum := 1
	emitStep := func(title, detail, status string) error {
		err := emit(SSEEvent{
			Type: SSEEventThinkingStep,
			Data: SSEThinkingStepEvent{
				StepNumber:      stepNum,
				Title:           sanitizeNoEmDash(title),
				Detail:          sanitizeNoEmDash(detail),
				Status:          status,
				SessionID:       sessionID,
				ClientRequestID: clientReqID,
			},
		})
		if status == "completed" {
			stepNum++
		}
		return err
	}

	if err := emitStep("Memahami maksud & konteks chat", "Menganalisa permintaan dan konteks obrolan.", "in_progress"); err != nil {
		compensateOnce()
		return nil, err
	}
	stepNum++

	nowWIB := o.nowFn().In(o.jakartaLoc)
	sysPrompt, err := prompts.RenderSystemPromptV2(prompts.SystemPromptInput{
		SurfaceMode:    surfaceMode,
		CurrentDateWIB: nowWIB.Format("2006-01-02 (WIB)"),
	})
	if err != nil {
		return failWithSSE(domain.ErrCodeInternalError, "Gagal memuat konfigurasi sistem Clarafin AI.", err)
	}

	bundle, pass1Summary, err := o.runPass1(ctx, userID, surfaceMode, sysPrompt, history, msg, &stepNum, sessionID, clientReqID, emit)
	if err != nil {
		return failWithSSE(domain.ErrCodeInternalError, "Terjadi kendala saat mengambil data keuangan atau merencanakan aksi.", err)
	}

	if err := emitStep("Menyusun jawaban & komponen aksi", "Memformat hasil analisa dan kartu konfirmasi.", "in_progress"); err != nil {
		compensateOnce()
		return nil, err
	}

	structured, err := o.runPass2WithRetry(ctx, surfaceMode, sysPrompt, msg, bundle, pass1Summary)
	if err != nil {
		return failWithSSE(domain.ErrCodeInternalError, "Clarafin AI gagal menyusun format jawaban terstruktur. Kuota kamu tidak dipotong.", err)
	}

	if err := o.quota.CommitSuccess(ctx, clientReqID); err != nil {
		return failWithSSE(domain.ErrCodeInternalError, "Gagal menyelesaikan pencatatan kuota AI.", err)
	}
	committed = true

	finalEvent := SSEFinalResponseEvent{
		SessionID:            sessionID,
		ClientRequestID:      clientReqID,
		RequestID:            traceReqID,
		SurfaceMode:          surfaceMode,
		IsPrefiltered:        false,
		PlanType:             reservation.QuotaStatus.PlanType,
		QuotaTotal:           reservation.QuotaStatus.QuotaTotal,
		QuotaUsed:            reservation.QuotaStatus.QuotaUsed,
		QuotaRemaining:       reservation.QuotaStatus.QuotaRemaining,
		AiStructuredResponse: *structured,
	}
	if err := emit(SSEEvent{Type: SSEEventFinalResponse, Data: finalEvent}); err != nil {
		return nil, err
	}

	return &ChatResult{
		SessionID:       sessionID,
		ClientRequestID: clientReqID,
		RequestID:       traceReqID,
		SurfaceMode:     surfaceMode,
		IsPrefiltered:   false,
		Response:        *structured,
		QuotaStatus:     reservation.QuotaStatus,
	}, nil
}

type quickExtractionPayload struct {
	DefaultWalletHint string  `json:"default_wallet_hint,omitempty"`
	ConfidenceScore   float32 `json:"confidence_score,omitempty"`
	Items             []struct {
		Title            string `json:"title"`
		AmountIDR        int64  `json:"amount_idr"`
		Type             string `json:"type"`
		RawCategory      string `json:"raw_category"`
		Note             string `json:"note,omitempty"`
		WalletHint       string `json:"wallet_hint,omitempty"`
		TargetWalletHint string `json:"target_wallet_hint,omitempty"`
	} `json:"items"`
}

// QuickAddDraft extracts 1..N transactions from natural text or voice transcript and stages them in ai_drafts.
func (o *Orchestrator) QuickAddDraft(ctx context.Context, userID uuid.UUID, req QuickAddRequest) (*DraftExtractionResult, error) {
	if o == nil || o.llm == nil || o.quota == nil || o.actions == nil || o.draftRepo == nil {
		return nil, ErrOrchestratorUnavailable
	}
	if userID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrInvalidChatRequest)
	}

	text := strings.TrimSpace(req.Text)
	if text == "" {
		return nil, fmt.Errorf("%w: text is required", ErrInvalidChatRequest)
	}

	source := strings.ToLower(strings.TrimSpace(req.Source))
	if source == "" {
		source = "ai_text"
	}
	var actionType, surfaceMode string
	switch source {
	case "ai_text":
		actionType = "quick_add"
		surfaceMode = "quick_sheet"
	case "ai_voice":
		actionType = "voice"
		surfaceMode = "voice"
	default:
		return nil, fmt.Errorf("%w: unsupported quick-add source %q", ErrInvalidChatRequest, req.Source)
	}

	promptParts := []LLMPart{{Text: buildQuickAddExtractionPrompt(text, req.DefaultWalletHint)}}
	return o.extractAndStageDrafts(ctx, userID, req.ClientRequestID, actionType, surfaceMode, source, req.DefaultWalletHint, promptParts)
}

// OCRDraft extracts transaction items from a receipt image and stages them in ai_drafts.
func (o *Orchestrator) OCRDraft(ctx context.Context, userID uuid.UUID, req OCRRequest) (*DraftExtractionResult, error) {
	if o == nil || o.llm == nil || o.quota == nil || o.actions == nil || o.draftRepo == nil {
		return nil, ErrOrchestratorUnavailable
	}
	if userID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrInvalidChatRequest)
	}
	if len(req.ImageBytes) == 0 {
		return nil, fmt.Errorf("%w: receipt image is required", ErrInvalidChatRequest)
	}
	if len(req.ImageBytes) > maxOCRImageBytes {
		return nil, fmt.Errorf("%w: image exceeds maximum 8 MiB limit", ErrInvalidChatRequest)
	}

	mimeType := strings.ToLower(strings.TrimSpace(req.MIMEType))
	switch mimeType {
	case "image/jpeg", "image/png", "image/webp":
	default:
		return nil, fmt.Errorf("%w: unsupported image mime_type %q", ErrInvalidChatRequest, req.MIMEType)
	}

	parts := []LLMPart{
		{Text: buildOCRExtractionPrompt(req.Caption, req.DefaultWalletHint)},
		{InlineBytes: req.ImageBytes, MIMEType: mimeType},
	}
	return o.extractAndStageDrafts(ctx, userID, req.ClientRequestID, "ocr", "ocr", "ocr", req.DefaultWalletHint, parts)
}

func (o *Orchestrator) extractAndStageDrafts(
	ctx context.Context,
	userID uuid.UUID,
	rawClientReqID, actionType, surfaceMode, source, defaultWalletHint string,
	parts []LLMPart,
) (*DraftExtractionResult, error) {
	clientReqID := normalizeClientRequestID(rawClientReqID)
	if len(clientReqID) > 128 {
		return nil, fmt.Errorf("%w: client_request_id exceeds 128 characters", service.ErrInvalidQuotaRequest)
	}
	reservation, err := o.quota.ReserveAction(ctx, userID, clientReqID, actionType, surfaceMode)
	if err != nil {
		return nil, err
	}
	if reservation.Reused {
		return nil, fmt.Errorf("%w: duplicate client_request_id %q", service.ErrReservationFinalized, clientReqID)
	}

	committed := false
	compensated := false
	compensateOnce := func() {
		if committed || compensated {
			return
		}
		compensated = true
		compCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = o.quota.CompensateFailure(compCtx, clientReqID)
	}

	schema := BuildQuickDraftExtractionSchema()
	sysInst := "Kamu adalah ekstraktor transaksi Clarafin. Ekstrak 1 atau lebih item transaksi dalam format JSON ketat dengan nominal bilangan bulat IDR. Gunakan slang Indonesia (rb/k=x1000, jt=x1000000, goceng=5000, gocap=50000, cepek=100000). Jangan pernah menyertakan em dash."

	var extracted quickExtractionPayload
	var parseErr error
	conv := []LLMMessage{{Role: "user", Parts: parts}}

	for attempt := 0; attempt < 2; attempt++ {
		resp, callErr := o.llm.GenerateContent(ctx, GenerateRequest{
			Model:             o.model,
			Pass:              PassExtraction,
			SystemInstruction: sysInst,
			Contents:          conv,
			CacheKey:          "clarafin_extract_" + prompts.PrefixHash(sysInst),
			Params: GenerationParams{
				Temperature:      0.1,
				TopP:             0.85,
				TopK:             40,
				PresencePenalty:  0.0,
				FrequencyPenalty: 0.0,
				MaxOutputTokens:  1024,
				ThinkingBudget:   128,
				SafetyThreshold:  SafetyBlockMediumAndAbove,
				ResponseMIMEType: "application/json",
				ResponseSchema:   schema,
			},
		})
		if callErr != nil || resp == nil {
			compensateOnce()
			return nil, fmt.Errorf("extraction LLM call: %w", callErr)
		}

		clean := stripJSONCodeFence(resp.Text)
		var attemptPayload quickExtractionPayload
		if err := json.Unmarshal([]byte(clean), &attemptPayload); err != nil || len(attemptPayload.Items) == 0 {
			parseErr = fmt.Errorf("%w: invalid extraction JSON (%v)", ErrInvalidStructuredResponse, err)
			conv = append(conv,
				LLMMessage{Role: "model", Parts: []LLMPart{{Text: resp.Text}}},
				LLMMessage{Role: "user", Parts: []LLMPart{{Text: "JSON tidak valid atau items kosong. Ulangi dengan JSON valid sesuai schema dan minimal 1 item."}}},
			)
			continue
		}
		extracted = attemptPayload
		parseErr = nil
		break
	}
	if parseErr != nil {
		compensateOnce()
		return nil, parseErr
	}

	resolvedDefaultWallet := strings.TrimSpace(defaultWalletHint)
	if resolvedDefaultWallet == "" {
		resolvedDefaultWallet = strings.TrimSpace(extracted.DefaultWalletHint)
	}

	prepItems := make([]PrepareTransactionItemInput, 0, len(extracted.Items))
	for _, item := range extracted.Items {
		prepItems = append(prepItems, PrepareTransactionItemInput{
			Title:            strings.TrimSpace(item.Title),
			AmountIDR:        item.AmountIDR,
			Type:             strings.ToLower(strings.TrimSpace(item.Type)),
			RawCategory:      strings.TrimSpace(item.RawCategory),
			Note:             strings.TrimSpace(item.Note),
			WalletHint:       strings.TrimSpace(item.WalletHint),
			TargetWalletHint: strings.TrimSpace(item.TargetWalletHint),
		})
	}

	prep, err := o.actions.CheckAndPrepareTransaction(ctx, userID, PrepareTransactionInput{
		DefaultWalletHint: resolvedDefaultWallet,
		Items:             prepItems,
	})
	if err != nil {
		compensateOnce()
		return nil, err
	}

	if prep.Status == "missing_wallet" || prep.TransactionDraft == nil {
		if err := o.quota.CommitSuccess(ctx, clientReqID); err != nil {
			compensateOnce()
			return nil, err
		}
		committed = true
		return &DraftExtractionResult{
			Status:              "missing_wallet",
			Drafts:              []service.AIDraftDTO{},
			WalletCreationDraft: prep.WalletCreationDraft,
			PendingItems:        prep.PendingItems,
			QuotaStatus:         reservation.QuotaStatus,
		}, nil
	}

	batchID := uuid.New()
	conf := extracted.ConfidenceScore
	if conf <= 0 || conf > 1 {
		conf = 0.9
	}

	dtos := make([]service.AIDraftDTO, 0, len(prep.TransactionDraft.Items))
	for idx, item := range prep.TransactionDraft.Items {
		mutID := scopedMutationID(clientReqID, idx)
		note := strings.TrimSpace(item.Note)
		if note == "" {
			note = item.Title
		}
		walletID := item.WalletID
		created, err := o.draftRepo.CreateAIDraft(ctx, repository.CreateAIDraftParams{
			UserID:              userID,
			WalletID:            &walletID,
			DestinationWalletID: item.TargetWalletID,
			BatchID:             &batchID,
			Source:              source,
			ClientMutationID:    &mutID,
			Type:                item.Type,
			Category:            item.CanonicalCategory,
			Amount:              item.AmountIDR,
			Title:               item.Title,
			MerchantOrNote:      note,
			OccurredAt:          item.OccurredAt,
			ConfidenceScore:     conf,
		})
		if err != nil {
			compensateOnce()
			return nil, fmt.Errorf("create ai draft %d: %w", idx, err)
		}
		dtos = append(dtos, aiDraftRowToDTO(created))
	}

	if err := o.quota.CommitSuccess(ctx, clientReqID); err != nil {
		compensateOnce()
		return nil, err
	}
	committed = true

	return &DraftExtractionResult{
		Status:      "ready",
		BatchID:     &batchID,
		Drafts:      dtos,
		QuotaStatus: reservation.QuotaStatus,
	}, nil
}

func (o *Orchestrator) runPass1(
	ctx context.Context,
	userID uuid.UUID,
	surfaceMode string,
	sysPrompt string,
	history []SanitizedTurn,
	userMessage string,
	stepNum *int,
	sessionID string,
	clientReqID string,
	emit func(SSEEvent) error,
) (*Pass1ToolBundle, string, error) {
	toolDecls := BuildPass1ToolDeclarations()
	cacheKey := "clarafin_p1_" + surfaceMode + "_" + prompts.PrefixHash(sysPrompt)

	conv := make([]LLMMessage, 0, len(history)+1)
	for _, h := range history {
		conv = append(conv, LLMMessage{
			Role:  h.Role,
			Parts: []LLMPart{{Text: h.Text}},
		})
	}
	conv = append(conv, LLMMessage{
		Role:  "user",
		Parts: []LLMPart{{Text: userMessage}},
	})

	bundle := &Pass1ToolBundle{}
	var observationText string

	for iter := 0; iter < maxPass1ToolIterations; iter++ {
		resp, err := o.llm.GenerateContent(ctx, GenerateRequest{
			Model:              o.model,
			Pass:               Pass1ToolPlanning,
			SystemInstruction:  sysPrompt,
			Contents:           conv,
			ToolDeclarations:   toolDecls,
			EnableGoogleSearch: false,
			CacheKey:           cacheKey,
			Params: GenerationParams{
				Temperature:     0.1,
				TopP:            0.85,
				TopK:            40,
				MaxOutputTokens: 1024,
				ThinkingBudget:  128,
				SafetyThreshold: SafetyBlockMediumAndAbove,
			},
		})
		if err != nil || resp == nil {
			return nil, "", fmt.Errorf("pass 1 generation failed: %w", err)
		}

		if len(resp.FunctionCalls) == 0 {
			observationText = strings.TrimSpace(resp.Text)
			break
		}

		modelParts := make([]LLMPart, 0, len(resp.FunctionCalls))
		for i := range resp.FunctionCalls {
			fc := resp.FunctionCalls[i]
			modelParts = append(modelParts, LLMPart{FunctionCall: &fc})
		}
		conv = append(conv, LLMMessage{Role: "model", Parts: modelParts})

		responseParts := make([]LLMPart, 0, len(resp.FunctionCalls))
		for _, tc := range resp.FunctionCalls {
			title, detail := describeToolStep(tc.Name, tc.Args)
			outMap, stepErr := o.executePass1Tool(ctx, userID, tc, bundle)
			status := "completed"
			if stepErr != nil {
				status = "failed"
				if isFatalToolError(stepErr) {
					return nil, "", stepErr
				}
				outMap = map[string]any{"error": stepErr.Error()}
			}

			step := ThinkingStep{
				StepNumber: *stepNum,
				Title:      sanitizeNoEmDash(title),
				Detail:     sanitizeNoEmDash(detail),
				Status:     status,
			}
			bundle.ExecutedSteps = append(bundle.ExecutedSteps, step)
			if err := emit(SSEEvent{
				Type: SSEEventThinkingStep,
				Data: SSEThinkingStepEvent{
					StepNumber:      step.StepNumber,
					Title:           step.Title,
					Detail:          step.Detail,
					Status:          step.Status,
					SessionID:       sessionID,
					ClientRequestID: clientReqID,
				},
			}); err != nil {
				return nil, "", err
			}
			*stepNum++

			responseParts = append(responseParts, LLMPart{
				FunctionResponse: &ToolResponse{
					ID:       tc.ID,
					Name:     tc.Name,
					Response: outMap,
				},
			})
		}
		conv = append(conv, LLMMessage{Role: "user", Parts: responseParts})
	}

	return bundle, observationText, nil
}

func (o *Orchestrator) executePass1Tool(
	ctx context.Context,
	userID uuid.UUID,
	tc ToolCall,
	bundle *Pass1ToolBundle,
) (map[string]any, error) {
	switch tc.Name {
	case "get_user_wallets":
		if o.financial == nil {
			return nil, ErrOrchestratorUnavailable
		}
		out, err := o.financial.GetUserWallets(ctx, userID)
		if err != nil {
			return nil, err
		}
		bundle.Wallets = out
		return structToMap(out)

	case "get_cashflow_summary":
		if o.financial == nil {
			return nil, ErrOrchestratorUnavailable
		}
		var input CashflowQueryInput
		if err := decodeToolArgs(tc.Args, &input); err != nil {
			return nil, fmt.Errorf("%w: %v", ErrInvalidFinancialToolInput, err)
		}
		out, err := o.financial.GetCashflowSummary(ctx, userID, input)
		if err != nil {
			return nil, err
		}
		switch strings.ToLower(strings.TrimSpace(out.GroupBy)) {
		case "income_to_expense_flow":
			bundle.FlowCashflow = out
		case "merchant":
			bundle.MerchantCashflow = out
		case "wallet":
			bundle.WalletCashflow = out
		default:
			if strings.ToLower(strings.TrimSpace(input.GroupBy)) == "income_to_expense_flow" {
				bundle.FlowCashflow = out
			} else if strings.ToLower(strings.TrimSpace(input.GroupBy)) == "merchant" {
				bundle.MerchantCashflow = out
			} else {
				bundle.CategoryCashflow = out
			}
		}
		return structToMap(out)

	case "get_budget_and_bills_status":
		if o.financial == nil {
			return nil, ErrOrchestratorUnavailable
		}
		out, err := o.financial.GetBudgetAndBillsStatus(ctx, userID)
		if err != nil {
			return nil, err
		}
		bundle.BudgetBills = out
		return structToMap(out)

	case "check_and_prepare_transaction":
		if o.actions == nil {
			return nil, ErrOrchestratorUnavailable
		}
		var input PrepareTransactionInput
		if err := decodeToolArgs(tc.Args, &input); err != nil {
			return nil, fmt.Errorf("%w: %v", ErrInvalidActionToolInput, err)
		}
		if len(input.Items) == 0 {
			var singleItem PrepareTransactionItemInput
			if err := decodeToolArgs(tc.Args, &singleItem); err == nil && (strings.TrimSpace(singleItem.Title) != "" || singleItem.AmountIDR > 0) {
				input.Items = []PrepareTransactionItemInput{singleItem}
			}
		}
		out, err := o.actions.CheckAndPrepareTransaction(ctx, userID, input)
		if err != nil {
			return nil, err
		}
		bundle.TxChecks = append(bundle.TxChecks, out)
		bundle.PrepareTx = mergePrepareTransactionResults(bundle.TxChecks)
		return structToMap(out)

	case "propose_goal_draft":
		if o.actions == nil {
			return nil, ErrOrchestratorUnavailable
		}
		var input GoalDraftInput
		if err := decodeToolArgs(tc.Args, &input); err != nil {
			return nil, fmt.Errorf("%w: %v", ErrInvalidActionToolInput, err)
		}
		out, err := o.actions.ProposeGoalDraft(ctx, userID, input)
		if err != nil {
			return nil, err
		}
		bundle.GoalDraft = out
		return structToMap(out)

	case "propose_budget_draft":
		if o.actions == nil {
			return nil, ErrOrchestratorUnavailable
		}
		var input BudgetDraftInput
		if err := decodeToolArgs(tc.Args, &input); err != nil {
			return nil, fmt.Errorf("%w: %v", ErrInvalidActionToolInput, err)
		}
		out, err := o.actions.ProposeBudgetDraft(ctx, userID, input)
		if err != nil {
			return nil, err
		}
		bundle.BudgetDraft = out
		return structToMap(out)

	case "propose_bill_draft":
		if o.actions == nil {
			return nil, ErrOrchestratorUnavailable
		}
		var input BillDraftInput
		if err := decodeToolArgs(tc.Args, &input); err != nil {
			return nil, fmt.Errorf("%w: %v", ErrInvalidActionToolInput, err)
		}
		out, err := o.actions.ProposeBillDraft(ctx, userID, input)
		if err != nil {
			return nil, err
		}
		bundle.BillDraft = out
		return structToMap(out)

	case "match_experts_and_package":
		if o.matching == nil {
			return nil, ErrOrchestratorUnavailable
		}
		var signals MatchSignals
		if err := decodeToolArgs(tc.Args, &signals); err != nil {
			return nil, fmt.Errorf("%w: %v", ErrInvalidMatchingInput, err)
		}
		out, err := o.matching.MatchExpertsAndPackage(ctx, userID, signals)
		if err != nil {
			return nil, err
		}
		bundle.Matching = out
		return structToMap(out)

	case "search_financial_knowledge":
		query, _ := tc.Args["query"].(string)
		query = strings.TrimSpace(query)
		if query == "" {
			return nil, fmt.Errorf("%w: search query is required", ErrInvalidChatRequest)
		}
		// Isolated google_search grounding sub-call: NEVER mix with custom function declarations.
		searchResp, err := o.llm.GenerateContent(ctx, GenerateRequest{
			Model:              o.model,
			Pass:               Pass1SearchGround,
			SystemInstruction:  "Cari dan ringkas fakta ekonomi atau aturan keuangan umum secara objektif dalam Bahasa Indonesia. Jangan sebut merek produk atau saham spesifik.",
			Contents:           []LLMMessage{{Role: "user", Parts: []LLMPart{{Text: query}}}},
			ToolDeclarations:   nil,
			EnableGoogleSearch: true,
			Params: GenerationParams{
				Temperature:     0.1,
				TopP:            0.85,
				TopK:            40,
				MaxOutputTokens: 512,
				ThinkingBudget:  0,
				SafetyThreshold: SafetyBlockMediumAndAbove,
			},
		})
		if err != nil {
			return nil, fmt.Errorf("isolated google_search sub-call: %w", err)
		}
		summary := sanitizeNoEmDash(strings.TrimSpace(searchResp.Text))
		if summary != "" {
			bundle.SearchSummaries = append(bundle.SearchSummaries, summary)
		}
		bundle.SearchSources = append(bundle.SearchSources, searchResp.GroundingSources...)
		return map[string]any{
			"query":   query,
			"summary": summary,
			"sources": searchResp.GroundingSources,
		}, nil

	default:
		return map[string]any{"error": fmt.Sprintf("unknown tool %q", tc.Name)}, nil
	}
}

func (o *Orchestrator) runPass2WithRetry(
	ctx context.Context,
	surfaceMode string,
	sysPrompt string,
	userMessage string,
	bundle *Pass1ToolBundle,
	pass1Summary string,
) (*AiStructuredResponse, error) {
	responseSchema := BuildStructuredResponseSchema()
	cacheKey := "clarafin_p2_" + surfaceMode + "_" + prompts.PrefixHash(sysPrompt)

	maxTokens := 2048
	if surfaceMode == "quick_sheet" {
		maxTokens = 1024
	}
	thinkingBudget := computePass2ThinkingBudget(surfaceMode, bundle)

	synthesisPrompt := buildPass2SynthesisPrompt(surfaceMode, userMessage, bundle, pass1Summary)
	conv := []LLMMessage{{Role: "user", Parts: []LLMPart{{Text: synthesisPrompt}}}}

	var lastErr error
	for attempt := 0; attempt < 2; attempt++ {
		resp, err := o.llm.GenerateContent(ctx, GenerateRequest{
			Model:              o.model,
			Pass:               Pass2StructuredJSON,
			SystemInstruction:  sysPrompt,
			Contents:           conv,
			ToolDeclarations:   nil,
			EnableGoogleSearch: false,
			CacheKey:           cacheKey,
			Params: GenerationParams{
				Temperature:      0.28,
				TopP:             0.85,
				TopK:             40,
				PresencePenalty:  0.0,
				FrequencyPenalty: 0.0,
				MaxOutputTokens:  maxTokens,
				ThinkingBudget:   thinkingBudget,
				SafetyThreshold:  SafetyBlockMediumAndAbove,
				ResponseMIMEType: "application/json",
				ResponseSchema:   responseSchema,
			},
		})
		if err != nil || resp == nil {
			return nil, fmt.Errorf("pass 2 generation failed: %w", err)
		}

		var parsed AiStructuredResponse
		cleanJSON := stripJSONCodeFence(resp.Text)
		if err := json.Unmarshal([]byte(cleanJSON), &parsed); err != nil {
			lastErr = fmt.Errorf("%w: malformed JSON (%v)", ErrInvalidStructuredResponse, err)
			conv = append(conv,
				LLMMessage{Role: "model", Parts: []LLMPart{{Text: resp.Text}}},
				LLMMessage{Role: "user", Parts: []LLMPart{{Text: fmt.Sprintf("JSON sebelumnya tidak valid (%v). Keluarkan hanya satu objek JSON valid sesuai skema AiStructuredResponse dengan field narrative tidak kosong.", err)}}},
			)
			continue
		}

		if _, err := ValidateAndReconcileStructuredResponse(&parsed, bundle); err != nil {
			lastErr = err
			conv = append(conv,
				LLMMessage{Role: "model", Parts: []LLMPart{{Text: resp.Text}}},
				LLMMessage{Role: "user", Parts: []LLMPart{{Text: fmt.Sprintf("Output JSON sebelumnya melanggar skema (%v). Perbaiki dan keluarkan hanya objek JSON valid sesuai AiStructuredResponse.", err)}}},
			)
			continue
		}

		return &parsed, nil
	}

	if lastErr == nil {
		lastErr = ErrInvalidStructuredResponse
	}
	return nil, lastErr
}

// BuildPass1ToolDeclarations constructs the 9 deterministic function schemas declared in Pass 1.
func BuildPass1ToolDeclarations() []ToolDeclaration {
	catEnum := CanonicalCategoryEnum()
	expenseMainEnum := CanonicalExpenseMainCategoryEnum()

	return []ToolDeclaration{
		{
			Name:        "get_user_wallets",
			Description: "Mengambil daftar dompet aktif milik pengguna beserta saldo riil dalam IDR.",
			Parameters: &ToolParameterSchema{
				Type:       "OBJECT",
				Properties: map[string]*ToolParameterSchema{},
			},
		},
		{
			Name:        "get_cashflow_summary",
			Description: "Menghitung agregasi SQL akurat pemasukan, pengeluaran, dan transfer pengguna untuk periode tertentu.",
			Parameters: &ToolParameterSchema{
				Type: "OBJECT",
				Properties: map[string]*ToolParameterSchema{
					"period":         {Type: "STRING", Description: "this_month, last_month, last_30_days, last_90_days, atau YYYY-MM."},
					"group_by":       {Type: "STRING", Enum: []string{"category", "merchant", "wallet", "income_to_expense_flow"}},
					"keyword_filter": {Type: "STRING", Description: "Kata kunci merchant atau topik opsional, misal kopi atau ojol."},
				},
				Required: []string{"period", "group_by"},
			},
		},
		{
			Name:        "get_budget_and_bills_status",
			Description: "Mengambil progres batas anggaran bulan ini, target tabungan (goals), dan tagihan jatuh tempo.",
			Parameters: &ToolParameterSchema{
				Type:       "OBJECT",
				Properties: map[string]*ToolParameterSchema{},
			},
		},
		{
			Name:        "check_and_prepare_transaction",
			Description: "Memvalidasi dompet terhadap dompet aktif user dan menyiapkan draf transaksi atau WalletCreationDraft jika dompet belum ada.",
			Parameters: &ToolParameterSchema{
				Type: "OBJECT",
				Properties: map[string]*ToolParameterSchema{
					"default_wallet_hint": {Type: "STRING"},
					"wallet_hint":         {Type: "STRING"},
					"target_wallet_hint":  {Type: "STRING"},
					"items": {
						Type: "ARRAY",
						Items: &ToolParameterSchema{
							Type: "OBJECT",
							Properties: map[string]*ToolParameterSchema{
								"title":              {Type: "STRING"},
								"amount_idr":         {Type: "INTEGER"},
								"type":               {Type: "STRING", Enum: []string{"income", "expense", "transfer"}},
								"raw_category":       {Type: "STRING"},
								"category":           {Type: "STRING", Enum: catEnum},
								"note":               {Type: "STRING"},
								"wallet_hint":        {Type: "STRING"},
								"target_wallet_hint": {Type: "STRING"},
							},
							Required: []string{"title", "amount_idr", "type"},
						},
					},
				},
				Required: []string{"items"},
			},
		},
		{
			Name:        "propose_goal_draft",
			Description: "Menyiapkan draf target tabungan (GoalDraft) dengan hitungan estimasi tabungan bulanan deterministik.",
			Parameters: &ToolParameterSchema{
				Type: "OBJECT",
				Properties: map[string]*ToolParameterSchema{
					"title":              {Type: "STRING"},
					"target_amount_idr":  {Type: "INTEGER"},
					"saved_amount_idr":   {Type: "INTEGER"},
					"target_date":        {Type: "STRING", Description: "Format YYYY-MM-DD opsional."},
					"months":             {Type: "INTEGER"},
					"priority":           {Type: "STRING", Enum: []string{"urgent", "needs", "wants"}},
					"linked_wallet_hint": {Type: "STRING"},
				},
				Required: []string{"title", "target_amount_idr"},
			},
		},
		{
			Name:        "propose_budget_draft",
			Description: "Menyiapkan draf batas anggaran kategori pengeluaran bulanan (BudgetDraft) berbasis rata-rata historis.",
			Parameters: &ToolParameterSchema{
				Type: "OBJECT",
				Properties: map[string]*ToolParameterSchema{
					"category":         {Type: "STRING", Enum: expenseMainEnum},
					"limit_amount_idr": {Type: "INTEGER"},
					"month_year":       {Type: "STRING", Description: "Format YYYY-MM opsional."},
					"context_hint":     {Type: "STRING"},
				},
				Required: []string{"category", "limit_amount_idr"},
			},
		},
		{
			Name:        "propose_bill_draft",
			Description: "Menyiapkan draf pengingat tagihan rutin (BillDraft) lengkap dengan jadwal jatuh tempo WIB berikutnya.",
			Parameters: &ToolParameterSchema{
				Type: "OBJECT",
				Properties: map[string]*ToolParameterSchema{
					"title":      {Type: "STRING"},
					"category":   {Type: "STRING", Enum: catEnum},
					"amount_idr": {Type: "INTEGER"},
					"due_day":    {Type: "INTEGER"},
					"due_date":   {Type: "STRING", Description: "Format YYYY-MM-DD opsional."},
					"frequency":  {Type: "STRING", Enum: []string{"weekly", "monthly", "yearly"}},
					"auto_pay":   {Type: "BOOLEAN"},
				},
				Required: []string{"title", "amount_idr"},
			},
		},
		{
			Name:        "match_experts_and_package",
			Description: "Mencocokkan 1 paket layanan katalog resmi dan 1-3 konsultan berjadwal 14 hari ke depan berdasarkan konteks chat.",
			Parameters: &ToolParameterSchema{
				Type: "OBJECT",
				Properties: map[string]*ToolParameterSchema{
					"method":              {Type: "STRING", Enum: []string{"online", "offline"}},
					"target":              {Type: "STRING", Enum: []string{"self", "couple", "family", "business", "corporate"}},
					"languages":           {Type: "ARRAY", Items: &ToolParameterSchema{Type: "STRING"}},
					"session_time":        {Type: "ARRAY", Items: &ToolParameterSchema{Type: "STRING"}},
					"budget_tier":         {Type: "STRING", Enum: []string{"low", "medium", "high"}},
					"main_topic":          {Type: "STRING"},
					"outcomes":            {Type: "ARRAY", Items: &ToolParameterSchema{Type: "STRING"}},
					"gender":              {Type: "STRING"},
					"approach_style":      {Type: "ARRAY", Items: &ToolParameterSchema{Type: "STRING"}},
					"age_preference":      {Type: "STRING"},
					"communication_style": {Type: "STRING"},
					"specific_tags":       {Type: "ARRAY", Items: &ToolParameterSchema{Type: "STRING"}},
					"user_goal_summary":   {Type: "STRING"},
				},
			},
		},
		{
			Name:        "search_financial_knowledge",
			Description: "Menjalankan pencarian web Google Search terisolasi untuk fakta makroekonomi, BI-Rate, inflasi, atau aturan pajak umum terkini.",
			Parameters: &ToolParameterSchema{
				Type: "OBJECT",
				Properties: map[string]*ToolParameterSchema{
					"query": {Type: "STRING", Description: "Kueri pencarian fakta ekonomi atau regulasi keuangan Indonesia."},
				},
				Required: []string{"query"},
			},
		},
	}
}

func computePass2ThinkingBudget(surfaceMode string, bundle *Pass1ToolBundle) int {
	if bundle == nil {
		if surfaceMode == "full_screen" {
			return 512
		}
		return 128
	}
	if bundle.Matching != nil ||
		bundle.FlowCashflow != nil ||
		len(bundle.SearchSummaries) > 0 ||
		bundle.GoalDraft != nil ||
		bundle.BudgetDraft != nil ||
		bundle.BillDraft != nil ||
		(surfaceMode == "full_screen" && (bundle.MerchantCashflow != nil || bundle.BudgetBills != nil)) {
		return 768
	}
	return 128
}

func mergePrepareTransactionResults(results []*PrepareTransactionResult) *PrepareTransactionResult {
	if len(results) == 0 {
		return nil
	}
	if len(results) == 1 {
		return results[0]
	}

	var firstMissingDraft *WalletCreationDraft
	for _, r := range results {
		if r != nil && r.Status == "missing_wallet" {
			if firstMissingDraft == nil && r.WalletCreationDraft != nil {
				cp := *r.WalletCreationDraft
				cp.ExistingWallets = append([]ExistingWalletChip(nil), r.WalletCreationDraft.ExistingWallets...)
				firstMissingDraft = &cp
			}
		}
	}

	if firstMissingDraft != nil {
		var pending []PendingTransactionItem
		for _, r := range results {
			if r == nil {
				continue
			}
			if len(r.PendingItems) > 0 {
				pending = append(pending, r.PendingItems...)
			} else if r.TransactionDraft != nil {
				for _, item := range r.TransactionDraft.Items {
					var targetWalletHint string
					if item.TargetWalletName != nil {
						targetWalletHint = *item.TargetWalletName
					}
					pending = append(pending, PendingTransactionItem{
						Title:                     item.Title,
						AmountIDR:                 item.AmountIDR,
						Type:                      item.Type,
						CanonicalCategory:         item.CanonicalCategory,
						CanonicalMainCategory:     item.CanonicalMainCategory,
						Note:                      item.Note,
						RequestedWalletHint:       item.WalletName,
						RequestedTargetWalletHint: targetWalletHint,
						OccurredAt:                item.OccurredAt,
					})
				}
			}
		}
		return &PrepareTransactionResult{
			Status:              "missing_wallet",
			WalletCreationDraft: firstMissingDraft,
			PendingItems:        pending,
		}
	}

	var mergedItems []TransactionDraftItem
	var totalAmount int64
	for _, r := range results {
		if r == nil || r.TransactionDraft == nil {
			continue
		}
		for _, item := range r.TransactionDraft.Items {
			mergedItems = append(mergedItems, item)
			totalAmount += item.AmountIDR
		}
	}
	if len(mergedItems) == 0 {
		return results[len(results)-1]
	}
	return &PrepareTransactionResult{
		Status: "ready",
		TransactionDraft: &TransactionDraftPayload{
			Items:          mergedItems,
			TotalAmountIDR: totalAmount,
			ItemCount:      len(mergedItems),
		},
	}
}

func buildPass2SynthesisPrompt(surfaceMode, userMessage string, bundle *Pass1ToolBundle, pass1Summary string) string {
	var b strings.Builder
	fmt.Fprintf(&b, "Surface aktif: %s\n", surfaceMode)
	fmt.Fprintf(&b, "Permintaan pengguna: %s\n\n", userMessage)
	if pass1Summary != "" {
		fmt.Fprintf(&b, "Catatan observasi Pass 1:\n%s\n\n", pass1Summary)
	}
	if bundle != nil {
		raw, err := json.Marshal(bundle)
		if err == nil {
			fmt.Fprintf(&b, "Data deterministik terverifikasi Pass 1 (WAJIB dipakai apa adanya tanpa mengubah angka atau ID):\n%s\n", string(raw))
		}
	}
	b.WriteString("\nHasilkan HANYA satu objek JSON valid sesuai AiStructuredResponse schema.")
	return b.String()
}

func buildQuickAddExtractionPrompt(text, defaultWalletHint string) string {
	if strings.TrimSpace(defaultWalletHint) != "" {
		return fmt.Sprintf("Ekstrak seluruh item transaksi dari catatan pengguna ini. Default wallet hint jika tidak disebut per item: %q.\nTeks: %s", defaultWalletHint, text)
	}
	return fmt.Sprintf("Ekstrak seluruh item transaksi dari catatan pengguna ini:\n%s", text)
}

func buildOCRExtractionPrompt(caption, defaultWalletHint string) string {
	var b strings.Builder
	b.WriteString("Baca struk belanja atau bukti pembayaran terlampir dan ekstrak transaksi pengeluaran/pemasukan ke format JSON schema.")
	if strings.TrimSpace(defaultWalletHint) != "" {
		fmt.Fprintf(&b, " Default wallet hint: %q.", defaultWalletHint)
	}
	if strings.TrimSpace(caption) != "" {
		fmt.Fprintf(&b, " Catatan tambahan pengguna: %s", caption)
	}
	return b.String()
}

func describeToolStep(toolName string, args map[string]any) (string, string) {
	switch toolName {
	case "get_user_wallets":
		return "Memeriksa dompet & saldo aktif", "Mengambil daftar dompet aktif dan saldo riil pengguna."
	case "get_cashflow_summary":
		groupBy, _ := args["group_by"].(string)
		if groupBy == "merchant" {
			return "Menghitung rincian merchant", "Menjalankan agregasi pengeluaran per merchant."
		}
		if groupBy == "income_to_expense_flow" {
			return "Menganalisa aliran kas", "Menghitung sumber pemasukan dan distribusi pengeluaran."
		}
		return "Menganalisa arus kas", "Menghitung ringkasan transaksi terverifikasi."
	case "get_budget_and_bills_status":
		return "Memeriksa anggaran, goal, & tagihan", "Mengambil sisa budget bulanan, target tabungan, dan tagihan aktif."
	case "check_and_prepare_transaction":
		return "Memvalidasi dompet & kategori transaksi", "Mencocokkan dompet aktif dan memetakan kategori kanonis."
	case "propose_goal_draft":
		return "Menyiapkan draf target tabungan", "Menghitung target nominal dan estimasi tabungan per bulan."
	case "propose_budget_draft":
		return "Menyiapkan draf batas anggaran", "Mengambil rata-rata belanja 30 hari dan menyiapkan budget kategori."
	case "propose_bill_draft":
		return "Menyiapkan draf pengingat tagihan", "Menentukan jadwal jatuh tempo berikutnya dalam zona WIB."
	case "match_experts_and_package":
		return "Mencocokkan paket & konsultan berjadwal", "Menyaring paket katalog dan praktisi tersedia 14 hari ke depan."
	case "search_financial_knowledge":
		return "Mencari referensi ekonomi terkini", "Menjalankan pencarian fakta makro atau regulasi keuangan terisolasi."
	default:
		return "Memproses alat bantu AI", "Menjalankan langkah verifikasi data."
	}
}

func isFatalToolError(err error) bool {
	if err == nil {
		return false
	}
	if errors.Is(err, ErrInvalidFinancialToolInput) ||
		errors.Is(err, ErrInvalidActionToolInput) ||
		errors.Is(err, ErrInvalidMatchingInput) ||
		errors.Is(err, ErrInvalidChatRequest) {
		return false
	}
	return true
}

func normalizeSurfaceMode(raw string) (string, error) {
	trimmed := strings.ToLower(strings.TrimSpace(raw))
	if trimmed == "" {
		return "full_screen", nil
	}
	switch trimmed {
	case "quick_sheet", "full_screen":
		return trimmed, nil
	default:
		return "", fmt.Errorf("%w: unsupported surface_mode %q", ErrInvalidChatRequest, raw)
	}
}

func normalizeClientRequestID(raw string) string {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return "req_" + uuid.NewString()
	}
	return trimmed
}

// scopedMutationID derives a deterministic <=128-byte per-item ClientMutationID so
// ConfirmAIDraft passes validateTransactionInput even when clientReqID is 127-128 bytes.
func scopedMutationID(clientReqID string, idx int) string {
	suffix := ":" + strconv.Itoa(idx)
	if len(clientReqID)+len(suffix) <= 128 {
		return clientReqID + suffix
	}
	sum := sha256.Sum256([]byte(clientReqID))
	digest := hex.EncodeToString(sum[:])
	maxDigest := 128 - len(suffix)
	if maxDigest < len(digest) {
		if maxDigest < 0 {
			maxDigest = 0
		}
		digest = digest[:maxDigest]
	}
	return digest + suffix
}

func decodeToolArgs(args map[string]any, dst any) error {
	if len(args) == 0 {
		return nil
	}
	normalized := normalizeNumericJSONMap(args)
	raw, err := json.Marshal(normalized)
	if err != nil {
		return err
	}
	return json.Unmarshal(raw, dst)
}

func structToMap(v any) (map[string]any, error) {
	raw, err := json.Marshal(v)
	if err != nil {
		return nil, err
	}
	var out map[string]any
	if err := json.Unmarshal(raw, &out); err != nil {
		return nil, err
	}
	return out, nil
}

func normalizeNumericJSONMap(v any) any {
	switch typed := v.(type) {
	case map[string]any:
		out := make(map[string]any, len(typed))
		for k, val := range typed {
			out[k] = normalizeNumericJSONMap(val)
		}
		return out
	case []any:
		out := make([]any, len(typed))
		for i, item := range typed {
			out[i] = normalizeNumericJSONMap(item)
		}
		return out
	case float64:
		if !math.IsNaN(typed) && !math.IsInf(typed, 0) && typed == math.Trunc(typed) && typed >= math.MinInt64 && typed <= math.MaxInt64 {
			return int64(typed)
		}
		return typed
	default:
		return typed
	}
}

func stripJSONCodeFence(raw string) string {
	trimmed := strings.TrimSpace(raw)
	if strings.HasPrefix(trimmed, "```") {
		if idx := strings.IndexByte(trimmed, '\n'); idx >= 0 {
			trimmed = trimmed[idx+1:]
		} else {
			trimmed = strings.TrimPrefix(trimmed, "```json")
			trimmed = strings.TrimPrefix(trimmed, "```")
		}
		trimmed = strings.TrimSuffix(strings.TrimSpace(trimmed), "```")
		trimmed = strings.TrimSpace(trimmed)
	}
	return trimmed
}

func aiDraftRowToDTO(d repository.AiDraft) service.AIDraftDTO {
	return service.AIDraftDTO{
		ID:                  d.ID,
		UserID:              d.UserID,
		WalletID:            d.WalletID,
		DestinationWalletID: d.DestinationWalletID,
		BatchID:             d.BatchID,
		Source:              d.Source,
		ExternalRefID:       d.ExternalRefID,
		ClientMutationID:    d.ClientMutationID,
		Type:                d.Type,
		Category:            d.Category,
		Amount:              d.Amount,
		Title:               d.Title,
		MerchantOrNote:      d.MerchantOrNote,
		OccurredAt:          d.OccurredAt,
		ConfidenceScore:     d.ConfidenceScore,
		Status:              d.Status,
		CreatedAt:           d.CreatedAt,
		UpdatedAt:           d.UpdatedAt,
	}
}
