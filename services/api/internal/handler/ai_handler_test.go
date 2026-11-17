package handler_test

import (
	"bufio"
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"

	"github.com/clarafin/api/internal/ai"
	"github.com/clarafin/api/internal/config"
	"github.com/clarafin/api/internal/domain"
	"github.com/clarafin/api/internal/handler"
	"github.com/clarafin/api/internal/middleware"
	"github.com/clarafin/api/internal/server"
	"github.com/clarafin/api/internal/service"
)

type stubAIChatService struct {
	chatFn     func(ctx context.Context, userID uuid.UUID, req ai.ChatRequest, emit func(ai.SSEEvent) error) (*ai.ChatResult, error)
	quickAddFn func(ctx context.Context, userID uuid.UUID, req ai.QuickAddRequest) (*ai.DraftExtractionResult, error)
	ocrFn      func(ctx context.Context, userID uuid.UUID, req ai.OCRRequest) (*ai.DraftExtractionResult, error)
}

func (s *stubAIChatService) ChatStream(ctx context.Context, userID uuid.UUID, req ai.ChatRequest, emit func(ai.SSEEvent) error) (*ai.ChatResult, error) {
	return s.chatFn(ctx, userID, req, emit)
}

func (s *stubAIChatService) QuickAddDraft(ctx context.Context, userID uuid.UUID, req ai.QuickAddRequest) (*ai.DraftExtractionResult, error) {
	return s.quickAddFn(ctx, userID, req)
}

func (s *stubAIChatService) OCRDraft(ctx context.Context, userID uuid.UUID, req ai.OCRRequest) (*ai.DraftExtractionResult, error) {
	return s.ocrFn(ctx, userID, req)
}

type parsedSSEEvent struct {
	Event string
	Data  map[string]any
}

func parseSSEBody(t *testing.T, raw string) []parsedSSEEvent {
	t.Helper()
	var events []parsedSSEEvent
	scanner := bufio.NewScanner(strings.NewReader(raw))
	var curEvent string
	var curData strings.Builder
	flush := func() {
		if curEvent == "" && curData.Len() == 0 {
			return
		}
		var m map[string]any
		if err := json.Unmarshal([]byte(curData.String()), &m); err != nil {
			t.Fatalf("invalid SSE data JSON (%q): %v", curData.String(), err)
		}
		events = append(events, parsedSSEEvent{Event: curEvent, Data: m})
		curEvent = ""
		curData.Reset()
	}
	for scanner.Scan() {
		line := scanner.Text()
		if line == "" {
			flush()
			continue
		}
		if strings.HasPrefix(line, "event:") {
			curEvent = strings.TrimSpace(strings.TrimPrefix(line, "event:"))
		} else if strings.HasPrefix(line, "data:") {
			curData.WriteString(strings.TrimSpace(strings.TrimPrefix(line, "data:")))
		}
	}
	flush()
	return events
}

