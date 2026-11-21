package gemini_test

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"google.golang.org/genai"

	"github.com/clarafin/api/internal/adapter/gemini"
	"github.com/clarafin/api/internal/ai"
)

func TestNewClient_EmptyAPIKeySafeFallback(t *testing.T) {
	c, err := gemini.NewClient(context.Background(), gemini.Config{
		APIKey:       "",
		DefaultModel: "gemini-3.5-flash",
	})
	if err != nil {
		t.Fatalf("NewClient with empty key should not fail: %v", err)
	}
	if c.IsConfigured() {
		t.Fatal("expected IsConfigured=false when APIKey is empty")
	}
	_, err = c.GenerateContent(context.Background(), ai.GenerateRequest{
		Contents: []ai.LLMMessage{{Role: "user", Parts: []ai.LLMPart{{Text: "cek saldo"}}}},
	})
	if !errors.Is(err, gemini.ErrGeminiUnavailable) {
		t.Fatalf("expected ErrGeminiUnavailable, got %v", err)
	}
}

func TestBuildGenaiConfig_StrictTwoPassAndMutualExclusion(t *testing.T) {
	t.Run("rejects mixing google_search with custom tool declarations", func(t *testing.T) {
		_, err := gemini.BuildGenaiConfig(ai.GenerateRequest{
			Pass:               ai.Pass1ToolPlanning,
			EnableGoogleSearch: true,
			ToolDeclarations:   []ai.ToolDeclaration{{Name: "get_user_wallets", Description: "wallets"}},
		})
		if err == nil {
			t.Fatal("expected error when mixing google_search and function declarations")
		}
	})

	t.Run("rejects mixing application/json with tools", func(t *testing.T) {
		_, err := gemini.BuildGenaiConfig(ai.GenerateRequest{
			Pass:             ai.Pass1ToolPlanning,
			ToolDeclarations: []ai.ToolDeclaration{{Name: "get_user_wallets", Description: "wallets"}},
			Params: ai.GenerationParams{
				ResponseMIMEType: "application/json",
			},
		})
		if err == nil {
			t.Fatal("expected error when mixing application/json with tools")
		}
	})

	t.Run("Pass 2 maps all parameters, safety threshold, thinkingBudget, and responseSchema", func(t *testing.T) {
		cfg, err := gemini.BuildGenaiConfig(ai.GenerateRequest{
			Pass:              ai.Pass2StructuredJSON,
			SystemInstruction: "Clarafin AI system prompt",
			Params: ai.GenerationParams{
				Temperature:      0.28,
				TopP:             0.85,
				TopK:             40,
				PresencePenalty:  0.0,
				FrequencyPenalty: 0.0,
				MaxOutputTokens:  2048,
				ThinkingBudget:   768,
				SafetyThreshold:  ai.SafetyBlockMediumAndAbove,
				ResponseMIMEType: "application/json",
				ResponseSchema:   ai.BuildStructuredResponseSchema(),
			},
		})
		if err != nil {
			t.Fatalf("BuildGenaiConfig(Pass2): %v", err)
		}
		if cfg.Temperature == nil || *cfg.Temperature != 0.28 {
			t.Fatalf("Temperature = %v, want 0.28", cfg.Temperature)
		}
		if cfg.TopP == nil || *cfg.TopP != 0.85 || cfg.TopK == nil || *cfg.TopK != 40 {
			t.Fatalf("TopP/TopK = (%v, %v), want (0.85, 40)", cfg.TopP, cfg.TopK)
		}
		if cfg.PresencePenalty == nil || *cfg.PresencePenalty != 0.0 || cfg.FrequencyPenalty == nil || *cfg.FrequencyPenalty != 0.0 {
			t.Fatalf("penalties must be explicitly 0.0")
		}
		if cfg.MaxOutputTokens != 2048 {
			t.Fatalf("MaxOutputTokens = %d, want 2048", cfg.MaxOutputTokens)
		}
		if cfg.ThinkingConfig == nil || cfg.ThinkingConfig.ThinkingBudget == nil || *cfg.ThinkingConfig.ThinkingBudget != 768 {
			t.Fatalf("ThinkingConfig = %+v, want ThinkingBudget 768", cfg.ThinkingConfig)
		}
		if len(cfg.SafetySettings) != 4 || cfg.SafetySettings[0].Threshold != genai.HarmBlockThresholdBlockMediumAndAbove {
			t.Fatalf("SafetySettings = %+v, want 4 BLOCK_MEDIUM_AND_ABOVE entries", cfg.SafetySettings)
		}
		if cfg.ResponseMIMEType != "application/json" || cfg.ResponseSchema == nil || cfg.ResponseSchema.Type != genai.TypeObject {
			t.Fatalf("ResponseSchema not properly converted: mime=%q schema=%+v", cfg.ResponseMIMEType, cfg.ResponseSchema)
		}
	})
}

