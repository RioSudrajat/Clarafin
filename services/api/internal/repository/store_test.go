package repository_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"net/url"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/clarafin/api/internal/repository"
)

func openTestStore(t *testing.T) (*repository.Store, context.Context) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
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

func createTempTestUser(t *testing.T, ctx context.Context, store *repository.Store, label string) repository.User {
	t.Helper()

	userID := uuid.New()
	email := fmt.Sprintf("repo-test-%s-%s@clarafin.test", label, userID.String()[:8])

	user, err := store.EnsureDevUserAccount(ctx, repository.EnsureDevUserParams{
		ID:       userID,
		Email:    email,
		FullName: "Test " + label,
	})
	if err != nil {
		t.Fatalf("EnsureDevUserAccount(%s): %v", label, err)
	}

	t.Cleanup(func() {
		cleanupCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		// Remove restrictive-FK child rows (transactions, goal_contributions) before cascading auth.users deletion.
		stmts := []string{
			`DELETE FROM transactions WHERE user_id = $1`,
			`DELETE FROM goal_contributions WHERE goal_id IN (SELECT id FROM goals WHERE user_id = $1)`,
			`DELETE FROM goals WHERE user_id = $1`,
			`DELETE FROM wallets WHERE user_id = $1`,
			`DELETE FROM auth.users WHERE id = $1`,
		}
		for _, stmt := range stmts {
			if _, err := store.Pool.Exec(cleanupCtx, stmt, userID); err != nil {
				t.Errorf("cleanup test user %s (%s): %v", userID, stmt, err)
			}
		}
	})

	return user
}

func strPtr(s string) *string        { return &s }
func int64Ptr(v int64) *int64        { return &v }
func boolPtr(b bool) *bool           { return &b }
func timePtr(t time.Time) *time.Time { return &t }

func TestStore_ReserveAIUsage_IdempotencyConflictAndTransitions(t *testing.T) {
	store, ctx := openTestStore(t)
	userA := createTempTestUser(t, ctx, store, "quota-a")
	userB := createTempTestUser(t, ctx, store, "quota-b")

	monthYear := "2026-11"
	reqID1 := "req_" + uuid.NewString()
	reqID2 := "req_" + uuid.NewString()

	reserved, err := store.ReserveAIUsage(ctx, repository.ReserveAIUsageParams{
		UserID:      userA.ID,
		RequestID:   reqID1,
		MonthYear:   monthYear,
		ActionType:  "chat",
		SurfaceMode: "full_screen",
		Bucket:      "free",
	})
	if err != nil {
		t.Fatalf("first ReserveAIUsage: %v", err)
	}
	if reserved.Status != "reserved" || reserved.UserID != userA.ID || reserved.RequestID != reqID1 {
		t.Fatalf("unexpected reserved row: %+v", reserved)
	}

	// Same request_id must conflict cleanly with ErrNoRows without duplicating rows.
	_, err = store.ReserveAIUsage(ctx, repository.ReserveAIUsageParams{
		UserID:      userA.ID,
		RequestID:   reqID1,
		MonthYear:   monthYear,
		ActionType:  "chat",
		SurfaceMode: "full_screen",
		Bucket:      "free",
	})
	if !errors.Is(err, pgx.ErrNoRows) {
		t.Fatalf("expected pgx.ErrNoRows on duplicate ReserveAIUsage, got %v", err)
	}

	// Owner can inspect existing reservation, while another user cannot.
	existing, err := store.GetAIUsageByRequestID(ctx, repository.GetAIUsageByRequestIDParams{
		UserID:    userA.ID,
		RequestID: reqID1,
	})
	if err != nil || existing.ID != reserved.ID {
		t.Fatalf("GetAIUsageByRequestID(userA) = (%+v, %v), want ID %s", existing, err, reserved.ID)
	}

	if _, err := store.GetAIUsageByRequestID(ctx, repository.GetAIUsageByRequestIDParams{
		UserID:    userB.ID,
		RequestID: reqID1,
	}); !errors.Is(err, pgx.ErrNoRows) {
		t.Fatalf("expected cross-user GetAIUsageByRequestID to return ErrNoRows, got %v", err)
	}

	// Cross-user completion or failure attempts must never mutate userA's reservation.
	if _, err := store.MarkAIUsageSuccess(ctx, repository.MarkAIUsageSuccessParams{
		UserID:    userB.ID,
		RequestID: reqID1,
	}); !errors.Is(err, pgx.ErrNoRows) {
		t.Fatalf("expected cross-user MarkAIUsageSuccess to return ErrNoRows, got %v", err)
	}

	succeeded, err := store.MarkAIUsageSuccess(ctx, repository.MarkAIUsageSuccessParams{
		UserID:    userA.ID,
		RequestID: reqID1,
	})
	if err != nil {
		t.Fatalf("MarkAIUsageSuccess(userA): %v", err)
	}
	if succeeded.Status != "success" {
		t.Fatalf("expected status 'success', got %q", succeeded.Status)
	}

	// Once finalized as success, MarkAIUsageFailed must not revert it.
	if _, err := store.MarkAIUsageFailed(ctx, repository.MarkAIUsageFailedParams{
		UserID:    userA.ID,
		RequestID: reqID1,
	}); !errors.Is(err, pgx.ErrNoRows) {
		t.Fatalf("expected MarkAIUsageFailed after success to return ErrNoRows, got %v", err)
	}

	// Second request reserved then marked failed must not count toward free quota usage.
	if _, err := store.ReserveAIUsage(ctx, repository.ReserveAIUsageParams{
		UserID:      userA.ID,
		RequestID:   reqID2,
		MonthYear:   monthYear,
		ActionType:  "quick_add",
		SurfaceMode: "quick_sheet",
		Bucket:      "free",
	}); err != nil {
		t.Fatalf("second ReserveAIUsage: %v", err)
	}
	failed, err := store.MarkAIUsageFailed(ctx, repository.MarkAIUsageFailedParams{
		UserID:    userA.ID,
		RequestID: reqID2,
	})
	if err != nil {
		t.Fatalf("MarkAIUsageFailed(userA): %v", err)
	}
	if failed.Status != "failed" {
		t.Fatalf("expected status 'failed', got %q", failed.Status)
	}

	usedCount, err := store.GetMonthlyFreeUsageCount(ctx, repository.GetMonthlyFreeUsageCountParams{
		UserID:    userA.ID,
		MonthYear: monthYear,
	})
	if err != nil {
		t.Fatalf("GetMonthlyFreeUsageCount: %v", err)
	}
	if usedCount != 1 {
		t.Fatalf("expected monthly free used count 1 (excluding failed), got %d", usedCount)
	}
}

