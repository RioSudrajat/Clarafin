package handler_test

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/clarafin/api/internal/domain"
	"github.com/clarafin/api/internal/handler"
	"github.com/clarafin/api/internal/middleware"
	"github.com/clarafin/api/internal/repository"
	"github.com/clarafin/api/internal/service"
)

func createTempHandlerUser(t *testing.T, ctx context.Context, store *repository.Store, label string) repository.User {
	t.Helper()

	userID := uuid.New()
	email := fmt.Sprintf("tracker-hdl-%s-%s@clarafin.test", label, userID.String()[:8])
	user, err := store.EnsureDevUserAccount(ctx, repository.EnsureDevUserParams{
		ID:       userID,
		Email:    email,
		FullName: "Handler " + label,
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

func newTestTrackerRouter(store *repository.Store) http.Handler {
	wib := time.FixedZone("WIB", 7*3600)
	quotaSvc := service.NewQuotaService(store, service.WithJakartaLocation(wib))
	trackerSvc := service.NewTrackerService(
		store,
		service.WithTrackerJakartaLocation(wib),
		service.WithTrackerQuotaProvider(quotaSvc),
	)
	h := handler.NewTrackerHandler(trackerSvc, wib)

	r := chi.NewRouter()
	r.Use(middleware.RequestID)
	r.Route("/v1", func(v1 chi.Router) {
		v1.Route("/ai", func(ai chi.Router) {
			h.RegisterAIDraftRoutes(ai)
		})
		h.RegisterRoutes(v1)
	})
	return r
}

func doTrackerReq(r http.Handler, userID uuid.UUID, method, path, body string) *httptest.ResponseRecorder {
	var bodyReader *bytes.Buffer
	if body != "" {
		bodyReader = bytes.NewBufferString(body)
	} else {
		bodyReader = bytes.NewBuffer(nil)
	}
	req := httptest.NewRequest(method, path, bodyReader)
	if body != "" {
		req.Header.Set("Content-Type", "application/json")
	}
	if userID != uuid.Nil {
		req = req.WithContext(middleware.ContextWithUserID(req.Context(), userID))
	}
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)
	return rec
}

func TestTrackerHandler_AuthAndStrictJSONValidation(t *testing.T) {
	store, _ := openTestStore(t)
	r := newTestTrackerRouter(store)
	userID := uuid.New()

	// Unauthenticated request returns 401.
	recNoAuth := doTrackerReq(r, uuid.Nil, http.MethodGet, "/v1/wallets", "")
	if recNoAuth.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 without auth context, got %d", recNoAuth.Code)
	}

	// Unknown JSON field rejected with 400 INVALID_REQUEST.
	recUnknown := doTrackerReq(r, userID, http.MethodPost, "/v1/wallets", `{"name":"BCA","type":"bank","evil_field":true}`)
	if recUnknown.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for unknown field, got %d (body: %s)", recUnknown.Code, recUnknown.Body.String())
	}

	// Trailing JSON token rejected with 400.
	recTrailing := doTrackerReq(r, userID, http.MethodPost, "/v1/wallets", `{"name":"BCA","type":"bank"}{"extra":1}`)
	if recTrailing.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for trailing JSON, got %d", recTrailing.Code)
	}

	// Oversized JSON payload (> 1MB) rejected with 400.
	oversized := `{"name":"` + strings.Repeat("a", (1<<20)+16) + `","type":"bank"}`
	recLarge := doTrackerReq(r, userID, http.MethodPost, "/v1/wallets", oversized)
	if recLarge.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for oversized body, got %d", recLarge.Code)
	}

	// Invalid UUID path parameter returns 400.
	recBadUUID := doTrackerReq(r, userID, http.MethodGet, "/v1/wallets/not-a-uuid", "")
	if recBadUUID.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for invalid UUID, got %d", recBadUUID.Code)
	}
}

