package server_test

import (
	"bytes"
	"context"
	"encoding/json"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"

	"github.com/clarafin/api/internal/config"
	"github.com/clarafin/api/internal/domain"
	"github.com/clarafin/api/internal/handler"
	"github.com/clarafin/api/internal/middleware"
	"github.com/clarafin/api/internal/repository"
	"github.com/clarafin/api/internal/server"
	"github.com/clarafin/api/internal/service"
)

func openIntegrationDeps(t *testing.T) (*repository.Store, *redis.Client) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	t.Cleanup(cancel)

	pool, err := pgxpool.New(ctx, buildTestPostgresDSN())
	if err != nil {
		t.Fatalf("connect pgxpool: %v", err)
	}
	t.Cleanup(pool.Close)
	if err := pool.Ping(ctx); err != nil {
		t.Fatalf("ping postgres: %v", err)
	}

	redisURL := "redis://redis:6379/0"
	for _, key := range []string{"TEST_REDIS_URL", "DOCKER_REDIS_URL"} {
		if raw := strings.TrimSpace(os.Getenv(key)); raw != "" {
			redisURL = raw
			break
		}
	}
	opts, err := redis.ParseURL(redisURL)
	if err != nil {
		t.Fatalf("parse redis url: %v", err)
	}
	rdb := redis.NewClient(opts)
	t.Cleanup(func() {
		_ = rdb.Close()
	})
	if err := rdb.Ping(ctx).Err(); err != nil {
		t.Fatalf("ping redis: %v", err)
	}

	return repository.NewStore(pool), rdb
}

func buildTestPostgresDSN() string {
	for _, key := range []string{"TEST_DATABASE_URL", "DOCKER_DATABASE_URL"} {
		if raw := strings.TrimSpace(os.Getenv(key)); raw != "" {
			return raw
		}
	}
	user := envOrDefault("POSTGRES_USER", "clarafin")
	pass := envOrDefault("POSTGRES_PASSWORD", "clarafin_dev_password")
	db := envOrDefault("POSTGRES_DB", "clarafin")
	host := envOrDefault("POSTGRES_HOST", "postgres")
	port := envOrDefault("POSTGRES_PORT", "5432")

	u := url.URL{
		Scheme:   "postgres",
		User:     url.UserPassword(user, pass),
		Host:     net.JoinHostPort(host, port),
		Path:     "/" + db,
		RawQuery: "sslmode=disable",
	}
	return u.String()
}

func envOrDefault(key, fallback string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return fallback
}

func TestRouter_HealthzCORSAndProductionDevTokenOmitted(t *testing.T) {
	cfg := &config.Config{
		AppEnv:            "production",
		SupabaseJWTSecret: "prod-supabase-secret-at-least-32chars",
		AIRateLimitPerMin: 10,
		EnableDevAuth:     false,
		AllowedOrigins:    []string{"https://app.clarafin.id"},
	}

	r := server.NewRouter(server.Dependencies{Config: cfg})

	// 1. /healthz returns standard envelope.
	reqHealth := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	reqHealth.Header.Set("Origin", "https://app.clarafin.id")
	recHealth := httptest.NewRecorder()
	r.ServeHTTP(recHealth, reqHealth)

	if recHealth.Code != http.StatusOK {
		t.Fatalf("GET /healthz expected 200, got %d", recHealth.Code)
	}
	if recHealth.Header().Get("Access-Control-Allow-Origin") != "https://app.clarafin.id" {
		t.Fatalf("expected allowed origin header, got %q", recHealth.Header().Get("Access-Control-Allow-Origin"))
	}

	// 2. Unlisted origin gets no Allow-Origin header.
	reqDisallowed := httptest.NewRequest(http.MethodOptions, "/healthz", nil)
	reqDisallowed.Header.Set("Origin", "https://evil.example.com")
	recDisallowed := httptest.NewRecorder()
	r.ServeHTTP(recDisallowed, reqDisallowed)
	if recDisallowed.Code != http.StatusNoContent {
		t.Fatalf("OPTIONS preflight expected 204, got %d", recDisallowed.Code)
	}
	if recDisallowed.Header().Get("Access-Control-Allow-Origin") != "" {
		t.Fatalf("expected no Allow-Origin for unlisted origin, got %q", recDisallowed.Header().Get("Access-Control-Allow-Origin"))
	}

	// 3. /v1/dev/token must return 404 when disabled / non-development.
	reqDev := httptest.NewRequest(http.MethodPost, "/v1/dev/token", bytes.NewBufferString(`{}`))
	recDev := httptest.NewRecorder()
	r.ServeHTTP(recDev, reqDev)
	if recDev.Code != http.StatusNotFound {
		t.Fatalf("POST /v1/dev/token in production expected 404, got %d", recDev.Code)
	}
}

