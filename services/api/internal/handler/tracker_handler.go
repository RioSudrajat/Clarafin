package handler

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/clarafin/api/internal/domain"
	"github.com/clarafin/api/internal/middleware"
	"github.com/clarafin/api/internal/service"
)

const maxTrackerJSONBodyBytes = 1 << 20

// TrackerProvider defines the user-scoped service contract consumed by TrackerHandler.
type TrackerProvider interface {
	GetMe(ctx context.Context, userID uuid.UUID) (*service.MeResponse, error)
	UpdateMe(ctx context.Context, userID uuid.UUID, input service.UpdateMeInput) (*service.MeResponse, error)
	ListCategories(ctx context.Context) (*service.CategoriesResponse, error)
	ListWallets(ctx context.Context, userID uuid.UUID) (*service.WalletsResponse, error)
	GetWallet(ctx context.Context, userID, walletID uuid.UUID) (*service.WalletDTO, error)
	CreateWallet(ctx context.Context, userID uuid.UUID, input service.CreateWalletInput) (*service.WalletDTO, error)
	UpdateWallet(ctx context.Context, userID, walletID uuid.UUID, input service.UpdateWalletInput) (*service.WalletDTO, error)
	DeleteWallet(ctx context.Context, userID, walletID uuid.UUID) error
	ListTransactions(ctx context.Context, userID uuid.UUID, filter service.ListTransactionsFilter) (*service.TransactionsResponse, error)
	GetTransaction(ctx context.Context, userID, txID uuid.UUID) (*service.TransactionDTO, error)
	CreateTransaction(ctx context.Context, userID uuid.UUID, input service.CreateTransactionInput) (*service.TransactionMutationResult, error)
	DeleteTransaction(ctx context.Context, userID, txID uuid.UUID) error
	ListPendingAIDrafts(ctx context.Context, userID uuid.UUID) ([]service.AIDraftDTO, error)
	ConfirmAIDraft(ctx context.Context, userID, draftID uuid.UUID, input service.ConfirmAIDraftInput) (*service.TransactionMutationResult, error)
	DiscardAIDraft(ctx context.Context, userID, draftID uuid.UUID) (*service.AIDraftDTO, error)
	GetPlanningSummary(ctx context.Context, userID uuid.UUID, monthYear string) (*service.PlanningSummaryResponse, error)
	ListBudgets(ctx context.Context, userID uuid.UUID, monthYear string) ([]service.BudgetWithSpentDTO, error)
	UpsertBudget(ctx context.Context, userID uuid.UUID, input service.UpsertBudgetInput) (*service.BudgetDTO, error)
	DeleteBudget(ctx context.Context, userID, budgetID uuid.UUID) error
	ListGoals(ctx context.Context, userID uuid.UUID) ([]service.GoalDTO, error)
	CreateGoal(ctx context.Context, userID uuid.UUID, input service.CreateGoalInput) (*service.GoalDTO, error)
	UpdateGoal(ctx context.Context, userID, goalID uuid.UUID, input service.UpdateGoalInput) (*service.GoalDTO, error)
	AddGoalContribution(ctx context.Context, userID, goalID uuid.UUID, input service.AddGoalContributionInput) (*service.GoalContributionResult, error)
	ListBills(ctx context.Context, userID uuid.UUID, isPaidFilter *bool) ([]service.BillDTO, error)
	CreateBill(ctx context.Context, userID uuid.UUID, input service.CreateBillInput) (*service.BillDTO, error)
	UpdateBill(ctx context.Context, userID, billID uuid.UUID, input service.UpdateBillInput) (*service.BillUpdateResult, error)
	DeleteBill(ctx context.Context, userID, billID uuid.UUID) error
	ListNotifications(ctx context.Context, userID uuid.UUID, limit int32) ([]service.NotificationDTO, error)
	MarkAllNotificationsRead(ctx context.Context, userID uuid.UUID) (int64, error)
}

// TrackerHandler serves JWT-authenticated profile, tracker CRUD, planning, and draft confirmation endpoints.
type TrackerHandler struct {
	service    TrackerProvider
	jakartaLoc *time.Location
}

// NewTrackerHandler constructs a TrackerHandler backed by svc.
func NewTrackerHandler(svc TrackerProvider, jakartaLoc *time.Location) *TrackerHandler {
	if jakartaLoc == nil {
		var err error
		jakartaLoc, err = time.LoadLocation("Asia/Jakarta")
		if err != nil {
			jakartaLoc = time.FixedZone("WIB", 7*3600)
		}
	}
	return &TrackerHandler{
		service:    svc,
		jakartaLoc: jakartaLoc,
	}
}

