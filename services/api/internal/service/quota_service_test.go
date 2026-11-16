package service_test

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/url"
	"os"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/clarafin/api/internal/repository"
	"github.com/clarafin/api/internal/service"
)

func openQuotaTestStore(t *testing.T) (*repository.Store, context.Context) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	t.Cleanup(cancel)

	pool, err := pgxpool.New(ctx, buildQuotaTestDSN())
	if err != nil {
		t.Fatalf("connect pgxpool: %v", err)
	}
	t.Cleanup(pool.Close)

	if err := pool.Ping(ctx); err != nil {
		t.Fatalf("ping postgres: %v", err)
	}

	return repository.NewStore(pool), ctx
}

func buildQuotaTestDSN() string {
	for _, key := range []string{"TEST_DATABASE_URL", "DOCKER_DATABASE_URL"} {
		if raw := strings.TrimSpace(os.Getenv(key)); raw != "" {
			return raw
		}
	}

	user := envQuotaOrDefault("POSTGRES_USER", "clarafin")
	pass := envQuotaOrDefault("POSTGRES_PASSWORD", "clarafin_dev_password")
	db := envQuotaOrDefault("POSTGRES_DB", "clarafin")
	host := envQuotaOrDefault("POSTGRES_HOST", "postgres")
	port := envQuotaOrDefault("POSTGRES_PORT", "5432")

	u := url.URL{
		Scheme:   "postgres",
		User:     url.UserPassword(user, pass),
		Host:     net.JoinHostPort(host, port),
		Path:     "/" + db,
		RawQuery: "sslmode=disable",
	}
	return u.String()
}

func envQuotaOrDefault(key, fallback string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return fallback
}

func createTempQuotaUser(t *testing.T, ctx context.Context, store *repository.Store, label string) repository.User {
	t.Helper()

	userID := uuid.New()
	email := fmt.Sprintf("quota-svc-%s-%s@clarafin.test", label, userID.String()[:8])

	user, err := store.EnsureDevUserAccount(ctx, repository.EnsureDevUserParams{
		ID:       userID,
		Email:    email,
		FullName: "Quota Test " + label,
	})
	if err != nil {
		t.Fatalf("EnsureDevUserAccount(%s): %v", label, err)
	}

	t.Cleanup(func() {
		cleanupCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if _, err := store.Pool.Exec(cleanupCtx, `DELETE FROM auth.users WHERE id = $1`, userID); err != nil {
			t.Errorf("cleanup test user %s: %v", userID, err)
		}
	})

	return user
}

func TestQuotaService_FreeLimit40AndExhaustion(t *testing.T) {
	store, ctx := openQuotaTestStore(t)
	user := createTempQuotaUser(t, ctx, store, "free40")

	fixedNow := time.Date(2026, 11, 15, 10, 0, 0, 0, time.FixedZone("WIB", 7*3600))
	svc := service.NewQuotaService(store, service.WithNowFunc(func() time.Time { return fixedNow }))

	status, err := svc.GetQuotaStatus(ctx, user.ID)
	if err != nil {
		t.Fatalf("initial GetQuotaStatus: %v", err)
	}
	if status.PlanType != "free" || status.QuotaTotal != 40 || status.QuotaUsed != 0 || status.QuotaRemaining != 40 {
		t.Fatalf("unexpected initial free status: %+v", status)
	}
	if status.RenewalDate != "2026-12-01T00:00:00+07:00" {
		t.Fatalf("expected renewal_date 2026-12-01T00:00:00+07:00, got %q", status.RenewalDate)
	}

	for i := 1; i <= 40; i++ {
		res, err := svc.ReserveAction(ctx, user.ID, fmt.Sprintf("req_free_%s_%d", user.ID.String()[:8], i), "chat", "full_screen")
		if err != nil {
			t.Fatalf("ReserveAction #%d: %v", i, err)
		}
		if res.Bucket != "free" || res.Reused {
			t.Fatalf("ReserveAction #%d unexpected bucket/reused: %+v", i, res)
		}
		if res.QuotaStatus.QuotaUsed != i || res.QuotaStatus.QuotaRemaining != 40-i {
			t.Fatalf("ReserveAction #%d quota mismatch: %+v", i, res.QuotaStatus)
		}
	}

	// 41st call must be rejected with ErrQuotaExceeded.
	_, err = svc.ReserveAction(ctx, user.ID, "req_free_41_"+uuid.NewString(), "chat", "full_screen")
	if !errors.Is(err, service.ErrQuotaExceeded) {
		t.Fatalf("expected ErrQuotaExceeded on 41st call, got %v", err)
	}
}

