package handler_test

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

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/clarafin/api/internal/config"
	"github.com/clarafin/api/internal/domain"
	"github.com/clarafin/api/internal/handler"
	"github.com/clarafin/api/internal/middleware"
	"github.com/clarafin/api/internal/repository"
)

func openTestStore(t *testing.T) (*repository.Store, context.Context) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	t.Cleanup(cancel)

	pool, err := pgxpool.New(ctx, buildTestPostgresDSN())
	if err != nil {
		t.Fatalf("connect pgxpool: %v", err)
	}
	t.Cleanup(pool.Close)

	if err := pool.Ping(ctx); err != nil {
		t.Fatalf("ping postgres: %v", err)
	}

	return repository.NewStore(pool), ctx
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

func TestDevAuthHandler_DisabledOutsideDevOrWhenFlagFalse(t *testing.T) {
	cases := []struct {
		name string
		cfg  *config.Config
	}{
		{
			name: "disabled in development",
			cfg: &config.Config{
				AppEnv:        "development",
				EnableDevAuth: false,
				DevJWTSecret:  "dev-secret-jwt-key-minimum-32chars",
			},
		},
		{
			name: "blocked in production even if flag set",
			cfg: &config.Config{
				AppEnv:        "production",
				EnableDevAuth: true,
				DevJWTSecret:  "dev-secret-jwt-key-minimum-32chars",
			},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			h := handler.NewDevAuthHandler(tc.cfg, nil)
			req := httptest.NewRequest(http.MethodPost, "/v1/dev/token", bytes.NewBufferString(`{}`))
			rec := httptest.NewRecorder()

			middleware.RequestID(http.HandlerFunc(h.IssueToken)).ServeHTTP(rec, req)

			if rec.Code != http.StatusNotFound {
				t.Fatalf("expected HTTP 404 when dev auth disabled/non-dev, got %d (body: %s)", rec.Code, rec.Body.String())
			}
		})
	}
}

func TestDevAuthHandler_InvalidInputReturnsBadRequest(t *testing.T) {
	cfg := &config.Config{
		AppEnv:        "development",
		EnableDevAuth: true,
		DevJWTSecret:  "dev-secret-jwt-key-minimum-32chars",
	}
	store, _ := openTestStore(t)
	h := handler.NewDevAuthHandler(cfg, store)

	cases := []struct {
		name string
		body string
	}{
		{name: "malformed json", body: `{`},
		{name: "unknown field", body: `{"role":"admin"}`},
		{name: "invalid uuid", body: `{"user_id":"not-a-uuid"}`},
		{name: "nil uuid", body: `{"user_id":"00000000-0000-0000-0000-000000000000"}`},
		{name: "invalid email", body: `{"email":"not-an-email"}`},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodPost, "/v1/dev/token", bytes.NewBufferString(tc.body))
			rec := httptest.NewRecorder()
			middleware.RequestID(http.HandlerFunc(h.IssueToken)).ServeHTTP(rec, req)

			if rec.Code != http.StatusBadRequest {
				t.Fatalf("expected HTTP 400, got %d (body: %s)", rec.Code, rec.Body.String())
			}
			var env struct {
				Error struct {
					Code string `json:"code"`
				} `json:"error"`
			}
			if err := json.Unmarshal(rec.Body.Bytes(), &env); err != nil {
				t.Fatalf("unmarshal error envelope: %v", err)
			}
			if env.Error.Code != domain.ErrCodeInvalidRequest {
				t.Fatalf("expected code %q, got %q", domain.ErrCodeInvalidRequest, env.Error.Code)
			}
		})
	}
}

