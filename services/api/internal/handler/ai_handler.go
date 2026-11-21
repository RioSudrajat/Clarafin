package handler

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"go.uber.org/zap"

	"github.com/clarafin/api/internal/ai"
	"github.com/clarafin/api/internal/domain"
	"github.com/clarafin/api/internal/middleware"
	"github.com/clarafin/api/internal/service"
)

const (
	maxOCRMultipartBodyBytes = 10 << 20
	maxOCRDecodedImageBytes  = 8 << 20
)

// AIChatService abstracts Clarafin AI chat streaming and draft extraction for HTTP handlers and tests.
type AIChatService interface {
	ChatStream(ctx context.Context, userID uuid.UUID, req ai.ChatRequest, emit func(ai.SSEEvent) error) (*ai.ChatResult, error)
	QuickAddDraft(ctx context.Context, userID uuid.UUID, req ai.QuickAddRequest) (*ai.DraftExtractionResult, error)
	OCRDraft(ctx context.Context, userID uuid.UUID, req ai.OCRRequest) (*ai.DraftExtractionResult, error)
}

// AIHandler serves POST /v1/ai/chat (SSE), POST /v1/ai/quick-add, and POST /v1/ai/ocr.
type AIHandler struct {
	service AIChatService
	logger  *zap.Logger
}

// NewAIHandler constructs an AIHandler backed by svc.
func NewAIHandler(svc AIChatService, logger *zap.Logger) *AIHandler {
	if logger == nil {
		logger = zap.NewNop()
	}
	return &AIHandler{
		service: svc,
		logger:  logger,
	}
}

// RegisterRoutes mounts /chat, /quick-add, and /ocr onto an authenticated /v1/ai rate-limited router.
func (h *AIHandler) RegisterRoutes(aiRouter chi.Router) {
	aiRouter.Post("/chat", h.Chat)
	aiRouter.Post("/quick-add", h.QuickAdd)
	aiRouter.Post("/ocr", h.OCR)
}

type chatHTTPRequest struct {
	SessionID       string              `json:"session_id"`
	ClientRequestID string              `json:"client_request_id"`
	Message         string              `json:"message"`
	SurfaceMode     string              `json:"surface_mode"`
	SessionHistory  []ai.RawHistoryTurn `json:"session_history,omitempty"`
}

type ocrJSONRequest struct {
	ClientRequestID   string `json:"client_request_id"`
	MIMEType          string `json:"mime_type"`
	ImageBase64       string `json:"image_base64"`
	DefaultWalletHint string `json:"default_wallet_hint,omitempty"`
	Caption           string `json:"caption,omitempty"`
}

// Chat handles POST /v1/ai/chat with pre-stream JSON validation/quota errors and SSE streaming.
func (h *AIHandler) Chat(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}

	var body chatHTTPRequest
	if !decodeStrictJSON(w, r, reqID, false, &body) {
		return
	}
	if strings.TrimSpace(body.Message) == "" {
		domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Message is required.", reqID)
		return
	}
	if sm := strings.ToLower(strings.TrimSpace(body.SurfaceMode)); sm != "" && sm != "quick_sheet" && sm != "full_screen" {
		domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Unsupported surface_mode.", reqID)
		return
	}

	rc := http.NewResponseController(w)
	var writeMu sync.Mutex
	streamStarted := false
	emittedTerminalError := false
	lastWriteAt := time.Now()

	writeSSE := func(ev ai.SSEEvent) error {
		payload, err := json.Marshal(ev.Data)
		if err != nil {
			return fmt.Errorf("marshal SSE event %s: %w", ev.Type, err)
		}
		writeMu.Lock()
		defer writeMu.Unlock()
		if !streamStarted {
			// Disable http.Server.WriteTimeout for long-lived SSE streaming without failing on httptest.ResponseRecorder.
			_ = rc.SetWriteDeadline(time.Time{})
			domain.WriteSSEHeaders(w)
			w.WriteHeader(http.StatusOK)
			streamStarted = true
		}
		if _, err := fmt.Fprintf(w, "event: %s\ndata: %s\n\n", ev.Type, payload); err != nil {
			return err
		}
		_ = rc.Flush()
		lastWriteAt = time.Now()
		if ev.Type == ai.SSEEventError {
			emittedTerminalError = true
		}
		return nil
	}

	// Emit periodic SSE keepalive comments while waiting on upstream LLM calls so mobile clients
	// and proxies do not drop an active stream due to idle socket timeouts.
	heartbeatDone := make(chan struct{})
	var heartbeatWG sync.WaitGroup
	heartbeatWG.Add(1)
	go func() {
		defer heartbeatWG.Done()
		ticker := time.NewTicker(10 * time.Second)
		defer ticker.Stop()
		for {
			select {
			case <-heartbeatDone:
				return
			case <-r.Context().Done():
				return
			case <-ticker.C:
				writeMu.Lock()
				if streamStarted && !emittedTerminalError && time.Since(lastWriteAt) >= 9*time.Second {
					if _, err := io.WriteString(w, ": keepalive\n\n"); err == nil {
						_ = rc.Flush()
						lastWriteAt = time.Now()
					}
				}
				writeMu.Unlock()
			}
		}
	}()

	_, err := h.service.ChatStream(r.Context(), userID, ai.ChatRequest{
		SessionID:       strings.TrimSpace(body.SessionID),
		ClientRequestID: strings.TrimSpace(body.ClientRequestID),
		RequestID:       reqID,
		Message:         body.Message,
		SurfaceMode:     body.SurfaceMode,
		SessionHistory:  body.SessionHistory,
	}, writeSSE)

	close(heartbeatDone)
	heartbeatWG.Wait()

	if err != nil {
		if !streamStarted {
			writeAIServiceError(w, reqID, err)
			return
		}
		if !emittedTerminalError {
			_ = writeSSE(ai.SSEEvent{
				Type: ai.SSEEventError,
				Data: ai.SSEErrorEvent{
					Code:            mapAIErrorCode(err),
					Message:         "Gagal memproses permintaan AI.",
					RequestID:       reqID,
					SessionID:       strings.TrimSpace(body.SessionID),
					ClientRequestID: strings.TrimSpace(body.ClientRequestID),
				},
			})
		}
	}
}