func TestQuotaService_ConcurrentIdempotentRequestIDAndBoundaryRace(t *testing.T) {
	store, ctx := openQuotaTestStore(t)
	freeUser := createTempQuotaUser(t, ctx, store, "idem-free")
	proUser := createTempQuotaUser(t, ctx, store, "idem-pro")

	fixedNow := time.Date(2026, 11, 15, 10, 0, 0, 0, time.FixedZone("WIB", 7*3600))
	svc := service.NewQuotaService(store, service.WithNowFunc(func() time.Time { return fixedNow }))

	// 1. Concurrent calls with the same client_request_id on a free user reserve only 1 row.
	sharedReqID := "req_same_" + uuid.NewString()
	const workers = 5
	var wg sync.WaitGroup
	errs := make(chan error, workers)
	resCh := make(chan *service.QuotaReservation, workers)

	for i := 0; i < workers; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			res, err := svc.ReserveAction(ctx, freeUser.ID, sharedReqID, "chat", "quick_sheet")
			if err != nil {
				errs <- err
				return
			}
			resCh <- res
		}()
	}
	wg.Wait()
	close(errs)
	close(resCh)

	for err := range errs {
		t.Fatalf("concurrent idempotent ReserveAction error: %v", err)
	}
	reusedCount := 0
	freshCount := 0
	for res := range resCh {
		if res.Reused {
			reusedCount++
		} else {
			freshCount++
		}
	}
	if freshCount != 1 || reusedCount != workers-1 {
		t.Fatalf("expected 1 fresh and %d reused reservations, got fresh=%d reused=%d", workers-1, freshCount, reusedCount)
	}

	var ledgerCount int
	if err := store.Pool.QueryRow(ctx, `SELECT COUNT(*) FROM ai_usage_ledger WHERE request_id = $1`, sharedReqID).Scan(&ledgerCount); err != nil {
		t.Fatalf("count ledger rows: %v", err)
	}
	if ledgerCount != 1 {
		t.Fatalf("expected 1 ledger row for %s, got %d", sharedReqID, ledgerCount)
	}

	// 2. Concurrent calls with the same request_id on a pro_monthly user do not double-charge quota_used.
	startsAt := fixedNow.Add(-1 * time.Hour)
	expiresAt := fixedNow.Add(24 * time.Hour)
	var subID uuid.UUID
	if err := store.Pool.QueryRow(ctx, `
		INSERT INTO pro_subscriptions (user_id, plan_type, price_paid, quota_total, quota_used, status, starts_at, expires_at)
		VALUES ($1, 'pro_monthly', 49000, 400, 0, 'active', $2, $3)
		RETURNING id
	`, proUser.ID, startsAt, expiresAt).Scan(&subID); err != nil {
		t.Fatalf("insert pro_subscription: %v", err)
	}

	proReqID := "req_pro_same_" + uuid.NewString()
	var proWG sync.WaitGroup
	proErrs := make(chan error, workers)
	for i := 0; i < workers; i++ {
		proWG.Add(1)
		go func() {
			defer proWG.Done()
			_, err := svc.ReserveAction(ctx, proUser.ID, proReqID, "chat", "full_screen")
			if err != nil {
				proErrs <- err
			}
		}()
	}
	proWG.Wait()
	close(proErrs)
	for err := range proErrs {
		t.Fatalf("concurrent pro idempotent error: %v", err)
	}

	var proUsed int32
	if err := store.Pool.QueryRow(ctx, `SELECT quota_used FROM pro_subscriptions WHERE id = $1`, subID).Scan(&proUsed); err != nil {
		t.Fatalf("query pro quota_used: %v", err)
	}
	if proUsed != 1 {
		t.Fatalf("expected pro_subscriptions.quota_used == 1 after concurrent retries, got %d", proUsed)
	}

	// 3. Free user at 39/40 firing 2 concurrent requests with distinct request_ids: 1 succeeds, 1 gets ErrQuotaExceeded.
	for i := 1; i <= 38; i++ {
		if _, err := svc.ReserveAction(ctx, freeUser.ID, fmt.Sprintf("req_fill_%s_%d", freeUser.ID.String()[:8], i), "chat", "full_screen"); err != nil {
			t.Fatalf("fill #%d: %v", i, err)
		}
	}

	var raceWG sync.WaitGroup
	raceErrs := make(chan error, 2)
	for i := 0; i < 2; i++ {
		raceWG.Add(1)
		go func(idx int) {
			defer raceWG.Done()
			_, err := svc.ReserveAction(ctx, freeUser.ID, fmt.Sprintf("req_race_%s_%d", freeUser.ID.String()[:8], idx), "chat", "full_screen")
			raceErrs <- err
		}(i)
	}
	raceWG.Wait()
	close(raceErrs)

	okCount, exceededCount := 0, 0
	for err := range raceErrs {
		switch {
		case err == nil:
			okCount++
		case errors.Is(err, service.ErrQuotaExceeded):
			exceededCount++
		default:
			t.Fatalf("unexpected race error: %v", err)
		}
	}
	if okCount != 1 || exceededCount != 1 {
		t.Fatalf("expected 1 success and 1 ErrQuotaExceeded at 39/40 race, got ok=%d exceeded=%d", okCount, exceededCount)
	}
}

