package ai

import (
	"context"
	"errors"
	"fmt"
	"math"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/clarafin/api/internal/repository"
)

// ErrInvalidFinancialToolInput indicates invalid period, group_by, or user_id passed to a financial tool.
var ErrInvalidFinancialToolInput = errors.New("invalid financial tool input")

// FinancialToolOption customizes FinancialTools clocks or timezone behavior.
type FinancialToolOption func(*FinancialTools)

// WithFinancialNowFunc overrides the clock source used for relative period resolution.
func WithFinancialNowFunc(fn func() time.Time) FinancialToolOption {
	return func(t *FinancialTools) {
		if fn != nil {
			t.nowFn = fn
		}
	}
}

// WithFinancialJakartaLocation overrides the Asia/Jakarta location used for WIB boundaries.
func WithFinancialJakartaLocation(loc *time.Location) FinancialToolOption {
	return func(t *FinancialTools) {
		if loc != nil {
			t.jakartaLoc = loc
		}
	}
}

// FinancialTools exposes JWT-locked, read-only SQL aggregation tools for the AI orchestrator.
type FinancialTools struct {
	store      *repository.Store
	nowFn      func() time.Time
	jakartaLoc *time.Location
}

// NewFinancialTools constructs FinancialTools backed by store.
func NewFinancialTools(store *repository.Store, opts ...FinancialToolOption) *FinancialTools {
	loc, err := time.LoadLocation("Asia/Jakarta")
	if err != nil {
		loc = time.FixedZone("WIB", 7*3600)
	}

	tools := &FinancialTools{
		store:      store,
		nowFn:      time.Now,
		jakartaLoc: loc,
	}
	for _, opt := range opts {
		if opt != nil {
			opt(tools)
		}
	}
	return tools
}

// WalletSummaryItem describes one active wallet returned by GetUserWallets.
type WalletSummaryItem struct {
	ID                  uuid.UUID `json:"id"`
	Name                string    `json:"name"`
	Type                string    `json:"type"`
	InstitutionCode     *string   `json:"institution_code,omitempty"`
	AccountNumberMasked *string   `json:"account_number_masked,omitempty"`
	BalanceIDR          int64     `json:"balance_idr"`
	SharePct            float64   `json:"share_pct"`
	IsAutoSync          bool      `json:"is_auto_sync"`
	IsVolatile          bool      `json:"is_volatile"`
	ReturnPercentage    *float32  `json:"return_percentage,omitempty"`
}

// WalletsToolOutput represents the active wallet summary for a single authenticated user.
type WalletsToolOutput struct {
	Wallets         []WalletSummaryItem `json:"wallets"`
	TotalBalanceIDR int64               `json:"total_balance_idr"`
	WalletCount     int                 `json:"wallet_count"`
}

// CashflowQueryInput configures period, grouping mode, and optional keyword filtering.
type CashflowQueryInput struct {
	Period        string `json:"period"`
	GroupBy       string `json:"group_by"`
	KeywordFilter string `json:"keyword_filter,omitempty"`
}

// FlowSourceNode represents an income source node in the MoneyFlowCard Sankey diagram.
type FlowSourceNode struct {
	Category string  `json:"category"`
	Amount   int64   `json:"amount"`
	SharePct float64 `json:"share_pct"`
	TxCount  int64   `json:"tx_count"`
}

// ExpenseCategoryNode represents an expense category node in the MoneyFlowCard Sankey diagram.
type ExpenseCategoryNode struct {
	Category string  `json:"category"`
	Amount   int64   `json:"amount"`
	SharePct float64 `json:"share_pct"`
	TxCount  int64   `json:"tx_count"`
}

// FlowEdge represents a proportional income-to-expense ribbon in MoneyFlowCard.
type FlowEdge struct {
	SourceCategory string `json:"source_category"`
	TargetCategory string `json:"target_category"`
	FlowAmount     int64  `json:"flow_amount"`
	SourceTotal    int64  `json:"source_total"`
	TargetTotal    int64  `json:"target_total"`
	ExpenseTxCount int64  `json:"expense_tx_count"`
}

// MerchantBreakdownRow represents one sorted row in SpendingBreakdownTableCard.
type MerchantBreakdownRow struct {
	Merchant    string   `json:"merchant"`
	TxCount     int64    `json:"tx_count"`
	TotalAmount int64    `json:"total_amount"`
	WalletNames []string `json:"wallet_names"`
	Categories  []string `json:"categories"`
}