func TestAIHandler_ChatSSE_SequenceAndHeaders(t *testing.T) {
	userID := uuid.New()
	svc := &stubAIChatService{
		chatFn: func(_ context.Context, gotUID uuid.UUID, req ai.ChatRequest, emit func(ai.SSEEvent) error) (*ai.ChatResult, error) {
			if gotUID != userID {
				t.Fatalf("wrong userID %s", gotUID)
			}
			if err := emit(ai.SSEEvent{
				Type: ai.SSEEventThinkingStep,
				Data: ai.SSEThinkingStepEvent{
					StepNumber:      1,
					Title:           "Memahami maksud & konteks chat",
					Detail:          "Mendeteksi perintah catat transaksi.",
					Status:          "in_progress",
					SessionID:       req.SessionID,
					ClientRequestID: req.ClientRequestID,
				},
			}); err != nil {
				return nil, err
			}
			if err := emit(ai.SSEEvent{
				Type: ai.SSEEventThinkingStep,
				Data: ai.SSEThinkingStepEvent{
					StepNumber:      2,
					Title:           "Memeriksa dompet & saldo aktif",
					Detail:          "Ditemukan GoPay.",
					Status:          "completed",
					SessionID:       req.SessionID,
					ClientRequestID: req.ClientRequestID,
				},
			}); err != nil {
				return nil, err
			}
			finalPayload := ai.SSEFinalResponseEvent{
				SessionID:       req.SessionID,
				ClientRequestID: req.ClientRequestID,
				RequestID:       "req_sse_1",
				SurfaceMode:     req.SurfaceMode,
				IsPrefiltered:   false,
				PlanType:        "free",
				QuotaTotal:      40,
				QuotaUsed:       1,
				QuotaRemaining:  39,
				AiStructuredResponse: ai.AiStructuredResponse{
					Narrative: "Draf transaksi Kopi Kenangan Rp 25.000 via GoPay siap dicatat.",
					ThinkingSummary: []ai.ThinkingStep{
						{StepNumber: 1, Title: "Memeriksa dompet", Detail: "GoPay ditemukan", Status: "completed"},
					},
				},
			}
			if err := emit(ai.SSEEvent{
				Type: ai.SSEEventFinalResponse,
				Data: finalPayload,
			}); err != nil {
				return nil, err
			}
			return &ai.ChatResult{
				Response:    finalPayload.AiStructuredResponse,
				QuotaStatus: service.QuotaStatus{PlanType: "free", QuotaTotal: 40, QuotaUsed: 1, QuotaRemaining: 39},
			}, nil
		},
	}

	h := handler.NewAIHandler(svc, nil)
	r := chi.NewRouter()
	r.Use(middleware.RequestID)
	r.Route("/v1/ai", func(aiR chi.Router) {
		h.RegisterRoutes(aiR)
	})

	body := `{"session_id":"sess_abc","client_request_id":"req_abc","message":"kopi 25rb gopay","surface_mode":"quick_sheet"}`
	req := httptest.NewRequest(http.MethodPost, "/v1/ai/chat", bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Request-Id", "req_sse_1")
	req = req.WithContext(middleware.ContextWithUserID(req.Context(), userID))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200 SSE response, got %d (body: %s)", rec.Code, rec.Body.String())
	}
	if ct := rec.Header().Get("Content-Type"); !strings.Contains(ct, "text/event-stream") {
		t.Fatalf("expected Content-Type text/event-stream, got %q", ct)
	}
	if rec.Header().Get("Cache-Control") != "no-cache" || rec.Header().Get("X-Accel-Buffering") != "no" {
		t.Fatalf("missing SSE caching/buffering headers: %+v", rec.Header())
	}

	events := parseSSEBody(t, rec.Body.String())
	if len(events) != 3 {
		t.Fatalf("expected 3 SSE events, got %d (%s)", len(events), rec.Body.String())
	}
	if events[0].Event != "thinking_step" || events[1].Event != "thinking_step" || events[2].Event != "final_response" {
		t.Fatalf("unexpected SSE event sequence: %+v", events)
	}
	final := events[2].Data
	if int(final["quota_remaining"].(float64)) != 39 || int(final["quota_total"].(float64)) != 40 {
		t.Fatalf("expected quota_remaining=39 and quota_total=40 in final_response, got %+v", final)
	}
	if final["session_id"] != "sess_abc" || final["client_request_id"] != "req_abc" {
		t.Fatalf("expected session_id and client_request_id echoed in final_response, got %+v", final)
	}
}