func TestQuotaService_CommitAndCompensateFailureRestoresQuota(t *testing.T) {
	store, ctx := openQuotaTestStore(t)
	freeUser := createTempQuotaUser(t, ctx, store, "comp-free")
	proUser := createTempQuotaUser(t, ctx, store, "comp-pro")

	fixedNow := time.Date(2026, 11, 15, 10, 0, 0, 0, time.FixedZone("WIB", 7*3600))
	svc := service.NewQuotaService(store, service.WithNowFunc(func() time.Time { return fixedNow }))

	for i := 1; i <= 39; i++ {
		reqID := fmt.Sprintf("req_pre_%s_%d", freeUser.ID.String()[:8], i)
		if _, err := svc.ReserveAction(ctx, freeUser.ID, reqID, "chat", "full_screen"); err != nil {
			t.Fatalf("pre reserve %d: %v", i, err)
		}
		if err := svc.CommitSuccess(ctx, reqID); err != nil {
			t.Fatalf("pre commit %d: %v", i, err)
		}
	}

	// Reserve 40th action, simulate failure -> CompensateFailure must restore usable slot (39/40).
	req40Fail := "req_40_fail_" + uuid.NewString()
	if _, err := svc.ReserveAction(ctx, freeUser.ID, req40Fail, "quick_add", "quick_sheet"); err != nil {
		t.Fatalf("reserve 40th: %v", err)
	}
	if err := svc.CompensateFailure(ctx, req40Fail); err != nil {
		t.Fatalf("CompensateFailure: %v", err)
	}
	// Repeating CompensateFailure is idempotent.
	if err := svc.CompensateFailure(ctx, req40Fail); err != nil {
		t.Fatalf("second CompensateFailure: %v", err)
	}

	status, err := svc.GetQuotaStatus(ctx, freeUser.ID)
	if err != nil {
		t.Fatalf("GetQuotaStatus after compensate: %v", err)
	}
	if status.QuotaUsed != 39 || status.QuotaRemaining != 1 {
		t.Fatalf("expected 39/40 used (1 remaining) after CompensateFailure, got %+v", status)
	}

	// User can reuse the restored 40th slot with a new request_id and commit it.
	req40Retry := "req_40_retry_" + uuid.NewString()
	if _, err := svc.ReserveAction(ctx, freeUser.ID, req40Retry, "quick_add", "quick_sheet"); err != nil {
		t.Fatalf("reserve restored slot: %v", err)
	}
	if err := svc.CommitSuccess(ctx, req40Retry); err != nil {
		t.Fatalf("CommitSuccess: %v", err)
	}
	// Repeating CommitSuccess is idempotent.
	if err := svc.CommitSuccess(ctx, req40Retry); err != nil {
		t.Fatalf("second CommitSuccess: %v", err)
	}
	// CompensateFailure after CommitSuccess must fail without reverting status.
	if err := svc.CompensateFailure(ctx, req40Retry); !errors.Is(err, service.ErrReservationFinalized) {
		t.Fatalf("expected ErrReservationFinalized when compensating committed request, got %v", err)
	}

	// Pro subscription compensation decrements pro_subscriptions.quota_used cleanly.
	startsAt := fixedNow.Add(-1 * time.Hour)
	expiresAt := fixedNow.Add(24 * time.Hour)
	var subID uuid.UUID
	if err := store.Pool.QueryRow(ctx, `
		INSERT INTO pro_subscriptions (user_id, plan_type, price_paid, quota_total, quota_used, status, starts_at, expires_at)
		VALUES ($1, 'pro_monthly', 49000, 2, 0, 'active', $2, $3)
		RETURNING id
	`, proUser.ID, startsAt, expiresAt).Scan(&subID); err != nil {
		t.Fatalf("insert pro_subscription: %v", err)
	}

	reqP1 := "req_p1_" + uuid.NewString()
	reqP2 := "req_p2_" + uuid.NewString()
	if _, err := svc.ReserveAction(ctx, proUser.ID, reqP1, "chat", "full_screen"); err != nil {
		t.Fatalf("pro reserve 1: %v", err)
	}
	if err := svc.CommitSuccess(ctx, reqP1); err != nil {
		t.Fatalf("pro commit 1: %v", err)
	}
	if _, err := svc.ReserveAction(ctx, proUser.ID, reqP2, "chat", "full_screen"); err != nil {
		t.Fatalf("pro reserve 2: %v", err)
	}
	if _, err := svc.ReserveAction(ctx, proUser.ID, "req_p3_"+uuid.NewString(), "chat", "full_screen"); !errors.Is(err, service.ErrQuotaExceeded) {
		t.Fatalf("expected ErrQuotaExceeded at 2/2 pro quota, got %v", err)
	}

	// Compensating reqP2 restores quota_used from 2 back to 1.
	if err := svc.CompensateFailure(ctx, reqP2); err != nil {
		t.Fatalf("pro CompensateFailure: %v", err)
	}
	// Duplicate compensation must NOT decrement below 1.
	if err := svc.CompensateFailure(ctx, reqP2); err != nil {
		t.Fatalf("pro second CompensateFailure: %v", err)
	}

	proStatus, err := svc.GetQuotaStatus(ctx, proUser.ID)
	if err != nil {
		t.Fatalf("pro GetQuotaStatus: %v", err)
	}
	if proStatus.PlanType != "pro_monthly" || proStatus.QuotaTotal != 2 || proStatus.QuotaUsed != 1 || proStatus.QuotaRemaining != 1 {
		t.Fatalf("unexpected pro status after compensation: %+v", proStatus)
	}

	if _, err := svc.ReserveAction(ctx, proUser.ID, "req_p2_retry_"+uuid.NewString(), "chat", "full_screen"); err != nil {
		t.Fatalf("pro reserve restored slot: %v", err)
	}
}

