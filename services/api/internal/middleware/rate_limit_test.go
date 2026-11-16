package middleware_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"

	"github.com/clarafin/api/internal/domain"
	"github.com/clarafin/api/internal/middleware"
)

func openTestRedis(t *testing.T) *redis.Client {
	t.Helper()

	redisURL := "redis://redis:6379/0"
	for _, key := range []string{"TEST_REDIS_URL", "DOCKER_REDIS_URL"} {
		if raw := strings.TrimSpace(os.Getenv(key)); raw != "" {
			redisURL = raw
			break
		}
	}

	opts, err := redis.ParseURL(redisURL)
	if err != nil {
		t.Fatalf("parse redis url %q: %v", redisURL, err)
	}

	rdb := redis.NewClient(opts)
	t.Cleanup(func() {
		_ = rdb.Close()
	})

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := rdb.Ping(ctx).Err(); err != nil {
		t.Fatalf("ping redis (%s): %v", redisURL, err)
	}
	return rdb
}

func registerRateLimitKeyCleanup(t *testing.T, rdb *redis.Client, userID uuid.UUID) {
	t.Helper()
	key := "ratelimit:ai:" + userID.String()
	t.Cleanup(func() {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if err := rdb.Del(ctx, key).Err(); err != nil {
			t.Errorf("cleanup redis key %s: %v", key, err)
		}
	})
}

func TestRateLimitAI_RequiresAuthenticatedUser(t *testing.T) {
	rdb := openTestRedis(t)

	nextCalled := false
	mw := middleware.RateLimitAI(rdb, 10, time.Minute)
	handler := middleware.RequestID(mw(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		nextCalled = true
		w.WriteHeader(http.StatusOK)
	})))

	req := httptest.NewRequest(http.MethodPost, "/v1/ai/chat", nil)
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if nextCalled {
		t.Fatal("expected unauthenticated request not to reach next handler")
	}
	assertUnauthorizedResponse(t, rec, "")
}

func TestRateLimitAI_TenRequestsPerMinuteAndUserIsolation(t *testing.T) {
	rdb := openTestRedis(t)

	userA := uuid.New()
	userB := uuid.New()
	registerRateLimitKeyCleanup(t, rdb, userA)
	registerRateLimitKeyCleanup(t, rdb, userB)

	mw := middleware.RateLimitAI(rdb, 10, time.Minute)
	handler := middleware.RequestID(mw(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	})))

	// 10 requests in 1 minute must succeed for userA.
	for i := 1; i <= 10; i++ {
		req := httptest.NewRequest(http.MethodPost, "/v1/ai/chat", nil)
		req = req.WithContext(middleware.ContextWithUserID(req.Context(), userA))
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("userA request %d: expected HTTP 200, got %d (body: %s)", i, rec.Code, rec.Body.String())
		}
		if gotLimit := rec.Header().Get("X-RateLimit-Limit"); gotLimit != "10" {
			t.Fatalf("userA request %d: expected X-RateLimit-Limit=10, got %q", i, gotLimit)
		}
	}

	// 11th request for userA must return 429 RATE_LIMITED.
	req11 := httptest.NewRequest(http.MethodPost, "/v1/ai/chat", nil)
	req11 = req11.WithContext(middleware.ContextWithUserID(req11.Context(), userA))
	req11.Header.Set("X-Request-Id", "req_ratelimit_11")
	rec11 := httptest.NewRecorder()
	handler.ServeHTTP(rec11, req11)

	if rec11.Code != http.StatusTooManyRequests {
		t.Fatalf("userA request 11: expected HTTP 429, got %d (body: %s)", rec11.Code, rec11.Body.String())
	}
	if gotRem := rec11.Header().Get("X-RateLimit-Remaining"); gotRem != "0" {
		t.Fatalf("expected X-RateLimit-Remaining=0 on 429, got %q", gotRem)
	}
	if retryAfter := rec11.Header().Get("Retry-After"); retryAfter == "" || retryAfter == "0" {
		t.Fatalf("expected positive Retry-After header on 429, got %q", retryAfter)
	}

	var env apiErrorEnvelope
	if err := json.Unmarshal(rec11.Body.Bytes(), &env); err != nil {
		t.Fatalf("unmarshal 429 envelope: %v", err)
	}
	if env.Error.Code != domain.ErrCodeRateLimited {
		t.Fatalf("expected error code %q, got %q", domain.ErrCodeRateLimited, env.Error.Code)
	}
	if env.Error.RequestID != "req_ratelimit_11" {
		t.Fatalf("expected request_id req_ratelimit_11, got %q", env.Error.RequestID)
	}

	// Verify Redis key has a bounded positive TTL.
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	ttl, err := rdb.PTTL(ctx, "ratelimit:ai:"+userA.String()).Result()
	if err != nil {
		t.Fatalf("check Redis PTTL: %v", err)
	}
	if ttl <= 0 || ttl > time.Minute {
		t.Fatalf("expected Redis TTL in (0, 1m], got %v", ttl)
	}

	// Different user_id must have an independent bucket and succeed.
	reqB := httptest.NewRequest(http.MethodPost, "/v1/ai/chat", nil)
	reqB = reqB.WithContext(middleware.ContextWithUserID(reqB.Context(), userB))
	recB := httptest.NewRecorder()
	handler.ServeHTTP(recB, reqB)

	if recB.Code != http.StatusOK {
		t.Fatalf("userB request 1: expected HTTP 200 (independent bucket), got %d (body: %s)", recB.Code, recB.Body.String())
	}
	if gotRem := recB.Header().Get("X-RateLimit-Remaining"); gotRem != "9" {
		t.Fatalf("userB request 1: expected X-RateLimit-Remaining=9, got %q", gotRem)
	}
}

func TestRateLimitAI_WindowResetsAfterExpiry(t *testing.T) {
	rdb := openTestRedis(t)
	userID := uuid.New()
	registerRateLimitKeyCleanup(t, rdb, userID)

	const window = 150 * time.Millisecond
	mw := middleware.RateLimitAI(rdb, 2, window)
	handler := middleware.RequestID(mw(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
	})))

	for i := 1; i <= 2; i++ {
		req := httptest.NewRequest(http.MethodPost, "/v1/ai/quick-add", nil)
		req = req.WithContext(middleware.ContextWithUserID(req.Context(), userID))
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)
		if rec.Code != http.StatusOK {
			t.Fatalf("request %d before window expiry: expected 200, got %d", i, rec.Code)
		}
	}

	reqBlocked := httptest.NewRequest(http.MethodPost, "/v1/ai/quick-add", nil)
	reqBlocked = reqBlocked.WithContext(middleware.ContextWithUserID(reqBlocked.Context(), userID))
	recBlocked := httptest.NewRecorder()
	handler.ServeHTTP(recBlocked, reqBlocked)
	if recBlocked.Code != http.StatusTooManyRequests {
		t.Fatalf("request 3 before window expiry: expected 429, got %d", recBlocked.Code)
	}

	time.Sleep(220 * time.Millisecond)

	reqAfter := httptest.NewRequest(http.MethodPost, "/v1/ai/quick-add", nil)
	reqAfter = reqAfter.WithContext(middleware.ContextWithUserID(reqAfter.Context(), userID))
	recAfter := httptest.NewRecorder()
	handler.ServeHTTP(recAfter, reqAfter)
	if recAfter.Code != http.StatusOK {
		t.Fatalf("request after window expiry: expected 200, got %d (body: %s)", recAfter.Code, recAfter.Body.String())
	}
}
