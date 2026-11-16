package handler_test

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/clarafin/api/internal/ai"
	"github.com/clarafin/api/internal/config"
	"github.com/clarafin/api/internal/domain"
	"github.com/clarafin/api/internal/handler"
	"github.com/clarafin/api/internal/middleware"
	"github.com/clarafin/api/internal/repository"
	"github.com/clarafin/api/internal/server"
)

func newTestPractitionerRouter(store *repository.Store, fixedNow time.Time, loc *time.Location) http.Handler {
	matching := ai.NewMatchingTool(
		store,
		ai.WithMatchingNowFunc(func() time.Time { return fixedNow }),
		ai.WithMatchingJakartaLocation(loc),
	)
	h := handler.NewPractitionerHandler(matching)

	r := chi.NewRouter()
	r.Use(middleware.RequestID)
	r.Route("/v1", func(v1 chi.Router) {
		h.RegisterRoutes(v1)
	})
	return r
}

func TestPractitionerHandler_CatalogAndPractitionersEndpoints(t *testing.T) {
	store, ctx := openTestStore(t)
	wib := time.FixedZone("WIB", 7*3600)
	fixedNow := time.Date(2026, 11, 23, 8, 0, 0, 0, wib)
	r := newTestPractitionerRouter(store, fixedNow, wib)

	// 1. GET /v1/catalog-packages returns all 15 official catalog packages.
	reqCat := httptest.NewRequest(http.MethodGet, "/v1/catalog-packages", nil)
	recCat := httptest.NewRecorder()
	r.ServeHTTP(recCat, reqCat)
	if recCat.Code != http.StatusOK {
		t.Fatalf("GET /v1/catalog-packages expected 200, got %d (body: %s)", recCat.Code, recCat.Body.String())
	}

	var catEnv struct {
		Data struct {
			CatalogPackages []ai.CatalogPackageDTO `json:"catalog_packages"`
		} `json:"data"`
		Meta domain.Meta `json:"meta"`
	}
	if err := json.Unmarshal(recCat.Body.Bytes(), &catEnv); err != nil {
		t.Fatalf("unmarshal catalog packages: %v", err)
	}
	if len(catEnv.Data.CatalogPackages) != 15 {
		t.Fatalf("expected 15 catalog packages, got %d", len(catEnv.Data.CatalogPackages))
	}

	// 2. GET /v1/practitioners returns all 6 canonical verified practitioners with c1..c6 IDs and slots.
	reqList := httptest.NewRequest(http.MethodGet, "/v1/practitioners", nil)
	recList := httptest.NewRecorder()
	r.ServeHTTP(recList, reqList)
	if recList.Code != http.StatusOK {
		t.Fatalf("GET /v1/practitioners expected 200, got %d (body: %s)", recList.Code, recList.Body.String())
	}

	rawBody := recList.Body.String()
	for _, forbidden := range []string{"ktp_file_url", "platform_cut_pct", "violation_count", "bank_account", "bank_name", "certificate_file_urls"} {
		if strings.Contains(rawBody, forbidden) {
			t.Fatalf("GET /v1/practitioners leaked private field %q", forbidden)
		}
	}

	var listEnv struct {
		Data struct {
			Practitioners []ai.PublicPractitionerDTO `json:"practitioners"`
		} `json:"data"`
	}
	if err := json.Unmarshal(recList.Body.Bytes(), &listEnv); err != nil {
		t.Fatalf("unmarshal practitioners list: %v", err)
	}
	if len(listEnv.Data.Practitioners) != 6 {
		t.Fatalf("expected 6 practitioners, got %d", len(listEnv.Data.Practitioners))
	}
	seenIDs := map[string]bool{}
	for _, p := range listEnv.Data.Practitioners {
		seenIDs[p.ConsultantID] = true
		if len(p.Packages) == 0 || len(p.UpcomingSlots) == 0 {
			t.Fatalf("expected packages and upcoming_slots for %s, got pkgs=%d slots=%d", p.ConsultantID, len(p.Packages), len(p.UpcomingSlots))
		}
	}
	for _, code := range []string{"c1", "c2", "c3", "c4", "c5", "c6"} {
		if !seenIDs[code] {
			t.Fatalf("missing canonical consultant_id %q in /v1/practitioners", code)
		}
	}

	// 3. Query filters: ?tier=basic returns c3; ?tag=budget_nikah returns c1 & c5; invalid params return 400.
	recTierBasic := httptest.NewRecorder()
	r.ServeHTTP(recTierBasic, httptest.NewRequest(http.MethodGet, "/v1/practitioners?tier=basic", nil))
	if recTierBasic.Code != http.StatusOK {
		t.Fatalf("?tier=basic expected 200, got %d", recTierBasic.Code)
	}
	var tierBasicEnv struct {
		Data struct {
			Practitioners []ai.PublicPractitionerDTO `json:"practitioners"`
		} `json:"data"`
	}
	if err := json.Unmarshal(recTierBasic.Body.Bytes(), &tierBasicEnv); err != nil {
		t.Fatalf("unmarshal ?tier=basic: %v", err)
	}
	if len(tierBasicEnv.Data.Practitioners) != 1 || tierBasicEnv.Data.Practitioners[0].ConsultantID != "c3" {
		t.Fatalf("expected only c3 for ?tier=basic, got %+v", tierBasicEnv.Data.Practitioners)
	}

	recTagCouple := httptest.NewRecorder()
	r.ServeHTTP(recTagCouple, httptest.NewRequest(http.MethodGet, "/v1/practitioners?tag=budget_nikah&method=online", nil))
	if recTagCouple.Code != http.StatusOK {
		t.Fatalf("?tag=budget_nikah expected 200, got %d", recTagCouple.Code)
	}
	var tagCoupleEnv struct {
		Data struct {
			Practitioners []ai.PublicPractitionerDTO `json:"practitioners"`
		} `json:"data"`
	}
	if err := json.Unmarshal(recTagCouple.Body.Bytes(), &tagCoupleEnv); err != nil {
		t.Fatalf("unmarshal ?tag=budget_nikah: %v", err)
	}
	if len(tagCoupleEnv.Data.Practitioners) != 2 {
		t.Fatalf("expected 2 practitioners (c1, c5) for ?tag=budget_nikah, got %d", len(tagCoupleEnv.Data.Practitioners))
	}

	recInvalidTier := httptest.NewRecorder()
	r.ServeHTTP(recInvalidTier, httptest.NewRequest(http.MethodGet, "/v1/practitioners?tier=vip", nil))
	if recInvalidTier.Code != http.StatusBadRequest {
		t.Fatalf("invalid tier expected 400, got %d", recInvalidTier.Code)
	}

	recInvalidMethod := httptest.NewRecorder()
	r.ServeHTTP(recInvalidMethod, httptest.NewRequest(http.MethodGet, "/v1/practitioners?method=telepathy", nil))
	if recInvalidMethod.Code != http.StatusBadRequest {
		t.Fatalf("invalid method expected 400, got %d", recInvalidMethod.Code)
	}

	// 4. GET /v1/practitioners/{id} accepts both "c1" and UUID, returns 400 on invalid id, 404 on unknown UUID.
	// Insert a temporary anonymized review on c1 to verify review serialization and privacy masking.
	reviewer := createTempHandlerUser(t, ctx, store, "rev-c1")
	c1ID := uuid.MustParse("00000000-0000-4000-8000-0000000000c1")
	var tempSessionID uuid.UUID
	if err := store.Pool.QueryRow(ctx, `
		INSERT INTO sessions (
			client_user_id, practitioner_id, service_category, tier, package_title,
			delivery_mode, scheduled_start_at, scheduled_end_at, subtotal_price_idr,
			platform_fee_idr, discount_amount_idr, price_paid, platform_cut_pct, status
		) VALUES (
			$1, $2, 'individual', 'medium', 'Optimalisasi Aset & Proteksi',
			'online', $3, $4, 299000, 15000, 0, 314000, 20, 'completed'
		) RETURNING id
	`, reviewer.ID, c1ID, fixedNow.Add(-48*time.Hour), fixedNow.Add(-47*time.Hour)).Scan(&tempSessionID); err != nil {
		t.Fatalf("insert completed session for review: %v", err)
	}
	if _, err := store.Pool.Exec(ctx, `
		INSERT INTO session_reviews (session_id, reviewer_user_id, rating, comment, is_anonymized)
		VALUES ($1, $2, 5, 'Sangat membantu merapikan cashflow.', TRUE)
	`, tempSessionID, reviewer.ID); err != nil {
		t.Fatalf("insert anonymized review: %v", err)
	}
	t.Cleanup(func() {
		cleanupCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_, _ = store.Pool.Exec(cleanupCtx, `DELETE FROM session_reviews WHERE session_id = $1`, tempSessionID)
		_, _ = store.Pool.Exec(cleanupCtx, `DELETE FROM sessions WHERE id = $1`, tempSessionID)
	})

	for _, idParam := range []string{"c1", c1ID.String()} {
		recDetail := httptest.NewRecorder()
		r.ServeHTTP(recDetail, httptest.NewRequest(http.MethodGet, "/v1/practitioners/"+idParam, nil))
		if recDetail.Code != http.StatusOK {
			t.Fatalf("GET /v1/practitioners/%s expected 200, got %d (body: %s)", idParam, recDetail.Code, recDetail.Body.String())
		}
		detailRaw := recDetail.Body.String()
		if strings.Contains(detailRaw, reviewer.FullName) {
			t.Fatalf("anonymized review leaked reviewer full_name %q", reviewer.FullName)
		}
		for _, forbidden := range []string{"ktp_file_url", "platform_cut_pct", "violation_count", "bank_account", "bank_name"} {
			if strings.Contains(detailRaw, forbidden) {
				t.Fatalf("GET /v1/practitioners/%s leaked private field %q", idParam, forbidden)
			}
		}
		var detailEnv struct {
			Data ai.PublicPractitionerDetailDTO `json:"data"`
		}
		if err := json.Unmarshal(recDetail.Body.Bytes(), &detailEnv); err != nil {
			t.Fatalf("unmarshal practitioner detail (%s): %v", idParam, err)
		}
		if detailEnv.Data.ConsultantID != "c1" || len(detailEnv.Data.Packages) != 4 || len(detailEnv.Data.UpcomingSlots) == 0 {
			t.Fatalf("unexpected detail for %s: %+v", idParam, detailEnv.Data)
		}
		if len(detailEnv.Data.Reviews) == 0 || detailEnv.Data.Reviews[0].ReviewerName != "Klien Clarafin" {
			t.Fatalf("expected anonymized reviewer_name 'Klien Clarafin', got %+v", detailEnv.Data.Reviews)
		}
	}

	recBadID := httptest.NewRecorder()
	r.ServeHTTP(recBadID, httptest.NewRequest(http.MethodGet, "/v1/practitioners/not-valid", nil))
	if recBadID.Code != http.StatusBadRequest {
		t.Fatalf("GET /v1/practitioners/not-valid expected 400, got %d", recBadID.Code)
	}

	recNotFound := httptest.NewRecorder()
	r.ServeHTTP(recNotFound, httptest.NewRequest(http.MethodGet, "/v1/practitioners/"+uuid.NewString(), nil))
	if recNotFound.Code != http.StatusNotFound {
		t.Fatalf("GET /v1/practitioners/{unknown} expected 404, got %d", recNotFound.Code)
	}
}

