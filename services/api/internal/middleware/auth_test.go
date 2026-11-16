package middleware_test

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"math/big"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"

	"github.com/clarafin/api/internal/config"
	"github.com/clarafin/api/internal/domain"
	"github.com/clarafin/api/internal/middleware"
)

type apiErrorEnvelope struct {
	Error struct {
		Code      string `json:"code"`
		Message   string `json:"message"`
		RequestID string `json:"request_id"`
	} `json:"error"`
}

func signHS256Token(t *testing.T, secret string, claims jwt.MapClaims) string {
	t.Helper()
	tok := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signed, err := tok.SignedString([]byte(secret))
	if err != nil {
		t.Fatalf("sign HS256 token: %v", err)
	}
	return signed
}

func assertUnauthorizedResponse(t *testing.T, rec *httptest.ResponseRecorder, wantReqID string) {
	t.Helper()
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("expected HTTP 401, got %d (body: %s)", rec.Code, rec.Body.String())
	}
	if ct := rec.Header().Get("Content-Type"); !strings.HasPrefix(ct, "application/json") {
		t.Fatalf("expected application/json Content-Type, got %q", ct)
	}
	var env apiErrorEnvelope
	if err := json.Unmarshal(rec.Body.Bytes(), &env); err != nil {
		t.Fatalf("unmarshal error envelope: %v (body: %s)", err, rec.Body.String())
	}
	if env.Error.Code != domain.ErrCodeUnauthorized {
		t.Fatalf("expected error code %q, got %q", domain.ErrCodeUnauthorized, env.Error.Code)
	}
	if env.Error.Message == "" {
		t.Fatal("expected non-empty error message")
	}
	if wantReqID != "" && env.Error.RequestID != wantReqID {
		t.Fatalf("expected request_id %q, got %q", wantReqID, env.Error.RequestID)
	}
}

func TestRequireAuth_RejectsMissingAndInvalidTokens(t *testing.T) {
	const supaSecret = "super-secret-supabase-jwt-key-32chars"
	const devSecret = "dev-secret-jwt-key-minimum-32chars"
	validSub := uuid.NewString()

	cfg := &config.Config{
		AppEnv:            "production",
		SupabaseJWTSecret: supaSecret,
		EnableDevAuth:     false,
		DevJWTSecret:      devSecret,
	}

	// Sign an unsigned alg=none JWT manually to ensure explicit rejection.
	noneHeader := base64.RawURLEncoding.EncodeToString([]byte(`{"alg":"none","typ":"JWT"}`))
	nonePayload := base64.RawURLEncoding.EncodeToString([]byte(`{"sub":"` + validSub + `","exp":` + "4102444800" + `}`))
	algNoneToken := noneHeader + "." + nonePayload + "."

	cases := []struct {
		name       string
		authHeader string
	}{
		{name: "missing header", authHeader: ""},
		{name: "non-bearer scheme", authHeader: "Basic dXNlcjpwYXNz"},
		{name: "empty bearer token", authHeader: "Bearer   "},
		{name: "malformed jwt", authHeader: "Bearer not-a-jwt-token"},
		{name: "alg none token", authHeader: "Bearer " + algNoneToken},
		{
			name: "wrong signature secret",
			authHeader: "Bearer " + signHS256Token(t, "wrong-secret-key-at-least-32-chars", jwt.MapClaims{
				"sub": validSub,
				"exp": time.Now().Add(time.Hour).Unix(),
			}),
		},
		{
			name: "expired token",
			authHeader: "Bearer " + signHS256Token(t, supaSecret, jwt.MapClaims{
				"sub": validSub,
				"exp": time.Now().Add(-time.Minute).Unix(),
			}),
		},
		{
			name: "missing exp claim",
			authHeader: "Bearer " + signHS256Token(t, supaSecret, jwt.MapClaims{
				"sub": validSub,
			}),
		},
		{
			name: "non-uuid subject",
			authHeader: "Bearer " + signHS256Token(t, supaSecret, jwt.MapClaims{
				"sub": "user-123",
				"exp": time.Now().Add(time.Hour).Unix(),
			}),
		},
		{
			name: "nil uuid subject",
			authHeader: "Bearer " + signHS256Token(t, supaSecret, jwt.MapClaims{
				"sub": uuid.Nil.String(),
				"exp": time.Now().Add(time.Hour).Unix(),
			}),
		},
		{
			name: "dev secret rejected when dev auth disabled",
			authHeader: "Bearer " + signHS256Token(t, devSecret, jwt.MapClaims{
				"sub": validSub,
				"exp": time.Now().Add(time.Hour).Unix(),
			}),
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			nextCalled := false
			handler := middleware.RequestID(
				middleware.RequireAuth(cfg)(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
					nextCalled = true
					w.WriteHeader(http.StatusOK)
				})),
			)

			req := httptest.NewRequest(http.MethodGet, "/v1/me", nil)
			req.Header.Set("X-Request-Id", "req_test_auth_fail")
			if tc.authHeader != "" {
				req.Header.Set("Authorization", tc.authHeader)
			}
			rec := httptest.NewRecorder()

			handler.ServeHTTP(rec, req)

			if nextCalled {
				t.Fatal("expected protected handler not to be called on unauthorized request")
			}
			assertUnauthorizedResponse(t, rec, "req_test_auth_fail")
		})
	}
}

