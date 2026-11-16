package domain_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/clarafin/api/internal/domain"
)

func TestWriteJSON_StandardSuccessEnvelope(t *testing.T) {
	rec := httptest.NewRecorder()
	data := map[string]any{
		"balance": 150000,
		"label":   "BCA Utama",
	}

	domain.WriteJSON(rec, http.StatusCreated, data, "req_123")

	if rec.Code != http.StatusCreated {
		t.Fatalf("expected HTTP 201, got %d", rec.Code)
	}
	if ct := rec.Header().Get("Content-Type"); ct != "application/json" {
		t.Fatalf("expected Content-Type application/json, got %q", ct)
	}

	var parsed struct {
		Data map[string]any `json:"data"`
		Meta struct {
			RequestID string `json:"request_id"`
		} `json:"meta"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &parsed); err != nil {
		t.Fatalf("unmarshal response: %v (body: %s)", err, rec.Body.String())
	}
	if parsed.Meta.RequestID != "req_123" {
		t.Fatalf("expected meta.request_id req_123, got %q", parsed.Meta.RequestID)
	}
	if parsed.Data["label"] != "BCA Utama" {
		t.Fatalf("unexpected data payload: %+v", parsed.Data)
	}
}

func TestWriteError_AndWithDetails_AndCanonicalCodes(t *testing.T) {
	cases := []struct {
		code       string
		wantStatus int
	}{
		{code: domain.ErrCodeUnauthorized, wantStatus: http.StatusUnauthorized},
		{code: domain.ErrCodeInvalidRequest, wantStatus: http.StatusBadRequest},
		{code: domain.ErrCodeRateLimited, wantStatus: http.StatusTooManyRequests},
		{code: domain.ErrCodeQuotaExceeded, wantStatus: http.StatusPaymentRequired},
		{code: domain.ErrCodeInternalError, wantStatus: http.StatusInternalServerError},
	}

	for _, tc := range cases {
		if got := domain.HTTPStatusForErrorCode(tc.code); got != tc.wantStatus {
			t.Fatalf("HTTPStatusForErrorCode(%q) = %d, want %d", tc.code, got, tc.wantStatus)
		}
	}

	rec := httptest.NewRecorder()
	domain.WriteErrorWithDetails(
		rec,
		http.StatusPaymentRequired,
		domain.ErrCodeQuotaExceeded,
		"Kuota aksi AI bulanan Anda telah habis.",
		"req_quota_1",
		map[string]any{"remaining": 0},
	)

	if rec.Code != http.StatusPaymentRequired {
		t.Fatalf("expected HTTP 402, got %d", rec.Code)
	}
	var parsed struct {
		Error struct {
			Code      string         `json:"code"`
			Message   string         `json:"message"`
			RequestID string         `json:"request_id"`
			Details   map[string]any `json:"details"`
		} `json:"error"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &parsed); err != nil {
		t.Fatalf("unmarshal error payload: %v", err)
	}
	if parsed.Error.Code != domain.ErrCodeQuotaExceeded {
		t.Fatalf("expected code %q, got %q", domain.ErrCodeQuotaExceeded, parsed.Error.Code)
	}
	if parsed.Error.RequestID != "req_quota_1" {
		t.Fatalf("expected request_id req_quota_1, got %q", parsed.Error.RequestID)
	}
	if parsed.Error.Details["remaining"] != float64(0) {
		t.Fatalf("expected details.remaining=0, got %+v", parsed.Error.Details)
	}
}

func TestWriteSSEHeaders(t *testing.T) {
	rec := httptest.NewRecorder()
	domain.WriteSSEHeaders(rec)

	expectations := map[string]string{
		"Content-Type":      "text/event-stream",
		"Cache-Control":     "no-cache",
		"Connection":        "keep-alive",
		"X-Accel-Buffering": "no",
	}
	for key, want := range expectations {
		if got := rec.Header().Get(key); got != want {
			t.Fatalf("header %s = %q, want %q", key, got, want)
		}
	}
}
