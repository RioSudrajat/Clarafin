package ai_test

import (
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/clarafin/api/internal/ai"
	"github.com/clarafin/api/internal/repository"
)

func TestActionTools_CheckAndPrepareTransaction_MissingWalletDoesNotSubstitute(t *testing.T) {
	store, ctx := openAITestStore(t)
	user := createTempAIUser(t, ctx, store, "missing-wallet")

	if _, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID: user.ID, Name: "BCA", Type: "bank", InstitutionCode: aiStrPtr("bca"), Balance: 8000000,
	}); err != nil {
		t.Fatalf("CreateWallet BCA: %v", err)
	}
	if _, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID: user.ID, Name: "GoPay", Type: "ewallet", InstitutionCode: aiStrPtr("gopay"), Balance: 1500000,
	}); err != nil {
		t.Fatalf("CreateWallet GoPay: %v", err)
	}

	wib := time.FixedZone("WIB", 7*3600)
	fixedNow := time.Date(2026, 11, 16, 10, 30, 0, 0, wib)
	actions := ai.NewActionTools(
		store,
		ai.WithActionNowFunc(func() time.Time { return fixedNow }),
		ai.WithActionJakartaLocation(wib),
	)

	res, err := actions.CheckAndPrepareTransaction(ctx, user.ID, ai.PrepareTransactionInput{
		Items: []ai.PrepareTransactionItemInput{
			{
				Title:       "Kopi Kenangan",
				AmountIDR:   28000,
				Type:        "expense",
				RawCategory: "kopi kenangan",
				WalletHint:  "bank jago",
			},
		},
	})
	if err != nil {
		t.Fatalf("CheckAndPrepareTransaction: %v", err)
	}
	if res.Status != "missing_wallet" {
		t.Fatalf("Status = %q, want missing_wallet", res.Status)
	}
	if res.TransactionDraft != nil {
		t.Fatalf("TransactionDraft must be withheld (nil) when wallet is missing, got %+v", res.TransactionDraft)
	}
	if res.WalletCreationDraft == nil {
		t.Fatalf("expected WalletCreationDraft to be populated")
	}
	if res.WalletCreationDraft.InstitutionID != "jago" {
		t.Fatalf("InstitutionID = %q, want jago", res.WalletCreationDraft.InstitutionID)
	}
	if res.WalletCreationDraft.InstitutionName != "Bank Jago" {
		t.Fatalf("InstitutionName = %q, want Bank Jago", res.WalletCreationDraft.InstitutionName)
	}
	if res.WalletCreationDraft.InstitutionType != "bank" {
		t.Fatalf("InstitutionType = %q, want bank", res.WalletCreationDraft.InstitutionType)
	}
	if len(res.WalletCreationDraft.ExistingWallets) != 2 ||
		res.WalletCreationDraft.ExistingWallets[0].Name != "BCA" ||
		res.WalletCreationDraft.ExistingWallets[1].Name != "GoPay" {
		t.Fatalf("ExistingWallets = %+v, want [BCA, GoPay]", res.WalletCreationDraft.ExistingWallets)
	}
	if len(res.PendingItems) != 1 || res.PendingItems[0].CanonicalCategory != "Food & Beverage • Coffee Shop" {
		t.Fatalf("PendingItems = %+v, want normalized Food & Beverage • Coffee Shop", res.PendingItems)
	}

	// Verify Jenius and Cash missing wallet detection also avoids substitution.
	jeniusRes, err := actions.CheckAndPrepareTransaction(ctx, user.ID, ai.PrepareTransactionInput{
		Items: []ai.PrepareTransactionItemInput{
			{Title: "Langganan Spotify", AmountIDR: 54990, Type: "expense", RawCategory: "spotify", WalletHint: "jenius"},
		},
	})
	if err != nil {
		t.Fatalf("CheckAndPrepareTransaction(jenius): %v", err)
	}
	if jeniusRes.Status != "missing_wallet" || jeniusRes.TransactionDraft != nil ||
		jeniusRes.WalletCreationDraft == nil || jeniusRes.WalletCreationDraft.InstitutionID != "jenius" ||
		jeniusRes.WalletCreationDraft.InstitutionName != "Jenius" || jeniusRes.WalletCreationDraft.InstitutionType != "bank" {
		t.Fatalf("unexpected Jenius missing_wallet result: %+v", jeniusRes)
	}

	// Multi-item split where one item uses existing GoPay and second uses missing Cash must still withhold TransactionDraft.
	partialMissing, err := actions.CheckAndPrepareTransaction(ctx, user.ID, ai.PrepareTransactionInput{
		Items: []ai.PrepareTransactionItemInput{
			{Title: "Kopi", AmountIDR: 28000, Type: "expense", RawCategory: "kopi", WalletHint: "gopay"},
			{Title: "Parkir", AmountIDR: 5000, Type: "expense", RawCategory: "parkir", WalletHint: "tunai"},
		},
	})
	if err != nil {
		t.Fatalf("CheckAndPrepareTransaction(partial missing): %v", err)
	}
	if partialMissing.Status != "missing_wallet" || partialMissing.TransactionDraft != nil {
		t.Fatalf("partial missing must withhold TransactionDraft, got %+v", partialMissing)
	}
	if partialMissing.WalletCreationDraft == nil || partialMissing.WalletCreationDraft.InstitutionID != "cash" ||
		partialMissing.WalletCreationDraft.InstitutionType != "cash" {
		t.Fatalf("expected missing cash institution draft, got %+v", partialMissing.WalletCreationDraft)
	}

	// Zero active wallets with empty hint still returns missing_wallet instead of crashing.
	emptyUser := createTempAIUser(t, ctx, store, "zero-wallets")
	zeroRes, err := actions.CheckAndPrepareTransaction(ctx, emptyUser.ID, ai.PrepareTransactionInput{
		Items: []ai.PrepareTransactionItemInput{
			{Title: "Sarapan", AmountIDR: 15000, Type: "expense", RawCategory: "Makanan"},
		},
	})
	if err != nil {
		t.Fatalf("CheckAndPrepareTransaction(zero wallets): %v", err)
	}
	if zeroRes.Status != "missing_wallet" || zeroRes.TransactionDraft != nil ||
		zeroRes.WalletCreationDraft == nil || len(zeroRes.WalletCreationDraft.ExistingWallets) != 0 ||
		zeroRes.WalletCreationDraft.InstitutionID != "cash" {
		t.Fatalf("unexpected zero-wallets result: %+v", zeroRes)
	}

	// Wallet tagged with another institution_code (e.g. "blu" named "blu by BCA Digital")
	// must NOT match when requesting "BCA"; it must trigger missing_wallet for BCA.
	bluUser := createTempAIUser(t, ctx, store, "blu-vs-bca")
	if _, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID: bluUser.ID, Name: "blu by BCA Digital", Type: "bank", InstitutionCode: aiStrPtr("blu"), Balance: 3500000,
	}); err != nil {
		t.Fatalf("CreateWallet blu: %v", err)
	}
	bluVsBCARes, err := actions.CheckAndPrepareTransaction(ctx, bluUser.ID, ai.PrepareTransactionInput{
		Items: []ai.PrepareTransactionItemInput{
			{Title: "Makan Siang", AmountIDR: 45000, Type: "expense", RawCategory: "Makanan", WalletHint: "BCA"},
		},
	})
	if err != nil {
		t.Fatalf("CheckAndPrepareTransaction(blu vs BCA): %v", err)
	}
	if bluVsBCARes.Status != "missing_wallet" || bluVsBCARes.TransactionDraft != nil ||
		bluVsBCARes.WalletCreationDraft == nil || bluVsBCARes.WalletCreationDraft.InstitutionID != "bca" {
		t.Fatalf("requesting BCA when only blu by BCA Digital exists must return missing_wallet for bca, got %+v", bluVsBCARes)
	}
	if len(bluVsBCARes.WalletCreationDraft.ExistingWallets) != 1 || bluVsBCARes.WalletCreationDraft.ExistingWallets[0].Name != "blu by BCA Digital" {
		t.Fatalf("expected existing blu chip, got %+v", bluVsBCARes.WalletCreationDraft.ExistingWallets)
	}
	bluMatchRes, err := actions.CheckAndPrepareTransaction(ctx, bluUser.ID, ai.PrepareTransactionInput{
		Items: []ai.PrepareTransactionItemInput{
			{Title: "Makan Siang", AmountIDR: 45000, Type: "expense", RawCategory: "Makanan", WalletHint: "blu"},
		},
	})
	if err != nil {
		t.Fatalf("CheckAndPrepareTransaction(blu direct): %v", err)
	}
	if bluMatchRes.Status != "ready" || bluMatchRes.TransactionDraft == nil || len(bluMatchRes.TransactionDraft.Items) != 1 ||
		bluMatchRes.TransactionDraft.Items[0].WalletName != "blu by BCA Digital" {
		t.Fatalf("expected ready draft on blu wallet, got %+v", bluMatchRes)
	}
}