func TestRequireAuth_AcceptsValidSupabaseAndDevHS256(t *testing.T) {
	const supaSecret = "super-secret-supabase-jwt-key-32chars"
	const devSecret = "dev-secret-jwt-key-minimum-32chars"
	userID := uuid.New()

	t.Run("valid supabase HS256 token injects user_id", func(t *testing.T) {
		cfg := &config.Config{
			AppEnv:            "production",
			SupabaseJWTSecret: supaSecret,
		}
		token := signHS256Token(t, supaSecret, jwt.MapClaims{
			"sub": userID.String(),
			"exp": time.Now().Add(time.Hour).Unix(),
		})

		var gotUserID uuid.UUID
		var gotOK bool
		handler := middleware.RequireAuth(cfg)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			gotUserID, gotOK = middleware.UserIDFromContext(r.Context())
			w.WriteHeader(http.StatusOK)
		}))

		req := httptest.NewRequest(http.MethodGet, "/v1/me", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected HTTP 200, got %d (body: %s)", rec.Code, rec.Body.String())
		}
		if !gotOK || gotUserID != userID {
			t.Fatalf("UserIDFromContext = (%s, %v), want (%s, true)", gotUserID, gotOK, userID)
		}
	})

	t.Run("dev HS256 token accepted only in development with EnableDevAuth", func(t *testing.T) {
		devCfg := &config.Config{
			AppEnv:        "development",
			EnableDevAuth: true,
			DevJWTSecret:  devSecret,
		}
		token := signHS256Token(t, devSecret, jwt.MapClaims{
			"sub": userID.String(),
			"exp": time.Now().Add(time.Hour).Unix(),
		})

		var gotUserID uuid.UUID
		var gotOK bool
		handler := middleware.RequireAuth(devCfg)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			gotUserID, gotOK = middleware.UserIDFromContext(r.Context())
			w.WriteHeader(http.StatusOK)
		}))

		req := httptest.NewRequest(http.MethodGet, "/v1/me", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected HTTP 200, got %d (body: %s)", rec.Code, rec.Body.String())
		}
		if !gotOK || gotUserID != userID {
			t.Fatalf("UserIDFromContext = (%s, %v), want (%s, true)", gotUserID, gotOK, userID)
		}
	})

	t.Run("fails closed when no JWT verifier configured", func(t *testing.T) {
		emptyCfg := &config.Config{AppEnv: "development"}
		token := signHS256Token(t, devSecret, jwt.MapClaims{
			"sub": userID.String(),
			"exp": time.Now().Add(time.Hour).Unix(),
		})

		handler := middleware.RequireAuth(emptyCfg)(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			w.WriteHeader(http.StatusOK)
		}))

		req := httptest.NewRequest(http.MethodGet, "/v1/me", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		assertUnauthorizedResponse(t, rec, "")
	})
}