func TestStore_ProSubscriptionQuotaLifecycleAndIsolation(t *testing.T) {
	store, ctx := openTestStore(t)
	userA := createTempTestUser(t, ctx, store, "sub-a")
	userB := createTempTestUser(t, ctx, store, "sub-b")

	var subID uuid.UUID
	startsAt := time.Now().Add(-1 * time.Hour)
	expiresAt := time.Now().Add(24 * time.Hour)

	if err := store.Pool.QueryRow(ctx, `
		INSERT INTO pro_subscriptions (user_id, plan_type, price_paid, quota_total, quota_used, status, starts_at, expires_at)
		VALUES ($1, 'pro_monthly', 49000, 2, 0, 'active', $2, $3)
		RETURNING id
	`, userA.ID, startsAt, expiresAt).Scan(&subID); err != nil {
		t.Fatalf("insert test pro_subscription: %v", err)
	}

	active, err := store.GetActiveProSubscription(ctx, userA.ID)
	if err != nil {
		t.Fatalf("GetActiveProSubscription: %v", err)
	}
	if active.ID != subID || active.QuotaTotal != 2 || active.QuotaUsed != 0 {
		t.Fatalf("unexpected active subscription: %+v", active)
	}

	if _, err := store.IncrementProSubscriptionUsage(ctx, repository.IncrementProSubscriptionUsageParams{
		UserID: userB.ID,
		ID:     subID,
	}); !errors.Is(err, pgx.ErrNoRows) {
		t.Fatalf("expected cross-user IncrementProSubscriptionUsage to fail with ErrNoRows, got %v", err)
	}

	for wantUsed := int32(1); wantUsed <= 2; wantUsed++ {
		updated, err := store.IncrementProSubscriptionUsage(ctx, repository.IncrementProSubscriptionUsageParams{
			UserID: userA.ID,
			ID:     subID,
		})
		if err != nil {
			t.Fatalf("IncrementProSubscriptionUsage step %d: %v", wantUsed, err)
		}
		if updated.QuotaUsed != wantUsed {
			t.Fatalf("expected quota_used %d, got %d", wantUsed, updated.QuotaUsed)
		}
	}

	// Capacity exhausted: third increment must return ErrNoRows.
	if _, err := store.IncrementProSubscriptionUsage(ctx, repository.IncrementProSubscriptionUsageParams{
		UserID: userA.ID,
		ID:     subID,
	}); !errors.Is(err, pgx.ErrNoRows) {
		t.Fatalf("expected exhausted IncrementProSubscriptionUsage to return ErrNoRows, got %v", err)
	}

	// Compensating rollback decrements quota_used.
	rolledBack, err := store.DecrementProSubscriptionUsage(ctx, repository.DecrementProSubscriptionUsageParams{
		UserID: userA.ID,
		ID:     subID,
	})
	if err != nil {
		t.Fatalf("DecrementProSubscriptionUsage: %v", err)
	}
	if rolledBack.QuotaUsed != 1 {
		t.Fatalf("expected quota_used 1 after decrement, got %d", rolledBack.QuotaUsed)
	}
}

