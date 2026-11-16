package ai_test

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/url"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/clarafin/api/internal/ai"
	"github.com/clarafin/api/internal/repository"
)

func openAITestStore(t *testing.T) (*repository.Store, context.Context) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	t.Cleanup(cancel)

	pool, err := pgxpool.New(ctx, buildAITestPostgresDSN())
	if err != nil {
		t.Fatalf("connect pgxpool: %v", err)
	}
	t.Cleanup(pool.Close)

	if err := pool.Ping(ctx); err != nil {
		t.Fatalf("ping postgres: %v", err)
	}

	return repository.NewStore(pool), ctx
}

func buildAITestPostgresDSN() string {
	for _, key := range []string{"TEST_DATABASE_URL", "DOCKER_DATABASE_URL"} {
		if raw := strings.TrimSpace(os.Getenv(key)); raw != "" {
			return raw
		}
	}

	user := aiEnvOrDefault("POSTGRES_USER", "clarafin")
	pass := aiEnvOrDefault("POSTGRES_PASSWORD", "clarafin_dev_password")
	db := aiEnvOrDefault("POSTGRES_DB", "clarafin")
	host := aiEnvOrDefault("POSTGRES_HOST", "postgres")
	port := aiEnvOrDefault("POSTGRES_PORT", "5432")

	u := url.URL{
		Scheme:   "postgres",
		User:     url.UserPassword(user, pass),
		Host:     net.JoinHostPort(host, port),
		Path:     "/" + db,
		RawQuery: "sslmode=disable",
	}
	return u.String()
}

func aiEnvOrDefault(key, fallback string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return fallback
}

func createTempAIUser(t *testing.T, ctx context.Context, store *repository.Store, label string) repository.User {
	t.Helper()

	userID := uuid.New()
	email := fmt.Sprintf("ai-tool-%s-%s@clarafin.test", label, userID.String()[:8])

	user, err := store.EnsureDevUserAccount(ctx, repository.EnsureDevUserParams{
		ID:       userID,
		Email:    email,
		FullName: "AI Tool " + label,
	})
	if err != nil {
		t.Fatalf("EnsureDevUserAccount(%s): %v", label, err)
	}

	t.Cleanup(func() {
		cleanupCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
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

func aiStrPtr(s string) *string { return &s }

func TestFinancialTools_UserIsolationAndWallets(t *testing.T) {
	store, ctx := openAITestStore(t)
	userA := createTempAIUser(t, ctx, store, "iso-a")
	userB := createTempAIUser(t, ctx, store, "iso-b")

	wA1, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID: userA.ID, Name: "BCA", Type: "bank", Balance: 8500000,
	})
	if err != nil {
		t.Fatalf("CreateWallet A1: %v", err)
	}
	if _, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID: userA.ID, Name: "GoPay", Type: "ewallet", Balance: 1500000,
	}); err != nil {
		t.Fatalf("CreateWallet A2: %v", err)
	}
	wAArchived, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID: userA.ID, Name: "Old Bank", Type: "bank", Balance: 999999,
	})
	if err != nil {
		t.Fatalf("CreateWallet A archived: %v", err)
	}
	if _, err := store.ArchiveWallet(ctx, repository.ArchiveWalletParams{
		UserID: userA.ID, ID: wAArchived.ID,
	}); err != nil {
		t.Fatalf("ArchiveWallet A: %v", err)
	}

	wB, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID: userB.ID, Name: "Mandiri B", Type: "bank", Balance: 75000000,
	})
	if err != nil {
		t.Fatalf("CreateWallet B: %v", err)
	}

	wib := time.FixedZone("WIB", 7*3600)
	fixedNow := time.Date(2026, 11, 16, 14, 0, 0, 0, wib)
	if _, err := store.InsertTransactionIdempotent(ctx, repository.InsertTransactionIdempotentParams{
		UserID: userA.ID, WalletID: wA1.ID, Type: "expense", Category: "Food & Beverage", Amount: 50000, Title: "Lunch A", OccurredAt: fixedNow.Add(-time.Hour), Source: "manual",
	}); err != nil {
		t.Fatalf("seed tx A: %v", err)
	}
	if _, err := store.InsertTransactionIdempotent(ctx, repository.InsertTransactionIdempotentParams{
		UserID: userB.ID, WalletID: wB.ID, Type: "income", Category: "Income • Salary", Amount: 40000000, Title: "Gaji B", OccurredAt: fixedNow.Add(-time.Hour), Source: "manual",
	}); err != nil {
		t.Fatalf("seed tx B: %v", err)
	}

	tools := ai.NewFinancialTools(
		store,
		ai.WithFinancialNowFunc(func() time.Time { return fixedNow }),
		ai.WithFinancialJakartaLocation(wib),
	)

	walletsOut, err := tools.GetUserWallets(ctx, userA.ID)
	if err != nil {
		t.Fatalf("GetUserWallets(userA): %v", err)
	}
	if walletsOut.WalletCount != 2 || len(walletsOut.Wallets) != 2 {
		t.Fatalf("expected 2 active wallets for userA, got %+v", walletsOut)
	}
	if walletsOut.TotalBalanceIDR != 10000000 {
		t.Fatalf("expected TotalBalanceIDR 10000000, got %d", walletsOut.TotalBalanceIDR)
	}
	for _, w := range walletsOut.Wallets {
		if w.Name == "Mandiri B" || w.Name == "Old Bank" {
			t.Fatalf("unexpected leaked or archived wallet %q in userA results", w.Name)
		}
	}

	cfOut, err := tools.GetCashflowSummary(ctx, userA.ID, ai.CashflowQueryInput{
		Period:  "this_month",
		GroupBy: "category",
	})
	if err != nil {
		t.Fatalf("GetCashflowSummary(userA): %v", err)
	}
	if cfOut.TotalIncomeIDR != 0 || cfOut.TotalExpenseIDR != 50000 || cfOut.NetCashflowIDR != -50000 || cfOut.TransactionCount != 1 {
		t.Fatalf("userA cashflow leaked or mismatched: %+v", cfOut)
	}
}