func TestTrackerHandler_EndToEndCRUDIdempotencyAndConflictMapping(t *testing.T) {
	store, ctx := openTestStore(t)
	userA := createTempHandlerUser(t, ctx, store, "a")
	userB := createTempHandlerUser(t, ctx, store, "b")
	r := newTestTrackerRouter(store)

	// 1. /v1/me GET + PATCH + /v1/categories GET.
	recMe := doTrackerReq(r, userA.ID, http.MethodGet, "/v1/me", "")
	if recMe.Code != http.StatusOK {
		t.Fatalf("GET /v1/me = %d (%s)", recMe.Code, recMe.Body.String())
	}
	recPatchMe := doTrackerReq(r, userA.ID, http.MethodPatch, "/v1/me", `{"full_name":"Rina Updated","onboarding_completed":true,"preferred_currency":"IDR"}`)
	if recPatchMe.Code != http.StatusOK {
		t.Fatalf("PATCH /v1/me = %d (%s)", recPatchMe.Code, recPatchMe.Body.String())
	}
	recCats := doTrackerReq(r, userA.ID, http.MethodGet, "/v1/categories", "")
	if recCats.Code != http.StatusOK {
		t.Fatalf("GET /v1/categories = %d (%s)", recCats.Code, recCats.Body.String())
	}
	var catsEnv struct {
		Data service.CategoriesResponse `json:"data"`
	}
	if err := json.Unmarshal(recCats.Body.Bytes(), &catsEnv); err != nil || catsEnv.Data.Total != 105 {
		t.Fatalf("expected 105 categories, got total=%d err=%v", catsEnv.Data.Total, err)
	}

	// 2. Wallets POST -> GET -> PATCH -> DELETE (unused vs FK conflict).
	recW1 := doTrackerReq(r, userA.ID, http.MethodPost, "/v1/wallets", `{"name":"BCA","type":"bank","balance":1000000}`)
	if recW1.Code != http.StatusCreated {
		t.Fatalf("POST /v1/wallets = %d (%s)", recW1.Code, recW1.Body.String())
	}
	var w1Env struct {
		Data service.WalletDTO `json:"data"`
	}
	if err := json.Unmarshal(recW1.Body.Bytes(), &w1Env); err != nil {
		t.Fatalf("unmarshal wallet: %v", err)
	}
	walletA1 := w1Env.Data

	recW2 := doTrackerReq(r, userA.ID, http.MethodPost, "/v1/wallets", `{"name":"Temp Wallet","type":"cash","balance":50000}`)
	if recW2.Code != http.StatusCreated {
		t.Fatalf("POST /v1/wallets #2 = %d", recW2.Code)
	}
	var w2Env struct {
		Data service.WalletDTO `json:"data"`
	}
	_ = json.Unmarshal(recW2.Body.Bytes(), &w2Env)
	if recDelUnused := doTrackerReq(r, userA.ID, http.MethodDelete, "/v1/wallets/"+w2Env.Data.ID.String(), ""); recDelUnused.Code != http.StatusOK {
		t.Fatalf("expected 200 deleting unused wallet, got %d (%s)", recDelUnused.Code, recDelUnused.Body.String())
	}

	// Cross-user GET wallet returns 404.
	if recCrossW := doTrackerReq(r, userB.ID, http.MethodGet, "/v1/wallets/"+walletA1.ID.String(), ""); recCrossW.Code != http.StatusNotFound {
		t.Fatalf("expected 404 on cross-user GET wallet, got %d", recCrossW.Code)
	}

	// 3. Transactions POST idempotency + validation + FK conflict on wallet delete.
	mutID := "hdl_mut_" + uuid.NewString()
	txPayload := fmt.Sprintf(`{"wallet_id":"%s","type":"expense","category":"Food & Beverage","amount":75000,"title":"Nasi Goreng","client_mutation_id":"%s"}`, walletA1.ID, mutID)

	recTx1 := doTrackerReq(r, userA.ID, http.MethodPost, "/v1/transactions", txPayload)
	if recTx1.Code != http.StatusCreated {
		t.Fatalf("first POST /v1/transactions = %d (%s)", recTx1.Code, recTx1.Body.String())
	}
	var txRes1 struct {
		Data service.TransactionMutationResult `json:"data"`
	}
	_ = json.Unmarshal(recTx1.Body.Bytes(), &txRes1)
	if txRes1.Data.IdempotentReplay || txRes1.Data.WalletBalanceIDR != 925000 {
		t.Fatalf("unexpected first tx result: %+v", txRes1.Data)
	}

	// Replay returns 200 with idempotent_replay=true and identical wallet balance 925000.
	recTx2 := doTrackerReq(r, userA.ID, http.MethodPost, "/v1/transactions", txPayload)
	if recTx2.Code != http.StatusOK {
		t.Fatalf("duplicate POST /v1/transactions = %d (%s)", recTx2.Code, recTx2.Body.String())
	}
	var txRes2 struct {
		Data service.TransactionMutationResult `json:"data"`
	}
	_ = json.Unmarshal(recTx2.Body.Bytes(), &txRes2)
	if !txRes2.Data.IdempotentReplay || txRes2.Data.WalletBalanceIDR != 925000 {
		t.Fatalf("unexpected replay tx result: %+v", txRes2.Data)
	}

	// Invalid transfer (same source & destination) returns 400 INVALID_REQUEST.
	badTransfer := fmt.Sprintf(`{"wallet_id":"%s","destination_wallet_id":"%s","type":"transfer","category":"Transfer","amount":10000,"title":"Self"}`, walletA1.ID, walletA1.ID)
	if recBadTrf := doTrackerReq(r, userA.ID, http.MethodPost, "/v1/transactions", badTransfer); recBadTrf.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for same-wallet transfer, got %d", recBadTrf.Code)
	}

	// Expense exceeding wallet balance returns 400 INSUFFICIENT_BALANCE.
	overdraftExpense := fmt.Sprintf(`{"wallet_id":"%s","type":"expense","category":"Shopping","amount":9999999,"title":"Overdraft","source":"manual","client_mutation_id":"handler-over-1"}`, walletA1.ID)
	recOverdraft := doTrackerReq(r, userA.ID, http.MethodPost, "/v1/transactions", overdraftExpense)
	if recOverdraft.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for overdraft expense, got %d (%s)", recOverdraft.Code, recOverdraft.Body.String())
	}
	var overdraftEnv struct {
		Error domain.ErrorDetail `json:"error"`
	}
	_ = json.Unmarshal(recOverdraft.Body.Bytes(), &overdraftEnv)
	if overdraftEnv.Error.Code != domain.ErrCodeInsufficientBalance {
		t.Fatalf("expected error code INSUFFICIENT_BALANCE, got %q", overdraftEnv.Error.Code)
	}

	// Deleting wallet referenced by transaction returns 409 CONFLICT.
	recDelUsed := doTrackerReq(r, userA.ID, http.MethodDelete, "/v1/wallets/"+walletA1.ID.String(), "")
	if recDelUsed.Code != http.StatusConflict {
		t.Fatalf("expected 409 deleting referenced wallet, got %d (%s)", recDelUsed.Code, recDelUsed.Body.String())
	}
	var conflictEnv struct {
		Error domain.ErrorDetail `json:"error"`
	}
	_ = json.Unmarshal(recDelUsed.Body.Bytes(), &conflictEnv)
	if conflictEnv.Error.Code != domain.ErrCodeConflict {
		t.Fatalf("expected error code CONFLICT, got %q", conflictEnv.Error.Code)
	}

	// 4. AI Draft confirm & duplicate confirm -> 409 CONFLICT, plus discard.
	draftConfirm, err := store.CreateAIDraft(ctx, repository.CreateAIDraftParams{
		UserID: userA.ID, WalletID: &walletA1.ID, Source: "ai_text", Type: "expense",
		Category: "Food & Beverage • Coffee Shop", Amount: 25000, Title: "Kopi Tuku",
		MerchantOrNote: "es kopi", OccurredAt: time.Now().UTC(), ConfidenceScore: 0.92,
	})
	if err != nil {
		t.Fatalf("seed draftConfirm: %v", err)
	}
	draftDiscard, err := store.CreateAIDraft(ctx, repository.CreateAIDraftParams{
		UserID: userA.ID, WalletID: &walletA1.ID, Source: "ai_text", Type: "expense",
		Category: "Shopping", Amount: 99000, Title: "Discard Me",
		MerchantOrNote: "test", OccurredAt: time.Now().UTC(), ConfidenceScore: 0.85,
	})
	if err != nil {
		t.Fatalf("seed draftDiscard: %v", err)
	}

	if recListDrafts := doTrackerReq(r, userA.ID, http.MethodGet, "/v1/ai/drafts", ""); recListDrafts.Code != http.StatusOK {
		t.Fatalf("GET /v1/ai/drafts = %d", recListDrafts.Code)
	}
	if recConfirm := doTrackerReq(r, userA.ID, http.MethodPost, "/v1/ai/drafts/"+draftConfirm.ID.String()+"/confirm", `{}`); recConfirm.Code != http.StatusOK {
		t.Fatalf("POST confirm = %d (%s)", recConfirm.Code, recConfirm.Body.String())
	}
	if recDupConfirm := doTrackerReq(r, userA.ID, http.MethodPost, "/v1/ai/drafts/"+draftConfirm.ID.String()+"/confirm", `{}`); recDupConfirm.Code != http.StatusConflict {
		t.Fatalf("expected 409 on duplicate confirm, got %d (%s)", recDupConfirm.Code, recDupConfirm.Body.String())
	}
	if recDiscard := doTrackerReq(r, userA.ID, http.MethodPost, "/v1/ai/drafts/"+draftDiscard.ID.String()+"/discard", ""); recDiscard.Code != http.StatusOK {
		t.Fatalf("POST discard = %d (%s)", recDiscard.Code, recDiscard.Body.String())
	}
	if recConfirmDiscarded := doTrackerReq(r, userA.ID, http.MethodPost, "/v1/ai/drafts/"+draftDiscard.ID.String()+"/confirm", `{}`); recConfirmDiscarded.Code != http.StatusConflict {
		t.Fatalf("expected 409 confirming discarded draft, got %d", recConfirmDiscarded.Code)
	}

	// 5. Budgets, Goals + Contributions, Bills, Planning, Notifications.
	recBudget := doTrackerReq(r, userA.ID, http.MethodPost, "/v1/budgets", `{"category":"Food & Beverage","month_year":"2026-11","limit_amount":1500000}`)
	if recBudget.Code != http.StatusOK {
		t.Fatalf("POST /v1/budgets = %d (%s)", recBudget.Code, recBudget.Body.String())
	}

	recGoal := doTrackerReq(r, userA.ID, http.MethodPost, "/v1/goals", fmt.Sprintf(`{"linked_wallet_id":"%s","title":"Dana Darurat","target_amount":5000000,"priority":"urgent"}`, walletA1.ID))
	if recGoal.Code != http.StatusCreated {
		t.Fatalf("POST /v1/goals = %d (%s)", recGoal.Code, recGoal.Body.String())
	}
	var goalEnv struct {
		Data service.GoalDTO `json:"data"`
	}
	_ = json.Unmarshal(recGoal.Body.Bytes(), &goalEnv)

	recContrib := doTrackerReq(r, userA.ID, http.MethodPost, "/v1/goals/"+goalEnv.Data.ID.String()+"/contributions", fmt.Sprintf(`{"wallet_id":"%s","amount":100000}`, walletA1.ID))
	if recContrib.Code != http.StatusOK {
		t.Fatalf("POST /v1/goals/{id}/contributions = %d (%s)", recContrib.Code, recContrib.Body.String())
	}

	recBill := doTrackerReq(r, userA.ID, http.MethodPost, "/v1/bills", `{"title":"Listrik PLN","category":"Bills & Utilities","amount":200000,"frequency":"monthly"}`)
	if recBill.Code != http.StatusCreated {
		t.Fatalf("POST /v1/bills = %d (%s)", recBill.Code, recBill.Body.String())
	}
	var billEnv struct {
		Data service.BillDTO `json:"data"`
	}
	_ = json.Unmarshal(recBill.Body.Bytes(), &billEnv)

	recPayBill := doTrackerReq(r, userA.ID, http.MethodPatch, "/v1/bills/"+billEnv.Data.ID.String(), fmt.Sprintf(`{"is_paid":true,"wallet_id":"%s"}`, walletA1.ID))
	if recPayBill.Code != http.StatusOK {
		t.Fatalf("PATCH /v1/bills/{id} = %d (%s)", recPayBill.Code, recPayBill.Body.String())
	}

	if recPlan := doTrackerReq(r, userA.ID, http.MethodGet, "/v1/planning?month_year=2026-11", ""); recPlan.Code != http.StatusOK {
		t.Fatalf("GET /v1/planning = %d (%s)", recPlan.Code, recPlan.Body.String())
	}
	if recNotifs := doTrackerReq(r, userA.ID, http.MethodGet, "/v1/notifications", ""); recNotifs.Code != http.StatusOK {
		t.Fatalf("GET /v1/notifications = %d (%s)", recNotifs.Code, recNotifs.Body.String())
	}
	if recReadAll := doTrackerReq(r, userA.ID, http.MethodPost, "/v1/notifications/read-all", ""); recReadAll.Code != http.StatusOK {
		t.Fatalf("POST /v1/notifications/read-all = %d (%s)", recReadAll.Code, recReadAll.Body.String())
	}

	// Verify final wallet balance: 1,000,000 - 75,000 (tx) - 25,000 (draft) - 100,000 (goal) - 200,000 (bill) = 600,000.
	recWalletFinal := doTrackerReq(r, userA.ID, http.MethodGet, "/v1/wallets/"+walletA1.ID.String(), "")
	var finalW struct {
		Data service.WalletDTO `json:"data"`
	}
	_ = json.Unmarshal(recWalletFinal.Body.Bytes(), &finalW)
	if finalW.Data.Balance != 600000 {
		t.Fatalf("expected final wallet balance 600000, got %d", finalW.Data.Balance)
	}

	// Duplicate bill pay without client_mutation_id returns 409 CONFLICT.
	if recDupBill := doTrackerReq(r, userA.ID, http.MethodPatch, "/v1/bills/"+billEnv.Data.ID.String(), fmt.Sprintf(`{"is_paid":true,"wallet_id":"%s"}`, walletA1.ID)); recDupBill.Code != http.StatusConflict {
		t.Fatalf("expected 409 on duplicate bill pay without client_mutation_id, got %d (%s)", recDupBill.Code, recDupBill.Body.String())
	}

	// Sequential bill-pay idempotent replay returns 200 with wallet_balance_idr populated and balance untouched.
	recBill2 := doTrackerReq(r, userA.ID, http.MethodPost, "/v1/bills", `{"title":"Air PDAM","category":"Bills & Utilities","amount":100000,"frequency":"monthly"}`)
	if recBill2.Code != http.StatusCreated {
		t.Fatalf("POST /v1/bills #2 = %d", recBill2.Code)
	}
	var bill2Env struct {
		Data service.BillDTO `json:"data"`
	}
	_ = json.Unmarshal(recBill2.Body.Bytes(), &bill2Env)
	billPayMut := "hdl_bill_mut_" + uuid.NewString()
	billPayBody := fmt.Sprintf(`{"is_paid":true,"wallet_id":"%s","client_mutation_id":"%s"}`, walletA1.ID, billPayMut)

	recBill2Pay1 := doTrackerReq(r, userA.ID, http.MethodPatch, "/v1/bills/"+bill2Env.Data.ID.String(), billPayBody)
	if recBill2Pay1.Code != http.StatusOK {
		t.Fatalf("first PATCH bill pay = %d (%s)", recBill2Pay1.Code, recBill2Pay1.Body.String())
	}
	recBill2Pay2 := doTrackerReq(r, userA.ID, http.MethodPatch, "/v1/bills/"+bill2Env.Data.ID.String(), billPayBody)
	if recBill2Pay2.Code != http.StatusOK {
		t.Fatalf("replay PATCH bill pay = %d (%s)", recBill2Pay2.Code, recBill2Pay2.Body.String())
	}
	var billReplayEnv struct {
		Data service.BillUpdateResult `json:"data"`
	}
	_ = json.Unmarshal(recBill2Pay2.Body.Bytes(), &billReplayEnv)
	if !billReplayEnv.Data.IdempotentReplay || billReplayEnv.Data.WalletBalanceIDR == nil || *billReplayEnv.Data.WalletBalanceIDR != 500000 {
		t.Fatalf("expected bill replay with wallet_balance_idr=500000, got %+v", billReplayEnv.Data)
	}

	// target_goal_id validation on non-transfer or nil UUID returns 400 INVALID_REQUEST.
	badGoalExpense := fmt.Sprintf(`{"wallet_id":"%s","target_goal_id":"%s","type":"expense","category":"Food & Beverage","amount":10000,"title":"Bad"}`, walletA1.ID, goalEnv.Data.ID)
	if recBadGoal := doTrackerReq(r, userA.ID, http.MethodPost, "/v1/transactions", badGoalExpense); recBadGoal.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for target_goal_id on expense, got %d (%s)", recBadGoal.Code, recBadGoal.Body.String())
	}
	badGoalNil := fmt.Sprintf(`{"wallet_id":"%s","target_goal_id":"00000000-0000-0000-0000-000000000000","type":"transfer","category":"Incoming Transfer","amount":10000,"title":"Nil"}`, walletA1.ID)
	if recNilGoal := doTrackerReq(r, userA.ID, http.MethodPost, "/v1/transactions", badGoalNil); recNilGoal.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for nil target_goal_id, got %d (%s)", recNilGoal.Code, recNilGoal.Body.String())
	}
}

