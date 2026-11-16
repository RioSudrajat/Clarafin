package domain

import (
	"bytes"
	"encoding/json"
	"net/http"
)

// Canonical API error codes shared across handlers and middleware.
const (
	ErrCodeUnauthorized   = "UNAUTHORIZED"
	ErrCodeForbidden      = "FORBIDDEN"
	ErrCodeNotFound       = "NOT_FOUND"
	ErrCodeConflict       = "CONFLICT"
	ErrCodeInvalidRequest = "INVALID_REQUEST"
	ErrCodeRateLimited    = "RATE_LIMITED"
	ErrCodeQuotaExceeded  = "QUOTA_EXCEEDED"
	ErrCodeInternalError  = "INTERNAL_ERROR"
)

// Meta carries per-request metadata returned in standard success envelopes.
type Meta struct {
	RequestID string `json:"request_id"`
}

// SuccessEnvelope wraps every non-streaming API success response.
type SuccessEnvelope struct {
	Data any  `json:"data"`
	Meta Meta `json:"meta"`
}

// ErrorDetail describes a structured error returned inside ErrorEnvelope.
type ErrorDetail struct {
	Code      string `json:"code"`
	Message   string `json:"message"`
	RequestID string `json:"request_id"`
	Details   any    `json:"details,omitempty"`
}

// ErrorEnvelope wraps every API error response.
type ErrorEnvelope struct {
	Error ErrorDetail `json:"error"`
}

// HTTPStatusForErrorCode maps canonical Clarafin error codes to their HTTP status codes.
func HTTPStatusForErrorCode(code string) int {
	switch code {
	case ErrCodeUnauthorized:
		return http.StatusUnauthorized
	case ErrCodeForbidden:
		return http.StatusForbidden
	case ErrCodeNotFound:
		return http.StatusNotFound
	case ErrCodeConflict:
		return http.StatusConflict
	case ErrCodeInvalidRequest:
		return http.StatusBadRequest
	case ErrCodeRateLimited:
		return http.StatusTooManyRequests
	case ErrCodeQuotaExceeded:
		return http.StatusPaymentRequired
	case ErrCodeInternalError:
		return http.StatusInternalServerError
	default:
		return http.StatusInternalServerError
	}
}

// WriteJSON serializes data into the standard Clarafin success envelope.
func WriteJSON(w http.ResponseWriter, status int, data any, requestID string) {
	payload := SuccessEnvelope{
		Data: data,
		Meta: Meta{RequestID: requestID},
	}

	var buf bytes.Buffer
	if err := json.NewEncoder(&buf).Encode(payload); err != nil {
		WriteError(w, http.StatusInternalServerError, ErrCodeInternalError, "Failed to encode response payload.", requestID)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_, _ = w.Write(buf.Bytes())
}

// WriteError writes a standard Clarafin JSON error envelope.
func WriteError(w http.ResponseWriter, status int, code, message, requestID string) {
	WriteErrorWithDetails(w, status, code, message, requestID, nil)
}

// WriteErrorWithDetails writes a standard Clarafin JSON error envelope with optional structured details.
func WriteErrorWithDetails(w http.ResponseWriter, status int, code, message, requestID string, details any) {
	payload := ErrorEnvelope{
		Error: ErrorDetail{
			Code:      code,
			Message:   message,
			RequestID: requestID,
			Details:   details,
		},
	}

	var buf bytes.Buffer
	if err := json.NewEncoder(&buf).Encode(payload); err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		_, _ = w.Write([]byte(`{"error":{"code":"INTERNAL_ERROR","message":"Failed to encode error payload.","request_id":""}}` + "\n"))
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_, _ = w.Write(buf.Bytes())
}

// WriteSSEHeaders configures response headers for Server-Sent Events streaming.
func WriteSSEHeaders(w http.ResponseWriter) {
	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")
	w.Header().Set("X-Accel-Buffering", "no")
}
