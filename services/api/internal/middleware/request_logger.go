package middleware

import (
	"context"
	"math"
	"net/http"
	"runtime/debug"
	"strings"
	"time"

	chimiddleware "github.com/go-chi/chi/v5/middleware"
	"github.com/google/uuid"
	"go.uber.org/zap"

	"github.com/clarafin/api/internal/domain"
)

type ctxKey string

const (
	requestIDContextKey ctxKey = "request_id"
	userIDContextKey    ctxKey = "user_id"
)

// ContextWithRequestID stores a request ID in ctx.
func ContextWithRequestID(ctx context.Context, requestID string) context.Context {
	if ctx == nil {
		ctx = context.Background()
	}
	return context.WithValue(ctx, requestIDContextKey, requestID)
}

// RequestIDFromContext returns the request ID stored in ctx, falling back to chi's RequestID if present.
func RequestIDFromContext(ctx context.Context) string {
	if ctx == nil {
		return ""
	}
	if id, ok := ctx.Value(requestIDContextKey).(string); ok && id != "" {
		return id
	}
	return chimiddleware.GetReqID(ctx)
}

// RequestID assigns or validates an incoming X-Request-Id header, binds it to context, and echoes it on responses.
func RequestID(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		reqID := strings.TrimSpace(r.Header.Get("X-Request-Id"))
		if !isSafeRequestID(reqID) {
			reqID = "req_" + uuid.NewString()
		}

		ctx := ContextWithRequestID(r.Context(), reqID)
		w.Header().Set("X-Request-Id", reqID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func isSafeRequestID(id string) bool {
	if len(id) == 0 || len(id) > 128 {
		return false
	}
	for i := 0; i < len(id); i++ {
		c := id[i]
		isAlphaNum := (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')
		if !isAlphaNum && c != '_' && c != '-' && c != '.' {
			return false
		}
	}
	return true
}

type statusResponseWriter struct {
	http.ResponseWriter
	status      int
	wroteHeader bool
	bytes       int
}

func (w *statusResponseWriter) WriteHeader(code int) {
	if w.wroteHeader {
		return
	}
	w.status = code
	w.wroteHeader = true
	w.ResponseWriter.WriteHeader(code)
}

func (w *statusResponseWriter) Write(p []byte) (int, error) {
	if !w.wroteHeader {
		w.WriteHeader(http.StatusOK)
	}
	n, err := w.ResponseWriter.Write(p)
	w.bytes += n
	return n, err
}

// Flush forwards SSE flushes when the underlying ResponseWriter supports streaming.
func (w *statusResponseWriter) Flush() {
	if flusher, ok := w.ResponseWriter.(http.Flusher); ok {
		flusher.Flush()
	}
}

// Unwrap lets http.ResponseController access the underlying ResponseWriter.
func (w *statusResponseWriter) Unwrap() http.ResponseWriter {
	return w.ResponseWriter
}

// RequestLogger logs structured HTTP request metadata via zap without ever logging headers, cookies, or secrets.
func RequestLogger(logger *zap.Logger) func(http.Handler) http.Handler {
	if logger == nil {
		logger = zap.NewNop()
	}

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()
			sw := &statusResponseWriter{
				ResponseWriter: w,
				status:         http.StatusOK,
			}

			next.ServeHTTP(sw, r)

			latencyMs := math.Round(float64(time.Since(start).Microseconds())/10.0) / 100.0
			fields := []zap.Field{
				zap.String("request_id", RequestIDFromContext(r.Context())),
				zap.String("method", r.Method),
				zap.String("path", r.URL.Path),
				zap.Int("status", sw.status),
				zap.Float64("latency_ms", latencyMs),
				zap.Int("bytes", sw.bytes),
			}

			switch {
			case sw.status >= http.StatusInternalServerError:
				logger.Error("http request completed", fields...)
			case sw.status >= http.StatusBadRequest:
				logger.Warn("http request completed", fields...)
			default:
				logger.Info("http request completed", fields...)
			}
		})
	}
}

// Recoverer catches handler panics, logs stack traces without leaking request headers, and returns a JSON 500 envelope.
func Recoverer(logger *zap.Logger) func(http.Handler) http.Handler {
	if logger == nil {
		logger = zap.NewNop()
	}

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			sw, ok := w.(*statusResponseWriter)
			if !ok {
				sw = &statusResponseWriter{
					ResponseWriter: w,
					status:         http.StatusOK,
				}
			}

			defer func() {
				if rvr := recover(); rvr != nil {
					if rvr == http.ErrAbortHandler {
						panic(rvr)
					}

					reqID := RequestIDFromContext(r.Context())
					logger.Error(
						"panic recovered in http handler",
						zap.String("request_id", reqID),
						zap.String("method", r.Method),
						zap.String("path", r.URL.Path),
						zap.Any("panic", rvr),
						zap.ByteString("stack", debug.Stack()),
					)

					if !sw.wroteHeader {
						domain.WriteError(sw, http.StatusInternalServerError, domain.ErrCodeInternalError, "Internal server error.", reqID)
					}
				}
			}()

			next.ServeHTTP(sw, r)
		})
	}
}