func TestFinancialTools_GetCashflowSummary_SankeyIncomeToExpenseFlow(t *testing.T) {
	store, ctx := openAITestStore(t)
	userA := createTempAIUser(t, ctx, store, "sankey-a")
	userB := createTempAIUser(t, ctx, store, "sankey-b")

	bca, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID: userA.ID, Name: "BCA", Type: "bank", Balance: 15000000,
	})
	if err != nil {
		t.Fatalf("CreateWallet BCA: %v", err)
	}
	gopay, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID: userA.ID, Name: "GoPay", Type: "ewallet", Balance: 2000000,
	})
	if err != nil {
		t.Fatalf("CreateWallet GoPay: %v", err)
	}
	walletB, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID: userB.ID, Name: "BNI B", Type: "bank", Balance: 50000000,
	})
	if err != nil {
		t.Fatalf("CreateWallet B: %v", err)
	}

	wib := time.FixedZone("WIB", 7*3600)
	fixedNow := time.Date(2026, 11, 16, 10, 0, 0, 0, wib)
	oct1 := time.Date(2026, 10, 1, 0, 15, 0, 0, wib)
	oct31Late := time.Date(2026, 10, 31, 23, 30, 0, 0, wib)
	nov1Early := time.Date(2026, 11, 1, 0, 10, 0, 0, wib)

	seed := []repository.InsertTransactionIdempotentParams{
		{UserID: userA.ID, WalletID: bca.ID, Type: "income", Category: "Income • Salary", Amount: 10230000, Title: "Gaji Oktober", OccurredAt: oct1, Source: "manual"},
		{UserID: userA.ID, WalletID: bca.ID, Type: "income", Category: "Investment • Bank Interest", Amount: 90000, Title: "Bunga Bank", OccurredAt: oct1.Add(48 * time.Hour), Source: "manual"},
		{UserID: userA.ID, WalletID: bca.ID, Type: "expense", Category: "Household Needs • Rent / Sewa", Amount: 2450000, Title: "Kos Oktober", OccurredAt: oct1.Add(72 * time.Hour), Source: "manual"},
		{UserID: userA.ID, WalletID: gopay.ID, Type: "expense", Category: "Food & Beverage • Coffee Shop", Amount: 550000, Title: "Ngopi Oktober", OccurredAt: oct31Late, Source: "ai_text"},
		// November transaction must NOT appear in last_month (October WIB).
		{UserID: userA.ID, WalletID: gopay.ID, Type: "expense", Category: "Food & Beverage • Coffee Shop", Amount: 999000, Title: "Ngopi November", OccurredAt: nov1Early, Source: "manual"},
		// User B October transaction must NEVER leak.
		{UserID: userB.ID, WalletID: walletB.ID, Type: "income", Category: "Income • Salary", Amount: 90000000, Title: "Gaji B", OccurredAt: oct1, Source: "manual"},
	}
	for i, p := range seed {
		if _, err := store.InsertTransactionIdempotent(ctx, p); err != nil {
			t.Fatalf("seed[%d]: %v", i, err)
		}
	}

	tools := ai.NewFinancialTools(
		store,
		ai.WithFinancialNowFunc(func() time.Time { return fixedNow }),
		ai.WithFinancialJakartaLocation(wib),
	)

	out, err := tools.GetCashflowSummary(ctx, userA.ID, ai.CashflowQueryInput{
		Period:  "last_month",
		GroupBy: "income_to_expense_flow",
	})
	if err != nil {
		t.Fatalf("GetCashflowSummary(income_to_expense_flow): %v", err)
	}

	if out.TotalIncomeIDR != 10320000 {
		t.Fatalf("TotalIncomeIDR = %d, want 10320000", out.TotalIncomeIDR)
	}
	if out.TotalExpenseIDR != 3000000 {
		t.Fatalf("TotalExpenseIDR = %d, want 3000000", out.TotalExpenseIDR)
	}
	if out.NetCashflowIDR != 7320000 {
		t.Fatalf("NetCashflowIDR = %d, want 7320000", out.NetCashflowIDR)
	}
	if out.TransactionCount != 4 {
		t.Fatalf("TransactionCount = %d, want 4", out.TransactionCount)
	}
	if len(out.IncomeSources) != 2 {
		t.Fatalf("expected 2 IncomeSources, got %+v", out.IncomeSources)
	}
	if len(out.ExpenseCategories) != 2 {
		t.Fatalf("expected 2 ExpenseCategories, got %+v", out.ExpenseCategories)
	}
	if out.ExpenseCategories[0].Category != "Household Needs • Rent / Sewa" || out.ExpenseCategories[0].Amount != 2450000 || out.ExpenseCategories[0].SharePct != 81.7 {
		t.Fatalf("unexpected top ExpenseCategory: %+v", out.ExpenseCategories[0])
	}
	if out.ExpenseCategories[1].Category != "Food & Beverage • Coffee Shop" || out.ExpenseCategories[1].Amount != 550000 || out.ExpenseCategories[1].SharePct != 18.3 {
		t.Fatalf("unexpected second ExpenseCategory: %+v", out.ExpenseCategories[1])
	}
	if len(out.FlowEdges) != 4 {
		t.Fatalf("expected 4 FlowEdges, got %d (%+v)", len(out.FlowEdges), out.FlowEdges)
	}
	var edgeSum int64
	for _, e := range out.FlowEdges {
		edgeSum += e.FlowAmount
	}
	if edgeSum != out.TotalExpenseIDR {
		t.Fatalf("sum(FlowEdges.FlowAmount)=%d != TotalExpenseIDR=%d", edgeSum, out.TotalExpenseIDR)
	}

	// Explicit YYYY-MM period must match last_month (2026-10) identically.
	explicitOut, err := tools.GetCashflowSummary(ctx, userA.ID, ai.CashflowQueryInput{
		Period:  "2026-10",
		GroupBy: "income_to_expense_flow",
	})
	if err != nil {
		t.Fatalf("GetCashflowSummary(2026-10): %v", err)
	}
	if explicitOut.TotalExpenseIDR != out.TotalExpenseIDR || explicitOut.TotalIncomeIDR != out.TotalIncomeIDR {
		t.Fatalf("2026-10 mismatch vs last_month: %+v", explicitOut)
	}
}