// RegisterRoutes mounts personal finance, profile, planning, and notification routes on r (expected under /v1).
func (h *TrackerHandler) RegisterRoutes(r chi.Router) {
	r.Get("/me", h.GetMe)
	r.Patch("/me", h.UpdateMe)

	r.Get("/categories", h.ListCategories)

	r.Route("/wallets", func(w chi.Router) {
		w.Get("/", h.ListWallets)
		w.Post("/", h.CreateWallet)
		w.Get("/{id}", h.GetWallet)
		w.Patch("/{id}", h.UpdateWallet)
		w.Delete("/{id}", h.DeleteWallet)
	})

	r.Route("/transactions", func(tx chi.Router) {
		tx.Get("/", h.ListTransactions)
		tx.Post("/", h.CreateTransaction)
		tx.Get("/{id}", h.GetTransaction)
		tx.Delete("/{id}", h.DeleteTransaction)
	})

	r.Get("/planning", h.GetPlanningSummary)

	r.Route("/budgets", func(b chi.Router) {
		b.Get("/", h.ListBudgets)
		b.Post("/", h.UpsertBudget)
		b.Delete("/{id}", h.DeleteBudget)
	})

	r.Route("/goals", func(g chi.Router) {
		g.Get("/", h.ListGoals)
		g.Post("/", h.CreateGoal)
		g.Patch("/{id}", h.UpdateGoal)
		g.Post("/{id}/contributions", h.AddGoalContribution)
	})

	r.Route("/bills", func(b chi.Router) {
		b.Get("/", h.ListBills)
		b.Post("/", h.CreateBill)
		b.Patch("/{id}", h.UpdateBill)
		b.Delete("/{id}", h.DeleteBill)
	})

	r.Route("/notifications", func(n chi.Router) {
		n.Get("/", h.ListNotifications)
		n.Post("/read-all", h.MarkAllNotificationsRead)
	})
}

// RegisterAIDraftRoutes mounts /drafts routes inside the /v1/ai group outside LLM rate limiting.
func (h *TrackerHandler) RegisterAIDraftRoutes(aiRouter chi.Router) {
	aiRouter.Route("/drafts", func(d chi.Router) {
		d.Get("/", h.ListPendingAIDrafts)
		d.Post("/{id}/confirm", h.ConfirmAIDraft)
		d.Post("/{id}/discard", h.DiscardAIDraft)
	})
}

// GetMe handles GET /v1/me.
func (h *TrackerHandler) GetMe(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	res, err := h.service.GetMe(r.Context(), userID)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, res, reqID)
}

// UpdateMe handles PATCH /v1/me.
func (h *TrackerHandler) UpdateMe(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	var body service.UpdateMeInput
	if !decodeStrictJSON(w, r, reqID, false, &body) {
		return
	}
	res, err := h.service.UpdateMe(r.Context(), userID, body)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, res, reqID)
}

// ListCategories handles GET /v1/categories.
func (h *TrackerHandler) ListCategories(w http.ResponseWriter, r *http.Request) {
	_, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	res, err := h.service.ListCategories(r.Context())
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, res, reqID)
}

// ListWallets handles GET /v1/wallets.
func (h *TrackerHandler) ListWallets(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	res, err := h.service.ListWallets(r.Context(), userID)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, res, reqID)
}

// GetWallet handles GET /v1/wallets/{id}.
func (h *TrackerHandler) GetWallet(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	walletID, ok := parseUUIDPathParam(w, r, reqID, "id")
	if !ok {
		return
	}
	res, err := h.service.GetWallet(r.Context(), userID, walletID)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, res, reqID)
}

// CreateWallet handles POST /v1/wallets.
func (h *TrackerHandler) CreateWallet(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	var body service.CreateWalletInput
	if !decodeStrictJSON(w, r, reqID, false, &body) {
		return
	}
	res, err := h.service.CreateWallet(r.Context(), userID, body)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusCreated, res, reqID)
}

// UpdateWallet handles PATCH /v1/wallets/{id}.
func (h *TrackerHandler) UpdateWallet(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	walletID, ok := parseUUIDPathParam(w, r, reqID, "id")
	if !ok {
		return
	}
	var body service.UpdateWalletInput
	if !decodeStrictJSON(w, r, reqID, false, &body) {
		return
	}
	res, err := h.service.UpdateWallet(r.Context(), userID, walletID, body)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, res, reqID)
}