func TestAIHandler_Chat_QuotaExceededReturns402_AndRateLimitReturns429(t *testing.T) {
	t.Run("QUOTA_EXCEEDED returns 402 JSON error envelope before SSE", func(t *testing.T) {
		svc := &stubAIChatService{
			chatFn: func(context.Context, uuid.UUID, ai.ChatRequest, func(ai.SSEEvent) error) (*ai.ChatResult, error) {
				return nil, service.ErrQuotaExceeded
			},
		}
		h := handler.NewAIHandler(svc, nil)

		req := httptest.NewRequest(http.MethodPost, "/v1/ai/chat", bytes.NewBufferString(`{"client_request_id":"req_q","message":"cek saldo","surface_mode":"full_screen"}`))
		req.Header.Set("Content-Type", "application/json")
		req = req.WithContext(middleware.ContextWithUserID(req.Context(), uuid.New()))
		rec := httptest.NewRecorder()
		middleware.RequestID(http.HandlerFunc(h.Chat)).ServeHTTP(rec, req)

		if rec.Code != http.StatusPaymentRequired {
			t.Fatalf("expected 402 Payment Required, got %d (body: %s)", rec.Code, rec.Body.String())
		}
		var env struct {
			Error domain.ErrorDetail `json:"error"`
		}
		if err := json.Unmarshal(rec.Body.Bytes(), &env); err != nil {
			t.Fatalf("unmarshal error envelope: %v", err)
		}
		if env.Error.Code != domain.ErrCodeQuotaExceeded {
			t.Fatalf("expected error code QUOTA_EXCEEDED, got %q", env.Error.Code)
		}
	})

	t.Run("RATE_LIMITED returns 429 JSON error envelope via router", func(t *testing.T) {
		store, ctx := openTestStore(t)
		user := createTempHandlerUser(t, ctx, store, "ai-rate")

		redisURL := "redis://redis:6379/0"
		opts, err := redis.ParseURL(redisURL)
		if err != nil {
			t.Fatalf("parse redis url: %v", err)
		}
		rdb := redis.NewClient(opts)
		t.Cleanup(func() {
			_ = rdb.Del(context.Background(), "ratelimit:ai:"+user.ID.String()).Err()
			_ = rdb.Close()
		})

		cfg := &config.Config{
			AppEnv:            "development",
			AIRateLimitPerMin: 1,
			EnableDevAuth:     true,
			DevJWTSecret:      "dev-secret-jwt-key-minimum-32chars",
			AllowedOrigins:    []string{"http://localhost:3000"},
		}

		svc := &stubAIChatService{
			chatFn: func(_ context.Context, _ uuid.UUID, req ai.ChatRequest, emit func(ai.SSEEvent) error) (*ai.ChatResult, error) {
				payload := ai.SSEFinalResponseEvent{
					SessionID:       req.SessionID,
					ClientRequestID: req.ClientRequestID,
					QuotaTotal:      40,
					QuotaRemaining:  40,
					AiStructuredResponse: ai.AiStructuredResponse{
						Narrative: "Halo!",
					},
				}
				_ = emit(ai.SSEEvent{Type: ai.SSEEventFinalResponse, Data: payload})
				return &ai.ChatResult{Response: payload.AiStructuredResponse}, nil
			},
		}

		r := server.NewRouter(server.Dependencies{
			Config:    cfg,
			Store:     store,
			Redis:     rdb,
			AIService: svc,
		})

		tokBody := `{"user_id":"` + user.ID.String() + `","email":"` + user.Email + `"}`
		recTok := httptest.NewRecorder()
		r.ServeHTTP(recTok, httptest.NewRequest(http.MethodPost, "/v1/dev/token", bytes.NewBufferString(tokBody)))
		var tokEnv struct {
			Data handler.DevTokenResponse `json:"data"`
		}
		_ = json.Unmarshal(recTok.Body.Bytes(), &tokEnv)

		// 1st call succeeds.
		req1 := httptest.NewRequest(http.MethodPost, "/v1/ai/chat", bytes.NewBufferString(`{"client_request_id":"r1","message":"halo","surface_mode":"quick_sheet"}`))
		req1.Header.Set("Authorization", "Bearer "+tokEnv.Data.AccessToken)
		req1.Header.Set("Content-Type", "application/json")
		rec1 := httptest.NewRecorder()
		r.ServeHTTP(rec1, req1)
		if rec1.Code != http.StatusOK {
			t.Fatalf("first call expected 200, got %d (body: %s)", rec1.Code, rec1.Body.String())
		}

		// 2nd call hits 429 RATE_LIMITED.
		req2 := httptest.NewRequest(http.MethodPost, "/v1/ai/chat", bytes.NewBufferString(`{"client_request_id":"r2","message":"halo","surface_mode":"quick_sheet"}`))
		req2.Header.Set("Authorization", "Bearer "+tokEnv.Data.AccessToken)
		req2.Header.Set("Content-Type", "application/json")
		rec2 := httptest.NewRecorder()
		r.ServeHTTP(rec2, req2)
		if rec2.Code != http.StatusTooManyRequests {
			t.Fatalf("second call expected 429, got %d (body: %s)", rec2.Code, rec2.Body.String())
		}

		// GET /v1/ai/quota remains exempt from the AI chat rate limit!
		reqQuota := httptest.NewRequest(http.MethodGet, "/v1/ai/quota", nil)
		reqQuota.Header.Set("Authorization", "Bearer "+tokEnv.Data.AccessToken)
		recQuota := httptest.NewRecorder()
		r.ServeHTTP(recQuota, reqQuota)
		if recQuota.Code != http.StatusOK {
			t.Fatalf("GET /v1/ai/quota expected 200 (exempt from 10rpm rate limit), got %d (body: %s)", recQuota.Code, recQuota.Body.String())
		}
	})
}