// CategoryBreakdownRow represents one aggregated category row.
type CategoryBreakdownRow struct {
	TxType      string     `json:"tx_type"`
	Category    string     `json:"category"`
	CategoryID  *uuid.UUID `json:"category_id,omitempty"`
	TxCount     int64      `json:"tx_count"`
	TotalAmount int64      `json:"total_amount"`
	SharePct    float64    `json:"share_pct"`
}

// WalletBreakdownRow represents per-wallet cashflow totals for a period.
type WalletBreakdownRow struct {
	WalletID         uuid.UUID `json:"wallet_id"`
	WalletName       string    `json:"wallet_name"`
	WalletType       string    `json:"wallet_type"`
	CurrentBalance   int64     `json:"current_balance"`
	TotalIncomeIDR   int64     `json:"total_income_idr"`
	TotalExpenseIDR  int64     `json:"total_expense_idr"`
	TotalTransferIDR int64     `json:"total_transfer_idr"`
	TxCount          int64     `json:"tx_count"`
}

// CashflowSummaryOutput holds exact SQL totals and structured analytical slices for AI tools.
type CashflowSummaryOutput struct {
	Period            string                 `json:"period"`
	PeriodLabel       string                 `json:"period_label"`
	GroupBy           string                 `json:"group_by"`
	KeywordFilter     string                 `json:"keyword_filter,omitempty"`
	StartAt           time.Time              `json:"start_at"`
	EndAt             time.Time              `json:"end_at"`
	TotalIncomeIDR    int64                  `json:"total_income_idr"`
	TotalExpenseIDR   int64                  `json:"total_expense_idr"`
	TotalTransferIDR  int64                  `json:"total_transfer_idr"`
	NetCashflowIDR    int64                  `json:"net_cashflow_idr"`
	TransactionCount  int64                  `json:"transaction_count"`
	IncomeCount       int64                  `json:"income_count"`
	ExpenseCount      int64                  `json:"expense_count"`
	TransferCount     int64                  `json:"transfer_count"`
	IncomeSources     []FlowSourceNode       `json:"income_sources"`
	ExpenseCategories []ExpenseCategoryNode  `json:"expense_categories"`
	FlowEdges         []FlowEdge             `json:"flow_edges"`
	MerchantRows      []MerchantBreakdownRow `json:"merchant_rows"`
	SourceWallets     []string               `json:"source_wallets"`
	CategoriesUsed    []string               `json:"categories_used"`
	CategoryRows      []CategoryBreakdownRow `json:"category_rows"`
	WalletRows        []WalletBreakdownRow   `json:"wallet_rows"`
}

// BudgetStatusItem summarizes one monthly category budget with actual spent totals.
type BudgetStatusItem struct {
	ID                 uuid.UUID  `json:"id"`
	CategoryID         *uuid.UUID `json:"category_id,omitempty"`
	Category           string     `json:"category"`
	MonthYear          string     `json:"month_year"`
	LimitAmountIDR     int64      `json:"limit_amount_idr"`
	SpentAmountIDR     int64      `json:"spent_amount_idr"`
	RemainingAmountIDR int64      `json:"remaining_amount_idr"`
	UsagePct           float64    `json:"usage_pct"`
	TxCount            int64      `json:"tx_count"`
	IsNearLimit        bool       `json:"is_near_limit"`
	IsOverBudget       bool       `json:"is_over_budget"`
}

// GoalStatusItem summarizes one active/completed savings goal for AI read-only inspection.
type GoalStatusItem struct {
	ID               uuid.UUID  `json:"id"`
	LinkedWalletID   *uuid.UUID `json:"linked_wallet_id,omitempty"`
	Title            string     `json:"title"`
	TargetAmountIDR  int64      `json:"target_amount_idr"`
	SavedAmountIDR   int64      `json:"saved_amount_idr"`
	RemainingIDR     int64      `json:"remaining_idr"`
	ProgressPct      float64    `json:"progress_pct"`
	TargetDate       *string    `json:"target_date,omitempty"`
	Priority         string     `json:"priority"`
	SourceAssetLabel *string    `json:"source_asset_label,omitempty"`
	Status           string     `json:"status"`
}