// DeleteWallet handles DELETE /v1/wallets/{id}.
func (h *TrackerHandler) DeleteWallet(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	walletID, ok := parseUUIDPathParam(w, r, reqID, "id")
	if !ok {
		return
	}
	if err := h.service.DeleteWallet(r.Context(), userID, walletID); err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, map[string]bool{"deleted": true}, reqID)
}

// ListTransactions handles GET /v1/transactions.
func (h *TrackerHandler) ListTransactions(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}

	q := r.URL.Query()
	var filter service.ListTransactionsFilter

	if rawWallet := strings.TrimSpace(q.Get("wallet_id")); rawWallet != "" {
		parsed, err := uuid.Parse(rawWallet)
		if err != nil || parsed == uuid.Nil {
			domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Invalid wallet_id query parameter.", reqID)
			return
		}
		filter.WalletID = &parsed
	}
	if rawType := strings.TrimSpace(q.Get("type")); rawType != "" {
		filter.Type = &rawType
	}
	if rawCat := strings.TrimSpace(q.Get("category")); rawCat != "" {
		filter.Category = &rawCat
	}
	if rawKw := strings.TrimSpace(q.Get("keyword")); rawKw != "" {
		filter.Keyword = &rawKw
	}
	if rawFrom := strings.TrimSpace(q.Get("date_from")); rawFrom != "" {
		t, err := parseQueryTimestamp(rawFrom, h.jakartaLoc)
		if err != nil {
			domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Invalid date_from timestamp.", reqID)
			return
		}
		filter.DateFrom = &t
	}
	if rawTo := strings.TrimSpace(q.Get("date_to")); rawTo != "" {
		t, err := parseQueryTimestamp(rawTo, h.jakartaLoc)
		if err != nil {
			domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Invalid date_to timestamp.", reqID)
			return
		}
		filter.DateTo = &t
	}
	if rawLimit := strings.TrimSpace(q.Get("limit")); rawLimit != "" {
		v, err := parseInt32QueryParam(rawLimit, 1)
		if err != nil {
			domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Invalid limit parameter.", reqID)
			return
		}
		filter.Limit = v
	}
	if rawOffset := strings.TrimSpace(q.Get("offset")); rawOffset != "" {
		v, err := parseInt32QueryParam(rawOffset, 0)
		if err != nil {
			domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Invalid offset parameter.", reqID)
			return
		}
		filter.Offset = v
	}

	res, err := h.service.ListTransactions(r.Context(), userID, filter)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, res, reqID)
}

// GetTransaction handles GET /v1/transactions/{id}.
func (h *TrackerHandler) GetTransaction(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	txID, ok := parseUUIDPathParam(w, r, reqID, "id")
	if !ok {
		return
	}
	res, err := h.service.GetTransaction(r.Context(), userID, txID)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, res, reqID)
}

// CreateTransaction handles POST /v1/transactions with atomic balance updates and client_mutation_id idempotency.
func (h *TrackerHandler) CreateTransaction(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	var body service.CreateTransactionInput
	if !decodeStrictJSON(w, r, reqID, false, &body) {
		return
	}
	res, err := h.service.CreateTransaction(r.Context(), userID, body)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	status := http.StatusCreated
	if res.IdempotentReplay {
		status = http.StatusOK
	}
	domain.WriteJSON(w, status, res, reqID)
}

// DeleteTransaction handles DELETE /v1/transactions/{id} with atomic balance reversal.
func (h *TrackerHandler) DeleteTransaction(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	txID, ok := parseUUIDPathParam(w, r, reqID, "id")
	if !ok {
		return
	}
	if err := h.service.DeleteTransaction(r.Context(), userID, txID); err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, map[string]bool{"deleted": true}, reqID)
}

// ListPendingAIDrafts handles GET /v1/ai/drafts.
func (h *TrackerHandler) ListPendingAIDrafts(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	items, err := h.service.ListPendingAIDrafts(r.Context(), userID)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, map[string]any{"drafts": items}, reqID)
}

// ConfirmAIDraft handles POST /v1/ai/drafts/{id}/confirm.
func (h *TrackerHandler) ConfirmAIDraft(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	draftID, ok := parseUUIDPathParam(w, r, reqID, "id")
	if !ok {
		return
	}
	var body service.ConfirmAIDraftInput
	if !decodeStrictJSON(w, r, reqID, true, &body) {
		return
	}
	res, err := h.service.ConfirmAIDraft(r.Context(), userID, draftID, body)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, res, reqID)
}