func TestStore_WithTx_CommitAndRollback(t *testing.T) {
	store, ctx := openTestStore(t)
	user := createTempTestUser(t, ctx, store, "tx")

	sentinelErr := errors.New("forced rollback")
	err := store.WithTx(ctx, func(q *repository.Queries) error {
		if _, err := q.CreateWallet(ctx, repository.CreateWalletParams{
			UserID:  user.ID,
			Name:    "Should Rollback",
			Type:    "bank",
			Balance: 500000,
		}); err != nil {
			return err
		}
		return sentinelErr
	})
	if !errors.Is(err, sentinelErr) {
		t.Fatalf("expected sentinelErr from rolled-back WithTx, got %v", err)
	}

	walletsAfterRollback, err := store.ListActiveWalletsByUser(ctx, user.ID)
	if err != nil {
		t.Fatalf("ListActiveWalletsByUser after rollback: %v", err)
	}
	if len(walletsAfterRollback) != 0 {
		t.Fatalf("expected 0 wallets after rollback, got %d", len(walletsAfterRollback))
	}

	var committedWallet repository.Wallet
	err = store.WithTx(ctx, func(q *repository.Queries) error {
		w, err := q.CreateWallet(ctx, repository.CreateWalletParams{
			UserID:  user.ID,
			Name:    "BCA Utama",
			Type:    "bank",
			Balance: 1000000,
		})
		if err != nil {
			return err
		}

		updated, err := q.UpdateWalletBalanceDelta(ctx, repository.UpdateWalletBalanceDeltaParams{
			UserID: user.ID,
			ID:     w.ID,
			Delta:  -150000,
		})
		if err != nil {
			return err
		}
		committedWallet = updated
		return nil
	})
	if err != nil {
		t.Fatalf("commit WithTx: %v", err)
	}
	if committedWallet.Balance != 850000 {
		t.Fatalf("expected committed wallet balance 850000, got %d", committedWallet.Balance)
	}

	walletsAfterCommit, err := store.ListActiveWalletsByUser(ctx, user.ID)
	if err != nil {
		t.Fatalf("ListActiveWalletsByUser after commit: %v", err)
	}
	if len(walletsAfterCommit) != 1 || walletsAfterCommit[0].Balance != 850000 {
		t.Fatalf("unexpected wallets after commit: %+v", walletsAfterCommit)
	}
}

func TestStore_InsertTransactionIdempotent_AndCrossUserIsolation(t *testing.T) {
	store, ctx := openTestStore(t)
	userA := createTempTestUser(t, ctx, store, "tx-a")
	userB := createTempTestUser(t, ctx, store, "tx-b")

	walletA, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID:  userA.ID,
		Name:    "GoPay A",
		Type:    "ewallet",
		Balance: 500000,
	})
	if err != nil {
		t.Fatalf("CreateWallet A: %v", err)
	}
	walletB, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID:  userB.ID,
		Name:    "GoPay B",
		Type:    "ewallet",
		Balance: 500000,
	})
	if err != nil {
		t.Fatalf("CreateWallet B: %v", err)
	}

	occurred := time.Date(2026, 11, 10, 10, 0, 0, 0, time.FixedZone("WIB", 7*3600))
	mutID := "mut_" + uuid.NewString()

	txA, err := store.InsertTransactionIdempotent(ctx, repository.InsertTransactionIdempotentParams{
		UserID:           userA.ID,
		WalletID:         walletA.ID,
		Type:             "expense",
		Category:         "Food & Beverage • Coffee Shop",
		Amount:           28000,
		Title:            "Kopi Kenangan",
		Note:             strPtr("es kopi susu"),
		OccurredAt:       occurred,
		Source:           "ai_text",
		ClientMutationID: strPtr(mutID),
	})
	if err != nil {
		t.Fatalf("first InsertTransactionIdempotent: %v", err)
	}

	// Retrying the same client_mutation_id for userA returns ErrNoRows without inserting a second row.
	_, err = store.InsertTransactionIdempotent(ctx, repository.InsertTransactionIdempotentParams{
		UserID:           userA.ID,
		WalletID:         walletA.ID,
		Type:             "expense",
		Category:         "Food & Beverage • Coffee Shop",
		Amount:           28000,
		Title:            "Kopi Kenangan",
		OccurredAt:       occurred,
		Source:           "ai_text",
		ClientMutationID: strPtr(mutID),
	})
	if !errors.Is(err, pgx.ErrNoRows) {
		t.Fatalf("expected ErrNoRows on duplicate client_mutation_id, got %v", err)
	}

	fetchedA, err := store.GetTransactionByClientMutationID(ctx, repository.GetTransactionByClientMutationIDParams{
		UserID:           userA.ID,
		ClientMutationID: strPtr(mutID),
	})
	if err != nil || fetchedA.ID != txA.ID {
		t.Fatalf("GetTransactionByClientMutationID(userA) = (%+v, %v), want ID %s", fetchedA, err, txA.ID)
	}

	// Same client_mutation_id string is allowed for a completely different user.
	if _, err := store.InsertTransactionIdempotent(ctx, repository.InsertTransactionIdempotentParams{
		UserID:           userB.ID,
		WalletID:         walletB.ID,
		Type:             "expense",
		Category:         "Transportation",
		Amount:           15000,
		Title:            "Gojek B",
		OccurredAt:       occurred,
		Source:           "manual",
		ClientMutationID: strPtr(mutID),
	}); err != nil {
		t.Fatalf("InsertTransactionIdempotent(userB) with own mutation namespace failed: %v", err)
	}

	// Cross-user read/update/delete guards must return no rows / 0 affected.
	if _, err := store.GetWalletByID(ctx, repository.GetWalletByIDParams{UserID: userB.ID, ID: walletA.ID}); !errors.Is(err, pgx.ErrNoRows) {
		t.Fatalf("expected cross-user GetWalletByID to fail with ErrNoRows, got %v", err)
	}
	if _, err := store.UpdateWalletBalanceDelta(ctx, repository.UpdateWalletBalanceDeltaParams{
		UserID: userB.ID,
		ID:     walletA.ID,
		Delta:  -10000,
	}); !errors.Is(err, pgx.ErrNoRows) {
		t.Fatalf("expected cross-user UpdateWalletBalanceDelta to fail with ErrNoRows, got %v", err)
	}
	if deletedRows, err := store.DeleteWallet(ctx, repository.DeleteWalletParams{
		UserID: userB.ID,
		ID:     walletA.ID,
	}); err != nil || deletedRows != 0 {
		t.Fatalf("expected cross-user DeleteWallet to affect 0 rows, got (%d, %v)", deletedRows, err)
	}
	if _, err := store.GetTransactionByID(ctx, repository.GetTransactionByIDParams{
		UserID: userB.ID,
		ID:     txA.ID,
	}); !errors.Is(err, pgx.ErrNoRows) {
		t.Fatalf("expected cross-user GetTransactionByID to fail with ErrNoRows, got %v", err)
	}

	// Scoped list with keyword filter returns only userA's matching row.
	txsA, err := store.ListTransactionsByUser(ctx, repository.ListTransactionsByUserParams{
		UserID:    userA.ID,
		Keyword:   strPtr("kenangan"),
		LimitRows: 10,
	})
	if err != nil {
		t.Fatalf("ListTransactionsByUser: %v", err)
	}
	if len(txsA) != 1 || txsA[0].ID != txA.ID {
		t.Fatalf("expected 1 filtered tx for userA, got %+v", txsA)
	}
}