func TestClient_ExplicitCacheCreatesAndFallsBackToImplicitPrefix(t *testing.T) {
	var cacheCreateCount atomic.Int32
	var generateCount atomic.Int32
	var sawCachedContentHeader atomic.Bool
	var sawFallbackSystemInst atomic.Bool

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		bodyBytes, _ := io.ReadAll(r.Body)
		bodyStr := string(bodyBytes)
		w.Header().Set("Content-Type", "application/json")

		if strings.Contains(r.URL.Path, "cachedContents") {
			n := cacheCreateCount.Add(1)
			if n == 1 {
				// First request succeeds creating explicit cache.
				_ = json.NewEncoder(w).Encode(map[string]any{
					"name":       "cachedContents/clarafin_test_cache_1",
					"model":      "models/gemini-3.5-flash",
					"expireTime": "2099-01-01T00:00:00Z",
				})
				return
			}
			// Subsequent cache key simulates token-threshold failure to test graceful fallback.
			w.WriteHeader(http.StatusBadRequest)
			_ = json.NewEncoder(w).Encode(map[string]any{
				"error": map[string]any{"code": 400, "message": "Cached content is too small"},
			})
			return
		}

		if strings.Contains(r.URL.Path, "generateContent") {
			call := generateCount.Add(1)
			if strings.Contains(bodyStr, "cachedContents/clarafin_test_cache_1") {
				sawCachedContentHeader.Store(true)
			}
			if call == 2 && strings.Contains(bodyStr, "systemInstruction") {
				sawFallbackSystemInst.Store(true)
			}
			_ = json.NewEncoder(w).Encode(map[string]any{
				"candidates": []any{
					map[string]any{
						"content": map[string]any{
							"role":  "model",
							"parts": []any{map[string]any{"text": `{"narrative":"Saldo aman.","thinking_summary":[]}`}},
						},
						"groundingMetadata": map[string]any{
							"groundingChunks": []any{
								map[string]any{"web": map[string]any{"uri": "https://www.bi.go.id", "title": "Bank Indonesia"}},
							},
						},
					},
				},
				"usageMetadata": map[string]any{
					"cachedContentTokenCount": 512,
				},
			})
			return
		}

		w.WriteHeader(http.StatusNotFound)
	}))
	defer srv.Close()

	// Route SDK requests to our mock HTTP test server cleanly without network calls.
	origHTTP := srv.Client()
	redirectClient := &http.Client{
		Transport: roundTripperFunc(func(req *http.Request) (*http.Response, error) {
			cloned := req.Clone(req.Context())
			cloned.URL.Scheme = "http"
			cloned.URL.Host = strings.TrimPrefix(srv.URL, "http://")
			return origHTTP.Transport.RoundTrip(cloned)
		}),
	}

	c, err := gemini.NewClient(context.Background(), gemini.Config{
		APIKey:              "test-fake-api-key",
		DefaultModel:        "gemini-3.5-flash",
		ContextCacheEnabled: true,
		HTTPClient:          redirectClient,
	})
	if err != nil {
		t.Fatalf("NewClient: %v", err)
	}

	// Call 1: explicit cache created and reused.
	resp1, err := c.GenerateContent(context.Background(), ai.GenerateRequest{
		Pass:              ai.Pass2StructuredJSON,
		SystemInstruction: "System prompt v2",
		CacheKey:          "key_alpha",
		Contents:          []ai.LLMMessage{{Role: "user", Parts: []ai.LLMPart{{Text: "cek saldo"}}}},
		Params: ai.GenerationParams{
			Temperature:      0.28,
			ResponseMIMEType: "application/json",
		},
	})
	if err != nil {
		t.Fatalf("GenerateContent #1: %v", err)
	}
	if !sawCachedContentHeader.Load() || !resp1.UsedContextCache {
		t.Fatalf("expected explicit cache usage on call #1, got resp=%+v", resp1)
	}
	if len(resp1.GroundingSources) != 1 || resp1.GroundingSources[0] != "https://www.bi.go.id" {
		t.Fatalf("expected GroundingSources extracted, got %v", resp1.GroundingSources)
	}

	// Call 2: different CacheKey fails cache creation -> gracefully falls back to implicit prefix caching.
	resp2, err := c.GenerateContent(context.Background(), ai.GenerateRequest{
		Pass:              ai.Pass2StructuredJSON,
		SystemInstruction: "System prompt v2 beta",
		CacheKey:          "key_beta",
		Contents:          []ai.LLMMessage{{Role: "user", Parts: []ai.LLMPart{{Text: "cek saldo"}}}},
		Params: ai.GenerationParams{
			Temperature:      0.28,
			ResponseMIMEType: "application/json",
		},
	})
	if err != nil {
		t.Fatalf("GenerateContent #2 fallback: %v", err)
	}
	if !sawFallbackSystemInst.Load() || resp2.CacheName != "" {
		t.Fatalf("expected implicit systemInstruction fallback on call #2, got resp=%+v", resp2)
	}
}

