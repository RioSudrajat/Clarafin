package service_test

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/clarafin/api/internal/repository"
	"github.com/clarafin/api/internal/service"
)

func createTempTrackerUser(t *testing.T, ctx context.Context, store *repository.Store, label string) repository.User {
	t.Helper()

	userID := uuid.New()
	email := fmt.Sprintf("tracker-svc-%s-%s@clarafin.test", label, userID.String()[:8])

	user, err := store.EnsureDevUserAccount(ctx, repository.EnsureDevUserParams{
		ID:       userID,
		Email:    email,
		FullName: "Tracker " + label,
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

func svcStrPtr(s string) *string { return &s }

func TestTrackerService_CrossUserIsolation(t *testing.T) {
	store, ctx := openQuotaTestStore(t)
	userA := createTempTrackerUser(t, ctx, store, "iso-a")
	userB := createTempTrackerUser(t, ctx, store, "iso-b")

	svc := service.NewTrackerService(store)

	walletA, err := svc.CreateWallet(ctx, userA.ID, service.CreateWalletInput{
		Name:    "BCA A",
		Type:    "bank",
		Balance: 2000000,
	})
	if err != nil {
		t.Fatalf("CreateWallet A: %v", err)
	}
	walletB, err := svc.CreateWallet(ctx, userB.ID, service.CreateWalletInput{
		Name:    "Mandiri B",
		Type:    "bank",
		Balance: 5000000,
	})
	if err != nil {
		t.Fatalf("CreateWallet B: %v", err)
	}

	goalA, err := svc.CreateGoal(ctx, userA.ID, service.CreateGoalInput{
		Title:        "Dana Darurat A",
		TargetAmount: 10000000,
		Priority:     "urgent",
	})
	if err != nil {
		t.Fatalf("CreateGoal A: %v", err)
	}

	// User B cannot read, mutate, or delete User A's wallet.
	if _, err := svc.GetWallet(ctx, userB.ID, walletA.ID); !errors.Is(err, service.ErrNotFound) {
		t.Fatalf("expected ErrNotFound on cross-user GetWallet, got %v", err)
	}
	if _, err := svc.UpdateWallet(ctx, userB.ID, walletA.ID, service.UpdateWalletInput{Name: svcStrPtr("Hacked")}); !errors.Is(err, service.ErrNotFound) {
		t.Fatalf("expected ErrNotFound on cross-user UpdateWallet, got %v", err)
	}
	if err := svc.DeleteWallet(ctx, userB.ID, walletA.ID); !errors.Is(err, service.ErrNotFound) {
		t.Fatalf("expected ErrNotFound on cross-user DeleteWallet, got %v", err)
	}

	// User B cannot create a transaction referencing User A's wallet or goal.
	if _, err := svc.CreateTransaction(ctx, userB.ID, service.CreateTransactionInput{
		WalletID:         walletA.ID,
		Type:             "expense",
		Category:         "Food & Beverage",
		Amount:           100000,
		Title:            "Cross Wallet Attack",
		ClientMutationID: svcStrPtr("cross_w_" + uuid.NewString()),
	}); !errors.Is(err, service.ErrNotFound) {
		t.Fatalf("expected ErrNotFound for cross-user wallet_id, got %v", err)
	}
	if _, err := svc.CreateTransaction(ctx, userB.ID, service.CreateTransactionInput{
		WalletID:            walletB.ID,
		DestinationWalletID: &walletA.ID,
		Type:                "transfer",
		Category:            "Transfer",
		Amount:              100000,
		Title:               "Cross Dest Wallet",
		ClientMutationID:    svcStrPtr("cross_dw_" + uuid.NewString()),
	}); !errors.Is(err, service.ErrNotFound) {
		t.Fatalf("expected ErrNotFound for cross-user destination_wallet_id, got %v", err)
	}
	if _, err := svc.CreateTransaction(ctx, userB.ID, service.CreateTransactionInput{
		WalletID:         walletB.ID,
		TargetGoalID:     &goalA.ID,
		Type:             "transfer",
		Category:         "Transfer",
		Amount:           100000,
		Title:            "Cross Goal",
		ClientMutationID: svcStrPtr("cross_goal_" + uuid.NewString()),
	}); !errors.Is(err, service.ErrNotFound) {
		t.Fatalf("expected ErrNotFound for cross-user target_goal_id, got %v", err)
	}

	// Verify balances remained untouched.
	checkA, err := svc.GetWallet(ctx, userA.ID, walletA.ID)
	if err != nil || checkA.Balance != 2000000 {
		t.Fatalf("userA wallet balance mutated or unreadable: (%+v, %v)", checkA, err)
	}
	checkB, err := svc.GetWallet(ctx, userB.ID, walletB.ID)
	if err != nil || checkB.Balance != 5000000 {
		t.Fatalf("userB wallet balance mutated or unreadable: (%+v, %v)", checkB, err)
	}

	// User B cannot confirm User A's draft, and User A cannot confirm a draft into User B's wallet.
	draftA, err := store.CreateAIDraft(ctx, repository.CreateAIDraftParams{
		UserID: userA.ID, WalletID: &walletA.ID, Source: "ai_text", Type: "expense",
		Category: "Food & Beverage", Amount: 35000, Title: "Bakmi", MerchantOrNote: "note",
		OccurredAt: time.Now().UTC(), ConfidenceScore: 0.9,
	})
	if err != nil {
		t.Fatalf("CreateAIDraft A: %v", err)
	}
	if _, err := svc.ConfirmAIDraft(ctx, userB.ID, draftA.ID, service.ConfirmAIDraftInput{}); !errors.Is(err, service.ErrNotFound) {
		t.Fatalf("expected ErrNotFound on cross-user ConfirmAIDraft, got %v", err)
	}
	if _, err := svc.ConfirmAIDraft(ctx, userA.ID, draftA.ID, service.ConfirmAIDraftInput{WalletID: &walletB.ID}); !errors.Is(err, service.ErrNotFound) {
		t.Fatalf("expected ErrNotFound on ConfirmAIDraft with foreign wallet, got %v", err)
	}
}

func TestTrackerService_CreateTransaction_IdempotencyAndACIDBalances(t *testing.T) {
	store, ctx := openQuotaTestStore(t)
	user := createTempTrackerUser(t, ctx, store, "idem")

	svc := service.NewTrackerService(store)
	bca, err := svc.CreateWallet(ctx, user.ID, service.CreateWalletInput{
		Name: "BCA", Type: "bank", Balance: 1000000,
	})
	if err != nil {
		t.Fatalf("CreateWallet BCA: %v", err)
	}
	gopay, err := svc.CreateWallet(ctx, user.ID, service.CreateWalletInput{
		Name: "GoPay", Type: "ewallet", Balance: 200000,
	})
	if err != nil {
		t.Fatalf("CreateWallet GoPay: %v", err)
	}
	goal, err := svc.CreateGoal(ctx, user.ID, service.CreateGoalInput{
		Title: "Liburan", TargetAmount: 5000000, Priority: "wants",
	})
	if err != nil {
		t.Fatalf("CreateGoal: %v", err)
	}

	// 1. Sequential and concurrent duplicate client_mutation_id must only deduct wallet once.
	mutID := "mut_expense_" + uuid.NewString()
	res1, err := svc.CreateTransaction(ctx, user.ID, service.CreateTransactionInput{
		WalletID:         bca.ID,
		Type:             "expense",
		Category:         "Food & Beverage • Coffee Shop",
		Amount:           50000,
		Title:            "Kopi Kenangan",
		ClientMutationID: &mutID,
	})
	if err != nil {
		t.Fatalf("first CreateTransaction: %v", err)
	}
	if res1.IdempotentReplay || res1.WalletBalanceIDR != 950000 {
		t.Fatalf("unexpected first tx result: %+v", res1)
	}

	res2, err := svc.CreateTransaction(ctx, user.ID, service.CreateTransactionInput{
		WalletID:         bca.ID,
		Type:             "expense",
		Category:         "Food & Beverage • Coffee Shop",
		Amount:           50000,
		Title:            "Kopi Kenangan",
		ClientMutationID: &mutID,
	})
	if err != nil {
		t.Fatalf("duplicate CreateTransaction: %v", err)
	}
	if !res2.IdempotentReplay || res2.Transaction.ID != res1.Transaction.ID || res2.WalletBalanceIDR != 950000 {
		t.Fatalf("expected IdempotentReplay=true with unchanged balance 950000, got %+v", res2)
	}

	// Concurrent burst with a fresh client_mutation_id on transfer + target_goal_id must mutate once.
	concurrentMutID := "mut_goal_trf_" + uuid.NewString()
	const workers = 5
	var wg sync.WaitGroup
	errs := make(chan error, workers)
	results := make(chan *service.TransactionMutationResult, workers)
	for i := 0; i < workers; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			r, err := svc.CreateTransaction(ctx, user.ID, service.CreateTransactionInput{
				WalletID:            bca.ID,
				DestinationWalletID: &gopay.ID,
				TargetGoalID:        &goal.ID,
				Type:                "transfer",
				Category:            "Incoming Transfer",
				Amount:              150000,
				Title:               "Sisihkan Tabungan",
				ClientMutationID:    &concurrentMutID,
			})
			if err != nil {
				errs <- err
				return
			}
			results <- r
		}()
	}
	wg.Wait()
	close(errs)
	close(results)

	for err := range errs {
		t.Fatalf("concurrent idempotent CreateTransaction error: %v", err)
	}
	freshCount, replayCount := 0, 0
	for r := range results {
		if r.IdempotentReplay {
			replayCount++
		} else {
			freshCount++
		}
	}
	if freshCount != 1 || replayCount != workers-1 {
		t.Fatalf("expected 1 fresh and %d replays, got fresh=%d replay=%d", workers-1, freshCount, replayCount)
	}

	bcaAfter, err := svc.GetWallet(ctx, user.ID, bca.ID)
	if err != nil || bcaAfter.Balance != 800000 {
		t.Fatalf("expected BCA balance 800000, got (%+v, %v)", bcaAfter, err)
	}
	gopayAfter, err := svc.GetWallet(ctx, user.ID, gopay.ID)
	if err != nil || gopayAfter.Balance != 350000 {
		t.Fatalf("expected GoPay balance 350000, got (%+v, %v)", gopayAfter, err)
	}
	goalAfter, err := store.GetGoalByID(ctx, repository.GetGoalByIDParams{UserID: user.ID, ID: goal.ID})
	if err != nil || goalAfter.SavedAmount != 150000 {
		t.Fatalf("expected Goal saved_amount 150000, got (%+v, %v)", goalAfter, err)
	}

	// Reversal via DeleteTransaction restores balances and goal saved_amount cleanly.
	if err := svc.DeleteTransaction(ctx, user.ID, res1.Transaction.ID); err != nil {
		t.Fatalf("DeleteTransaction(expense): %v", err)
	}
	bcaRestored, err := svc.GetWallet(ctx, user.ID, bca.ID)
	if err != nil || bcaRestored.Balance != 850000 {
		t.Fatalf("expected BCA balance 850000 after expense delete, got (%+v, %v)", bcaRestored, err)
	}

	// DeleteWallet with remaining transfer transaction must return ErrConflict.
	if err := svc.DeleteWallet(ctx, user.ID, bca.ID); !errors.Is(err, service.ErrConflict) {
		t.Fatalf("expected ErrConflict when deleting wallet with transactions, got %v", err)
	}
}

func TestTrackerService_DraftConfirmAndBillPayAtomicity(t *testing.T) {
	store, ctx := openQuotaTestStore(t)
	user := createTempTrackerUser(t, ctx, store, "draft-bill")
	svc := service.NewTrackerService(store)

	wallet, err := svc.CreateWallet(ctx, user.ID, service.CreateWalletInput{
		Name: "GoPay", Type: "ewallet", Balance: 500000,
	})
	if err != nil {
		t.Fatalf("CreateWallet: %v", err)
	}

	draft, err := store.CreateAIDraft(ctx, repository.CreateAIDraftParams{
		UserID: user.ID, WalletID: &wallet.ID, Source: "ai_text", Type: "expense",
		Category: "Food & Beverage • Coffee Shop", Amount: 28000, Title: "Kopi Kenangan",
		MerchantOrNote: "kopi susu", OccurredAt: time.Now().UTC(), ConfidenceScore: 0.95,
	})
	if err != nil {
		t.Fatalf("CreateAIDraft: %v", err)
	}

	confirmRes, err := svc.ConfirmAIDraft(ctx, user.ID, draft.ID, service.ConfirmAIDraftInput{
		ClientMutationID: svcStrPtr("draft_confirm_1_" + uuid.NewString()),
	})
	if err != nil {
		t.Fatalf("ConfirmAIDraft: %v", err)
	}
	if confirmRes.WalletBalanceIDR != 472000 {
		t.Fatalf("expected balance 472000 after draft confirm, got %d", confirmRes.WalletBalanceIDR)
	}

	// Duplicate confirm must return ErrConflict and must NOT deduct balance twice.
	if _, err := svc.ConfirmAIDraft(ctx, user.ID, draft.ID, service.ConfirmAIDraftInput{
		ClientMutationID: svcStrPtr("draft_confirm_2_" + uuid.NewString()),
	}); !errors.Is(err, service.ErrConflict) {
		t.Fatalf("expected ErrConflict on duplicate ConfirmAIDraft, got %v", err)
	}

	bill, err := svc.CreateBill(ctx, user.ID, service.CreateBillInput{
		Title:     "IndiHome",
		Category:  svcStrPtr("Bills & Utilities • Internet & Wi-Fi"),
		Amount:    350000,
		Frequency: "monthly",
	})
	if err != nil {
		t.Fatalf("CreateBill: %v", err)
	}
	paidBool := true
	billRes, err := svc.UpdateBill(ctx, user.ID, bill.ID, service.UpdateBillInput{
		IsPaid:   &paidBool,
		WalletID: &wallet.ID,
	})
	if err != nil {
		t.Fatalf("UpdateBill(pay): %v", err)
	}
	if !billRes.Bill.IsPaid {
		t.Fatal("expected bill IsPaid == true")
	}
	wAfterBill, err := svc.GetWallet(ctx, user.ID, wallet.ID)
	if err != nil || wAfterBill.Balance != 122000 {
		t.Fatalf("expected wallet balance 122000 after paying bill, got (%+v, %v)", wAfterBill, err)
	}
}

func TestTrackerService_ConcurrentBillPayDoubleDeductionAndIdempotentReplay(t *testing.T) {
	store, ctx := openQuotaTestStore(t)
	user := createTempTrackerUser(t, ctx, store, "bill-race")
	svc := service.NewTrackerService(store)

	wallet, err := svc.CreateWallet(ctx, user.ID, service.CreateWalletInput{
		Name: "BCA Bill", Type: "bank", Balance: 2000000,
	})
	if err != nil {
		t.Fatalf("CreateWallet: %v", err)
	}
	otherWallet, err := svc.CreateWallet(ctx, user.ID, service.CreateWalletInput{
		Name: "GoPay Bill", Type: "ewallet", Balance: 500000,
	})
	if err != nil {
		t.Fatalf("CreateWallet other: %v", err)
	}

	// 1. Multi-goroutine concurrent double-pay WITHOUT client_mutation_id:
	// exactly 1 caller transitions false -> true and deducts wallet once; others get ErrConflict.
	raceBill, err := svc.CreateBill(ctx, user.ID, service.CreateBillInput{
		Title:     "PLN Token",
		Category:  svcStrPtr("Bills & Utilities"),
		Amount:    300000,
		Frequency: "monthly",
	})
	if err != nil {
		t.Fatalf("CreateBill race: %v", err)
	}

	const workers = 5
	paidTrue := true
	var wg sync.WaitGroup
	okCh := make(chan *service.BillUpdateResult, workers)
	errCh := make(chan error, workers)

	for i := 0; i < workers; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			res, err := svc.UpdateBill(ctx, user.ID, raceBill.ID, service.UpdateBillInput{
				IsPaid:   &paidTrue,
				WalletID: &wallet.ID,
			})
			if err != nil {
				errCh <- err
				return
			}
			okCh <- res
		}()
	}
	wg.Wait()
	close(okCh)
	close(errCh)

	if len(okCh) != 1 {
		t.Fatalf("expected exactly 1 winning concurrent bill payment, got %d", len(okCh))
	}
	if len(errCh) != workers-1 {
		t.Fatalf("expected %d competing callers to fail, got %d", workers-1, len(errCh))
	}
	for err := range errCh {
		if !errors.Is(err, service.ErrConflict) {
			t.Fatalf("expected competing caller error to be ErrConflict, got %v", err)
		}
	}

	var txCount int
	if err := store.Pool.QueryRow(ctx, `SELECT COUNT(*) FROM transactions WHERE user_id = $1 AND title = 'PLN Token'`, user.ID).Scan(&txCount); err != nil {
		t.Fatalf("count bill tx: %v", err)
	}
	if txCount != 1 {
		t.Fatalf("expected 1 expense transaction for PLN Token, got %d", txCount)
	}
	wAfterRace, err := svc.GetWallet(ctx, user.ID, wallet.ID)
	if err != nil || wAfterRace.Balance != 1700000 {
		t.Fatalf("expected BCA Bill balance 1700000 after race, got (%+v, %v)", wAfterRace, err)
	}

	// 2. Unrelated earlier transaction cannot hijack an unpaid bill or masquerade as a bill replay.
	unrelatedMutID := "unrelated_tx_" + uuid.NewString()
	if _, err := svc.CreateTransaction(ctx, user.ID, service.CreateTransactionInput{
		WalletID:         wallet.ID,
		Type:             "expense",
		Category:         "Food & Beverage",
		Amount:           50000,
		Title:            "Lunch",
		ClientMutationID: &unrelatedMutID,
	}); err != nil {
		t.Fatalf("CreateTransaction unrelated: %v", err)
	}

	idemBill, err := svc.CreateBill(ctx, user.ID, service.CreateBillInput{
		Title:     "BPJS Kesehatan",
		Category:  svcStrPtr("Bills & Utilities"),
		Amount:    150000,
		Frequency: "monthly",
	})
	if err != nil {
		t.Fatalf("CreateBill idem: %v", err)
	}

	// Passing an unrelated client_mutation_id on an unpaid bill must fail with ErrConflict.
	if _, err := svc.UpdateBill(ctx, user.ID, idemBill.ID, service.UpdateBillInput{
		IsPaid:           &paidTrue,
		WalletID:         &wallet.ID,
		ClientMutationID: &unrelatedMutID,
	}); !errors.Is(err, service.ErrConflict) {
		t.Fatalf("expected ErrConflict when paying unpaid bill with pre-existing unrelated client_mutation_id, got %v", err)
	}

	// Authentic bill payment with fresh client_mutation_id succeeds and populates WalletBalanceIDR.
	billMutID := "bill_pay_idem_" + uuid.NewString()
	firstPay, err := svc.UpdateBill(ctx, user.ID, idemBill.ID, service.UpdateBillInput{
		IsPaid:           &paidTrue,
		WalletID:         &wallet.ID,
		ClientMutationID: &billMutID,
	})
	if err != nil {
		t.Fatalf("first idempotent UpdateBill: %v", err)
	}
	if firstPay.IdempotentReplay || firstPay.WalletBalanceIDR == nil || *firstPay.WalletBalanceIDR != 1500000 {
		t.Fatalf("unexpected first bill payment result: %+v", firstPay)
	}

	// Sequential idempotent replay keeps bill.UpdatedAt untouched and returns non-nil WalletBalanceIDR.
	replayPay, err := svc.UpdateBill(ctx, user.ID, idemBill.ID, service.UpdateBillInput{
		Title:            svcStrPtr("BPJS Kesehatan"),
		IsPaid:           &paidTrue,
		WalletID:         &wallet.ID,
		ClientMutationID: &billMutID,
	})
	if err != nil {
		t.Fatalf("sequential idempotent UpdateBill replay: %v", err)
	}
	if !replayPay.IdempotentReplay || replayPay.Transaction == nil || replayPay.WalletBalanceIDR == nil || *replayPay.WalletBalanceIDR != 1500000 {
		t.Fatalf("expected authentic replay with WalletBalanceIDR=1500000, got %+v", replayPay)
	}
	if !replayPay.Bill.UpdatedAt.Equal(firstPay.Bill.UpdatedAt) {
		t.Fatalf("expected bill updated_at to remain untouched on replay (%v vs %v)", replayPay.Bill.UpdatedAt, firstPay.Bill.UpdatedAt)
	}

	// Mismatched client_mutation_id or mismatched wallet/amount on replay must return ErrConflict.
	if _, err := svc.UpdateBill(ctx, user.ID, idemBill.ID, service.UpdateBillInput{
		IsPaid:           &paidTrue,
		WalletID:         &wallet.ID,
		ClientMutationID: &unrelatedMutID,
	}); !errors.Is(err, service.ErrConflict) {
		t.Fatalf("expected ErrConflict on replay with unrelated client_mutation_id, got %v", err)
	}
	if _, err := svc.UpdateBill(ctx, user.ID, idemBill.ID, service.UpdateBillInput{
		IsPaid:           &paidTrue,
		WalletID:         &otherWallet.ID,
		ClientMutationID: &billMutID,
	}); !errors.Is(err, service.ErrConflict) {
		t.Fatalf("expected ErrConflict on replay with mismatched wallet_id, got %v", err)
	}
	if _, err := svc.UpdateBill(ctx, user.ID, idemBill.ID, service.UpdateBillInput{
		Title:            svcStrPtr("Mutated Title"),
		IsPaid:           &paidTrue,
		WalletID:         &wallet.ID,
		ClientMutationID: &billMutID,
	}); !errors.Is(err, service.ErrConflict) {
		t.Fatalf("expected ErrConflict on replay with mismatched title, got %v", err)
	}

	wFinal, err := svc.GetWallet(ctx, user.ID, wallet.ID)
	if err != nil || wFinal.Balance != 1500000 {
		t.Fatalf("expected final wallet balance 1500000 without double deduction, got (%+v, %v)", wFinal, err)
	}

	// 3. Multi-goroutine concurrent bill payment WITH identical client_mutation_id:
	// 1 fresh transition + (workers-1) idempotent replays, 1 tx row, single wallet deduction.
	concIdemBill, err := svc.CreateBill(ctx, user.ID, service.CreateBillInput{
		Title:     "Streaming Music",
		Category:  svcStrPtr("Bills & Utilities"),
		Amount:    50000,
		Frequency: "monthly",
	})
	if err != nil {
		t.Fatalf("CreateBill concIdem: %v", err)
	}
	concMutID := "bill_conc_idem_" + uuid.NewString()
	var concWG sync.WaitGroup
	concResCh := make(chan *service.BillUpdateResult, workers)
	concErrCh := make(chan error, workers)
	for i := 0; i < workers; i++ {
		concWG.Add(1)
		go func() {
			defer concWG.Done()
			r, err := svc.UpdateBill(ctx, user.ID, concIdemBill.ID, service.UpdateBillInput{
				IsPaid:           &paidTrue,
				WalletID:         &wallet.ID,
				ClientMutationID: &concMutID,
			})
			if err != nil {
				concErrCh <- err
				return
			}
			concResCh <- r
		}()
	}
	concWG.Wait()
	close(concResCh)
	close(concErrCh)

	for err := range concErrCh {
		t.Fatalf("concurrent identical client_mutation_id bill pay failed: %v", err)
	}
	freshPayCount, replayPayCount := 0, 0
	for r := range concResCh {
		if r.WalletBalanceIDR == nil || *r.WalletBalanceIDR != 1450000 {
			t.Fatalf("expected WalletBalanceIDR=1450000 on every concurrent result, got %+v", r)
		}
		if r.IdempotentReplay {
			replayPayCount++
		} else {
			freshPayCount++
		}
	}
	if freshPayCount != 1 || replayPayCount != workers-1 {
		t.Fatalf("expected 1 fresh and %d replays, got fresh=%d replay=%d", workers-1, freshPayCount, replayPayCount)
	}
}