func TestStore_CashflowAnalytics_TotalsEdgesMerchantAndCategory(t *testing.T) {
	store, ctx := openTestStore(t)
	userA := createTempTestUser(t, ctx, store, "cf-a")
	userB := createTempTestUser(t, ctx, store, "cf-b")

	bcaA, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID: userA.ID, Name: "BCA", Type: "bank", Balance: 15000000,
	})
	if err != nil {
		t.Fatalf("CreateWallet BCA: %v", err)
	}
	gopayA, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID: userA.ID, Name: "GoPay", Type: "ewallet", Balance: 1000000,
	})
	if err != nil {
		t.Fatalf("CreateWallet GoPay: %v", err)
	}
	walletB, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID: userB.ID, Name: "Mandiri B", Type: "bank", Balance: 99000000,
	})
	if err != nil {
		t.Fatalf("CreateWallet B: %v", err)
	}

	wib := time.FixedZone("WIB", 7*3600)
	octStart := time.Date(2026, 10, 1, 0, 0, 0, 0, wib)
	novStart := time.Date(2026, 11, 1, 0, 0, 0, 0, wib)

	seedTx := []repository.InsertTransactionIdempotentParams{
		{UserID: userA.ID, WalletID: bcaA.ID, Type: "income", Category: "Income • Salary", Amount: 10230000, Title: "Gaji Oktober", OccurredAt: octStart.Add(24 * time.Hour), Source: "manual"},
		{UserID: userA.ID, WalletID: bcaA.ID, Type: "income", Category: "Investment • Bank Interest", Amount: 90000, Title: "Bunga Bank", OccurredAt: octStart.Add(48 * time.Hour), Source: "manual"},
		{UserID: userA.ID, WalletID: bcaA.ID, Type: "expense", Category: "Household Needs • Rent / Sewa", Amount: 2450000, Title: "Bayar Kos", OccurredAt: octStart.Add(72 * time.Hour), Source: "manual"},
		{UserID: userA.ID, WalletID: gopayA.ID, Type: "expense", Category: "Food & Beverage • Coffee Shop", Amount: 28000, Title: "Kopi Kenangan", OccurredAt: octStart.Add(96 * time.Hour), Source: "ai_text"},
		{UserID: userA.ID, WalletID: bcaA.ID, Type: "expense", Category: "Food & Beverage • Coffee Shop", Amount: 25000, Title: "Kopi Kenangan", OccurredAt: octStart.Add(120 * time.Hour), Source: "ai_text"},
		{UserID: userA.ID, WalletID: gopayA.ID, Type: "expense", Category: "Food & Beverage • Coffee Shop", Amount: 28000, Title: "Fore Coffee", Note: strPtr("kopi susu"), OccurredAt: octStart.Add(144 * time.Hour), Source: "manual"},
		{UserID: userA.ID, WalletID: bcaA.ID, DestinationWalletID: &gopayA.ID, Type: "transfer", Category: "Incoming Transfer", Amount: 500000, Title: "Topup GoPay", OccurredAt: octStart.Add(150 * time.Hour), Source: "manual"},
		// Outside October window (must be excluded from October queries).
		{UserID: userA.ID, WalletID: bcaA.ID, Type: "expense", Category: "Food & Beverage", Amount: 999000, Title: "Kopi Kenangan Nov", OccurredAt: novStart.Add(time.Hour), Source: "manual"},
		// User B transactions in October (must never leak into user A queries).
		{UserID: userB.ID, WalletID: walletB.ID, Type: "income", Category: "Income • Salary", Amount: 50000000, Title: "Gaji B", OccurredAt: octStart.Add(24 * time.Hour), Source: "manual"},
		{UserID: userB.ID, WalletID: walletB.ID, Type: "expense", Category: "Food & Beverage • Coffee Shop", Amount: 777000, Title: "Kopi Kenangan", OccurredAt: octStart.Add(48 * time.Hour), Source: "manual"},
	}

	for idx, p := range seedTx {
		if _, err := store.InsertTransactionIdempotent(ctx, p); err != nil {
			t.Fatalf("seed tx[%d]: %v", idx, err)
		}
	}

	totals, err := store.GetCashflowPeriodTotals(ctx, repository.GetCashflowPeriodTotalsParams{
		UserID:  userA.ID,
		StartAt: octStart,
		EndAt:   novStart,
	})
	if err != nil {
		t.Fatalf("GetCashflowPeriodTotals: %v", err)
	}
	if totals.TotalIncome != 10320000 || totals.TotalExpense != 2531000 || totals.TotalTransfer != 500000 || totals.NetCashflow != 7789000 {
		t.Fatalf("unexpected period totals: %+v", totals)
	}
	if totals.IncomeCount != 2 || totals.ExpenseCount != 4 || totals.TransferCount != 1 || totals.TotalCount != 7 {
		t.Fatalf("unexpected period counts: %+v", totals)
	}

	edges, err := store.GetCashflowFlowEdges(ctx, repository.GetCashflowFlowEdgesParams{
		UserID:  userA.ID,
		StartAt: octStart,
		EndAt:   novStart,
	})
	if err != nil {
		t.Fatalf("GetCashflowFlowEdges: %v", err)
	}
	// 2 income sources x 2 expense categories = 4 edges.
	if len(edges) != 4 {
		t.Fatalf("expected 4 flow edges, got %d (%+v)", len(edges), edges)
	}
	var sumFlow int64
	sumByTarget := map[string]int64{}
	for _, e := range edges {
		sumFlow += e.FlowAmount
		sumByTarget[e.TargetCategory] += e.FlowAmount
	}
	if sumFlow != totals.TotalExpense {
		t.Fatalf("expected sum(flow_amount)=%d to match total_expense=%d", sumFlow, totals.TotalExpense)
	}
	if sumByTarget["Household Needs • Rent / Sewa"] != 2450000 || sumByTarget["Food & Beverage • Coffee Shop"] != 81000 {
		t.Fatalf("unexpected per-target flow sums: %+v", sumByTarget)
	}

	// Expense-only fallback in September (zero income in September).
	sepStart := time.Date(2026, 9, 1, 0, 0, 0, 0, wib)
	if _, err := store.InsertTransactionIdempotent(ctx, repository.InsertTransactionIdempotentParams{
		UserID: userA.ID, WalletID: gopayA.ID, Type: "expense", Category: "Transportation", Amount: 42000, Title: "TransJakarta", OccurredAt: sepStart.Add(12 * time.Hour), Source: "manual",
	}); err != nil {
		t.Fatalf("seed sep expense: %v", err)
	}
	sepEdges, err := store.GetCashflowFlowEdges(ctx, repository.GetCashflowFlowEdgesParams{
		UserID:  userA.ID,
		StartAt: sepStart,
		EndAt:   octStart,
	})
	if err != nil {
		t.Fatalf("GetCashflowFlowEdges(sep): %v", err)
	}
	if len(sepEdges) != 1 || sepEdges[0].SourceCategory != "Existing Balance" || sepEdges[0].FlowAmount != 42000 {
		t.Fatalf("unexpected expense-only fallback edges: %+v", sepEdges)
	}

	merchants, err := store.GetCashflowMerchantBreakdown(ctx, repository.GetCashflowMerchantBreakdownParams{
		UserID:        userA.ID,
		StartAt:       octStart,
		EndAt:         novStart,
		KeywordFilter: "kopi",
	})
	if err != nil {
		t.Fatalf("GetCashflowMerchantBreakdown: %v", err)
	}
	if len(merchants) != 2 {
		t.Fatalf("expected 2 coffee merchants for userA, got %d (%+v)", len(merchants), merchants)
	}
	if merchants[0].Merchant != "Kopi Kenangan" || merchants[0].TxCount != 2 || merchants[0].TotalAmount != 53000 {
		t.Fatalf("unexpected top merchant row: %+v", merchants[0])
	}
	if len(merchants[0].WalletNames) != 2 || merchants[0].WalletNames[0] != "BCA" || merchants[0].WalletNames[1] != "GoPay" {
		t.Fatalf("expected wallet_names [BCA GoPay], got %v", merchants[0].WalletNames)
	}

	allMerchants, err := store.GetCashflowMerchantBreakdown(ctx, repository.GetCashflowMerchantBreakdownParams{
		UserID:        userA.ID,
		StartAt:       octStart,
		EndAt:         novStart,
		KeywordFilter: "",
	})
	if err != nil {
		t.Fatalf("GetCashflowMerchantBreakdown(all): %v", err)
	}
	if len(allMerchants) != 3 || allMerchants[0].Merchant != "Bayar Kos" {
		t.Fatalf("expected 3 total merchants led by Bayar Kos, got %+v", allMerchants)
	}

	catBreakdown, err := store.GetCashflowCategoryBreakdown(ctx, repository.GetCashflowCategoryBreakdownParams{
		UserID:  userA.ID,
		StartAt: octStart,
		EndAt:   novStart,
		TxType:  "expense",
	})
	if err != nil {
		t.Fatalf("GetCashflowCategoryBreakdown: %v", err)
	}
	if len(catBreakdown) != 2 || catBreakdown[0].TotalAmount != 2450000 || catBreakdown[1].TotalAmount != 81000 {
		t.Fatalf("unexpected category breakdown: %+v", catBreakdown)
	}
}