func TestTrackerHandler_PaginationInt32OverflowValidation(t *testing.T) {
	store, _ := openTestStore(t)
	r := newTestTrackerRouter(store)
	userID := uuid.New()

	invalidQueries := []string{
		"/v1/transactions?limit=4294967297",
		"/v1/transactions?limit=9999999999",
		"/v1/transactions?limit=0",
		"/v1/transactions?limit=-5",
		"/v1/transactions?offset=4294967297",
		"/v1/transactions?offset=-1",
		"/v1/notifications?limit=4294967297",
		"/v1/notifications?limit=0",
		"/v1/notifications?limit=-10",
	}

	for _, path := range invalidQueries {
		rec := doTrackerReq(r, userID, http.MethodGet, path, "")
		if rec.Code != http.StatusBadRequest {
			t.Fatalf("GET %s expected 400 INVALID_REQUEST, got %d (body: %s)", path, rec.Code, rec.Body.String())
		}
		var env struct {
			Error domain.ErrorDetail `json:"error"`
		}
		if err := json.Unmarshal(rec.Body.Bytes(), &env); err != nil {
			t.Fatalf("unmarshal error for %s: %v", path, err)
		}
		if env.Error.Code != domain.ErrCodeInvalidRequest {
			t.Fatalf("GET %s expected code INVALID_REQUEST, got %q", path, env.Error.Code)
		}
	}
}