// DiscardAIDraft handles POST /v1/ai/drafts/{id}/discard.
func (h *TrackerHandler) DiscardAIDraft(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	draftID, ok := parseUUIDPathParam(w, r, reqID, "id")
	if !ok {
		return
	}
	res, err := h.service.DiscardAIDraft(r.Context(), userID, draftID)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, res, reqID)
}

// GetPlanningSummary handles GET /v1/planning.
func (h *TrackerHandler) GetPlanningSummary(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	monthYear := strings.TrimSpace(r.URL.Query().Get("month_year"))
	res, err := h.service.GetPlanningSummary(r.Context(), userID, monthYear)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, res, reqID)
}

// ListBudgets handles GET /v1/budgets.
func (h *TrackerHandler) ListBudgets(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	monthYear := strings.TrimSpace(r.URL.Query().Get("month_year"))
	items, err := h.service.ListBudgets(r.Context(), userID, monthYear)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, map[string]any{"budgets": items}, reqID)
}

// UpsertBudget handles POST /v1/budgets.
func (h *TrackerHandler) UpsertBudget(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	var body service.UpsertBudgetInput
	if !decodeStrictJSON(w, r, reqID, false, &body) {
		return
	}
	res, err := h.service.UpsertBudget(r.Context(), userID, body)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, res, reqID)
}

// DeleteBudget handles DELETE /v1/budgets/{id}.
func (h *TrackerHandler) DeleteBudget(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	budgetID, ok := parseUUIDPathParam(w, r, reqID, "id")
	if !ok {
		return
	}
	if err := h.service.DeleteBudget(r.Context(), userID, budgetID); err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, map[string]bool{"deleted": true}, reqID)
}

// ListGoals handles GET /v1/goals.
func (h *TrackerHandler) ListGoals(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	items, err := h.service.ListGoals(r.Context(), userID)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, map[string]any{"goals": items}, reqID)
}

// CreateGoal handles POST /v1/goals.
func (h *TrackerHandler) CreateGoal(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	var body service.CreateGoalInput
	if !decodeStrictJSON(w, r, reqID, false, &body) {
		return
	}
	res, err := h.service.CreateGoal(r.Context(), userID, body)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusCreated, res, reqID)
}

// UpdateGoal handles PATCH /v1/goals/{id}.
func (h *TrackerHandler) UpdateGoal(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	goalID, ok := parseUUIDPathParam(w, r, reqID, "id")
	if !ok {
		return
	}
	var body service.UpdateGoalInput
	if !decodeStrictJSON(w, r, reqID, false, &body) {
		return
	}
	res, err := h.service.UpdateGoal(r.Context(), userID, goalID, body)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, res, reqID)
}

// AddGoalContribution handles POST /v1/goals/{id}/contributions.
func (h *TrackerHandler) AddGoalContribution(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	goalID, ok := parseUUIDPathParam(w, r, reqID, "id")
	if !ok {
		return
	}
	var body service.AddGoalContributionInput
	if !decodeStrictJSON(w, r, reqID, false, &body) {
		return
	}
	res, err := h.service.AddGoalContribution(r.Context(), userID, goalID, body)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, res, reqID)
}

// ListBills handles GET /v1/bills.
func (h *TrackerHandler) ListBills(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	var isPaidFilter *bool
	if raw := strings.TrimSpace(r.URL.Query().Get("is_paid")); raw != "" {
		v, err := strconv.ParseBool(raw)
		if err != nil {
			domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Invalid is_paid query parameter.", reqID)
			return
		}
		isPaidFilter = &v
	}
	items, err := h.service.ListBills(r.Context(), userID, isPaidFilter)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, map[string]any{"bills": items}, reqID)
}

// CreateBill handles POST /v1/bills.
func (h *TrackerHandler) CreateBill(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	var body service.CreateBillInput
	if !decodeStrictJSON(w, r, reqID, false, &body) {
		return
	}
	res, err := h.service.CreateBill(r.Context(), userID, body)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusCreated, res, reqID)
}

// UpdateBill handles PATCH /v1/bills/{id}.
func (h *TrackerHandler) UpdateBill(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	billID, ok := parseUUIDPathParam(w, r, reqID, "id")
	if !ok {
		return
	}
	var body service.UpdateBillInput
	if !decodeStrictJSON(w, r, reqID, false, &body) {
		return
	}
	res, err := h.service.UpdateBill(r.Context(), userID, billID, body)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, res, reqID)
}

// DeleteBill handles DELETE /v1/bills/{id}.
func (h *TrackerHandler) DeleteBill(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	billID, ok := parseUUIDPathParam(w, r, reqID, "id")
	if !ok {
		return
	}
	if err := h.service.DeleteBill(r.Context(), userID, billID); err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, map[string]bool{"deleted": true}, reqID)
}