func TestStore_BudgetsGoalsBillsAIDraftsAndMatchSubmissions(t *testing.T) {
	store, ctx := openTestStore(t)
	userA := createTempTestUser(t, ctx, store, "plan-a")
	userB := createTempTestUser(t, ctx, store, "plan-b")

	walletA, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID: userA.ID, Name: "BCA Plan", Type: "bank", Balance: 5000000,
	})
	if err != nil {
		t.Fatalf("CreateWallet A: %v", err)
	}

	// UpsertBudget idempotency and subcategory aggregation.
	if _, err := store.UpsertBudget(ctx, repository.UpsertBudgetParams{
		UserID:      userA.ID,
		Category:    "Food & Beverage",
		MonthYear:   "2026-11",
		LimitAmount: 1000000,
	}); err != nil {
		t.Fatalf("first UpsertBudget: %v", err)
	}
	updatedBudget, err := store.UpsertBudget(ctx, repository.UpsertBudgetParams{
		UserID:      userA.ID,
		Category:    "Food & Beverage",
		MonthYear:   "2026-11",
		LimitAmount: 1500000,
	})
	if err != nil {
		t.Fatalf("second UpsertBudget: %v", err)
	}
	if updatedBudget.LimitAmount != 1500000 {
		t.Fatalf("expected updated limit 1500000, got %d", updatedBudget.LimitAmount)
	}
	if _, err := store.UpsertBudget(ctx, repository.UpsertBudgetParams{
		UserID:      userA.ID,
		Category:    "Transportation",
		MonthYear:   "2026-11",
		LimitAmount: 500000,
	}); err != nil {
		t.Fatalf("UpsertBudget Transportation: %v", err)
	}

	novWib := time.Date(2026, 11, 5, 14, 0, 0, 0, time.FixedZone("WIB", 7*3600))
	if _, err := store.InsertTransactionIdempotent(ctx, repository.InsertTransactionIdempotentParams{
		UserID: userA.ID, WalletID: walletA.ID, Type: "expense", Category: "Food & Beverage • Coffee Shop", Amount: 120000, Title: "Kopi", OccurredAt: novWib, Source: "manual",
	}); err != nil {
		t.Fatalf("insert budget tx: %v", err)
	}

	budgets, err := store.ListBudgetsWithSpent(ctx, repository.ListBudgetsWithSpentParams{
		UserID:    userA.ID,
		MonthYear: "2026-11",
	})
	if err != nil {
		t.Fatalf("ListBudgetsWithSpent: %v", err)
	}
	if len(budgets) != 2 {
		t.Fatalf("expected 2 budgets (including 0-spend Transportation), got %d", len(budgets))
	}
	if budgets[0].Category != "Food & Beverage" || budgets[0].SpentAmount != 120000 || budgets[0].RemainingAmount != 1380000 {
		t.Fatalf("unexpected Food & Beverage budget spent row: %+v", budgets[0])
	}
	if budgets[1].Category != "Transportation" || budgets[1].SpentAmount != 0 || budgets[1].RemainingAmount != 500000 {
		t.Fatalf("unexpected Transportation budget spent row: %+v", budgets[1])
	}

	// Goal + contribution scoping.
	targetDate := time.Date(2027, 6, 1, 0, 0, 0, 0, time.UTC)
	goalA, err := store.CreateGoal(ctx, repository.CreateGoalParams{
		UserID:         userA.ID,
		LinkedWalletID: &walletA.ID,
		Title:          "Dana Darurat",
		TargetAmount:   1000000,
		SavedAmount:    200000,
		TargetDate:     timePtr(targetDate),
		Priority:       "urgent",
	})
	if err != nil {
		t.Fatalf("CreateGoal: %v", err)
	}
	if _, err := store.UpsertGoalContribution(ctx, repository.UpsertGoalContributionParams{
		UserID:            userB.ID,
		GoalID:            goalA.ID,
		WalletID:          walletA.ID,
		ContributedAmount: 100000,
	}); !errors.Is(err, pgx.ErrNoRows) {
		t.Fatalf("expected cross-user UpsertGoalContribution to return ErrNoRows, got %v", err)
	}
	contrib, err := store.UpsertGoalContribution(ctx, repository.UpsertGoalContributionParams{
		UserID:            userA.ID,
		GoalID:            goalA.ID,
		WalletID:          walletA.ID,
		ContributedAmount: 800000,
	})
	if err != nil || contrib.ContributedAmount != 800000 {
		t.Fatalf("UpsertGoalContribution = (%+v, %v)", contrib, err)
	}
	completedGoal, err := store.AddGoalSavedAmount(ctx, repository.AddGoalSavedAmountParams{
		UserID: userA.ID,
		ID:     goalA.ID,
		Delta:  800000,
	})
	if err != nil || completedGoal.Status != "completed" {
		t.Fatalf("expected goal auto-completion, got (%+v, %v)", completedGoal, err)
	}

	// Bills.
	billA, err := store.CreateBill(ctx, repository.CreateBillParams{
		UserID:    userA.ID,
		Title:     "Indihome",
		Category:  strPtr("Bills & Utilities"),
		Amount:    385000,
		DueDate:   timePtr(targetDate),
		Frequency: "monthly",
	})
	if err != nil {
		t.Fatalf("CreateBill: %v", err)
	}
	bills, err := store.ListUpcomingBillsByUser(ctx, userA.ID)
	if err != nil || len(bills) != 1 || bills[0].ID != billA.ID {
		t.Fatalf("ListUpcomingBillsByUser = (%+v, %v)", bills, err)
	}
	if _, err := store.MarkBillPaid(ctx, repository.MarkBillPaidParams{
		UserID: userA.ID, ID: billA.ID, IsPaid: true,
	}); err != nil {
		t.Fatalf("MarkBillPaid: %v", err)
	}

	// AI Drafts confirmation idempotency & cross-user guard.
	draftMut := "draft_" + uuid.NewString()
	draftA, err := store.CreateAIDraft(ctx, repository.CreateAIDraftParams{
		UserID:           userA.ID,
		WalletID:         &walletA.ID,
		Source:           "ai_text",
		ClientMutationID: strPtr(draftMut),
		Type:             "expense",
		Category:         "Food & Beverage",
		Amount:           35000,
		Title:            "Bakmi GM",
		MerchantOrNote:   "lunch",
		OccurredAt:       novWib,
		ConfidenceScore:  0.95,
	})
	if err != nil {
		t.Fatalf("CreateAIDraft: %v", err)
	}
	if _, err := store.ConfirmAIDraft(ctx, repository.ConfirmAIDraftParams{
		UserID: userB.ID,
		ID:     draftA.ID,
	}); !errors.Is(err, pgx.ErrNoRows) {
		t.Fatalf("expected cross-user ConfirmAIDraft to fail with ErrNoRows, got %v", err)
	}
	confirmedDraft, err := store.ConfirmAIDraft(ctx, repository.ConfirmAIDraftParams{
		UserID: userA.ID,
		ID:     draftA.ID,
		Amount: int64Ptr(36000),
	})
	if err != nil || confirmedDraft.Status != "confirmed" || confirmedDraft.Amount != 36000 {
		t.Fatalf("ConfirmAIDraft = (%+v, %v)", confirmedDraft, err)
	}
	if _, err := store.ConfirmAIDraft(ctx, repository.ConfirmAIDraftParams{
		UserID: userA.ID,
		ID:     draftA.ID,
	}); !errors.Is(err, pgx.ErrNoRows) {
		t.Fatalf("expected duplicate ConfirmAIDraft to fail with ErrNoRows, got %v", err)
	}

	// Match Expert Submission UUID[] roundtrip & User profile update.
	c1 := uuid.MustParse("00000000-0000-4000-8000-0000000000c1")
	c5 := uuid.MustParse("00000000-0000-4000-8000-0000000000c5")
	rawAnswers, _ := json.Marshal(map[string]string{"main_topic": "couple"})
	if _, err := store.CreateMatchExpertSubmission(ctx, repository.CreateMatchExpertSubmissionParams{
		UserID:             userA.ID,
		AnswersJson:        rawAnswers,
		TopPractitionerIds: []uuid.UUID{c1, c5},
	}); err != nil {
		t.Fatalf("CreateMatchExpertSubmission: %v", err)
	}
	latestSub, err := store.GetLatestMatchExpertSubmission(ctx, userA.ID)
	if err != nil || len(latestSub.TopPractitionerIds) != 2 || latestSub.TopPractitionerIds[0] != c1 {
		t.Fatalf("GetLatestMatchExpertSubmission = (%+v, %v)", latestSub, err)
	}

	if _, err := store.UpdateUserProfile(ctx, repository.UpdateUserProfileParams{
		UserID:              userA.ID,
		OnboardingCompleted: boolPtr(true),
		MonthlyBudgetLimit:  int64Ptr(7500000),
	}); err != nil {
		t.Fatalf("UpdateUserProfile: %v", err)
	}
	profile, err := store.GetUserProfileByID(ctx, userA.ID)
	if err != nil || !profile.OnboardingCompleted || profile.MonthlyBudgetLimit != 7500000 {
		t.Fatalf("GetUserProfileByID = (%+v, %v)", profile, err)
	}
}

