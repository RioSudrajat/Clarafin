package middleware_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"go.uber.org/zap/zaptest/observer"

	"github.com/clarafin/api/internal/domain"
	"github.com/clarafin/api/internal/middleware"
)

func TestRequestID_GeneratesOrValidatesHeader(t *testing.T) {
	t.Run("generates req_ prefix when missing", func(t *testing.T) {
		var ctxReqID string
		h := middleware.RequestID(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ctxReqID = middleware.RequestIDFromContext(r.Context())
			w.WriteHeader(http.StatusOK)
		}))

		req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, req)

		if !strings.HasPrefix(ctxReqID, "req_") {
			t.Fatalf("expected generated request ID with req_ prefix, got %q", ctxReqID)
		}
		if rec.Header().Get("X-Request-Id") != ctxReqID {
			t.Fatalf("expected X-Request-Id header %q, got %q", ctxReqID, rec.Header().Get("X-Request-Id"))
		}
	})

	t.Run("preserves valid incoming X-Request-Id and rejects unsafe header", func(t *testing.T) {
		var ctxReqID string
		h := middleware.RequestID(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ctxReqID = middleware.RequestIDFromContext(r.Context())
			w.WriteHeader(http.StatusOK)
		}))

		reqValid := httptest.NewRequest(http.MethodGet, "/healthz", nil)
		reqValid.Header.Set("X-Request-Id", "req_client-trace.01")
		recValid := httptest.NewRecorder()
		h.ServeHTTP(recValid, reqValid)
		if ctxReqID != "req_client-trace.01" {
			t.Fatalf("expected preserved request ID, got %q", ctxReqID)
		}

		reqUnsafe := httptest.NewRequest(http.MethodGet, "/healthz", nil)
		reqUnsafe.Header.Set("X-Request-Id", "bad\r\nid with spaces")
		recUnsafe := httptest.NewRecorder()
		h.ServeHTTP(recUnsafe, reqUnsafe)
		if !strings.HasPrefix(ctxReqID, "req_") || strings.Contains(ctxReqID, "bad") {
			t.Fatalf("expected unsafe X-Request-Id to be replaced, got %q", ctxReqID)
		}
	})
}

func TestRequestLogger_LogsFieldsWithoutSecretsAndPreservesFlusher(t *testing.T) {
	core, logs := observer.New(zapcore.DebugLevel)
	logger := zap.New(core)

	const secretToken = "super-secret-jwt-token-do-not-log"
	const secretCookie = "session_secret=abc123"

	var flushed bool
	h := middleware.RequestID(
		middleware.RequestLogger(logger)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if flusher, ok := w.(http.Flusher); ok {
				flusher.Flush()
				flushed = true
			}
			w.WriteHeader(http.StatusCreated)
			_, _ = w.Write([]byte(`{"ok":true}`))
		})),
	)

	req := httptest.NewRequest(http.MethodPost, "/v1/transactions?token="+secretToken, nil)
	req.Header.Set("X-Request-Id", "req_log_1")
	req.Header.Set("Authorization", "Bearer "+secretToken)
	req.Header.Set("Cookie", secretCookie)
	rec := httptest.NewRecorder()

	h.ServeHTTP(rec, req)

	if !flushed {
		t.Fatal("expected wrapped ResponseWriter to preserve http.Flusher for SSE")
	}

	entries := logs.All()
	if len(entries) != 1 {
		t.Fatalf("expected 1 zap log entry, got %d", len(entries))
	}

	entry := entries[0]
	if entry.Level != zapcore.InfoLevel {
		t.Fatalf("expected Info level for 201 status, got %v", entry.Level)
	}
	fields := entry.ContextMap()
	if fields["request_id"] != "req_log_1" {
		t.Fatalf("expected request_id req_log_1, got %v", fields["request_id"])
	}
	if fields["method"] != http.MethodPost {
		t.Fatalf("expected method POST, got %v", fields["method"])
	}
	if fields["path"] != "/v1/transactions" {
		t.Fatalf("expected path /v1/transactions, got %v", fields["path"])
	}
	if fields["status"] != int64(http.StatusCreated) {
		t.Fatalf("expected status 201, got %v", fields["status"])
	}
	if fields["bytes"] != int64(len(`{"ok":true}`)) {
		t.Fatalf("expected bytes %d, got %v", len(`{"ok":true}`), fields["bytes"])
	}
	if _, hasLatency := fields["latency_ms"]; !hasLatency {
		t.Fatal("expected latency_ms field in log entry")
	}

	// Ensure Authorization, cookies, and query secrets never appear in logged fields.
	rawFields, _ := json.Marshal(fields)
	logStr := string(rawFields)
	if strings.Contains(logStr, secretToken) || strings.Contains(logStr, secretCookie) || strings.Contains(logStr, "Authorization") {
		t.Fatalf("request log leaked sensitive credential data: %s", logStr)
	}
}

func TestRecoverer_ReturnsJSONInternalError(t *testing.T) {
	core, logs := observer.New(zapcore.DebugLevel)
	logger := zap.New(core)

	h := middleware.RequestID(
		middleware.Recoverer(logger)(http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {
			panic("boom")
		})),
	)

	req := httptest.NewRequest(http.MethodGet, "/v1/boom", nil)
	req.Header.Set("X-Request-Id", "req_panic_1")
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Fatalf("expected HTTP 500 on panic, got %d", rec.Code)
	}
	var env apiErrorEnvelope
	if err := json.Unmarshal(rec.Body.Bytes(), &env); err != nil {
		t.Fatalf("unmarshal panic error envelope: %v", err)
	}
	if env.Error.Code != domain.ErrCodeInternalError || env.Error.RequestID != "req_panic_1" {
		t.Fatalf("unexpected panic envelope: %+v", env)
	}
	if logs.FilterLevelExact(zapcore.ErrorLevel).Len() != 1 {
		t.Fatalf("expected 1 Error log entry for recovered panic")
	}
}