// BillStatusItem summarizes one unpaid bill sorted by earliest due date.
type BillStatusItem struct {
	ID           uuid.UUID `json:"id"`
	Title        string    `json:"title"`
	Category     *string   `json:"category,omitempty"`
	AmountIDR    int64     `json:"amount_idr"`
	DueDate      *string   `json:"due_date,omitempty"`
	DaysUntilDue *int      `json:"days_until_due,omitempty"`
	IsOverdue    bool      `json:"is_overdue"`
	Frequency    string    `json:"frequency"`
	AutoPay      bool      `json:"auto_pay"`
}

// BudgetBillsOutput combines monthly budgets, savings goals, and upcoming unpaid bills.
type BudgetBillsOutput struct {
	MonthYear             string             `json:"month_year"`
	Budgets               []BudgetStatusItem `json:"budgets"`
	Goals                 []GoalStatusItem   `json:"goals"`
	UpcomingBills         []BillStatusItem   `json:"upcoming_bills"`
	TotalBudgetLimitIDR   int64              `json:"total_budget_limit_idr"`
	TotalBudgetSpentIDR   int64              `json:"total_budget_spent_idr"`
	TotalGoalsTargetIDR   int64              `json:"total_goals_target_idr"`
	TotalGoalsSavedIDR    int64              `json:"total_goals_saved_idr"`
	TotalUpcomingBillsIDR int64              `json:"total_upcoming_bills_idr"`
}

// GetUserWallets returns active wallets and exact balance totals strictly for userID.
func (t *FinancialTools) GetUserWallets(ctx context.Context, userID uuid.UUID) (*WalletsToolOutput, error) {
	if t == nil || t.store == nil {
		return nil, errors.New("financial tools store is not initialized")
	}
	if userID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrInvalidFinancialToolInput)
	}

	rows, err := t.store.ListActiveWalletsByUser(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("list active wallets: %w", err)
	}

	var totalBalance int64
	for _, w := range rows {
		totalBalance += w.Balance
	}

	items := make([]WalletSummaryItem, 0, len(rows))
	for _, w := range rows {
		var share float64
		if totalBalance > 0 && w.Balance > 0 {
			share = roundSharePct(w.Balance, totalBalance)
		}
		items = append(items, WalletSummaryItem{
			ID:                  w.ID,
			Name:                w.Name,
			Type:                w.Type,
			InstitutionCode:     w.InstitutionCode,
			AccountNumberMasked: w.AccountNumberMasked,
			BalanceIDR:          w.Balance,
			SharePct:            share,
			IsAutoSync:          w.IsAutoSync,
			IsVolatile:          w.IsVolatile,
			ReturnPercentage:    w.ReturnPercentage,
		})
	}

	return &WalletsToolOutput{
		Wallets:         items,
		TotalBalanceIDR: totalBalance,
		WalletCount:     len(items),
	}, nil
}

// GetCashflowSummary computes exact SQL cashflow aggregations scoped strictly to userID.
func (t *FinancialTools) GetCashflowSummary(ctx context.Context, userID uuid.UUID, input CashflowQueryInput) (*CashflowSummaryOutput, error) {
	if t == nil || t.store == nil {
		return nil, errors.New("financial tools store is not initialized")
	}
	if userID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrInvalidFinancialToolInput)
	}

	period, label, startAt, endAt, err := resolvePeriodWindow(input.Period, t.nowFn(), t.jakartaLoc)
	if err != nil {
		return nil, err
	}

	groupBy := strings.ToLower(strings.TrimSpace(input.GroupBy))
	if groupBy == "" {
		groupBy = "category"
	}
	switch groupBy {
	case "category", "merchant", "wallet", "income_to_expense_flow":
	default:
		return nil, fmt.Errorf("%w: unsupported group_by %q", ErrInvalidFinancialToolInput, input.GroupBy)
	}

	keyword := strings.TrimSpace(input.KeywordFilter)

	out := &CashflowSummaryOutput{
		Period:            period,
		PeriodLabel:       label,
		GroupBy:           groupBy,
		KeywordFilter:     keyword,
		StartAt:           startAt,
		EndAt:             endAt,
		IncomeSources:     []FlowSourceNode{},
		ExpenseCategories: []ExpenseCategoryNode{},
		FlowEdges:         []FlowEdge{},
		MerchantRows:      []MerchantBreakdownRow{},
		SourceWallets:     []string{},
		CategoriesUsed:    []string{},
		CategoryRows:      []CategoryBreakdownRow{},
		WalletRows:        []WalletBreakdownRow{},
	}

	if err := t.populateTotals(ctx, userID, startAt, endAt, keyword, out); err != nil {
		return nil, err
	}

	switch groupBy {
	case "income_to_expense_flow":
		if err := t.populateFlowSummary(ctx, userID, startAt, endAt, keyword, out); err != nil {
			return nil, err
		}
	case "merchant":
		if err := t.populateMerchantSummary(ctx, userID, startAt, endAt, keyword, out); err != nil {
			return nil, err
		}
	case "category":
		if err := t.populateCategorySummary(ctx, userID, startAt, endAt, keyword, out); err != nil {
			return nil, err
		}
	case "wallet":
		if err := t.populateWalletSummary(ctx, userID, startAt, endAt, keyword, out); err != nil {
			return nil, err
		}
	}

	return out, nil
}