func TestBuildGenaiConfig_AndRealHTTPSerialization_StructuredAndExtractionSchemas(t *testing.T) {
	assertValidGenaiSchemaTree := func(t *testing.T, path string, s *genai.Schema) {
		t.Helper()
		var walk func(p string, node *genai.Schema)
		walk = func(p string, node *genai.Schema) {
			if node == nil {
				t.Fatalf("%s: schema node is nil", p)
			}
			switch node.Type {
			case genai.TypeObject, genai.TypeString, genai.TypeNumber, genai.TypeInteger, genai.TypeBoolean, genai.TypeArray:
			default:
				t.Fatalf("%s: invalid or unspecified genai.Type %q", p, node.Type)
			}
			if node.Type == genai.TypeArray && node.Items == nil {
				t.Fatalf("%s: array schema missing Items", p)
			}
			if node.Items != nil {
				walk(p+".items", node.Items)
			}
			for k, prop := range node.Properties {
				walk(p+"."+k, prop)
			}
		}
		walk(path, s)
	}

	structuredCfg, err := gemini.BuildGenaiConfig(ai.GenerateRequest{
		Pass: ai.Pass2StructuredJSON,
		Params: ai.GenerationParams{
			Temperature:      0.28,
			ResponseMIMEType: "application/json",
			ResponseSchema:   ai.BuildStructuredResponseSchema(),
		},
	})
	if err != nil {
		t.Fatalf("BuildGenaiConfig(StructuredResponseSchema): %v", err)
	}
	if structuredCfg.ResponseSchema == nil || structuredCfg.ResponseSchema.Type != genai.TypeObject {
		t.Fatalf("expected root TypeObject on StructuredResponseSchema, got %+v", structuredCfg.ResponseSchema)
	}
	assertValidGenaiSchemaTree(t, "structured", structuredCfg.ResponseSchema)

	extractCfg, err := gemini.BuildGenaiConfig(ai.GenerateRequest{
		Pass: ai.PassExtraction,
		Params: ai.GenerationParams{
			Temperature:      0.1,
			ResponseMIMEType: "application/json",
			ResponseSchema:   ai.BuildQuickDraftExtractionSchema(),
		},
	})
	if err != nil {
		t.Fatalf("BuildGenaiConfig(QuickDraftExtractionSchema): %v", err)
	}
	if extractCfg.ResponseSchema == nil || extractCfg.ResponseSchema.Type != genai.TypeObject {
		t.Fatalf("expected root TypeObject on QuickDraftExtractionSchema, got %+v", extractCfg.ResponseSchema)
	}
	assertValidGenaiSchemaTree(t, "extraction", extractCfg.ResponseSchema)

	// Also verify ToGenaiSchema infers Type when omitted on object/array/enum nodes.
	inferred := gemini.ToGenaiSchema(&ai.ToolParameterSchema{
		Properties: map[string]*ai.ToolParameterSchema{
			"status": {Enum: []string{"ready", "missing_wallet"}},
			"tags":   {Items: &ai.ToolParameterSchema{Type: "STRING"}},
		},
	})
	assertValidGenaiSchemaTree(t, "inferred", inferred)

	// Exercise a real genai.Client over HTTP to prove SDK serialization of both schemas and Pass 1 tools.
	var capturedBodies []string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		b, _ := io.ReadAll(r.Body)
		capturedBodies = append(capturedBodies, string(b))
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"candidates": []any{
				map[string]any{
					"content": map[string]any{
						"role":  "model",
						"parts": []any{map[string]any{"text": `{"narrative":"OK","thinking_summary":[]}`}},
					},
				},
			},
		})
	}))
	defer srv.Close()

	origHTTP := srv.Client()
	redirectClient := &http.Client{
		Transport: roundTripperFunc(func(req *http.Request) (*http.Response, error) {
			cloned := req.Clone(req.Context())
			cloned.URL.Scheme = "http"
			cloned.URL.Host = strings.TrimPrefix(srv.URL, "http://")
			return origHTTP.Transport.RoundTrip(cloned)
		}),
	}

	c, err := gemini.NewClient(context.Background(), gemini.Config{
		APIKey:              "test-key",
		DefaultModel:        "gemini-3.5-flash",
		ContextCacheEnabled: false,
		HTTPClient:          redirectClient,
	})
	if err != nil {
		t.Fatalf("NewClient: %v", err)
	}

	if _, err := c.GenerateContent(context.Background(), ai.GenerateRequest{
		Pass:             ai.Pass1ToolPlanning,
		ToolDeclarations: ai.BuildPass1ToolDeclarations(),
		Contents:         []ai.LLMMessage{{Role: "user", Parts: []ai.LLMPart{{Text: "kopi 25k"}}}},
		Params:           ai.GenerationParams{Temperature: 0.1},
	}); err != nil {
		t.Fatalf("GenerateContent(Pass1 tools) failed SDK schema check: %v", err)
	}

	if _, err := c.GenerateContent(context.Background(), ai.GenerateRequest{
		Pass:     ai.Pass2StructuredJSON,
		Contents: []ai.LLMMessage{{Role: "user", Parts: []ai.LLMPart{{Text: "synthesize"}}}},
		Params: ai.GenerationParams{
			Temperature:      0.28,
			ResponseMIMEType: "application/json",
			ResponseSchema:   ai.BuildStructuredResponseSchema(),
		},
	}); err != nil {
		t.Fatalf("GenerateContent(Pass2 StructuredResponseSchema) failed SDK schema check: %v", err)
	}

	if _, err := c.GenerateContent(context.Background(), ai.GenerateRequest{
		Pass:     ai.PassExtraction,
		Contents: []ai.LLMMessage{{Role: "user", Parts: []ai.LLMPart{{Text: "kopi 25k"}}}},
		Params: ai.GenerationParams{
			Temperature:      0.1,
			ResponseMIMEType: "application/json",
			ResponseSchema:   ai.BuildQuickDraftExtractionSchema(),
		},
	}); err != nil {
		t.Fatalf("GenerateContent(PassExtraction QuickDraftExtractionSchema) failed SDK schema check: %v", err)
	}

	if len(capturedBodies) != 3 {
		t.Fatalf("expected 3 HTTP requests serialized, got %d", len(capturedBodies))
	}
	if !strings.Contains(capturedBodies[1], `"responseSchema"`) || !strings.Contains(capturedBodies[2], `"responseSchema"`) {
		t.Fatalf("expected generationConfig.responseSchema serialized in HTTP body")
	}
}