func TestActionTools_CheckAndPrepareTransaction_MultiItemAndAliasesReady(t *testing.T) {
	store, ctx := openAITestStore(t)
	user := createTempAIUser(t, ctx, store, "multi-ready")
	otherUser := createTempAIUser(t, ctx, store, "multi-other")

	gopay, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID: user.ID, Name: "GoPay", Type: "ewallet", InstitutionCode: aiStrPtr("gopay"), Balance: 900000,
	})
	if err != nil {
		t.Fatalf("CreateWallet GoPay: %v", err)
	}
	mandiri, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID: user.ID, Name: "Mandiri Utama", Type: "bank", InstitutionCode: aiStrPtr("mandiri"), Balance: 5000000,
	})
	if err != nil {
		t.Fatalf("CreateWallet Mandiri: %v", err)
	}
	foreignWallet, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID: otherUser.ID, Name: "Bank Jago", Type: "bank", InstitutionCode: aiStrPtr("jago"), Balance: 10000000,
	})
	if err != nil {
		t.Fatalf("CreateWallet foreign: %v", err)
	}

	wib := time.FixedZone("WIB", 7*3600)
	fixedNow := time.Date(2026, 11, 16, 13, 15, 0, 0, wib)
	actions := ai.NewActionTools(
		store,
		ai.WithActionNowFunc(func() time.Time { return fixedNow }),
		ai.WithActionJakartaLocation(wib),
	)

	res, err := actions.CheckAndPrepareTransaction(ctx, user.ID, ai.PrepareTransactionInput{
		WalletHint: "gopay",
		Items: []ai.PrepareTransactionItemInput{
			{Title: "Kopi Kenangan", AmountIDR: 28000, Type: "expense", RawCategory: "kopi kenangan"},
			{Title: "Parkir", AmountIDR: 5000, Type: "expense", RawCategory: "parkir"},
		},
	})
	if err != nil {
		t.Fatalf("CheckAndPrepareTransaction multi-item: %v", err)
	}
	if res.Status != "ready" || res.WalletCreationDraft != nil || res.TransactionDraft == nil {
		t.Fatalf("expected ready TransactionDraft, got %+v", res)
	}
	if res.TransactionDraft.ItemCount != 2 || len(res.TransactionDraft.Items) != 2 || res.TransactionDraft.TotalAmountIDR != 33000 {
		t.Fatalf("unexpected draft totals: %+v", res.TransactionDraft)
	}

	item0 := res.TransactionDraft.Items[0]
	item1 := res.TransactionDraft.Items[1]
	if item0.Title != "Kopi Kenangan" || item0.AmountIDR != 28000 || item0.CanonicalCategory != "Food & Beverage • Coffee Shop" ||
		item0.CanonicalMainCategory != "Food & Beverage" || item0.WalletID != gopay.ID || item0.WalletName != "GoPay" {
		t.Fatalf("unexpected item0: %+v", item0)
	}
	if item1.Title != "Parkir" || item1.AmountIDR != 5000 || item1.CanonicalCategory != "Transportation • Parking & Toll" ||
		item1.CanonicalMainCategory != "Transportation" || item1.WalletID != gopay.ID || item1.WalletName != "GoPay" {
		t.Fatalf("unexpected item1: %+v", item1)
	}

	// Alias matching: "livin" resolves to user's Mandiri wallet, and transfer sets target_wallet_id.
	trfRes, err := actions.CheckAndPrepareTransaction(ctx, user.ID, ai.PrepareTransactionInput{
		Items: []ai.PrepareTransactionItemInput{
			{
				Title:            "Topup GoPay",
				AmountIDR:        250000,
				Type:             "transfer",
				WalletHint:       "livin",
				TargetWalletHint: "gopay",
			},
		},
	})
	if err != nil {
		t.Fatalf("CheckAndPrepareTransaction transfer: %v", err)
	}
	if trfRes.Status != "ready" || trfRes.TransactionDraft == nil || len(trfRes.TransactionDraft.Items) != 1 {
		t.Fatalf("expected ready transfer draft, got %+v", trfRes)
	}
	trfItem := trfRes.TransactionDraft.Items[0]
	if trfItem.WalletID != mandiri.ID || trfItem.TargetWalletID == nil || *trfItem.TargetWalletID != gopay.ID || trfItem.CanonicalCategory != "Transfer" {
		t.Fatalf("unexpected transfer draft item: %+v", trfItem)
	}

	// Foreign wallet_id must NOT match userA's wallets.
	foreignRes, err := actions.CheckAndPrepareTransaction(ctx, user.ID, ai.PrepareTransactionInput{
		Items: []ai.PrepareTransactionItemInput{
			{Title: "Test", AmountIDR: 10000, Type: "expense", RawCategory: "Makanan", WalletID: &foreignWallet.ID},
		},
	})
	if err != nil {
		t.Fatalf("CheckAndPrepareTransaction foreign wallet: %v", err)
	}
	if foreignRes.Status != "missing_wallet" || foreignRes.TransactionDraft != nil {
		t.Fatalf("foreign wallet_id must not resolve or substitute, got %+v", foreignRes)
	}

	// Invalid inputs must fail cleanly.
	if _, err := actions.CheckAndPrepareTransaction(ctx, user.ID, ai.PrepareTransactionInput{}); !errors.Is(err, ai.ErrInvalidActionToolInput) {
		t.Fatalf("expected ErrInvalidActionToolInput for empty items, got %v", err)
	}
	if _, err := actions.CheckAndPrepareTransaction(ctx, user.ID, ai.PrepareTransactionInput{
		Items: []ai.PrepareTransactionItemInput{{Title: "Kopi", AmountIDR: 0, Type: "expense"}},
	}); !errors.Is(err, ai.ErrInvalidActionToolInput) {
		t.Fatalf("expected ErrInvalidActionToolInput for zero amount, got %v", err)
	}
	// Incompatible explicit Type paired with opposite-type or transfer Category must reject cleanly.
	if _, err := actions.CheckAndPrepareTransaction(ctx, user.ID, ai.PrepareTransactionInput{
		Items: []ai.PrepareTransactionItemInput{{Title: "Gaji", AmountIDR: 5000000, Type: "expense", RawCategory: "Gaji", WalletHint: "gopay"}},
	}); !errors.Is(err, ai.ErrInvalidActionToolInput) {
		t.Fatalf("expected ErrInvalidActionToolInput for expense type paired with income category Gaji, got %v", err)
	}
	if _, err := actions.CheckAndPrepareTransaction(ctx, user.ID, ai.PrepareTransactionInput{
		Items: []ai.PrepareTransactionItemInput{{Title: "Pindah", AmountIDR: 100000, Type: "expense", RawCategory: "Transfer", WalletHint: "gopay"}},
	}); !errors.Is(err, ai.ErrInvalidActionToolInput) {
		t.Fatalf("expected ErrInvalidActionToolInput for expense type paired with Transfer category, got %v", err)
	}
}