func TestPractitionerRoutes_MountedOnServerWithAuth(t *testing.T) {
	store, _ := openTestStore(t)
	userID := uuid.New()
	email := "prac-router-" + userID.String()[:8] + "@clarafin.test"
	t.Cleanup(func() {
		cleanupCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_, _ = store.Pool.Exec(cleanupCtx, `DELETE FROM auth.users WHERE id = $1`, userID)
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
	})

	// Unauthenticated requests return 401.
	for _, path := range []string{"/v1/practitioners", "/v1/practitioners/c1", "/v1/catalog-packages"} {
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, path, nil))
		if rec.Code != http.StatusUnauthorized {
			t.Fatalf("unauthenticated %s expected 401, got %d", path, rec.Code)
		}
	}

	// Mint dev token and verify 200 OK on all 3 mounted endpoints.
	tokReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/dev/token",
		bytes.NewBufferString(`{"user_id":"`+userID.String()+`","email":"`+email+`","full_name":"Prac Tester"}`),
	)
	tokRec := httptest.NewRecorder()
	r.ServeHTTP(tokRec, tokReq)
	if tokRec.Code != http.StatusOK {
		t.Fatalf("POST /v1/dev/token expected 200, got %d", tokRec.Code)
	}
	var tokEnv struct {
		Data handler.DevTokenResponse `json:"data"`
	}
	if err := json.Unmarshal(tokRec.Body.Bytes(), &tokEnv); err != nil {
		t.Fatalf("unmarshal token: %v", err)
	}

	for _, path := range []string{"/v1/practitioners", "/v1/practitioners/c1", "/v1/catalog-packages"} {
		req := httptest.NewRequest(http.MethodGet, path, nil)
		req.Header.Set("Authorization", "Bearer "+tokEnv.Data.AccessToken)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)
		if rec.Code != http.StatusOK {
			t.Fatalf("authenticated GET %s expected 200, got %d (body: %s)", path, rec.Code, rec.Body.String())
		}
	}
}