func (t *FinancialTools) populateTotals(
	ctx context.Context,
	userID uuid.UUID,
	startAt, endAt time.Time,
	keyword string,
	out *CashflowSummaryOutput,
) error {
	if keyword == "" {
		totals, err := t.store.GetCashflowPeriodTotals(ctx, repository.GetCashflowPeriodTotalsParams{
			UserID:  userID,
			StartAt: startAt,
			EndAt:   endAt,
		})
		if err != nil {
			return fmt.Errorf("query cashflow period totals: %w", err)
		}
		out.TotalIncomeIDR = totals.TotalIncome
		out.TotalExpenseIDR = totals.TotalExpense
		out.TotalTransferIDR = totals.TotalTransfer
		out.NetCashflowIDR = totals.NetCashflow
		out.TransactionCount = totals.TotalCount
		out.IncomeCount = totals.IncomeCount
		out.ExpenseCount = totals.ExpenseCount
		out.TransferCount = totals.TransferCount
		return nil
	}

	totals, err := t.store.GetCashflowFilteredPeriodTotals(ctx, repository.GetCashflowFilteredPeriodTotalsParams{
		UserID:        userID,
		StartAt:       startAt,
		EndAt:         endAt,
		KeywordFilter: keyword,
	})
	if err != nil {
		return fmt.Errorf("query filtered cashflow period totals: %w", err)
	}
	out.TotalIncomeIDR = totals.TotalIncome
	out.TotalExpenseIDR = totals.TotalExpense
	out.TotalTransferIDR = totals.TotalTransfer
	out.NetCashflowIDR = totals.NetCashflow
	out.TransactionCount = totals.TotalCount
	out.IncomeCount = totals.IncomeCount
	out.ExpenseCount = totals.ExpenseCount
	out.TransferCount = totals.TransferCount
	return nil
}

func (t *FinancialTools) populateFlowSummary(
	ctx context.Context,
	userID uuid.UUID,
	startAt, endAt time.Time,
	keyword string,
	out *CashflowSummaryOutput,
) error {
	if err := t.populateCategorySummary(ctx, userID, startAt, endAt, keyword, out); err != nil {
		return err
	}

	if keyword != "" {
		return nil
	}

	edges, err := t.store.GetCashflowFlowEdges(ctx, repository.GetCashflowFlowEdgesParams{
		UserID:  userID,
		StartAt: startAt,
		EndAt:   endAt,
	})
	if err != nil {
		return fmt.Errorf("query cashflow flow edges: %w", err)
	}

	out.FlowEdges = make([]FlowEdge, 0, len(edges))
	for _, e := range edges {
		out.FlowEdges = append(out.FlowEdges, FlowEdge{
			SourceCategory: e.SourceCategory,
			TargetCategory: e.TargetCategory,
			FlowAmount:     e.FlowAmount,
			SourceTotal:    e.SourceTotal,
			TargetTotal:    e.TargetTotal,
			ExpenseTxCount: e.ExpenseTxCount,
		})
	}
	return nil
}