func TestQuotaService_UnlimitedNeverBlocks(t *testing.T) {
	store, ctx := openQuotaTestStore(t)
	user := createTempQuotaUser(t, ctx, store, "unlimited")

	fixedNow := time.Date(2026, 11, 15, 10, 0, 0, 0, time.FixedZone("WIB", 7*3600))
	svc := service.NewQuotaService(store, service.WithNowFunc(func() time.Time { return fixedNow }))

	startsAt := fixedNow.Add(-1 * time.Hour)
	expiresAt := fixedNow.Add(30 * 24 * time.Hour)
	if _, err := store.Pool.Exec(ctx, `
		INSERT INTO pro_subscriptions (user_id, plan_type, price_paid, quota_total, quota_used, status, starts_at, expires_at)
		VALUES ($1, 'unlimited_monthly', 99000, -1, 0, 'active', $2, $3)
	`, user.ID, startsAt, expiresAt); err != nil {
		t.Fatalf("insert unlimited subscription: %v", err)
	}

	for i := 1; i <= 45; i++ {
		res, err := svc.ReserveAction(ctx, user.ID, fmt.Sprintf("req_unli_%s_%d", user.ID.String()[:8], i), "chat", "full_screen")
		if err != nil {
			t.Fatalf("unlimited ReserveAction #%d failed: %v", i, err)
		}
		if res.Bucket != "unlimited" {
			t.Fatalf("expected bucket 'unlimited', got %q", res.Bucket)
		}
	}

	status, err := svc.GetQuotaStatus(ctx, user.ID)
	if err != nil {
		t.Fatalf("unlimited GetQuotaStatus: %v", err)
	}
	if status.PlanType != "unlimited" || status.QuotaTotal != -1 || status.QuotaRemaining != -1 {
		t.Fatalf("unexpected unlimited status: %+v", status)
	}
	if status.QuotaUsed != 45 {
		t.Fatalf("expected unlimited monthly used=45, got %d", status.QuotaUsed)
	}
}