func TestFinancialTools_GetCashflowSummary_MerchantKeywordKopiAndWalletBreakdown(t *testing.T) {
	store, ctx := openAITestStore(t)
	userA := createTempAIUser(t, ctx, store, "kopi-a")
	userB := createTempAIUser(t, ctx, store, "kopi-b")

	bca, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID: userA.ID, Name: "BCA", Type: "bank", Balance: 5000000,
	})
	if err != nil {
		t.Fatalf("CreateWallet BCA: %v", err)
	}
	gopay, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID: userA.ID, Name: "GoPay", Type: "ewallet", Balance: 500000,
	})
	if err != nil {
		t.Fatalf("CreateWallet GoPay: %v", err)
	}
	walletB, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID: userB.ID, Name: "OVO B", Type: "ewallet", Balance: 5000000,
	})
	if err != nil {
		t.Fatalf("CreateWallet B: %v", err)
	}

	wib := time.FixedZone("WIB", 7*3600)
	fixedNow := time.Date(2026, 11, 16, 12, 0, 0, 0, wib)
	oct10 := time.Date(2026, 10, 10, 9, 0, 0, 0, wib)

	seed := []repository.InsertTransactionIdempotentParams{
		{UserID: userA.ID, WalletID: gopay.ID, Type: "expense", Category: "Food & Beverage • Coffee Shop", Amount: 25000, Title: "Kopi Kenangan", OccurredAt: oct10, Source: "ai_text"},
		{UserID: userA.ID, WalletID: bca.ID, Type: "expense", Category: "Food & Beverage • Coffee Shop", Amount: 30000, Title: "Kopi Kenangan", OccurredAt: oct10.Add(24 * time.Hour), Source: "manual"},
		{UserID: userA.ID, WalletID: gopay.ID, Type: "expense", Category: "Food & Beverage • Coffee Shop", Amount: 28000, Title: "Fore Coffee", Note: aiStrPtr("Es Kopi Aren"), OccurredAt: oct10.Add(48 * time.Hour), Source: "manual"},
		{UserID: userA.ID, WalletID: bca.ID, Type: "expense", Category: "Transportation • Ride Hailing / Taxi", Amount: 45000, Title: "Gojek", OccurredAt: oct10.Add(72 * time.Hour), Source: "manual"},
		// User B coffee expense must not leak into userA's kopi report.
		{UserID: userB.ID, WalletID: walletB.ID, Type: "expense", Category: "Food & Beverage • Coffee Shop", Amount: 199000, Title: "Kopi Kenangan", OccurredAt: oct10, Source: "manual"},
	}
	for i, p := range seed {
		if _, err := store.InsertTransactionIdempotent(ctx, p); err != nil {
			t.Fatalf("seed[%d]: %v", i, err)
		}
	}

	tools := ai.NewFinancialTools(
		store,
		ai.WithFinancialNowFunc(func() time.Time { return fixedNow }),
		ai.WithFinancialJakartaLocation(wib),
	)

	out, err := tools.GetCashflowSummary(ctx, userA.ID, ai.CashflowQueryInput{
		Period:        "last_month",
		GroupBy:       "merchant",
		KeywordFilter: "kopi",
	})
	if err != nil {
		t.Fatalf("GetCashflowSummary(merchant, kopi): %v", err)
	}

	if out.TotalExpenseIDR != 83000 || out.TransactionCount != 3 {
		t.Fatalf("expected kopi total 83000 from 3 tx, got TotalExpenseIDR=%d TransactionCount=%d", out.TotalExpenseIDR, out.TransactionCount)
	}
	if len(out.MerchantRows) != 2 {
		t.Fatalf("expected 2 merchant rows, got %d (%+v)", len(out.MerchantRows), out.MerchantRows)
	}
	if out.MerchantRows[0].Merchant != "Kopi Kenangan" || out.MerchantRows[0].TxCount != 2 || out.MerchantRows[0].TotalAmount != 55000 {
		t.Fatalf("expected top merchant Kopi Kenangan (2 tx, 55000), got %+v", out.MerchantRows[0])
	}
	if out.MerchantRows[1].Merchant != "Fore Coffee" || out.MerchantRows[1].TxCount != 1 || out.MerchantRows[1].TotalAmount != 28000 {
		t.Fatalf("expected second merchant Fore Coffee (1 tx, 28000), got %+v", out.MerchantRows[1])
	}
	if len(out.SourceWallets) != 2 || out.SourceWallets[0] != "BCA" || out.SourceWallets[1] != "GoPay" {
		t.Fatalf("expected SourceWallets [BCA GoPay], got %v", out.SourceWallets)
	}
	if len(out.CategoriesUsed) != 1 || out.CategoriesUsed[0] != "Food & Beverage • Coffee Shop" {
		t.Fatalf("expected CategoriesUsed [Food & Beverage • Coffee Shop], got %v", out.CategoriesUsed)
	}

	walletOut, err := tools.GetCashflowSummary(ctx, userA.ID, ai.CashflowQueryInput{
		Period:  "last_90_days",
		GroupBy: "wallet",
	})
	if err != nil {
		t.Fatalf("GetCashflowSummary(wallet): %v", err)
	}
	if len(walletOut.WalletRows) != 2 {
		t.Fatalf("expected 2 wallet rows, got %+v", walletOut.WalletRows)
	}

	if _, err := tools.GetCashflowSummary(ctx, userA.ID, ai.CashflowQueryInput{
		Period:  "next_year",
		GroupBy: "category",
	}); !errors.Is(err, ai.ErrInvalidFinancialToolInput) {
		t.Fatalf("expected ErrInvalidFinancialToolInput for bad period, got %v", err)
	}
}