func (t *FinancialTools) populateMerchantSummary(
	ctx context.Context,
	userID uuid.UUID,
	startAt, endAt time.Time,
	keyword string,
	out *CashflowSummaryOutput,
) error {
	rows, err := t.store.GetCashflowMerchantBreakdown(ctx, repository.GetCashflowMerchantBreakdownParams{
		UserID:        userID,
		StartAt:       startAt,
		EndAt:         endAt,
		KeywordFilter: keyword,
	})
	if err != nil {
		return fmt.Errorf("query cashflow merchant breakdown: %w", err)
	}

	walletSet := make(map[string]struct{})
	catSet := make(map[string]struct{})
	out.MerchantRows = make([]MerchantBreakdownRow, 0, len(rows))

	for _, r := range rows {
		wallets := append([]string(nil), r.WalletNames...)
		if wallets == nil {
			wallets = []string{}
		}
		cats := append([]string(nil), r.Categories...)
		if cats == nil {
			cats = []string{}
		}
		for _, w := range wallets {
			walletSet[w] = struct{}{}
		}
		for _, c := range cats {
			catSet[c] = struct{}{}
		}

		out.MerchantRows = append(out.MerchantRows, MerchantBreakdownRow{
			Merchant:    r.Merchant,
			TxCount:     r.TxCount,
			TotalAmount: r.TotalAmount,
			WalletNames: wallets,
			Categories:  cats,
		})
	}

	out.SourceWallets = sortedKeys(walletSet)
	out.CategoriesUsed = sortedKeys(catSet)
	return nil
}

func (t *FinancialTools) populateCategorySummary(
	ctx context.Context,
	userID uuid.UUID,
	startAt, endAt time.Time,
	keyword string,
	out *CashflowSummaryOutput,
) error {
	type catRow struct {
		txType      string
		category    string
		categoryID  *uuid.UUID
		txCount     int64
		totalAmount int64
	}

	var rows []catRow
	if keyword == "" {
		raw, err := t.store.GetCashflowCategoryBreakdown(ctx, repository.GetCashflowCategoryBreakdownParams{
			UserID:  userID,
			StartAt: startAt,
			EndAt:   endAt,
			TxType:  "",
		})
		if err != nil {
			return fmt.Errorf("query cashflow category breakdown: %w", err)
		}
		for _, r := range raw {
			rows = append(rows, catRow{
				txType:      r.TxType,
				category:    r.Category,
				categoryID:  r.CategoryID,
				txCount:     r.TxCount,
				totalAmount: r.TotalAmount,
			})
		}
	} else {
		raw, err := t.store.GetCashflowCategoryBreakdownFiltered(ctx, repository.GetCashflowCategoryBreakdownFilteredParams{
			UserID:        userID,
			StartAt:       startAt,
			EndAt:         endAt,
			TxType:        "",
			KeywordFilter: keyword,
		})
		if err != nil {
			return fmt.Errorf("query filtered cashflow category breakdown: %w", err)
		}
		for _, r := range raw {
			rows = append(rows, catRow{
				txType:      r.TxType,
				category:    r.Category,
				categoryID:  r.CategoryID,
				txCount:     r.TxCount,
				totalAmount: r.TotalAmount,
			})
		}
	}

	catSet := make(map[string]struct{})
	for _, r := range rows {
		catSet[r.category] = struct{}{}

		var share float64
		switch r.txType {
		case "income":
			share = roundSharePct(r.totalAmount, out.TotalIncomeIDR)
			out.IncomeSources = append(out.IncomeSources, FlowSourceNode{
				Category: r.category,
				Amount:   r.totalAmount,
				SharePct: share,
				TxCount:  r.txCount,
			})
		case "expense":
			share = roundSharePct(r.totalAmount, out.TotalExpenseIDR)
			out.ExpenseCategories = append(out.ExpenseCategories, ExpenseCategoryNode{
				Category: r.category,
				Amount:   r.totalAmount,
				SharePct: share,
				TxCount:  r.txCount,
			})
		case "transfer":
			share = roundSharePct(r.totalAmount, out.TotalTransferIDR)
		}

		out.CategoryRows = append(out.CategoryRows, CategoryBreakdownRow{
			TxType:      r.txType,
			Category:    r.category,
			CategoryID:  r.categoryID,
			TxCount:     r.txCount,
			TotalAmount: r.totalAmount,
			SharePct:    share,
		})
	}
	out.CategoriesUsed = sortedKeys(catSet)
	return nil
}