func TestQuotaService_WIBMonthBoundaryRollover(t *testing.T) {
	store, ctx := openQuotaTestStore(t)
	user := createTempQuotaUser(t, ctx, store, "wib-rollover")

	// 2026-10-31T16:55:00Z == 2026-10-31 23:55:00 WIB -> month_year "2026-10".
	currentTime := time.Date(2026, 10, 31, 16, 55, 0, 0, time.UTC)
	svc := service.NewQuotaService(store, service.WithNowFunc(func() time.Time { return currentTime }))

	for i := 1; i <= 40; i++ {
		res, err := svc.ReserveAction(ctx, user.ID, fmt.Sprintf("req_oct_%s_%d", user.ID.String()[:8], i), "chat", "full_screen")
		if err != nil {
			t.Fatalf("October ReserveAction #%d: %v", i, err)
		}
		if res.MonthYear != "2026-10" {
			t.Fatalf("expected month_year 2026-10, got %q", res.MonthYear)
		}
	}

	if _, err := svc.ReserveAction(ctx, user.ID, "req_oct_41_"+uuid.NewString(), "chat", "full_screen"); !errors.Is(err, service.ErrQuotaExceeded) {
		t.Fatalf("expected ErrQuotaExceeded at 23:55 WIB on Oct 31, got %v", err)
	}

	// Advance 10 minutes to 2026-10-31T17:05:00Z == 2026-11-01 00:05:00 WIB -> month_year "2026-11".
	currentTime = time.Date(2026, 10, 31, 17, 5, 0, 0, time.UTC)

	status, err := svc.GetQuotaStatus(ctx, user.ID)
	if err != nil {
		t.Fatalf("November GetQuotaStatus: %v", err)
	}
	if status.QuotaUsed != 0 || status.QuotaRemaining != 40 {
		t.Fatalf("expected fresh 0/40 quota at 00:05 WIB Nov 1, got %+v", status)
	}
	if status.RenewalDate != "2026-12-01T00:00:00+07:00" {
		t.Fatalf("expected renewal_date 2026-12-01T00:00:00+07:00, got %q", status.RenewalDate)
	}

	resNov, err := svc.ReserveAction(ctx, user.ID, "req_nov_1_"+uuid.NewString(), "chat", "full_screen")
	if err != nil {
		t.Fatalf("November ReserveAction after WIB midnight reset: %v", err)
	}
	if resNov.MonthYear != "2026-11" {
		t.Fatalf("expected month_year 2026-11, got %q", resNov.MonthYear)
	}
}

func TestQuotaService_ValidationAndMissingUser(t *testing.T) {
	store, ctx := openQuotaTestStore(t)
	svc := service.NewQuotaService(store)

	if _, err := svc.ReserveAction(ctx, uuid.Nil, "req_1", "chat", "full_screen"); !errors.Is(err, service.ErrInvalidQuotaRequest) {
		t.Fatalf("expected ErrInvalidQuotaRequest for nil userID, got %v", err)
	}
	if _, err := svc.ReserveAction(ctx, uuid.New(), "   ", "chat", "full_screen"); !errors.Is(err, service.ErrInvalidQuotaRequest) {
		t.Fatalf("expected ErrInvalidQuotaRequest for empty requestID, got %v", err)
	}
	if _, err := svc.ReserveAction(ctx, uuid.New(), "req_1", "hack", "full_screen"); !errors.Is(err, service.ErrInvalidQuotaRequest) {
		t.Fatalf("expected ErrInvalidQuotaRequest for invalid actionType, got %v", err)
	}
	if _, err := svc.ReserveAction(ctx, uuid.New(), "req_1", "chat", "unknown_surface"); !errors.Is(err, service.ErrInvalidQuotaRequest) {
		t.Fatalf("expected ErrInvalidQuotaRequest for invalid surfaceMode, got %v", err)
	}
	if _, err := svc.ReserveAction(ctx, uuid.New(), "req_missing_"+uuid.NewString(), "chat", "full_screen"); !errors.Is(err, service.ErrUserNotFound) {
		t.Fatalf("expected ErrUserNotFound for nonexistent user, got %v", err)
	}
	if _, err := svc.GetQuotaStatus(ctx, uuid.New()); !errors.Is(err, service.ErrUserNotFound) {
		t.Fatalf("expected ErrUserNotFound on GetQuotaStatus for nonexistent user, got %v", err)
	}
	if err := svc.CommitSuccess(ctx, "req_nonexistent_"+uuid.NewString()); !errors.Is(err, service.ErrReservationNotFound) {
		t.Fatalf("expected ErrReservationNotFound on CommitSuccess, got %v", err)
	}
	if err := svc.CompensateFailure(ctx, "req_nonexistent_"+uuid.NewString()); !errors.Is(err, service.ErrReservationNotFound) {
		t.Fatalf("expected ErrReservationNotFound on CompensateFailure, got %v", err)
	}
}