func TestActionTools_ProposeGoalDraft_DeterministicArithmeticAndNoMutation(t *testing.T) {
	store, ctx := openAITestStore(t)
	user := createTempAIUser(t, ctx, store, "goal-draft")

	wib := time.FixedZone("WIB", 7*3600)
	fixedNow := time.Date(2026, 11, 16, 9, 0, 0, 0, wib)
	actions := ai.NewActionTools(
		store,
		ai.WithActionNowFunc(func() time.Time { return fixedNow }),
		ai.WithActionJakartaLocation(wib),
	)

	targetDate := "2027-05-16"
	goalDraft, err := actions.ProposeGoalDraft(ctx, user.ID, ai.GoalDraftInput{
		Title:           "Dana Darurat",
		TargetAmountIDR: 15000000,
		TargetDate:      &targetDate,
		Priority:        "urgent",
	})
	if err != nil {
		t.Fatalf("ProposeGoalDraft: %v", err)
	}
	if goalDraft.MonthsRemaining != 6 {
		t.Fatalf("MonthsRemaining = %d, want 6", goalDraft.MonthsRemaining)
	}
	if goalDraft.MonthlySavingEstimateIDR != 2500000 {
		t.Fatalf("MonthlySavingEstimateIDR = %d, want 2500000", goalDraft.MonthlySavingEstimateIDR)
	}

	// Non-divisible amount rounds up cleanly so total saved over remaining months reaches target.
	threeMonths := "2027-02-16"
	roundUpDraft, err := actions.ProposeGoalDraft(ctx, user.ID, ai.GoalDraftInput{
		Title:           "Laptop Baru",
		TargetAmountIDR: 10000000,
		TargetDate:      &threeMonths,
	})
	if err != nil {
		t.Fatalf("ProposeGoalDraft(roundUp): %v", err)
	}
	if roundUpDraft.MonthsRemaining != 3 || roundUpDraft.MonthlySavingEstimateIDR != 3333334 {
		t.Fatalf("roundUp = %+v, want MonthsRemaining=3 MonthlySavingEstimateIDR=3333334", roundUpDraft)
	}

	// Same-month target date clamps months >= 1.
	sameMonth := "2026-11-30"
	sameMonthDraft, err := actions.ProposeGoalDraft(ctx, user.ID, ai.GoalDraftInput{
		Title:           "Dana Cepat",
		TargetAmountIDR: 2000000,
		SavedAmountIDR:  500000,
		TargetDate:      &sameMonth,
	})
	if err != nil {
		t.Fatalf("ProposeGoalDraft(sameMonth): %v", err)
	}
	if sameMonthDraft.MonthsRemaining != 1 || sameMonthDraft.RemainingAmountIDR != 1500000 || sameMonthDraft.MonthlySavingEstimateIDR != 1500000 {
		t.Fatalf("sameMonth = %+v", sameMonthDraft)
	}

	// Past target date rejected.
	pastDate := "2026-10-01"
	if _, err := actions.ProposeGoalDraft(ctx, user.ID, ai.GoalDraftInput{
		Title: "Old", TargetAmountIDR: 1000000, TargetDate: &pastDate,
	}); !errors.Is(err, ai.ErrInvalidActionToolInput) {
		t.Fatalf("expected ErrInvalidActionToolInput for past target_date, got %v", err)
	}

	// Verify zero DB mutations.
	goals, err := store.ListGoalsByUser(ctx, user.ID)
	if err != nil {
		t.Fatalf("ListGoalsByUser: %v", err)
	}
	if len(goals) != 0 {
		t.Fatalf("ProposeGoalDraft must not mutate DB, found %d goals", len(goals))
	}

	// Months helper calculates target date and identical Rp 2.500.000/bulan.
	monthsHorizon := 6
	monthsDraft, err := actions.ProposeGoalDraft(ctx, user.ID, ai.GoalDraftInput{
		Title:           "Dana Pendidikan",
		TargetAmountIDR: 15000000,
		Months:          &monthsHorizon,
	})
	if err != nil {
		t.Fatalf("ProposeGoalDraft(months): %v", err)
	}
	if monthsDraft.MonthsRemaining != 6 || monthsDraft.MonthlySavingEstimateIDR != 2500000 ||
		monthsDraft.TargetDate == nil || *monthsDraft.TargetDate != "2027-05-16" {
		t.Fatalf("monthsDraft = %+v", monthsDraft)
	}
}