func extractModelFromGeneratePath(path string) string {
	idx := strings.Index(path, "/models/")
	if idx < 0 {
		return ""
	}
	rest := path[idx+len("/models/"):]
	if colon := strings.IndexByte(rest, ':'); colon >= 0 {
		return rest[:colon]
	}
	return rest
}

func newRedirectHTTPClient(srv *httptest.Server) *http.Client {
	origHTTP := srv.Client()
	return &http.Client{
		Transport: roundTripperFunc(func(req *http.Request) (*http.Response, error) {
			cloned := req.Clone(req.Context())
			cloned.URL.Scheme = "http"
			cloned.URL.Host = strings.TrimPrefix(srv.URL, "http://")
			return origHTTP.Transport.RoundTrip(cloned)
		}),
	}
}

func writeMockSuccessCandidate(w http.ResponseWriter, text string) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]any{
		"candidates": []any{
			map[string]any{
				"content": map[string]any{
					"role":  "model",
					"parts": []any{map[string]any{"text": text}},
				},
			},
		},
	})
}

func writeMockAPIError(w http.ResponseWriter, httpCode int, status, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(httpCode)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"error": map[string]any{
			"code":    httpCode,
			"status":  status,
			"message": message,
		},
	})
}

func TestClient_FailoverOn404_MemoizesDeprecatedModelOnSubsequentCalls(t *testing.T) {
	var mu sync.Mutex
	hitsByModel := make(map[string]int)

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		model := extractModelFromGeneratePath(r.URL.Path)
		mu.Lock()
		hitsByModel[model]++
		mu.Unlock()

		if model == "gemini-2.5-flash" {
			writeMockAPIError(w, http.StatusNotFound, "NOT_FOUND", "This model models/gemini-2.5-flash is no longer available to new users.")
			return
		}
		if model == "gemini-3-flash-preview" {
			writeMockSuccessCandidate(w, `{"narrative":"Halo dari fallback","thinking_summary":[]}`)
			return
		}
		writeMockAPIError(w, http.StatusServiceUnavailable, "UNAVAILABLE", "unexpected model")
	}))
	defer srv.Close()

	c, err := gemini.NewClient(context.Background(), gemini.Config{
		APIKey:              "test-key",
		DefaultModel:        "gemini-2.5-flash",
		FallbackModels:      []string{"gemini-3-flash-preview", "gemini-3.8-flash"},
		ContextCacheEnabled: false,
		HTTPClient:          newRedirectHTTPClient(srv),
	})
	if err != nil {
		t.Fatalf("NewClient: %v", err)
	}

	req := ai.GenerateRequest{
		Pass:     ai.Pass2StructuredJSON,
		Contents: []ai.LLMMessage{{Role: "user", Parts: []ai.LLMPart{{Text: "cek saldo"}}}},
		Params:   ai.GenerationParams{Temperature: 0.28},
	}

	resp1, err := c.GenerateContent(context.Background(), req)
	if err != nil {
		t.Fatalf("GenerateContent #1 failed: %v", err)
	}
	if resp1.Model != "gemini-3-flash-preview" {
		t.Fatalf("expected resp1.Model 'gemini-3-flash-preview', got %q", resp1.Model)
	}

	mu.Lock()
	primaryHitsAfterFirst := hitsByModel["gemini-2.5-flash"]
	secondHitsAfterFirst := hitsByModel["gemini-3-flash-preview"]
	mu.Unlock()
	if primaryHitsAfterFirst != 1 || secondHitsAfterFirst != 1 {
		t.Fatalf("expected 1 hit to primary and 1 hit to fallback on call #1, got primary=%d fallback=%d", primaryHitsAfterFirst, secondHitsAfterFirst)
	}

	// Second call must skip the 404-memoized primary model with 0 extra network hits.
	resp2, err := c.GenerateContent(context.Background(), req)
	if err != nil {
		t.Fatalf("GenerateContent #2 failed: %v", err)
	}
	if resp2.Model != "gemini-3-flash-preview" {
		t.Fatalf("expected resp2.Model 'gemini-3-flash-preview', got %q", resp2.Model)
	}

	mu.Lock()
	primaryHitsAfterSecond := hitsByModel["gemini-2.5-flash"]
	secondHitsAfterSecond := hitsByModel["gemini-3-flash-preview"]
	mu.Unlock()
	if primaryHitsAfterSecond != 1 {
		t.Fatalf("expected 0 extra hits to 404 primary model on call #2, got total %d", primaryHitsAfterSecond)
	}
	if secondHitsAfterSecond != 2 {
		t.Fatalf("expected 2 total hits to second model after call #2, got %d", secondHitsAfterSecond)
	}
}