func (t *FinancialTools) populateWalletSummary(
	ctx context.Context,
	userID uuid.UUID,
	startAt, endAt time.Time,
	keyword string,
	out *CashflowSummaryOutput,
) error {
	rows, err := t.store.GetCashflowWalletBreakdown(ctx, repository.GetCashflowWalletBreakdownParams{
		UserID:        userID,
		StartAt:       startAt,
		EndAt:         endAt,
		KeywordFilter: keyword,
	})
	if err != nil {
		return fmt.Errorf("query cashflow wallet breakdown: %w", err)
	}

	walletSet := make(map[string]struct{}, len(rows))
	out.WalletRows = make([]WalletBreakdownRow, 0, len(rows))
	for _, r := range rows {
		walletSet[r.WalletName] = struct{}{}
		out.WalletRows = append(out.WalletRows, WalletBreakdownRow{
			WalletID:         r.WalletID,
			WalletName:       r.WalletName,
			WalletType:       r.WalletType,
			CurrentBalance:   r.CurrentBalance,
			TotalIncomeIDR:   r.TotalIncome,
			TotalExpenseIDR:  r.TotalExpense,
			TotalTransferIDR: r.TotalTransfer,
			TxCount:          r.TxCount,
		})
	}
	out.SourceWallets = sortedKeys(walletSet)
	return nil
}

// GetBudgetAndBillsStatus returns monthly category budgets with spent totals, savings goals,
// and upcoming unpaid bills strictly for userID.
func (t *FinancialTools) GetBudgetAndBillsStatus(ctx context.Context, userID uuid.UUID) (*BudgetBillsOutput, error) {
	if t == nil || t.store == nil {
		return nil, errors.New("financial tools store is not initialized")
	}
	if userID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrInvalidFinancialToolInput)
	}

	nowWIB := t.nowFn().In(t.jakartaLoc)
	monthYear := nowWIB.Format("2006-01")
	todayWIB := time.Date(nowWIB.Year(), nowWIB.Month(), nowWIB.Day(), 0, 0, 0, 0, t.jakartaLoc)

	budgets, err := t.store.ListBudgetsWithSpent(ctx, repository.ListBudgetsWithSpentParams{
		UserID:    userID,
		MonthYear: monthYear,
	})
	if err != nil {
		return nil, fmt.Errorf("list budgets with spent: %w", err)
	}

	goals, err := t.store.ListGoalsByUser(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("list goals: %w", err)
	}

	bills, err := t.store.ListUpcomingBillsByUser(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("list upcoming bills: %w", err)
	}

	out := &BudgetBillsOutput{
		MonthYear:     monthYear,
		Budgets:       make([]BudgetStatusItem, 0, len(budgets)),
		Goals:         make([]GoalStatusItem, 0, len(goals)),
		UpcomingBills: make([]BillStatusItem, 0, len(bills)),
	}

	for _, b := range budgets {
		usagePct := roundSharePct(b.SpentAmount, b.LimitAmount)
		out.TotalBudgetLimitIDR += b.LimitAmount
		out.TotalBudgetSpentIDR += b.SpentAmount
		out.Budgets = append(out.Budgets, BudgetStatusItem{
			ID:                 b.ID,
			CategoryID:         b.CategoryID,
			Category:           b.Category,
			MonthYear:          b.MonthYear,
			LimitAmountIDR:     b.LimitAmount,
			SpentAmountIDR:     b.SpentAmount,
			RemainingAmountIDR: b.RemainingAmount,
			UsagePct:           usagePct,
			TxCount:            b.TxCount,
			IsNearLimit:        usagePct >= 80.0,
			IsOverBudget:       b.SpentAmount > b.LimitAmount,
		})
	}

	for _, g := range goals {
		remaining := max(g.TargetAmount-g.SavedAmount, 0)
		var targetDateStr *string
		if g.TargetDate != nil {
			formatted := g.TargetDate.Format("2006-01-02")
			targetDateStr = &formatted
		}
		out.TotalGoalsTargetIDR += g.TargetAmount
		out.TotalGoalsSavedIDR += g.SavedAmount
		out.Goals = append(out.Goals, GoalStatusItem{
			ID:               g.ID,
			LinkedWalletID:   g.LinkedWalletID,
			Title:            g.Title,
			TargetAmountIDR:  g.TargetAmount,
			SavedAmountIDR:   g.SavedAmount,
			RemainingIDR:     remaining,
			ProgressPct:      roundSharePct(g.SavedAmount, g.TargetAmount),
			TargetDate:       targetDateStr,
			Priority:         g.Priority,
			SourceAssetLabel: g.SourceAssetLabel,
			Status:           g.Status,
		})
	}

	for _, b := range bills {
		var dueDateStr *string
		var daysUntil *int
		isOverdue := false
		if b.DueDate != nil {
			formatted := b.DueDate.Format("2006-01-02")
			dueDateStr = &formatted
			dueDay := time.Date(b.DueDate.Year(), b.DueDate.Month(), b.DueDate.Day(), 0, 0, 0, 0, t.jakartaLoc)
			days := int(dueDay.Sub(todayWIB).Hours() / 24)
			daysUntil = &days
			isOverdue = days < 0
		}
		out.TotalUpcomingBillsIDR += b.Amount
		out.UpcomingBills = append(out.UpcomingBills, BillStatusItem{
			ID:           b.ID,
			Title:        b.Title,
			Category:     b.Category,
			AmountIDR:    b.Amount,
			DueDate:      dueDateStr,
			DaysUntilDue: daysUntil,
			IsOverdue:    isOverdue,
			Frequency:    b.Frequency,
			AutoPay:      b.AutoPay,
		})
	}

	return out, nil
}