func TestRouter_EndToEndDevTokenAuthAndAIRateLimit(t *testing.T) {
	store, rdb := openIntegrationDeps(t)

	userID := uuid.New()
	email := "router-e2e-" + userID.String()[:8] + "@clarafin.test"
	redisKey := "ratelimit:ai:" + userID.String()

	t.Cleanup(func() {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if err := rdb.Del(ctx, redisKey).Err(); err != nil {
			t.Errorf("cleanup redis key %s: %v", redisKey, err)
		}
		if _, err := store.Pool.Exec(ctx, `DELETE FROM auth.users WHERE id = $1`, userID); err != nil {
			t.Errorf("cleanup test user %s: %v", userID, err)
		}
	})

	cfg := &config.Config{
		AppEnv:            "development",
		AIRateLimitPerMin: 10,
		EnableDevAuth:     true,
		DevJWTSecret:      "dev-secret-jwt-key-minimum-32chars",
		AllowedOrigins:    []string{"http://localhost:3000"},
	}

	r := server.NewRouter(server.Dependencies{
		Config: cfg,
		Store:  store,
		Redis:  rdb,
		RegisterAIRoutes: func(ai chi.Router) {
			ai.Post("/probe", func(w http.ResponseWriter, r *http.Request) {
				uid, ok := middleware.UserIDFromContext(r.Context())
				if !ok {
					domain.WriteError(w, http.StatusUnauthorized, domain.ErrCodeUnauthorized, "missing user", middleware.RequestIDFromContext(r.Context()))
					return
				}
				domain.WriteJSON(w, http.StatusOK, map[string]string{"user_id": uid.String()}, middleware.RequestIDFromContext(r.Context()))
			})
		},
	})

	// Step 1: Mint dev token via POST /v1/dev/token.
	tokBody := `{"user_id":"` + userID.String() + `","email":"` + email + `","full_name":"Router Tester"}`
	reqTok := httptest.NewRequest(http.MethodPost, "/v1/dev/token", bytes.NewBufferString(tokBody))
	recTok := httptest.NewRecorder()
	r.ServeHTTP(recTok, reqTok)
	if recTok.Code != http.StatusOK {
		t.Fatalf("POST /v1/dev/token expected 200, got %d (body: %s)", recTok.Code, recTok.Body.String())
	}

	var tokEnv struct {
		Data handler.DevTokenResponse `json:"data"`
	}
	if err := json.Unmarshal(recTok.Body.Bytes(), &tokEnv); err != nil {
		t.Fatalf("unmarshal dev token response: %v", err)
	}

	// Step 2: Unauthenticated call to /v1/ai/probe and /v1/ai/quota return 401.
	reqNoAuth := httptest.NewRequest(http.MethodPost, "/v1/ai/probe", nil)
	recNoAuth := httptest.NewRecorder()
	r.ServeHTTP(recNoAuth, reqNoAuth)
	if recNoAuth.Code != http.StatusUnauthorized {
		t.Fatalf("unauthenticated /v1/ai/probe expected 401, got %d", recNoAuth.Code)
	}

	reqQuotaNoAuth := httptest.NewRequest(http.MethodGet, "/v1/ai/quota", nil)
	recQuotaNoAuth := httptest.NewRecorder()
	r.ServeHTTP(recQuotaNoAuth, reqQuotaNoAuth)
	if recQuotaNoAuth.Code != http.StatusUnauthorized {
		t.Fatalf("unauthenticated /v1/ai/quota expected 401, got %d", recQuotaNoAuth.Code)
	}

	// Step 2b: Polling GET /v1/ai/quota 15 times succeeds and does NOT burn the 10rpm AI chat rate limit.
	for i := 1; i <= 15; i++ {
		reqQ := httptest.NewRequest(http.MethodGet, "/v1/ai/quota", nil)
		reqQ.Header.Set("Authorization", "Bearer "+tokEnv.Data.AccessToken)
		recQ := httptest.NewRecorder()
		r.ServeHTTP(recQ, reqQ)
		if recQ.Code != http.StatusOK {
			t.Fatalf("GET /v1/ai/quota poll #%d expected 200, got %d (body: %s)", i, recQ.Code, recQ.Body.String())
		}
		if i == 1 {
			var qEnv struct {
				Data service.QuotaStatus `json:"data"`
			}
			if err := json.Unmarshal(recQ.Body.Bytes(), &qEnv); err != nil {
				t.Fatalf("unmarshal GET /v1/ai/quota: %v", err)
			}
			if qEnv.Data.PlanType != "free" || qEnv.Data.QuotaTotal != 40 || qEnv.Data.QuotaRemaining != 40 {
				t.Fatalf("unexpected quota response: %+v", qEnv.Data)
			}
		}
	}

	// Step 3: 10 authenticated calls succeed, 11th returns 429 RATE_LIMITED.
	for i := 1; i <= 10; i++ {
		reqAI := httptest.NewRequest(http.MethodPost, "/v1/ai/probe", nil)
		reqAI.Header.Set("Authorization", "Bearer "+tokEnv.Data.AccessToken)
		recAI := httptest.NewRecorder()
		r.ServeHTTP(recAI, reqAI)
		if recAI.Code != http.StatusOK {
			t.Fatalf("AI probe request %d expected 200, got %d (body: %s)", i, recAI.Code, recAI.Body.String())
		}
	}

	req11 := httptest.NewRequest(http.MethodPost, "/v1/ai/probe", nil)
	req11.Header.Set("Authorization", "Bearer "+tokEnv.Data.AccessToken)
	rec11 := httptest.NewRecorder()
	r.ServeHTTP(rec11, req11)
	if rec11.Code != http.StatusTooManyRequests {
		t.Fatalf("AI probe request 11 expected 429, got %d (body: %s)", rec11.Code, rec11.Body.String())
	}

	// Step 4: Even while /v1/ai/probe is rate-limited, GET /v1/ai/quota remains accessible.
	reqQAfter := httptest.NewRequest(http.MethodGet, "/v1/ai/quota", nil)
	reqQAfter.Header.Set("Authorization", "Bearer "+tokEnv.Data.AccessToken)
	recQAfter := httptest.NewRecorder()
	r.ServeHTTP(recQAfter, reqQAfter)
	if recQAfter.Code != http.StatusOK {
		t.Fatalf("GET /v1/ai/quota while chat rate-limited expected 200, got %d (body: %s)", recQAfter.Code, recQAfter.Body.String())
	}

	// Step 5: Mounted /v1/me, /v1/wallets, and /v1/ai/drafts also remain accessible and auth-protected.
	reqMeNoAuth := httptest.NewRequest(http.MethodGet, "/v1/me", nil)
	recMeNoAuth := httptest.NewRecorder()
	r.ServeHTTP(recMeNoAuth, reqMeNoAuth)
	if recMeNoAuth.Code != http.StatusUnauthorized {
		t.Fatalf("unauthenticated /v1/me expected 401, got %d", recMeNoAuth.Code)
	}

	reqMe := httptest.NewRequest(http.MethodGet, "/v1/me", nil)
	reqMe.Header.Set("Authorization", "Bearer "+tokEnv.Data.AccessToken)
	recMe := httptest.NewRecorder()
	r.ServeHTTP(recMe, reqMe)
	if recMe.Code != http.StatusOK {
		t.Fatalf("GET /v1/me expected 200, got %d (body: %s)", recMe.Code, recMe.Body.String())
	}

	reqDrafts := httptest.NewRequest(http.MethodGet, "/v1/ai/drafts", nil)
	reqDrafts.Header.Set("Authorization", "Bearer "+tokEnv.Data.AccessToken)
	recDrafts := httptest.NewRecorder()
	r.ServeHTTP(recDrafts, reqDrafts)
	if recDrafts.Code != http.StatusOK {
		t.Fatalf("GET /v1/ai/drafts while chat rate-limited expected 200, got %d (body: %s)", recDrafts.Code, recDrafts.Body.String())
	}
}
