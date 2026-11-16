package handler_test

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/clarafin/api/internal/domain"
	"github.com/clarafin/api/internal/handler"
	"github.com/clarafin/api/internal/middleware"
	"github.com/clarafin/api/internal/repository"
	"github.com/clarafin/api/internal/service"
)

type stubQuotaProvider struct {
	fn func(ctx context.Context, userID uuid.UUID) (*service.QuotaStatus, error)
}

func (s stubQuotaProvider) GetQuotaStatus(ctx context.Context, userID uuid.UUID) (*service.QuotaStatus, error) {
	return s.fn(ctx, userID)
}

func TestQuotaHandler_GetQuota_AuthAndErrors(t *testing.T) {
	t.Run("missing user context returns 401 UNAUTHORIZED", func(t *testing.T) {
		h := handler.NewQuotaHandler(stubQuotaProvider{
			fn: func(context.Context, uuid.UUID) (*service.QuotaStatus, error) {
				t.Fatal("service should not be called without authenticated user")
				return nil, nil
			},
		})

		req := httptest.NewRequest(http.MethodGet, "/v1/ai/quota", nil)
		req.Header.Set("X-Request-Id", "req_no_user")
		rec := httptest.NewRecorder()

		middleware.RequestID(http.HandlerFunc(h.GetQuota)).ServeHTTP(rec, req)

		if rec.Code != http.StatusUnauthorized {
			t.Fatalf("expected 401, got %d (body: %s)", rec.Code, rec.Body.String())
		}
		var env struct {
			Error domain.ErrorDetail `json:"error"`
		}
		if err := json.Unmarshal(rec.Body.Bytes(), &env); err != nil {
			t.Fatalf("unmarshal error: %v", err)
		}
		if env.Error.Code != domain.ErrCodeUnauthorized || env.Error.RequestID != "req_no_user" {
			t.Fatalf("unexpected error envelope: %+v", env.Error)
		}
	})

	t.Run("nil service returns 500 INTERNAL_ERROR", func(t *testing.T) {
		h := handler.NewQuotaHandler(nil)
		req := httptest.NewRequest(http.MethodGet, "/v1/ai/quota", nil)
		req = req.WithContext(middleware.ContextWithUserID(req.Context(), uuid.New()))
		rec := httptest.NewRecorder()

		middleware.RequestID(http.HandlerFunc(h.GetQuota)).ServeHTTP(rec, req)

		if rec.Code != http.StatusInternalServerError {
			t.Fatalf("expected 500, got %d", rec.Code)
		}
	})

	t.Run("ErrUserNotFound returns 404 NOT_FOUND", func(t *testing.T) {
		h := handler.NewQuotaHandler(stubQuotaProvider{
			fn: func(context.Context, uuid.UUID) (*service.QuotaStatus, error) {
				return nil, service.ErrUserNotFound
			},
		})
		req := httptest.NewRequest(http.MethodGet, "/v1/ai/quota", nil)
		req = req.WithContext(middleware.ContextWithUserID(req.Context(), uuid.New()))
		rec := httptest.NewRecorder()

		middleware.RequestID(http.HandlerFunc(h.GetQuota)).ServeHTTP(rec, req)

		if rec.Code != http.StatusNotFound {
			t.Fatalf("expected 404, got %d (body: %s)", rec.Code, rec.Body.String())
		}
	})

	t.Run("unexpected error returns 500 INTERNAL_ERROR", func(t *testing.T) {
		h := handler.NewQuotaHandler(stubQuotaProvider{
			fn: func(context.Context, uuid.UUID) (*service.QuotaStatus, error) {
				return nil, errors.New("db timeout")
			},
		})
		req := httptest.NewRequest(http.MethodGet, "/v1/ai/quota", nil)
		req = req.WithContext(middleware.ContextWithUserID(req.Context(), uuid.New()))
		rec := httptest.NewRecorder()

		middleware.RequestID(http.HandlerFunc(h.GetQuota)).ServeHTTP(rec, req)

		if rec.Code != http.StatusInternalServerError {
			t.Fatalf("expected 500, got %d", rec.Code)
		}
	})
}