func TestStore_PractitionersMatchingAndCanonicalCatalogs(t *testing.T) {
	store, ctx := openTestStore(t)

	categories, err := store.ListCategories(ctx)
	if err != nil {
		t.Fatalf("ListCategories: %v", err)
	}
	if len(categories) != 105 {
		t.Fatalf("expected 105 canonical categories, got %d", len(categories))
	}

	catalogPkgs, err := store.ListCatalogPackages(ctx)
	if err != nil {
		t.Fatalf("ListCatalogPackages: %v", err)
	}
	if len(catalogPkgs) != 15 {
		t.Fatalf("expected 15 canonical catalog packages, got %d", len(catalogPkgs))
	}

	pracRows, err := store.ListVerifiedPractitionersWithPackages(ctx)
	if err != nil {
		t.Fatalf("ListVerifiedPractitionersWithPackages: %v", err)
	}
	if len(pracRows) < 26 {
		t.Fatalf("expected >= 26 practitioner package rows, got %d", len(pracRows))
	}

	uniquePracs := map[uuid.UUID]struct{}{}
	pracIDs := make([]uuid.UUID, 0, 6)
	for _, r := range pracRows {
		if r.Status != "verified" {
			t.Fatalf("expected only verified practitioners, got %q", r.Status)
		}
		if _, ok := uniquePracs[r.PractitionerID]; !ok {
			uniquePracs[r.PractitionerID] = struct{}{}
			pracIDs = append(pracIDs, r.PractitionerID)
		}
	}
	if len(uniquePracs) != 6 {
		t.Fatalf("expected 6 canonical verified practitioners, got %d", len(uniquePracs))
	}

	availRows, err := store.ListActiveAvailabilityByPractitioners(ctx, pracIDs)
	if err != nil {
		t.Fatalf("ListActiveAvailabilityByPractitioners: %v", err)
	}
	if len(availRows) == 0 {
		t.Fatal("expected active availability rows for canonical practitioners")
	}
	for _, a := range availRows {
		if !a.StartTimeWib.Valid || !a.EndTimeWib.Valid || a.EndTimeWib.Microseconds <= a.StartTimeWib.Microseconds {
			t.Fatalf("invalid availability window: %+v", a)
		}
	}

	// Verify active holds query filters out released/expired holds while returning active held/booked holds.
	c1 := uuid.MustParse("00000000-0000-4000-8000-0000000000c1")
	holdStart := time.Now().Add(48 * time.Hour).UTC().Truncate(time.Hour)
	holdEnd := holdStart.Add(time.Hour)
	releasedStart := holdStart.Add(2 * time.Hour)
	releasedEnd := releasedStart.Add(time.Hour)

	var activeHoldID, releasedHoldID uuid.UUID
	if err := store.Pool.QueryRow(ctx, `
		INSERT INTO booking_slot_holds (practitioner_id, slot_start_at, slot_end_at, status, expires_at)
		VALUES ($1, $2, $3, 'held', NOW() + INTERVAL '15 minutes')
		RETURNING id
	`, c1, holdStart, holdEnd).Scan(&activeHoldID); err != nil {
		t.Fatalf("insert active hold: %v", err)
	}
	if err := store.Pool.QueryRow(ctx, `
		INSERT INTO booking_slot_holds (practitioner_id, slot_start_at, slot_end_at, status, expires_at)
		VALUES ($1, $2, $3, 'released', NOW() + INTERVAL '15 minutes')
		RETURNING id
	`, c1, releasedStart, releasedEnd).Scan(&releasedHoldID); err != nil {
		t.Fatalf("insert released hold: %v", err)
	}
	t.Cleanup(func() {
		cleanupCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_, _ = store.Pool.Exec(cleanupCtx, `DELETE FROM booking_slot_holds WHERE id IN ($1, $2)`, activeHoldID, releasedHoldID)
	})

	holds, err := store.ListActiveSlotHoldsInRange(ctx, repository.ListActiveSlotHoldsInRangeParams{
		PractitionerIds: []uuid.UUID{c1},
		RangeStart:      holdStart.Add(-1 * time.Hour),
		RangeEnd:        releasedEnd.Add(1 * time.Hour),
	})
	if err != nil {
		t.Fatalf("ListActiveSlotHoldsInRange: %v", err)
	}
	foundActive := false
	for _, h := range holds {
		if h.ID == releasedHoldID {
			t.Fatalf("released hold %s should not be returned", releasedHoldID)
		}
		if h.ID == activeHoldID {
			foundActive = true
		}
	}
	if !foundActive {
		t.Fatalf("expected active hold %s in range results", activeHoldID)
	}

	pins, err := store.ListStaffPinsByTagSlug(ctx, "pinjol")
	if err != nil {
		t.Fatalf("ListStaffPinsByTagSlug: %v", err)
	}
	if len(pins) == 0 || len(pins) > 3 {
		t.Fatalf("expected 1..3 staff pins for tag 'pinjol', got %d", len(pins))
	}

	multiPins, err := store.ListStaffPinsByTagSlugs(ctx, []string{"cashflow", "pinjol"})
	if err != nil {
		t.Fatalf("ListStaffPinsByTagSlugs: %v", err)
	}
	if len(multiPins) < 4 {
		t.Fatalf("expected >= 4 pins across cashflow & pinjol, got %d", len(multiPins))
	}

	tags, err := store.ListProblemTags(ctx)
	if err != nil || len(tags) < 15 {
		t.Fatalf("ListProblemTags = (%d, %v)", len(tags), err)
	}
	venues, err := store.ListActiveVenues(ctx)
	if err != nil || len(venues) < 6 {
		t.Fatalf("ListActiveVenues = (%d, %v)", len(venues), err)
	}
	vouchers, err := store.ListActiveVouchers(ctx)
	if err != nil || len(vouchers) < 6 {
		t.Fatalf("ListActiveVouchers = (%d, %v)", len(vouchers), err)
	}

	// Silence unused pgtype import warning check if compiler changes; pgtype.Time is asserted via availRows above.
	_ = pgtype.Time{}
}