func TestActionTools_ProposeBudgetDraft_NormalizesAndQueriesRealSpend(t *testing.T) {
	store, ctx := openAITestStore(t)
	userA := createTempAIUser(t, ctx, store, "budget-a")
	userB := createTempAIUser(t, ctx, store, "budget-b")

	walletA, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID: userA.ID, Name: "BCA", Type: "bank", InstitutionCode: aiStrPtr("bca"), Balance: 5000000,
	})
	if err != nil {
		t.Fatalf("CreateWallet A: %v", err)
	}
	walletB, err := store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID: userB.ID, Name: "BCA B", Type: "bank", InstitutionCode: aiStrPtr("bca"), Balance: 5000000,
	})
	if err != nil {
		t.Fatalf("CreateWallet B: %v", err)
	}

	wib := time.FixedZone("WIB", 7*3600)
	fixedNow := time.Date(2026, 11, 16, 15, 0, 0, 0, wib)

	seed := []repository.InsertTransactionIdempotentParams{
		// Current month + within last 30 days (Nov 2026) -> 200.000
		{UserID: userA.ID, WalletID: walletA.ID, Type: "expense", Category: "Food & Beverage • Coffee Shop", Amount: 50000, Title: "Kopi", OccurredAt: time.Date(2026, 11, 10, 10, 0, 0, 0, wib), Source: "manual"},
		{UserID: userA.ID, WalletID: walletA.ID, Type: "expense", Category: "Food & Beverage", Amount: 150000, Title: "Makan Siang", OccurredAt: time.Date(2026, 11, 5, 12, 0, 0, 0, wib), Source: "manual"},
		// Prior month (Oct 25) still within last_30_days (Oct 18..Nov 16) -> +300.000 (so 30d = 500.000, current_month = 200.000)
		{UserID: userA.ID, WalletID: walletA.ID, Type: "expense", Category: "Food & Beverage • Restaurant", Amount: 300000, Title: "Warteg", OccurredAt: time.Date(2026, 10, 25, 19, 0, 0, 0, wib), Source: "manual"},
		// Unrelated category must not count toward Food & Beverage budget.
		{UserID: userA.ID, WalletID: walletA.ID, Type: "expense", Category: "Transportation • Parking & Toll", Amount: 90000, Title: "Tol", OccurredAt: time.Date(2026, 11, 12, 9, 0, 0, 0, wib), Source: "manual"},
		// User B spend must never leak.
		{UserID: userB.ID, WalletID: walletB.ID, Type: "expense", Category: "Food & Beverage", Amount: 9000000, Title: "Catering B", OccurredAt: time.Date(2026, 11, 12, 9, 0, 0, 0, wib), Source: "manual"},
	}
	for i, p := range seed {
		if _, err := store.InsertTransactionIdempotent(ctx, p); err != nil {
			t.Fatalf("seed[%d]: %v", i, err)
		}
	}

	actions := ai.NewActionTools(
		store,
		ai.WithActionNowFunc(func() time.Time { return fixedNow }),
		ai.WithActionJakartaLocation(wib),
	)

	draft, err := actions.ProposeBudgetDraft(ctx, userA.ID, ai.BudgetDraftInput{
		Category:       "kopi kenangan",
		LimitAmountIDR: 1200000,
	})
	if err != nil {
		t.Fatalf("ProposeBudgetDraft: %v", err)
	}
	if draft.Category != "Food & Beverage" {
		t.Fatalf("Category = %q, want Food & Beverage (canonical main category)", draft.Category)
	}
	if draft.MonthYear != "2026-11" {
		t.Fatalf("MonthYear = %q, want 2026-11", draft.MonthYear)
	}
	if draft.CurrentMonthSpendIDR != 200000 {
		t.Fatalf("CurrentMonthSpendIDR = %d, want 200000", draft.CurrentMonthSpendIDR)
	}
	if draft.Avg30DSpendIDR != 500000 {
		t.Fatalf("Avg30DSpendIDR = %d, want 500000", draft.Avg30DSpendIDR)
	}
	if draft.LimitAmountIDR != 1200000 {
		t.Fatalf("LimitAmountIDR = %d, want 1200000", draft.LimitAmountIDR)
	}

	// Reject non-positive limit, income categories, and Transfer category.
	if _, err := actions.ProposeBudgetDraft(ctx, userA.ID, ai.BudgetDraftInput{
		Category: "Makanan", LimitAmountIDR: 0,
	}); !errors.Is(err, ai.ErrInvalidActionToolInput) {
		t.Fatalf("expected ErrInvalidActionToolInput for zero limit, got %v", err)
	}
	if _, err := actions.ProposeBudgetDraft(ctx, userA.ID, ai.BudgetDraftInput{
		Category: "Gaji", LimitAmountIDR: 1000000,
	}); !errors.Is(err, ai.ErrInvalidActionToolInput) {
		t.Fatalf("expected ErrInvalidActionToolInput for income category budget, got %v", err)
	}
	if _, err := actions.ProposeBudgetDraft(ctx, userA.ID, ai.BudgetDraftInput{
		Category: "Transfer", LimitAmountIDR: 1000000,
	}); !errors.Is(err, ai.ErrInvalidActionToolInput) {
		t.Fatalf("expected ErrInvalidActionToolInput for Transfer category budget, got %v", err)
	}

	// Zero DB mutations check.
	budgets, err := store.ListBudgetsWithSpent(ctx, repository.ListBudgetsWithSpentParams{
		UserID: userA.ID, MonthYear: "2026-11",
	})
	if err != nil {
		t.Fatalf("ListBudgetsWithSpent: %v", err)
	}
	if len(budgets) != 0 {
		t.Fatalf("ProposeBudgetDraft must not mutate DB, found %d budgets", len(budgets))
	}
}