func TestTrackerService_TargetGoalIDValidation(t *testing.T) {
	store, ctx := openQuotaTestStore(t)
	user := createTempTrackerUser(t, ctx, store, "goal-val")
	svc := service.NewTrackerService(store)

	wallet, err := svc.CreateWallet(ctx, user.ID, service.CreateWalletInput{
		Name: "BCA Goal", Type: "bank", Balance: 1000000,
	})
	if err != nil {
		t.Fatalf("CreateWallet: %v", err)
	}
	goal, err := svc.CreateGoal(ctx, user.ID, service.CreateGoalInput{
		Title: "Emergency Fund", TargetAmount: 5000000, Priority: "urgent",
	})
	if err != nil {
		t.Fatalf("CreateGoal: %v", err)
	}

	for _, txType := range []string{"expense", "income"} {
		if _, err := svc.CreateTransaction(ctx, user.ID, service.CreateTransactionInput{
			WalletID:     wallet.ID,
			TargetGoalID: &goal.ID,
			Type:         txType,
			Category:     "Food & Beverage",
			Amount:       25000,
			Title:        "Invalid Goal Attachment",
		}); !errors.Is(err, service.ErrInvalidInput) {
			t.Fatalf("expected ErrInvalidInput when target_goal_id set on %s, got %v", txType, err)
		}
	}

	nilUUID := uuid.Nil
	if _, err := svc.CreateTransaction(ctx, user.ID, service.CreateTransactionInput{
		WalletID:     wallet.ID,
		TargetGoalID: &nilUUID,
		Type:         "transfer",
		Category:     "Incoming Transfer",
		Amount:       25000,
		Title:        "Nil Target Goal",
	}); !errors.Is(err, service.ErrInvalidInput) {
		t.Fatalf("expected ErrInvalidInput when target_goal_id is uuid.Nil, got %v", err)
	}

	if _, err := svc.CreateTransaction(ctx, user.ID, service.CreateTransactionInput{
		WalletID:     wallet.ID,
		TargetGoalID: &goal.ID,
		Type:         "transfer",
		Category:     "Incoming Transfer",
		Amount:       100000,
		Title:        "Valid Goal Transfer",
	}); err != nil {
		t.Fatalf("expected valid transfer with target_goal_id to succeed, got %v", err)
	}
}