func TestAIHandler_QuickAddAndOCR_Endpoints(t *testing.T) {
	userID := uuid.New()
	draftID := uuid.New()

	svc := &stubAIChatService{
		quickAddFn: func(_ context.Context, gotUID uuid.UUID, req ai.QuickAddRequest) (*ai.DraftExtractionResult, error) {
			if gotUID != userID || req.Text == "" {
				t.Fatalf("unexpected quick-add args: uid=%s req=%+v", gotUID, req)
			}
			return &ai.DraftExtractionResult{
				Status: "ready",
				Drafts: []service.AIDraftDTO{
					{
						ID:              draftID,
						UserID:          userID,
						Source:          "ai_text",
						Type:            "expense",
						Category:        "Food & Beverage • Coffee Shop",
						Amount:          28000,
						Title:           "Kopi Kenangan",
						MerchantOrNote:  "Kopi Kenangan",
						ConfidenceScore: 0.94,
						Status:          "pending_review",
					},
				},
				QuotaStatus: service.QuotaStatus{PlanType: "free", QuotaTotal: 40, QuotaUsed: 1, QuotaRemaining: 39},
			}, nil
		},
		ocrFn: func(_ context.Context, gotUID uuid.UUID, req ai.OCRRequest) (*ai.DraftExtractionResult, error) {
			if gotUID != userID || len(req.ImageBytes) == 0 || req.MIMEType != "image/jpeg" {
				t.Fatalf("unexpected ocr args: uid=%s mime=%q len=%d", gotUID, req.MIMEType, len(req.ImageBytes))
			}
			return &ai.DraftExtractionResult{
				Status: "ready",
				Drafts: []service.AIDraftDTO{
					{
						ID:              draftID,
						UserID:          userID,
						Source:          "ocr",
						Type:            "expense",
						Category:        "Food & Beverage • Fast Food",
						Amount:          55000,
						Title:           "HokBen",
						MerchantOrNote:  "Makan Malam HokBen",
						ConfidenceScore: 0.92,
						Status:          "pending_review",
					},
				},
				QuotaStatus: service.QuotaStatus{PlanType: "free", QuotaTotal: 40, QuotaUsed: 2, QuotaRemaining: 38},
			}, nil
		},
	}

	h := handler.NewAIHandler(svc, nil)
	r := chi.NewRouter()
	r.Use(middleware.RequestID)
	r.Route("/v1/ai", func(aiR chi.Router) {
		h.RegisterRoutes(aiR)
	})

	// 1. POST /v1/ai/quick-add
	reqQA := httptest.NewRequest(http.MethodPost, "/v1/ai/quick-add", bytes.NewBufferString(`{"client_request_id":"qa_1","text":"ngopi kenangan 28rb pake gopay","source":"ai_text"}`))
	reqQA.Header.Set("Content-Type", "application/json")
	reqQA = reqQA.WithContext(middleware.ContextWithUserID(reqQA.Context(), userID))
	recQA := httptest.NewRecorder()
	r.ServeHTTP(recQA, reqQA)
	if recQA.Code != http.StatusCreated {
		t.Fatalf("POST /v1/ai/quick-add expected 201, got %d (body: %s)", recQA.Code, recQA.Body.String())
	}

	// 2. POST /v1/ai/ocr (JSON base64)
	b64 := base64.StdEncoding.EncodeToString([]byte{0xFF, 0xD8, 0xFF, 0xE0})
	reqOCR := httptest.NewRequest(http.MethodPost, "/v1/ai/ocr", bytes.NewBufferString(`{"client_request_id":"ocr_1","mime_type":"image/jpeg","image_base64":"`+b64+`"}`))
	reqOCR.Header.Set("Content-Type", "application/json")
	reqOCR = reqOCR.WithContext(middleware.ContextWithUserID(reqOCR.Context(), userID))
	recOCR := httptest.NewRecorder()
	r.ServeHTTP(recOCR, reqOCR)
	if recOCR.Code != http.StatusCreated {
		t.Fatalf("POST /v1/ai/ocr (json) expected 201, got %d (body: %s)", recOCR.Code, recOCR.Body.String())
	}

	// 3. POST /v1/ai/ocr (multipart/form-data)
	var mpBuf bytes.Buffer
	mw := multipart.NewWriter(&mpBuf)
	_ = mw.WriteField("client_request_id", "ocr_mp_1")
	fw, _ := mw.CreateFormFile("image", "struk.jpg")
	_, _ = fw.Write([]byte{0xFF, 0xD8, 0xFF, 0xE0})
	_ = mw.Close()

	reqMP := httptest.NewRequest(http.MethodPost, "/v1/ai/ocr", &mpBuf)
	reqMP.Header.Set("Content-Type", mw.FormDataContentType())
	reqMP = reqMP.WithContext(middleware.ContextWithUserID(reqMP.Context(), userID))
	recMP := httptest.NewRecorder()
	r.ServeHTTP(recMP, reqMP)
	if recMP.Code != http.StatusCreated {
		t.Fatalf("POST /v1/ai/ocr (multipart) expected 201, got %d (body: %s)", recMP.Code, recMP.Body.String())
	}

	// 4. POST /v1/ai/ocr rejects unsupported MIME type with 400.
	reqBadMime := httptest.NewRequest(http.MethodPost, "/v1/ai/ocr", bytes.NewBufferString(`{"client_request_id":"ocr_bad","mime_type":"application/pdf","image_base64":"`+b64+`"}`))
	reqBadMime.Header.Set("Content-Type", "application/json")
	reqBadMime = reqBadMime.WithContext(middleware.ContextWithUserID(reqBadMime.Context(), userID))
	recBadMime := httptest.NewRecorder()
	r.ServeHTTP(recBadMime, reqBadMime)
	if recBadMime.Code != http.StatusBadRequest {
		t.Fatalf("POST /v1/ai/ocr invalid mime expected 400, got %d", recBadMime.Code)
	}

	// 5. Conflicting client_request_id maps to 409 Conflict.
	conflictSvc := &stubAIChatService{
		quickAddFn: func(context.Context, uuid.UUID, ai.QuickAddRequest) (*ai.DraftExtractionResult, error) {
			return nil, service.ErrRequestIDConflict
		},
	}
	conflictHandler := handler.NewAIHandler(conflictSvc, nil)
	reqConflict := httptest.NewRequest(http.MethodPost, "/v1/ai/quick-add", bytes.NewBufferString(`{"client_request_id":"dup_1","text":"kopi 25k"}`))
	reqConflict.Header.Set("Content-Type", "application/json")
	reqConflict = reqConflict.WithContext(middleware.ContextWithUserID(reqConflict.Context(), userID))
	recConflict := httptest.NewRecorder()
	middleware.RequestID(http.HandlerFunc(conflictHandler.QuickAdd)).ServeHTTP(recConflict, reqConflict)
	if recConflict.Code != http.StatusConflict {
		t.Fatalf("expected 409 Conflict on ErrRequestIDConflict, got %d", recConflict.Code)
	}
}