// ListNotifications handles GET /v1/notifications.
func (h *TrackerHandler) ListNotifications(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	var limit int32 = 50
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		v, err := parseInt32QueryParam(raw, 1)
		if err != nil {
			domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Invalid limit parameter.", reqID)
			return
		}
		limit = v
	}
	items, err := h.service.ListNotifications(r.Context(), userID, limit)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, map[string]any{"notifications": items}, reqID)
}

// MarkAllNotificationsRead handles POST /v1/notifications/read-all.
func (h *TrackerHandler) MarkAllNotificationsRead(w http.ResponseWriter, r *http.Request) {
	userID, reqID, ok := h.requireContext(w, r)
	if !ok {
		return
	}
	count, err := h.service.MarkAllNotificationsRead(r.Context(), userID)
	if err != nil {
		writeTrackerServiceError(w, reqID, err)
		return
	}
	domain.WriteJSON(w, http.StatusOK, map[string]int64{"marked_read_count": count}, reqID)
}

func (h *TrackerHandler) requireContext(w http.ResponseWriter, r *http.Request) (uuid.UUID, string, bool) {
	reqID := middleware.RequestIDFromContext(r.Context())
	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		domain.WriteError(w, http.StatusUnauthorized, domain.ErrCodeUnauthorized, "Authentication required.", reqID)
		return uuid.Nil, reqID, false
	}
	if h == nil || h.service == nil {
		domain.WriteError(w, http.StatusInternalServerError, domain.ErrCodeInternalError, "Tracker service is not initialized.", reqID)
		return uuid.Nil, reqID, false
	}
	return userID, reqID, true
}

func parseUUIDPathParam(w http.ResponseWriter, r *http.Request, reqID, param string) (uuid.UUID, bool) {
	raw := strings.TrimSpace(chi.URLParam(r, param))
	if raw == "" {
		domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Missing resource identifier.", reqID)
		return uuid.Nil, false
	}
	id, err := uuid.Parse(raw)
	if err != nil || id == uuid.Nil {
		domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Invalid resource UUID.", reqID)
		return uuid.Nil, false
	}
	return id, true
}

func decodeStrictJSON(w http.ResponseWriter, r *http.Request, reqID string, allowEmpty bool, dst any) bool {
	if r.Body == nil {
		if allowEmpty {
			return true
		}
		domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Request body is required.", reqID)
		return false
	}

	limited := http.MaxBytesReader(w, r.Body, maxTrackerJSONBodyBytes)
	dec := json.NewDecoder(limited)
	dec.DisallowUnknownFields()

	if err := dec.Decode(dst); err != nil {
		if errors.Is(err, io.EOF) && allowEmpty {
			return true
		}
		var maxErr *http.MaxBytesError
		if errors.As(err, &maxErr) {
			domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Request body exceeds maximum allowed size.", reqID)
			return false
		}
		domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Invalid JSON request body.", reqID)
		return false
	}

	if err := dec.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Request body must contain a single JSON object.", reqID)
		return false
	}
	return true
}

func writeTrackerServiceError(w http.ResponseWriter, reqID string, err error) {
	switch {
	case errors.Is(err, service.ErrInvalidInput), errors.Is(err, service.ErrInvalidQuotaRequest):
		domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Invalid request parameters.", reqID)
	case errors.Is(err, service.ErrNotFound), errors.Is(err, service.ErrUserNotFound):
		domain.WriteError(w, http.StatusNotFound, domain.ErrCodeNotFound, "Requested resource was not found.", reqID)
	case errors.Is(err, service.ErrConflict):
		domain.WriteError(w, http.StatusConflict, domain.ErrCodeConflict, "Request conflicts with the current resource state.", reqID)
	default:
		domain.WriteError(w, http.StatusInternalServerError, domain.ErrCodeInternalError, "Failed to process tracker request.", reqID)
	}
}

func parseQueryTimestamp(raw string, loc *time.Location) (time.Time, error) {
	if t, err := time.Parse(time.RFC3339, raw); err == nil {
		return t, nil
	}
	if t, err := time.ParseInLocation("2006-01-02", raw, loc); err == nil {
		return t, nil
	}
	return time.Time{}, errors.New("invalid timestamp")
}

func parseInt32QueryParam(raw string, minVal int64) (int32, error) {
	v, err := strconv.ParseInt(raw, 10, 32)
	if err != nil || v < minVal {
		return 0, errors.New("invalid integer query parameter")
	}
	return int32(v), nil
}