// QuickAdd handles POST /v1/ai/quick-add and returns staged pending_review ai_drafts or missing_wallet guidance.
func (h *AIHandler) QuickAdd(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}

	var body ai.QuickAddRequest
	if !decodeStrictJSON(w, r, reqID, false, &body) {
		return
	}
	if strings.TrimSpace(body.Text) == "" {
		domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Text is required.", reqID)
		return
	}

	res, err := h.service.QuickAddDraft(r.Context(), userID, body)
	if err != nil {
		writeAIServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusCreated, res, reqID)
}

// OCR handles POST /v1/ai/ocr accepting either application/json base64 or multipart/form-data image uploads.
func (h *AIHandler) OCR(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}

	ocrReq, ok := h.parseOCRRequest(w, r, reqID)
	if !ok {
		return
	}

	res, err := h.service.OCRDraft(r.Context(), userID, ocrReq)
	if err != nil {
		writeAIServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusCreated, res, reqID)
}

func (h *AIHandler) parseOCRRequest(w http.ResponseWriter, r *http.Request, reqID string) (ai.OCRRequest, bool) {
	ct := strings.ToLower(strings.TrimSpace(r.Header.Get("Content-Type")))
	if strings.HasPrefix(ct, "multipart/form-data") {
		r.Body = http.MaxBytesReader(w, r.Body, maxOCRMultipartBodyBytes)
		if err := r.ParseMultipartForm(maxOCRMultipartBodyBytes); err != nil {
			domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Invalid multipart receipt payload.", reqID)
			return ai.OCRRequest{}, false
		}
		if r.MultipartForm != nil {
			defer func() {
				_ = r.MultipartForm.RemoveAll()
			}()
		}

		file, header, err := r.FormFile("image")
		if err != nil {
			domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Receipt image file field 'image' is required.", reqID)
			return ai.OCRRequest{}, false
		}
		defer func() {
			_ = file.Close()
		}()

		imgBytes, err := io.ReadAll(io.LimitReader(file, maxOCRDecodedImageBytes+1))
		if err != nil {
			domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Failed to read receipt image.", reqID)
			return ai.OCRRequest{}, false
		}
		if len(imgBytes) == 0 || len(imgBytes) > maxOCRDecodedImageBytes {
			domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Receipt image must be between 1 byte and 8 MiB.", reqID)
			return ai.OCRRequest{}, false
		}

		mimeType := strings.TrimSpace(r.FormValue("mime_type"))
		if mimeType == "" && header != nil {
			hdrCT := strings.TrimSpace(header.Header.Get("Content-Type"))
			if hdrCT != "" && !strings.EqualFold(hdrCT, "application/octet-stream") {
				mimeType = hdrCT
			}
		}
		if mimeType == "" {
			mimeType = http.DetectContentType(imgBytes)
		}
		normalizedMime, valid := normalizeAllowedImageMIME(mimeType)
		if !valid {
			domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Unsupported receipt image mime_type.", reqID)
			return ai.OCRRequest{}, false
		}

		return ai.OCRRequest{
			ClientRequestID:   strings.TrimSpace(r.FormValue("client_request_id")),
			MIMEType:          normalizedMime,
			ImageBytes:        imgBytes,
			DefaultWalletHint: strings.TrimSpace(r.FormValue("default_wallet_hint")),
			Caption:           strings.TrimSpace(r.FormValue("caption")),
		}, true
	}

	var body ocrJSONRequest
	if !decodeStrictJSONLarge(w, r, reqID, maxOCRMultipartBodyBytes, &body) {
		return ai.OCRRequest{}, false
	}
	rawB64 := strings.TrimSpace(body.ImageBase64)
	if rawB64 == "" {
		domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "image_base64 is required.", reqID)
		return ai.OCRRequest{}, false
	}
	if strings.HasPrefix(rawB64, "data:") {
		if commaIdx := strings.IndexByte(rawB64, ','); commaIdx >= 0 {
			if body.MIMEType == "" {
				meta := strings.TrimPrefix(rawB64[:commaIdx], "data:")
				body.MIMEType = strings.TrimSuffix(meta, ";base64")
			}
			rawB64 = rawB64[commaIdx+1:]
		}
	}

	imgBytes, err := base64.StdEncoding.DecodeString(rawB64)
	if err != nil {
		imgBytes, err = base64.RawStdEncoding.DecodeString(rawB64)
	}
	if err != nil || len(imgBytes) == 0 || len(imgBytes) > maxOCRDecodedImageBytes {
		domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Invalid base64 receipt image.", reqID)
		return ai.OCRRequest{}, false
	}

	mimeType := strings.TrimSpace(body.MIMEType)
	if mimeType == "" {
		mimeType = http.DetectContentType(imgBytes)
	}
	normalizedMime, valid := normalizeAllowedImageMIME(mimeType)
	if !valid {
		domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Unsupported receipt image mime_type.", reqID)
		return ai.OCRRequest{}, false
	}

	return ai.OCRRequest{
		ClientRequestID:   strings.TrimSpace(body.ClientRequestID),
		MIMEType:          normalizedMime,
		ImageBytes:        imgBytes,
		DefaultWalletHint: strings.TrimSpace(body.DefaultWalletHint),
		Caption:           strings.TrimSpace(body.Caption),
	}, true
}