func TestActionTools_ProposeBillDraft_ValidatesAndComputesWIBDueDate(t *testing.T) {
	store, ctx := openAITestStore(t)
	user := createTempAIUser(t, ctx, store, "bill-draft")

	wib := time.FixedZone("WIB", 7*3600)
	fixedNow := time.Date(2026, 11, 16, 20, 0, 0, 0, wib)
	actions := ai.NewActionTools(
		store,
		ai.WithActionNowFunc(func() time.Time { return fixedNow }),
		ai.WithActionJakartaLocation(wib),
	)

	// Due day 20 in current month has not passed yet.
	b1, err := actions.ProposeBillDraft(ctx, user.ID, ai.BillDraftInput{
		Title:     "Listrik PLN",
		Category:  "listrik",
		AmountIDR: 450000,
		DueDay:    20,
		Frequency: "monthly",
		AutoPay:   true,
	})
	if err != nil {
		t.Fatalf("ProposeBillDraft(upcoming): %v", err)
	}
	if b1.CanonicalCategory != "Bills & Utilities • Electricity / Listrik PLN" || b1.CanonicalMainCategory != "Bills & Utilities" {
		t.Fatalf("unexpected bill category: %+v", b1)
	}
	if b1.NextDueDate != "2026-11-20" {
		t.Fatalf("NextDueDate = %q, want 2026-11-20", b1.NextDueDate)
	}

	// Due day 10 already passed in Nov -> advances to Dec 10.
	b2, err := actions.ProposeBillDraft(ctx, user.ID, ai.BillDraftInput{
		Title:     "Wi-Fi Indihome",
		AmountIDR: 380000,
		DueDay:    10,
		Frequency: "monthly",
	})
	if err != nil {
		t.Fatalf("ProposeBillDraft(nextMonth): %v", err)
	}
	if b2.CanonicalCategory != "Bills & Utilities • Internet & Wi-Fi" || b2.NextDueDate != "2026-12-10" {
		t.Fatalf("unexpected nextMonth bill: %+v", b2)
	}

	// Due day 31 in November (30 days) clamps cleanly to 2026-11-30 instead of overflowing to Dec 1.
	b3, err := actions.ProposeBillDraft(ctx, user.ID, ai.BillDraftInput{
		Title:     "Kos Bulanan",
		Category:  "kos",
		AmountIDR: 2000000,
		DueDay:    31,
		Frequency: "monthly",
	})
	if err != nil {
		t.Fatalf("ProposeBillDraft(clamp31): %v", err)
	}
	if b3.NextDueDate != "2026-11-30" {
		t.Fatalf("NextDueDate for due_day 31 in Nov = %q, want 2026-11-30", b3.NextDueDate)
	}

	// Yearly frequency past due_day advances +1 year; weekly advances +7 days past today.
	bYearly, err := actions.ProposeBillDraft(ctx, user.ID, ai.BillDraftInput{
		Title: "Pajak STNK", Category: "pajak", AmountIDR: 1500000, DueDay: 5, Frequency: "yearly",
	})
	if err != nil || bYearly.NextDueDate != "2027-11-05" {
		t.Fatalf("yearly bill = %+v, err=%v", bYearly, err)
	}
	bWeekly, err := actions.ProposeBillDraft(ctx, user.ID, ai.BillDraftInput{
		Title: "Galon Air", Category: "Belanja", AmountIDR: 25000, DueDay: 10, Frequency: "weekly",
	})
	if err != nil || bWeekly.NextDueDate != "2026-11-17" {
		t.Fatalf("weekly bill = %+v, err=%v", bWeekly, err)
	}

	// Invalid due_day, amount, frequency, non-expense category, userID must reject cleanly.
	for _, invalid := range []ai.BillDraftInput{
		{Title: "", AmountIDR: 10000, DueDay: 5, Frequency: "monthly"},
		{Title: "PLN", AmountIDR: 0, DueDay: 5, Frequency: "monthly"},
		{Title: "PLN", AmountIDR: 10000, DueDay: 0, Frequency: "monthly"},
		{Title: "PLN", AmountIDR: 10000, DueDay: 32, Frequency: "monthly"},
		{Title: "PLN", AmountIDR: 10000, DueDay: 5, Frequency: "daily"},
		{Title: "Gaji Karyawan", Category: "Gaji", AmountIDR: 5000000, DueDay: 25, Frequency: "monthly"},
		{Title: "Pindah Saldo", Category: "Transfer", AmountIDR: 500000, DueDay: 15, Frequency: "monthly"},
	} {
		if _, err := actions.ProposeBillDraft(ctx, user.ID, invalid); !errors.Is(err, ai.ErrInvalidActionToolInput) {
			t.Fatalf("expected ErrInvalidActionToolInput for %+v, got %v", invalid, err)
		}
	}
	if _, err := actions.ProposeBillDraft(ctx, uuid.Nil, ai.BillDraftInput{
		Title: "PLN", AmountIDR: 10000, DueDay: 5, Frequency: "monthly",
	}); !errors.Is(err, ai.ErrInvalidActionToolInput) {
		t.Fatalf("expected ErrInvalidActionToolInput for nil userID, got %v", err)
	}

	// Zero DB mutations check.
	bills, err := store.ListUpcomingBillsByUser(ctx, user.ID)
	if err != nil {
		t.Fatalf("ListUpcomingBillsByUser: %v", err)
	}
	if len(bills) != 0 {
		t.Fatalf("ProposeBillDraft must not mutate DB, found %d bills", len(bills))
	}
}
