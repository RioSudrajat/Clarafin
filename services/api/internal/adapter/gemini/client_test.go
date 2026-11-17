package gemini_test

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"

	"google.golang.org/genai"

	"github.com/clarafin/api/internal/adapter/gemini"
	"github.com/clarafin/api/internal/ai"
)

func TestNewClient_EmptyAPIKeySafeFallback(t *testing.T) {
	c, err := gemini.NewClient(context.Background(), gemini.Config{
		APIKey:       "",
		DefaultModel: "gemini-2.5-flash",
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
					"model":      "models/gemini-2.5-flash",
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
		DefaultModel:        "gemini-2.5-flash",
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

type roundTripperFunc func(*http.Request) (*http.Response, error)

func (f roundTripperFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return f(req)
}