func resolvePeriodWindow(raw string, now time.Time, loc *time.Location) (string, string, time.Time, time.Time, error) {
	nowWIB := now.In(loc)
	period := strings.TrimSpace(raw)
	if period == "" {
		period = "this_month"
	}

	switch strings.ToLower(period) {
	case "this_month":
		start := time.Date(nowWIB.Year(), nowWIB.Month(), 1, 0, 0, 0, 0, loc)
		end := start.AddDate(0, 1, 0)
		return "this_month", start.Format("January 2006"), start, end, nil
	case "last_month":
		end := time.Date(nowWIB.Year(), nowWIB.Month(), 1, 0, 0, 0, 0, loc)
		start := end.AddDate(0, -1, 0)
		return "last_month", start.Format("January 2006"), start, end, nil
	case "last_30_days":
		todayStart := time.Date(nowWIB.Year(), nowWIB.Month(), nowWIB.Day(), 0, 0, 0, 0, loc)
		start := todayStart.AddDate(0, 0, -29)
		end := todayStart.AddDate(0, 0, 1)
		label := fmt.Sprintf("%s to %s", start.Format("2006-01-02"), todayStart.Format("2006-01-02"))
		return "last_30_days", label, start, end, nil
	case "last_90_days":
		todayStart := time.Date(nowWIB.Year(), nowWIB.Month(), nowWIB.Day(), 0, 0, 0, 0, loc)
		start := todayStart.AddDate(0, 0, -89)
		end := todayStart.AddDate(0, 0, 1)
		label := fmt.Sprintf("%s to %s", start.Format("2006-01-02"), todayStart.Format("2006-01-02"))
		return "last_90_days", label, start, end, nil
	default:
		if len(period) != 7 || period[4] != '-' {
			return "", "", time.Time{}, time.Time{}, fmt.Errorf("%w: unsupported period %q", ErrInvalidFinancialToolInput, raw)
		}
		parsed, err := time.ParseInLocation("2006-01", period, loc)
		if err != nil {
			return "", "", time.Time{}, time.Time{}, fmt.Errorf("%w: invalid YYYY-MM period %q", ErrInvalidFinancialToolInput, raw)
		}
		start := time.Date(parsed.Year(), parsed.Month(), 1, 0, 0, 0, 0, loc)
		end := start.AddDate(0, 1, 0)
		return period, start.Format("January 2006"), start, end, nil
	}
}

func roundSharePct(part, whole int64) float64 {
	if whole <= 0 || part <= 0 {
		return 0
	}
	return math.Round((float64(part)*1000.0)/float64(whole)) / 10.0
}

func sortedKeys(set map[string]struct{}) []string {
	if len(set) == 0 {
		return []string{}
	}
	keys := make([]string, 0, len(set))
	for k := range set {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}