func normalizeAllowedImageMIME(raw string) (string, bool) {
	mimeOnly := strings.ToLower(strings.TrimSpace(strings.Split(raw, ";")[0]))
	switch mimeOnly {
	case "image/jpeg", "image/jpg":
		return "image/jpeg", true
	case "image/png":
		return "image/png", true
	case "image/webp":
		return "image/webp", true
	default:
		return "", false
	}
}

func decodeStrictJSONLarge(w http.ResponseWriter, r *http.Request, reqID string, maxBytes int64, dst any) bool {
	if r.Body == nil {
		domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Request body is required.", reqID)
		return false
	}

	limited := http.MaxBytesReader(w, r.Body, maxBytes)
	dec := json.NewDecoder(limited)
	dec.DisallowUnknownFields()

	if err := dec.Decode(dst); err != nil {
		var maxErr *http.MaxBytesError
		if errors.As(err, &maxErr) {
			domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Request body exceeds maximum allowed size.", reqID)
			return false
		}
		domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Invalid JSON request body.", reqID)
		return false
	}

	if err := dec.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Request body must contain a single JSON object.", reqID)
		return false
	}
	return true
}

func (h *AIHandler) requireContext(w http.ResponseWriter, r *http.Request) (uuid.UUID, string, bool) {
	reqID := middleware.RequestIDFromContext(r.Context())
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		domain.WriteError(w, http.StatusUnauthorized, domain.ErrCodeUnauthorized, "Authentication required.", reqID)
		return uuid.Nil, reqID, false
	}
	if h == nil || h.service == nil {
		domain.WriteError(w, http.StatusInternalServerError, domain.ErrCodeInternalError, "AI service is not initialized.", reqID)
		return uuid.Nil, reqID, false
	}
	return userID, reqID, true
}

func writeAIServiceError(w http.ResponseWriter, reqID string, err error) {
	switch {
	case errors.Is(err, service.ErrQuotaExceeded):
		domain.WriteError(w, http.StatusPaymentRequired, domain.ErrCodeQuotaExceeded, "Monthly AI quota exceeded.", reqID)
	case errors.Is(err, ai.ErrInvalidSessionHistory),
		errors.Is(err, ai.ErrInvalidChatRequest),
		errors.Is(err, ai.ErrInvalidActionToolInput),
		errors.Is(err, service.ErrInvalidQuotaRequest):
		domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Invalid AI request payload.", reqID)
	case errors.Is(err, service.ErrRequestIDConflict),
		errors.Is(err, service.ErrReservationFinalized):
		domain.WriteError(w, http.StatusConflict, domain.ErrCodeConflict, "Duplicate or conflicting client_request_id.", reqID)
	case errors.Is(err, service.ErrUserNotFound):
		domain.WriteError(w, http.StatusNotFound, domain.ErrCodeNotFound, "User account not found.", reqID)
	default:
		domain.WriteError(w, http.StatusInternalServerError, domain.ErrCodeInternalError, "Failed to process AI request.", reqID)
	}
}

func mapAIErrorCode(err error) string {
	switch {
	case errors.Is(err, service.ErrQuotaExceeded):
		return domain.ErrCodeQuotaExceeded
	case errors.Is(err, ai.ErrInvalidSessionHistory),
		errors.Is(err, ai.ErrInvalidChatRequest),
		errors.Is(err, service.ErrInvalidQuotaRequest):
		return domain.ErrCodeInvalidRequest
	case errors.Is(err, service.ErrRequestIDConflict),
		errors.Is(err, service.ErrReservationFinalized):
		return domain.ErrCodeConflict
	case errors.Is(err, service.ErrUserNotFound):
		return domain.ErrCodeNotFound
	default:
		return domain.ErrCodeInternalError
	}
}