func TestClient_FailoverOn503_DoesNotPermanentlySkipPrimaryModel(t *testing.T) {
	var mu sync.Mutex
	hitsByModel := make(map[string]int)

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		model := extractModelFromGeneratePath(r.URL.Path)
		mu.Lock()
		hitsByModel[model]++
		hitNum := hitsByModel[model]
		mu.Unlock()

		if model == "gemini-3.5-flash" {
			if hitNum == 1 {
				writeMockAPIError(w, http.StatusServiceUnavailable, "UNAVAILABLE", "The model is overloaded. Please try again later.")
				return
			}
			writeMockSuccessCandidate(w, `{"narrative":"Primary recovered","thinking_summary":[]}`)
			return
		}
		if model == "gemini-3-flash-preview" {
			writeMockSuccessCandidate(w, `{"narrative":"Fallback succeeded","thinking_summary":[]}`)
			return
		}
		writeMockAPIError(w, http.StatusNotFound, "NOT_FOUND", "unknown")
	}))
	defer srv.Close()

	c, err := gemini.NewClient(context.Background(), gemini.Config{
		APIKey:              "test-key",
		DefaultModel:        "gemini-3.5-flash",
		FallbackModels:      []string{"gemini-3-flash-preview"},
		ContextCacheEnabled: false,
		HTTPClient:          newRedirectHTTPClient(srv),
	})
	if err != nil {
		t.Fatalf("NewClient: %v", err)
	}

	req := ai.GenerateRequest{
		Pass:     ai.Pass1ToolPlanning,
		Contents: []ai.LLMMessage{{Role: "user", Parts: []ai.LLMPart{{Text: "cek saldo"}}}},
		Params:   ai.GenerationParams{Temperature: 0.1},
	}

	resp1, err := c.GenerateContent(context.Background(), req)
	if err != nil {
		t.Fatalf("GenerateContent #1 failed: %v", err)
	}
	if resp1.Model != "gemini-3-flash-preview" {
		t.Fatalf("expected call #1 to succeed on 'gemini-3-flash-preview', got %q", resp1.Model)
	}

	// Call #2 must still try primary first since 503 is transient.
	resp2, err := c.GenerateContent(context.Background(), req)
	if err != nil {
		t.Fatalf("GenerateContent #2 failed: %v", err)
	}
	if resp2.Model != "gemini-3.5-flash" {
		t.Fatalf("expected call #2 to retry and succeed on 'gemini-3.5-flash', got %q", resp2.Model)
	}

	mu.Lock()
	defer mu.Unlock()
	if hitsByModel["gemini-3.5-flash"] != 2 || hitsByModel["gemini-3-flash-preview"] != 1 {
		t.Fatalf("unexpected hit counts: %+v", hitsByModel)
	}
}