func TestAIHandler_Chat_ValidationAndMidStreamError(t *testing.T) {
	userID := uuid.New()
	svc := &stubAIChatService{
		chatFn: func(_ context.Context, _ uuid.UUID, req ai.ChatRequest, emit func(ai.SSEEvent) error) (*ai.ChatResult, error) {
			_ = emit(ai.SSEEvent{
				Type: ai.SSEEventThinkingStep,
				Data: ai.SSEThinkingStepEvent{
					StepNumber:      1,
					Title:           "Memproses",
					Detail:          "Menganalisa",
					Status:          "in_progress",
					SessionID:       req.SessionID,
					ClientRequestID: req.ClientRequestID,
				},
			})
			return nil, errors.New("unexpected upstream crash")
		},
	}

	h := handler.NewAIHandler(svc, nil)
	r := chi.NewRouter()
	r.Use(middleware.RequestID)
	r.Route("/v1/ai", func(aiR chi.Router) {
		h.RegisterRoutes(aiR)
	})

	// Empty message returns 400.
	reqEmpty := httptest.NewRequest(http.MethodPost, "/v1/ai/chat", bytes.NewBufferString(`{"message":"   ","surface_mode":"quick_sheet"}`))
	reqEmpty.Header.Set("Content-Type", "application/json")
	reqEmpty = reqEmpty.WithContext(middleware.ContextWithUserID(reqEmpty.Context(), userID))
	recEmpty := httptest.NewRecorder()
	r.ServeHTTP(recEmpty, reqEmpty)
	if recEmpty.Code != http.StatusBadRequest {
		t.Fatalf("empty message expected 400, got %d", recEmpty.Code)
	}

	// Mid-stream failure emits terminal SSE error event without crashing.
	reqFail := httptest.NewRequest(http.MethodPost, "/v1/ai/chat", bytes.NewBufferString(`{"session_id":"s1","client_request_id":"r_err","message":"analisa kas","surface_mode":"full_screen"}`))
	reqFail.Header.Set("Content-Type", "application/json")
	reqFail = reqFail.WithContext(middleware.ContextWithUserID(reqFail.Context(), userID))
	recFail := httptest.NewRecorder()
	r.ServeHTTP(recFail, reqFail)
	if recFail.Code != http.StatusOK {
		t.Fatalf("mid-stream failure expected 200 SSE start, got %d", recFail.Code)
	}
	events := parseSSEBody(t, recFail.Body.String())
	if len(events) != 2 || events[0].Event != "thinking_step" || events[1].Event != "error" {
		t.Fatalf("expected thinking_step then error SSE event, got %+v", events)
	}
}