func TestQuotaHandler_GetQuota_ReturnsCanonicalPlanPayloads(t *testing.T) {
	cases := []struct {
		name   string
		status service.QuotaStatus
	}{
		{
			name: "free plan",
			status: service.QuotaStatus{
				PlanType:       "free",
				QuotaTotal:     40,
				QuotaUsed:      3,
				QuotaRemaining: 37,
				RenewalDate:    "2026-12-01T00:00:00+07:00",
			},
		},
		{
			name: "pro monthly plan",
			status: service.QuotaStatus{
				PlanType:       "pro_monthly",
				QuotaTotal:     400,
				QuotaUsed:      12,
				QuotaRemaining: 388,
				RenewalDate:    "2026-12-15T10:00:00+07:00",
			},
		},
		{
			name: "unlimited plan",
			status: service.QuotaStatus{
				PlanType:       "unlimited",
				QuotaTotal:     -1,
				QuotaUsed:      9,
				QuotaRemaining: -1,
				RenewalDate:    "2026-12-15T10:00:00+07:00",
			},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			userID := uuid.New()
			h := handler.NewQuotaHandler(stubQuotaProvider{
				fn: func(_ context.Context, gotID uuid.UUID) (*service.QuotaStatus, error) {
					if gotID != userID {
						t.Fatalf("expected userID %s, got %s", userID, gotID)
					}
					cp := tc.status
					return &cp, nil
				},
			})

			req := httptest.NewRequest(http.MethodGet, "/v1/ai/quota", nil)
			req.Header.Set("X-Request-Id", "req_quota_ok")
			req = req.WithContext(middleware.ContextWithUserID(req.Context(), userID))
			rec := httptest.NewRecorder()

			middleware.RequestID(http.HandlerFunc(h.GetQuota)).ServeHTTP(rec, req)

			if rec.Code != http.StatusOK {
				t.Fatalf("expected 200, got %d (body: %s)", rec.Code, rec.Body.String())
			}

			var env struct {
				Data map[string]any `json:"data"`
				Meta domain.Meta    `json:"meta"`
			}
			if err := json.Unmarshal(rec.Body.Bytes(), &env); err != nil {
				t.Fatalf("unmarshal response: %v", err)
			}
			if env.Meta.RequestID != "req_quota_ok" {
				t.Fatalf("expected meta.request_id req_quota_ok, got %q", env.Meta.RequestID)
			}
			if env.Data["plan_type"] != tc.status.PlanType {
				t.Fatalf("plan_type = %v, want %q", env.Data["plan_type"], tc.status.PlanType)
			}
			if int(env.Data["quota_total"].(float64)) != tc.status.QuotaTotal {
				t.Fatalf("quota_total = %v, want %d", env.Data["quota_total"], tc.status.QuotaTotal)
			}
			if int(env.Data["quota_used"].(float64)) != tc.status.QuotaUsed {
				t.Fatalf("quota_used = %v, want %d", env.Data["quota_used"], tc.status.QuotaUsed)
			}
			if int(env.Data["quota_remaining"].(float64)) != tc.status.QuotaRemaining {
				t.Fatalf("quota_remaining = %v, want %d", env.Data["quota_remaining"], tc.status.QuotaRemaining)
			}
			if env.Data["renewal_date"] != tc.status.RenewalDate {
				t.Fatalf("renewal_date = %v, want %q", env.Data["renewal_date"], tc.status.RenewalDate)
			}
		})
	}
}

func TestQuotaHandler_GetQuota_IntegrationWithPostgres(t *testing.T) {
	store, ctx := openTestStore(t)
	userID := uuid.New()
	email := "quota-handler-" + userID.String()[:8] + "@clarafin.test"
	if _, err := store.EnsureDevUserAccount(ctx, repository.EnsureDevUserParams{
		ID:       userID,
		Email:    email,
		FullName: "Quota Handler Tester",
	}); err != nil {
		t.Fatalf("EnsureDevUserAccount: %v", err)
	}
	t.Cleanup(func() {
		cleanupCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if _, err := store.Pool.Exec(cleanupCtx, `DELETE FROM auth.users WHERE id = $1`, userID); err != nil {
			t.Errorf("cleanup test user %s: %v", userID, err)
		}
	})

	fixedNow := time.Date(2026, 11, 16, 12, 0, 0, 0, time.FixedZone("WIB", 7*3600))
	svc := service.NewQuotaService(store, service.WithNowFunc(func() time.Time { return fixedNow }))
	if _, err := svc.ReserveAction(ctx, userID, "req_qh_"+uuid.NewString(), "chat", "full_screen"); err != nil {
		t.Fatalf("ReserveAction: %v", err)
	}

	h := handler.NewQuotaHandler(svc)
	req := httptest.NewRequest(http.MethodGet, "/v1/ai/quota", nil)
	req = req.WithContext(middleware.ContextWithUserID(req.Context(), userID))
	rec := httptest.NewRecorder()
	middleware.RequestID(http.HandlerFunc(h.GetQuota)).ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d (body: %s)", rec.Code, rec.Body.String())
	}

	var env struct {
		Data service.QuotaStatus `json:"data"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &env); err != nil {
		t.Fatalf("unmarshal response: %v", err)
	}
	if env.Data.PlanType != "free" || env.Data.QuotaTotal != 40 || env.Data.QuotaUsed != 1 || env.Data.QuotaRemaining != 39 {
		t.Fatalf("unexpected integration quota status: %+v", env.Data)
	}
}