func TestClient_NoFailoverOn400InvalidArgument(t *testing.T) {
	var mu sync.Mutex
	hitsByModel := make(map[string]int)

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		model := extractModelFromGeneratePath(r.URL.Path)
		mu.Lock()
		hitsByModel[model]++
		mu.Unlock()

		writeMockAPIError(w, http.StatusBadRequest, "INVALID_ARGUMENT", "Invalid schema payload")
	}))
	defer srv.Close()

	c, err := gemini.NewClient(context.Background(), gemini.Config{
		APIKey:              "test-key",
		DefaultModel:        "gemini-3.5-flash",
		FallbackModels:      []string{"gemini-3-flash-preview", "gemini-3.8-flash"},
		ContextCacheEnabled: false,
		HTTPClient:          newRedirectHTTPClient(srv),
	})
	if err != nil {
		t.Fatalf("NewClient: %v", err)
	}

	_, err = c.GenerateContent(context.Background(), ai.GenerateRequest{
		Pass:     ai.Pass2StructuredJSON,
		Contents: []ai.LLMMessage{{Role: "user", Parts: []ai.LLMPart{{Text: "cek saldo"}}}},
		Params:   ai.GenerationParams{Temperature: 0.28},
	})
	if err == nil {
		t.Fatal("expected 400 INVALID_ARGUMENT error, got nil")
	}

	mu.Lock()
	defer mu.Unlock()
	if hitsByModel["gemini-3.5-flash"] != 1 {
		t.Fatalf("expected exactly 1 hit to primary model, got %d", hitsByModel["gemini-3.5-flash"])
	}
	if hitsByModel["gemini-3-flash-preview"] != 0 || hitsByModel["gemini-3.8-flash"] != 0 {
		t.Fatalf("expected 0 hits to fallback models on 400 error, got %+v", hitsByModel)
	}
}

func TestClient_AllCandidatesReturn503_TriesEachOnceAndReturnsError(t *testing.T) {
	var mu sync.Mutex
	var order []string

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		model := extractModelFromGeneratePath(r.URL.Path)
		mu.Lock()
		order = append(order, model)
		mu.Unlock()

		writeMockAPIError(w, http.StatusServiceUnavailable, "UNAVAILABLE", "High demand")
	}))
	defer srv.Close()

	c, err := gemini.NewClient(context.Background(), gemini.Config{
		APIKey:              "test-key",
		DefaultModel:        "gemini-3.5-flash",
		FallbackModels:      []string{"gemini-3-flash-preview", "gemini-3.8-flash"},
		ContextCacheEnabled: false,
		HTTPClient:          newRedirectHTTPClient(srv),
	})
	if err != nil {
		t.Fatalf("NewClient: %v", err)
	}

	_, err = c.GenerateContent(context.Background(), ai.GenerateRequest{
		Pass:     ai.Pass1ToolPlanning,
		Contents: []ai.LLMMessage{{Role: "user", Parts: []ai.LLMPart{{Text: "cek saldo"}}}},
		Params:   ai.GenerationParams{Temperature: 0.1},
	})
	if err == nil {
		t.Fatal("expected error when all candidates return 503, got nil")
	}

	mu.Lock()
	defer mu.Unlock()
	wantOrder := []string{"gemini-3.5-flash", "gemini-3-flash-preview", "gemini-3.8-flash"}
	if len(order) != len(wantOrder) {
		t.Fatalf("expected candidate call order %v, got %v", wantOrder, order)
	}
	for i := range wantOrder {
		if order[i] != wantOrder[i] {
			t.Fatalf("candidate[%d] = %q, want %q (full order=%v)", i, order[i], wantOrder[i], order)
		}
	}
}