func TestDevAuthHandler_ProvisionsUserAndIssuesVerifiableJWT(t *testing.T) {
	store, ctx := openTestStore(t)
	userID := uuid.New()
	email := "dev-auth-" + userID.String()[:8] + "@clarafin.test"

	t.Cleanup(func() {
		cleanupCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if _, err := store.Pool.Exec(cleanupCtx, `DELETE FROM auth.users WHERE id = $1`, userID); err != nil {
			t.Errorf("cleanup test user %s: %v", userID, err)
		}
	})

	cfg := &config.Config{
		AppEnv:        "development",
		EnableDevAuth: true,
		DevJWTSecret:  "dev-secret-jwt-key-minimum-32chars",
	}
	h := handler.NewDevAuthHandler(cfg, store)

	payload := `{"user_id":"` + userID.String() + `","email":"` + email + `","full_name":"Dev Tester"}`
	req := httptest.NewRequest(http.MethodPost, "/v1/dev/token", bytes.NewBufferString(payload))
	req.Header.Set("X-Request-Id", "req_dev_auth_1")
	rec := httptest.NewRecorder()

	middleware.RequestID(http.HandlerFunc(h.IssueToken)).ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected HTTP 200, got %d (body: %s)", rec.Code, rec.Body.String())
	}

	var resp struct {
		Data handler.DevTokenResponse `json:"data"`
		Meta domain.Meta              `json:"meta"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("unmarshal dev token response: %v", err)
	}
	if resp.Meta.RequestID != "req_dev_auth_1" {
		t.Fatalf("expected meta.request_id req_dev_auth_1, got %q", resp.Meta.RequestID)
	}
	if resp.Data.AccessToken == "" || resp.Data.TokenType != "Bearer" || resp.Data.User.ID != userID {
		t.Fatalf("unexpected dev token payload: %+v", resp.Data)
	}

	// Verify both public.users and user_preferences rows were created in Postgres.
	pref, err := store.GetUserPreferences(ctx, userID)
	if err != nil {
		t.Fatalf("GetUserPreferences after dev token: %v", err)
	}
	if pref.UserID != userID {
		t.Fatalf("expected user_preferences for %s, got %s", userID, pref.UserID)
	}

	// Verify the issued JWT passes RequireAuth and injects user_id.
	var verifiedUserID uuid.UUID
	protected := middleware.RequireAuth(cfg)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id, ok := middleware.UserIDFromContext(r.Context())
		if !ok {
			t.Fatal("expected UserIDFromContext true")
		}
		verifiedUserID = id
		w.WriteHeader(http.StatusOK)
	}))

	authReq := httptest.NewRequest(http.MethodGet, "/v1/me", nil)
	authReq.Header.Set("Authorization", "Bearer "+resp.Data.AccessToken)
	authRec := httptest.NewRecorder()
	protected.ServeHTTP(authRec, authReq)

	if authRec.Code != http.StatusOK || verifiedUserID != userID {
		t.Fatalf("RequireAuth verification failed: status=%d userID=%s", authRec.Code, verifiedUserID)
	}
}

type stubDevProvisioner struct {
	fn func(ctx context.Context, arg repository.EnsureDevUserParams) (repository.User, error)
}

func (s stubDevProvisioner) EnsureDevUserAccount(ctx context.Context, arg repository.EnsureDevUserParams) (repository.User, error) {
	return s.fn(ctx, arg)
}

func TestDevAuthHandler_DefaultsAndEmailConflict(t *testing.T) {
	cfg := &config.Config{
		AppEnv:        "development",
		EnableDevAuth: true,
		DevJWTSecret:  "dev-secret-jwt-key-minimum-32chars",
	}

	t.Run("empty body provisions default dev user deterministically", func(t *testing.T) {
		var gotArg repository.EnsureDevUserParams
		h := handler.NewDevAuthHandler(cfg, stubDevProvisioner{
			fn: func(_ context.Context, arg repository.EnsureDevUserParams) (repository.User, error) {
				gotArg = arg
				return repository.User{
					ID:       arg.ID,
					Email:    arg.Email,
					FullName: arg.FullName,
				}, nil
			},
		})

		req := httptest.NewRequest(http.MethodPost, "/v1/dev/token", nil)
		rec := httptest.NewRecorder()
		middleware.RequestID(http.HandlerFunc(h.IssueToken)).ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected HTTP 200 for empty body, got %d (body: %s)", rec.Code, rec.Body.String())
		}
		if gotArg.Email != "dev@clarafin.local" || gotArg.FullName != "Clarafin Dev User" || gotArg.ID == uuid.Nil {
			t.Fatalf("unexpected default EnsureDevUserParams: %+v", gotArg)
		}
	})

	t.Run("duplicate email conflict returns HTTP 409 CONFLICT", func(t *testing.T) {
		h := handler.NewDevAuthHandler(cfg, stubDevProvisioner{
			fn: func(_ context.Context, _ repository.EnsureDevUserParams) (repository.User, error) {
				return repository.User{}, &pgconn.PgError{Code: "23505"}
			},
		})

		req := httptest.NewRequest(http.MethodPost, "/v1/dev/token", bytes.NewBufferString(`{"email":"taken@clarafin.test"}`))
		rec := httptest.NewRecorder()
		middleware.RequestID(http.HandlerFunc(h.IssueToken)).ServeHTTP(rec, req)

		if rec.Code != http.StatusConflict {
			t.Fatalf("expected HTTP 409, got %d (body: %s)", rec.Code, rec.Body.String())
		}
		var env struct {
			Error struct {
				Code string `json:"code"`
			} `json:"error"`
		}
		if err := json.Unmarshal(rec.Body.Bytes(), &env); err != nil {
			t.Fatalf("unmarshal 409 envelope: %v", err)
		}
		if env.Error.Code != domain.ErrCodeConflict {
			t.Fatalf("expected error code %q, got %q", domain.ErrCodeConflict, env.Error.Code)
		}
	})
}