func TestFinancialTools_GetBudgetAndBillsStatus(t *testing.T) {
	store, ctx := openAITestStore(t)
	userA := createTempAIUser(t, ctx, store, "bb-a")
	userB := createTempAIUser(t, ctx, store, "bb-b")

	wib := time.FixedZone("WIB", 7*3600)
	fixedNow := time.Date(2026, 11, 16, 9, 0, 0, 0, wib)

	walletA, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID: userA.ID, Name: "BCA", Type: "bank", Balance: 5000000,
	})
	if err != nil {
		t.Fatalf("CreateWallet A: %v", err)
	}
	if _, err := store.UpsertBudget(ctx, repository.UpsertBudgetParams{
		UserID: userA.ID, Category: "Food & Beverage", MonthYear: "2026-11", LimitAmount: 1000000,
	}); err != nil {
		t.Fatalf("UpsertBudget A: %v", err)
	}
	if _, err := store.UpsertBudget(ctx, repository.UpsertBudgetParams{
		UserID: userB.ID, Category: "Food & Beverage", MonthYear: "2026-11", LimitAmount: 9000000,
	}); err != nil {
		t.Fatalf("UpsertBudget B: %v", err)
	}
	if _, err := store.InsertTransactionIdempotent(ctx, repository.InsertTransactionIdempotentParams{
		UserID: userA.ID, WalletID: walletA.ID, Type: "expense", Category: "Food & Beverage • Coffee Shop", Amount: 850000, Title: "Coffee Pack", OccurredAt: fixedNow.Add(-24 * time.Hour), Source: "manual",
	}); err != nil {
		t.Fatalf("seed budget tx A: %v", err)
	}

	dueSoon := time.Date(2026, 11, 18, 0, 0, 0, 0, time.UTC)
	if _, err := store.CreateBill(ctx, repository.CreateBillParams{
		UserID: userA.ID, Title: "Listrik PLN", Category: aiStrPtr("Bills & Utilities"), Amount: 350000, DueDate: &dueSoon, Frequency: "monthly",
	}); err != nil {
		t.Fatalf("CreateBill A: %v", err)
	}
	if _, err := store.CreateGoal(ctx, repository.CreateGoalParams{
		UserID: userA.ID, LinkedWalletID: &walletA.ID, Title: "Dana Darurat", TargetAmount: 10000000, SavedAmount: 2500000, Priority: "urgent",
	}); err != nil {
		t.Fatalf("CreateGoal A: %v", err)
	}

	tools := ai.NewFinancialTools(
		store,
		ai.WithFinancialNowFunc(func() time.Time { return fixedNow }),
		ai.WithFinancialJakartaLocation(wib),
	)

	status, err := tools.GetBudgetAndBillsStatus(ctx, userA.ID)
	if err != nil {
		t.Fatalf("GetBudgetAndBillsStatus: %v", err)
	}
	if status.MonthYear != "2026-11" || len(status.Budgets) != 1 || len(status.Goals) != 1 || len(status.UpcomingBills) != 1 {
		t.Fatalf("unexpected BudgetBillsOutput: %+v", status)
	}
	if status.Budgets[0].SpentAmountIDR != 850000 || status.Budgets[0].RemainingAmountIDR != 150000 || !status.Budgets[0].IsNearLimit {
		t.Fatalf("unexpected budget calculation: %+v", status.Budgets[0])
	}
	if status.UpcomingBills[0].DaysUntilDue == nil || *status.UpcomingBills[0].DaysUntilDue != 2 || status.UpcomingBills[0].IsOverdue {
		t.Fatalf("unexpected bill due calculation: %+v", status.UpcomingBills[0])
	}
}