func TestClient_FallbackModelIsolatesContextCache_SendsInlineSystemInstruction(t *testing.T) {
	var mu sync.Mutex
	bodiesByModel := make(map[string]string)

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		bodyBytes, _ := io.ReadAll(r.Body)
		bodyStr := string(bodyBytes)

		if strings.Contains(r.URL.Path, "cachedContents") {
			w.Header().Set("Content-Type", "application/json")
			_ = json.NewEncoder(w).Encode(map[string]any{
				"name":       "cachedContents/clarafin_primary_cache_only",
				"model":      "models/gemini-3.5-flash",
				"expireTime": "2099-01-01T00:00:00Z",
			})
			return
		}

		if strings.Contains(r.URL.Path, "generateContent") {
			model := extractModelFromGeneratePath(r.URL.Path)
			mu.Lock()
			bodiesByModel[model] = bodyStr
			mu.Unlock()

			if model == "gemini-3.5-flash" {
				writeMockAPIError(w, http.StatusServiceUnavailable, "UNAVAILABLE", "Primary overloaded")
				return
			}
			if model == "gemini-3-flash-preview" {
				writeMockSuccessCandidate(w, `{"narrative":"Inline fallback ok","thinking_summary":[]}`)
				return
			}
		}

		w.WriteHeader(http.StatusNotFound)
	}))
	defer srv.Close()

	c, err := gemini.NewClient(context.Background(), gemini.Config{
		APIKey:              "test-key",
		DefaultModel:        "gemini-3.5-flash",
		FallbackModels:      []string{"gemini-3-flash-preview"},
		ContextCacheEnabled: true,
		HTTPClient:          newRedirectHTTPClient(srv),
	})
	if err != nil {
		t.Fatalf("NewClient: %v", err)
	}

	resp, err := c.GenerateContent(context.Background(), ai.GenerateRequest{
		Pass:              ai.Pass2StructuredJSON,
		SystemInstruction: "Clarafin system prompt isolated",
		CacheKey:          "key_isolated",
		Contents:          []ai.LLMMessage{{Role: "user", Parts: []ai.LLMPart{{Text: "cek saldo"}}}},
		Params: ai.GenerationParams{
			Temperature:      0.28,
			ResponseMIMEType: "application/json",
		},
	})
	if err != nil {
		t.Fatalf("GenerateContent failed: %v", err)
	}
	if resp.Model != "gemini-3-flash-preview" {
		t.Fatalf("expected fallback model 'gemini-3-flash-preview', got %q", resp.Model)
	}
	if resp.CacheName != "" || resp.UsedContextCache {
		t.Fatalf("expected fallback response not to report primary cache usage, got %+v", resp)
	}

	mu.Lock()
	primaryBody := bodiesByModel["gemini-3.5-flash"]
	fallbackBody := bodiesByModel["gemini-3-flash-preview"]
	mu.Unlock()

	if !strings.Contains(primaryBody, "cachedContents/clarafin_primary_cache_only") {
		t.Fatalf("expected primary model request to use CachedContent, got body: %s", primaryBody)
	}
	if strings.Contains(fallbackBody, "cachedContents/clarafin_primary_cache_only") || strings.Contains(fallbackBody, `"cachedContent"`) {
		t.Fatalf("fallback model request must NOT send primary model CachedContent, got body: %s", fallbackBody)
	}
	if !strings.Contains(fallbackBody, "systemInstruction") || !strings.Contains(fallbackBody, "Clarafin system prompt isolated") {
		t.Fatalf("fallback model request must send inline systemInstruction, got body: %s", fallbackBody)
	}
}

type roundTripperFunc func(*http.Request) (*http.Response, error)

func (f roundTripperFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return f(req)
}

func TestClient_PerAttemptTimeoutFailsOverToNextModel(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		model := extractModelFromGeneratePath(r.URL.Path)
		if model == "gemini-slow" {
			select {
			case <-r.Context().Done():
				return
			case <-time.After(2 * time.Second):
				writeMockSuccessCandidate(w, `{"narrative":"Too late"}`)
				return
			}
		}
		writeMockSuccessCandidate(w, `{"narrative":"Fast fallback"}`)
	}))
	defer srv.Close()

	c, err := gemini.NewClient(context.Background(), gemini.Config{
		APIKey:              "test-key",
		DefaultModel:        "gemini-slow",
		FallbackModels:      []string{"gemini-fast"},
		ContextCacheEnabled: false,
		AttemptTimeout:      120 * time.Millisecond,
		CooldownDuration:    time.Minute,
		HTTPClient:          newRedirectHTTPClient(srv),
	})
	if err != nil {
		t.Fatalf("NewClient: %v", err)
	}

	resp, err := c.GenerateContent(context.Background(), ai.GenerateRequest{
		Pass:     ai.Pass1ToolPlanning,
		Contents: []ai.LLMMessage{{Role: "user", Parts: []ai.LLMPart{{Text: "halo"}}}},
		Params:   ai.GenerationParams{Temperature: 0.1},
	})
	if err != nil {
		t.Fatalf("GenerateContent failed: %v", err)
	}
	if resp.Model != "gemini-fast" {
		t.Fatalf("expected failover to 'gemini-fast', got %q", resp.Model)
	}
}