func TestRequireAuth_JWKS_ES256_RS256_AndRotation(t *testing.T) {
	ecKey1, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatalf("generate EC key 1: %v", err)
	}
	ecKey2, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatalf("generate EC key 2: %v", err)
	}
	rsaKey, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatalf("generate RSA key: %v", err)
	}

	var rotated atomic.Bool
	jwksSrv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		activeEC := ecKey1
		activeKid := "ec-kid-1"
		if rotated.Load() {
			activeEC = ecKey2
			activeKid = "ec-kid-2"
		}

		ecBytes := 32
		xPad := activeEC.PublicKey.X.FillBytes(make([]byte, ecBytes))
		yPad := activeEC.PublicKey.Y.FillBytes(make([]byte, ecBytes))

		eBytes := big.NewInt(int64(rsaKey.PublicKey.E)).Bytes()
		jwks := map[string]any{
			"keys": []map[string]any{
				{
					"kty": "EC",
					"use": "sig",
					"alg": "ES256",
					"kid": activeKid,
					"crv": "P-256",
					"x":   base64.RawURLEncoding.EncodeToString(xPad),
					"y":   base64.RawURLEncoding.EncodeToString(yPad),
				},
				{
					"kty": "RSA",
					"use": "sig",
					"alg": "RS256",
					"kid": "rsa-kid-1",
					"n":   base64.RawURLEncoding.EncodeToString(rsaKey.PublicKey.N.Bytes()),
					"e":   base64.RawURLEncoding.EncodeToString(eBytes),
				},
			},
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(jwks)
	}))
	defer jwksSrv.Close()

	cfg := &config.Config{
		AppEnv:          "production",
		SupabaseJWKSURL: jwksSrv.URL,
	}

	userID := uuid.New()
	authMW := middleware.RequireAuth(cfg)
	protected := authMW(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotID, ok := middleware.UserIDFromContext(r.Context())
		if !ok || gotID != userID {
			t.Fatalf("UserIDFromContext = (%s, %v), want (%s, true)", gotID, ok, userID)
		}
		w.WriteHeader(http.StatusOK)
	}))

	// 1. Valid ES256 token.
	esTok := jwt.NewWithClaims(jwt.SigningMethodES256, jwt.MapClaims{
		"sub": userID.String(),
		"exp": time.Now().Add(time.Hour).Unix(),
	})
	esTok.Header["kid"] = "ec-kid-1"
	esSigned, err := esTok.SignedString(ecKey1)
	if err != nil {
		t.Fatalf("sign ES256 token: %v", err)
	}

	req1 := httptest.NewRequest(http.MethodGet, "/v1/me", nil)
	req1.Header.Set("Authorization", "Bearer "+esSigned)
	rec1 := httptest.NewRecorder()
	protected.ServeHTTP(rec1, req1)
	if rec1.Code != http.StatusOK {
		t.Fatalf("expected HTTP 200 for ES256 JWKS token, got %d (%s)", rec1.Code, rec1.Body.String())
	}

	// 2. Valid RS256 token.
	rsTok := jwt.NewWithClaims(jwt.SigningMethodRS256, jwt.MapClaims{
		"sub": userID.String(),
		"exp": time.Now().Add(time.Hour).Unix(),
	})
	rsTok.Header["kid"] = "rsa-kid-1"
	rsSigned, err := rsTok.SignedString(rsaKey)
	if err != nil {
		t.Fatalf("sign RS256 token: %v", err)
	}

	req2 := httptest.NewRequest(http.MethodGet, "/v1/me", nil)
	req2.Header.Set("Authorization", "Bearer "+rsSigned)
	rec2 := httptest.NewRecorder()
	protected.ServeHTTP(rec2, req2)
	if rec2.Code != http.StatusOK {
		t.Fatalf("expected HTTP 200 for RS256 JWKS token, got %d (%s)", rec2.Code, rec2.Body.String())
	}

	// 3. Reject HS256 when only JWKS is configured (algorithm confusion guard).
	hsConfused := signHS256Token(t, "arbitrary-hmac-secret-32chars-min", jwt.MapClaims{
		"sub": userID.String(),
		"exp": time.Now().Add(time.Hour).Unix(),
	})
	req3 := httptest.NewRequest(http.MethodGet, "/v1/me", nil)
	req3.Header.Set("Authorization", "Bearer "+hsConfused)
	rec3 := httptest.NewRecorder()
	protected.ServeHTTP(rec3, req3)
	assertUnauthorizedResponse(t, rec3, "")

	// 4. Key rotation: unknown kid triggers JWKS refresh and succeeds for new key.
	rotated.Store(true)
	esTok2 := jwt.NewWithClaims(jwt.SigningMethodES256, jwt.MapClaims{
		"sub": userID.String(),
		"exp": time.Now().Add(time.Hour).Unix(),
	})
	esTok2.Header["kid"] = "ec-kid-2"
	esSigned2, err := esTok2.SignedString(ecKey2)
	if err != nil {
		t.Fatalf("sign rotated ES256 token: %v", err)
	}

	req4 := httptest.NewRequest(http.MethodGet, "/v1/me", nil)
	req4.Header.Set("Authorization", "Bearer "+esSigned2)
	rec4 := httptest.NewRecorder()
	protected.ServeHTTP(rec4, req4)
	if rec4.Code != http.StatusOK {
		t.Fatalf("expected HTTP 200 after JWKS key rotation, got %d (%s)", rec4.Code, rec4.Body.String())
	}
}