func TestClient_CooldownSkipsDegradedModelOnSubsequentCalls(t *testing.T) {
	var mu sync.Mutex
	hitsByModel := make(map[string]int)

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		model := extractModelFromGeneratePath(r.URL.Path)
		mu.Lock()
		hitsByModel[model]++
		mu.Unlock()

		if model == "gemini-degraded" {
			writeMockAPIError(w, http.StatusServiceUnavailable, "UNAVAILABLE", "overloaded")
			return
		}
		writeMockSuccessCandidate(w, `{"narrative":"Healthy model"}`)
	}))
	defer srv.Close()

	c, err := gemini.NewClient(context.Background(), gemini.Config{
		APIKey:              "test-key",
		DefaultModel:        "gemini-degraded",
		FallbackModels:      []string{"gemini-healthy"},
		ContextCacheEnabled: false,
		CooldownDuration:    time.Minute,
		HTTPClient:          newRedirectHTTPClient(srv),
	})
	if err != nil {
		t.Fatalf("NewClient: %v", err)
	}

	req := ai.GenerateRequest{
		Pass:     ai.Pass1ToolPlanning,
		Contents: []ai.LLMMessage{{Role: "user", Parts: []ai.LLMPart{{Text: "halo"}}}},
		Params:   ai.GenerationParams{Temperature: 0.1},
	}

	for i := 0; i < 3; i++ {
		resp, err := c.GenerateContent(context.Background(), req)
		if err != nil {
			t.Fatalf("call %d failed: %v", i+1, err)
		}
		if resp.Model != "gemini-healthy" {
			t.Fatalf("call %d expected 'gemini-healthy', got %q", i+1, resp.Model)
		}
	}

	mu.Lock()
	defer mu.Unlock()
	if hitsByModel["gemini-degraded"] != 1 {
		t.Fatalf("expected degraded model to be hit only once during cooldown, got %d", hitsByModel["gemini-degraded"])
	}
	if hitsByModel["gemini-healthy"] != 3 {
		t.Fatalf("expected healthy model to be hit 3 times, got %d", hitsByModel["gemini-healthy"])
	}
}

func TestClient_GoogleSearch429FailsOverToNextModelWithSearchIntact(t *testing.T) {
	var mu sync.Mutex
	hitsByModel := make(map[string]int)
	var fallbackSawSearch bool

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		bodyBytes, _ := io.ReadAll(r.Body)
		model := extractModelFromGeneratePath(r.URL.Path)
		mu.Lock()
		hitsByModel[model]++
		if model == "gemini-search-ok" && strings.Contains(string(bodyBytes), "googleSearch") {
			fallbackSawSearch = true
		}
		mu.Unlock()

		if model == "gemini-search-429" {
			writeMockAPIError(w, http.StatusTooManyRequests, "RESOURCE_EXHAUSTED", "quota exceeded")
			return
		}
		writeMockSuccessCandidate(w, `Ringkasan BI Rate 6%`)
	}))
	defer srv.Close()

	c, err := gemini.NewClient(context.Background(), gemini.Config{
		APIKey:              "test-key",
		DefaultModel:        "gemini-search-429",
		FallbackModels:      []string{"gemini-search-ok"},
		ContextCacheEnabled: false,
		CooldownDuration:    time.Minute,
		HTTPClient:          newRedirectHTTPClient(srv),
	})
	if err != nil {
		t.Fatalf("NewClient: %v", err)
	}

	resp, err := c.GenerateContent(context.Background(), ai.GenerateRequest{
		Pass:               ai.Pass1SearchGround,
		EnableGoogleSearch: true,
		Contents:           []ai.LLMMessage{{Role: "user", Parts: []ai.LLMPart{{Text: "BI rate 6%"}}}},
		Params:             ai.GenerationParams{Temperature: 0.1},
	})
	if err != nil {
		t.Fatalf("GenerateContent failed: %v", err)
	}
	if resp.Model != "gemini-search-ok" {
		t.Fatalf("expected failover to 'gemini-search-ok', got %q", resp.Model)
	}

	mu.Lock()
	defer mu.Unlock()
	if hitsByModel["gemini-search-429"] != 1 {
		t.Fatalf("expected 429 model not to be retried without search, got %d hits", hitsByModel["gemini-search-429"])
	}
	if !fallbackSawSearch {
		t.Fatal("expected fallback model to receive googleSearch tool intact")
	}
}
