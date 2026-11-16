package ai

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"
	"unicode"

	"github.com/google/uuid"

	"github.com/clarafin/api/internal/repository"
)

// ErrInvalidActionToolInput indicates invalid arguments passed to ActionTools.
var ErrInvalidActionToolInput = errors.New("invalid action tool input")

var validActionTxTypes = map[string]struct{}{
	"income":   {},
	"expense":  {},
	"transfer": {},
}

var validActionGoalPriorities = map[string]struct{}{
	"urgent": {},
	"needs":  {},
	"wants":  {},
}

var validActionBillFrequencies = map[string]struct{}{
	"weekly":  {},
	"monthly": {},
	"yearly":  {},
}

// ActionToolOption customizes ActionTools dependencies and clocks.
type ActionToolOption func(*ActionTools)

// WithActionNowFunc overrides the clock source used for WIB dates and estimates.
func WithActionNowFunc(fn func() time.Time) ActionToolOption {
	return func(t *ActionTools) {
		if fn != nil {
			t.nowFn = fn
		}
	}
}

// WithActionJakartaLocation overrides the Asia/Jakarta location used for WIB boundaries.
func WithActionJakartaLocation(loc *time.Location) ActionToolOption {
	return func(t *ActionTools) {
		if loc != nil {
			t.jakartaLoc = loc
		}
	}
}

// WithActionFinancialTools injects a preconfigured FinancialTools instance.
func WithActionFinancialTools(ft *FinancialTools) ActionToolOption {
	return func(t *ActionTools) {
		if ft != nil {
			t.financialTools = ft
		}
	}
}

// ActionTools produces validated, read-only confirmation drafts for AI actions.
// None of its methods mutate database state; persistence requires explicit user confirmation.
type ActionTools struct {
	store          *repository.Store
	financialTools *FinancialTools
	nowFn          func() time.Time
	jakartaLoc     *time.Location
}

// NewActionTools constructs ActionTools backed by store and FinancialTools.
func NewActionTools(store *repository.Store, opts ...ActionToolOption) *ActionTools {
	loc, err := time.LoadLocation("Asia/Jakarta")
	if err != nil {
		loc = time.FixedZone("WIB", 7*3600)
	}

	tools := &ActionTools{
		store:      store,
		nowFn:      time.Now,
		jakartaLoc: loc,
	}
	for _, opt := range opts {
		if opt != nil {
			opt(tools)
		}
	}
	if tools.financialTools == nil {
		tools.financialTools = NewFinancialTools(
			store,
			WithFinancialNowFunc(tools.nowFn),
			WithFinancialJakartaLocation(tools.jakartaLoc),
		)
	}
	return tools
}

// PrepareTransactionItemInput represents one parsed transaction item before wallet validation.
type PrepareTransactionItemInput struct {
	Title            string     `json:"title"`
	AmountIDR        int64      `json:"amount_idr"`
	Type             string     `json:"type"`
	RawCategory      string     `json:"raw_category,omitempty"`
	Category         string     `json:"category,omitempty"`
	Note             string     `json:"note,omitempty"`
	WalletHint       string     `json:"wallet_hint,omitempty"`
	TargetWalletHint string     `json:"target_wallet_hint,omitempty"`
	WalletID         *uuid.UUID `json:"wallet_id,omitempty"`
	TargetWalletID   *uuid.UUID `json:"target_wallet_id,omitempty"`
	OccurredAt       *time.Time `json:"occurred_at,omitempty"`
}

// PrepareTransactionInput batches 1..N items from natural language or multi-item splits.
type PrepareTransactionInput struct {
	Items             []PrepareTransactionItemInput `json:"items"`
	DefaultWalletHint string                        `json:"default_wallet_hint,omitempty"`
	WalletHint        string                        `json:"wallet_hint,omitempty"`
	TargetWalletHint  string                        `json:"target_wallet_hint,omitempty"`
}

// ExistingWalletChip describes an existing active user wallet offered as a quick-switch chip.
type ExistingWalletChip struct {
	ID              uuid.UUID `json:"id"`
	Name            string    `json:"name"`
	Type            string    `json:"type"`
	InstitutionCode *string   `json:"institution_code,omitempty"`
	BalanceIDR      int64     `json:"balance_idr"`
}

// PendingTransactionItem captures normalized item details held while waiting for missing wallet creation.
type PendingTransactionItem struct {
	Title                     string    `json:"title"`
	AmountIDR                 int64     `json:"amount_idr"`
	Type                      string    `json:"type"`
	CanonicalCategory         string    `json:"canonical_category"`
	CanonicalMainCategory     string    `json:"canonical_main_category"`
	Note                      string    `json:"note,omitempty"`
	RequestedWalletHint       string    `json:"requested_wallet_hint,omitempty"`
	RequestedTargetWalletHint string    `json:"requested_target_wallet_hint,omitempty"`
	OccurredAt                time.Time `json:"occurred_at"`
}

// WalletCreationDraft suggests creating a missing institution wallet without substituting another wallet.
type WalletCreationDraft struct {
	InstitutionID     string               `json:"institution_id"`
	InstitutionName   string               `json:"institution_name"`
	InstitutionType   string               `json:"institution_type"`
	MissingWalletHint string               `json:"missing_wallet_hint,omitempty"`
	ExistingWallets   []ExistingWalletChip `json:"existing_wallets"`
}

// TransactionDraftItem represents a validated, wallet-linked transaction ready for confirmation.
type TransactionDraftItem struct {
	Title                 string     `json:"title"`
	AmountIDR             int64      `json:"amount_idr"`
	Type                  string     `json:"type"`
	CanonicalCategory     string     `json:"canonical_category"`
	CanonicalMainCategory string     `json:"canonical_main_category"`
	WalletID              uuid.UUID  `json:"wallet_id"`
	WalletName            string     `json:"wallet_name"`
	TargetWalletID        *uuid.UUID `json:"target_wallet_id,omitempty"`
	TargetWalletName      *string    `json:"target_wallet_name,omitempty"`
	Note                  string     `json:"note,omitempty"`
	OccurredAt            time.Time  `json:"occurred_at"`
}

// TransactionDraftPayload contains 1..N ready transaction drafts and exact sum totals.
type TransactionDraftPayload struct {
	Items          []TransactionDraftItem `json:"items"`
	TotalAmountIDR int64                  `json:"total_amount_idr"`
	ItemCount      int                    `json:"item_count"`
}

// PrepareTransactionResult returns either a ready TransactionDraft or a WalletCreationDraft.
type PrepareTransactionResult struct {
	Status              string                   `json:"status"`
	TransactionDraft    *TransactionDraftPayload `json:"transaction_draft,omitempty"`
	WalletCreationDraft *WalletCreationDraft     `json:"wallet_creation_draft,omitempty"`
	PendingItems        []PendingTransactionItem `json:"pending_items,omitempty"`
}

// GoalDraftInput specifies parameters for a proposed savings goal draft.
type GoalDraftInput struct {
	Title            string     `json:"title"`
	TargetAmountIDR  int64      `json:"target_amount_idr"`
	SavedAmountIDR   int64      `json:"saved_amount_idr,omitempty"`
	TargetDate       *string    `json:"target_date,omitempty"`
	Months           *int       `json:"months,omitempty"`
	Priority         string     `json:"priority,omitempty"`
	LinkedWalletHint string     `json:"linked_wallet_hint,omitempty"`
	LinkedWalletID   *uuid.UUID `json:"linked_wallet_id,omitempty"`
}

// GoalDraftPayload contains deterministic Go savings schedule calculations for user confirmation.
type GoalDraftPayload struct {
	Title                    string     `json:"title"`
	TargetAmountIDR          int64      `json:"target_amount_idr"`
	SavedAmountIDR           int64      `json:"saved_amount_idr"`
	RemainingAmountIDR       int64      `json:"remaining_amount_idr"`
	TargetDate               *string    `json:"target_date,omitempty"`
	MonthsRemaining          int        `json:"months_remaining"`
	MonthlySavingEstimateIDR int64      `json:"monthly_saving_estimate_idr"`
	Priority                 string     `json:"priority"`
	LinkedWalletID           *uuid.UUID `json:"linked_wallet_id,omitempty"`
	LinkedWalletName         *string    `json:"linked_wallet_name,omitempty"`
	SourceAssetLabel         *string    `json:"source_asset_label,omitempty"`
}

// BudgetDraftInput specifies parameters for a proposed monthly category budget draft.
type BudgetDraftInput struct {
	Category       string `json:"category"`
	LimitAmountIDR int64  `json:"limit_amount_idr"`
	MonthYear      string `json:"month_year,omitempty"`
	ContextHint    string `json:"context_hint,omitempty"`
}

// BudgetDraftPayload holds normalized main category and real historical spend baselines from SQL.
type BudgetDraftPayload struct {
	Category             string `json:"category"`
	MonthYear            string `json:"month_year"`
	LimitAmountIDR       int64  `json:"limit_amount_idr"`
	CurrentMonthSpendIDR int64  `json:"current_month_spend_idr"`
	Avg30DSpendIDR       int64  `json:"avg_30d_spend_idr"`
	ExistingLimitIDR     *int64 `json:"existing_limit_idr,omitempty"`
	IsUpdate             bool   `json:"is_update"`
}

// BillDraftInput specifies parameters for a proposed recurring bill reminder draft.
type BillDraftInput struct {
	Title     string  `json:"title"`
	Category  string  `json:"category,omitempty"`
	AmountIDR int64   `json:"amount_idr"`
	DueDay    int     `json:"due_day,omitempty"`
	DueDate   *string `json:"due_date,omitempty"`
	Frequency string  `json:"frequency,omitempty"`
	AutoPay   bool    `json:"auto_pay,omitempty"`
}

// BillDraftPayload holds a validated recurring bill draft with next due date computed in WIB.
type BillDraftPayload struct {
	Title                 string `json:"title"`
	CanonicalCategory     string `json:"canonical_category"`
	CanonicalMainCategory string `json:"canonical_main_category"`
	AmountIDR             int64  `json:"amount_idr"`
	DueDay                int    `json:"due_day"`
	NextDueDate           string `json:"next_due_date"`
	Frequency             string `json:"frequency"`
	AutoPay               bool   `json:"auto_pay"`
}

type institutionSpec struct {
	id      string
	name    string
	wType   string
	aliases []string
}

var institutionCatalog = []institutionSpec{
	{id: "bca", name: "BCA", wType: "bank", aliases: []string{"bca", "bank central asia", "bank bca"}},
	{id: "mandiri", name: "Mandiri", wType: "bank", aliases: []string{"mandiri", "bank mandiri", "livin", "livin mandiri", "livin by mandiri"}},
	{id: "bri", name: "BRI", wType: "bank", aliases: []string{"bri", "bank bri", "brimo", "bank rakyat indonesia"}},
	{id: "bni", name: "BNI", wType: "bank", aliases: []string{"bni", "bank bni", "wondr", "bank negara indonesia"}},
	{id: "bsi", name: "BSI", wType: "bank", aliases: []string{"bsi", "bank bsi", "bank syariah indonesia", "byond"}},
	{id: "jago", name: "Bank Jago", wType: "bank", aliases: []string{"jago", "bank jago", "kantong jago"}},
	{id: "jenius", name: "Jenius", wType: "bank", aliases: []string{"jenius", "bank jenius", "btpn jenius", "smbc jenius"}},
	{id: "seabank", name: "SeaBank", wType: "bank", aliases: []string{"seabank", "sea bank"}},
	{id: "blu", name: "blu by BCA Digital", wType: "bank", aliases: []string{"blu", "blu bca", "bca digital"}},
	{id: "cimb", name: "CIMB Niaga", wType: "bank", aliases: []string{"cimb", "cimb niaga", "octo"}},
	{id: "permata", name: "Bank Permata", wType: "bank", aliases: []string{"permata", "bank permata"}},
	{id: "gopay", name: "GoPay", wType: "ewallet", aliases: []string{"gopay", "go pay", "gopay wallet"}},
	{id: "dana", name: "DANA", wType: "ewallet", aliases: []string{"dana", "dompet dana"}},
	{id: "ovo", name: "OVO", wType: "ewallet", aliases: []string{"ovo"}},
	{id: "shopeepay", name: "ShopeePay", wType: "ewallet", aliases: []string{"shopeepay", "shopee pay", "spay"}},
	{id: "linkaja", name: "LinkAja", wType: "ewallet", aliases: []string{"linkaja", "link aja"}},
	{id: "binance", name: "Binance", wType: "cex", aliases: []string{"binance"}},
	{id: "bitget", name: "Bitget", wType: "cex", aliases: []string{"bitget"}},
	{id: "floq", name: "Floq", wType: "cex", aliases: []string{"floq"}},
	{id: "indodax", name: "Indodax", wType: "cex", aliases: []string{"indodax"}},
	{id: "pintu", name: "Pintu", wType: "cex", aliases: []string{"pintu"}},
	{id: "tokocrypto", name: "Tokocrypto", wType: "cex", aliases: []string{"tokocrypto"}},
	{id: "uniswap", name: "Uniswap", wType: "dex", aliases: []string{"uniswap"}},
	{id: "phantom", name: "Phantom Wallet", wType: "web3_wallet", aliases: []string{"phantom", "phantom wallet"}},
	{id: "metamask", name: "MetaMask", wType: "web3_wallet", aliases: []string{"metamask"}},
	{id: "trustwallet", name: "Trust Wallet", wType: "web3_wallet", aliases: []string{"trustwallet", "trust wallet"}},
	{id: "bibit", name: "Bibit Reksadana", wType: "mutual_fund", aliases: []string{"bibit", "bibit reksadana"}},
	{id: "stockbit", name: "Stockbit Saham", wType: "stock", aliases: []string{"stockbit", "stockbit saham"}},
	{id: "cash", name: "Cash", wType: "cash", aliases: []string{"cash", "tunai", "dompet tunai", "uang tunai", "kas"}},
}

// CheckAndPrepareTransaction resolves requested wallets against the user's active wallets first.
// If any requested wallet does not exist, TransactionDraft is strictly withheld (never substituted)
// and WalletCreationDraft is returned alongside existing wallet chips and normalized pending items.
func (t *ActionTools) CheckAndPrepareTransaction(
	ctx context.Context,
	userID uuid.UUID,
	input PrepareTransactionInput,
) (*PrepareTransactionResult, error) {
	if err := t.requireInitialized(userID); err != nil {
		return nil, err
	}
	if len(input.Items) == 0 {
		return nil, fmt.Errorf("%w: at least one transaction item is required", ErrInvalidActionToolInput)
	}

	walletsOut, err := t.financialTools.GetUserWallets(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("fetch user wallets: %w", err)
	}

	nowWIB := t.nowFn().In(t.jakartaLoc)
	defaultHint := strings.TrimSpace(input.WalletHint)
	if defaultHint == "" {
		defaultHint = strings.TrimSpace(input.DefaultWalletHint)
	}
	defaultTargetHint := strings.TrimSpace(input.TargetWalletHint)

	pendingItems := make([]PendingTransactionItem, 0, len(input.Items))
	draftItems := make([]TransactionDraftItem, 0, len(input.Items))
	var missingWallet *WalletCreationDraft
	var totalAmount int64

	for i, item := range input.Items {
		title := strings.TrimSpace(item.Title)
		if title == "" {
			return nil, fmt.Errorf("%w: item %d title is required", ErrInvalidActionToolInput, i)
		}
		if item.AmountIDR <= 0 {
			return nil, fmt.Errorf("%w: item %d amount_idr must be > 0", ErrInvalidActionToolInput, i)
		}

		rawType := strings.ToLower(strings.TrimSpace(item.Type))
		if rawType != "" {
			if _, ok := validActionTxTypes[rawType]; !ok {
				return nil, fmt.Errorf("%w: item %d has unsupported type %q", ErrInvalidActionToolInput, i, item.Type)
			}
		}

		rawCategory := strings.TrimSpace(item.RawCategory)
		if rawCategory == "" {
			rawCategory = strings.TrimSpace(item.Category)
		}
		note := strings.TrimSpace(item.Note)
		contextHint := strings.TrimSpace(title + " " + note)
		catResult := NormalizeCanonicalCategory(rawCategory, rawType, contextHint)
		if rawType != "" && catResult.Type != rawType {
			return nil, fmt.Errorf("%w: item %d category %q (%s) is incompatible with type %q", ErrInvalidActionToolInput, i, catResult.CanonicalCategory, catResult.Type, rawType)
		}

		itemType := rawType
		if itemType == "" {
			itemType = catResult.Type
		}

		occurredAt := nowWIB
		if item.OccurredAt != nil && !item.OccurredAt.IsZero() {
			occurredAt = item.OccurredAt.In(t.jakartaLoc)
		}

		walletHint := strings.TrimSpace(item.WalletHint)
		if walletHint == "" {
			walletHint = defaultHint
		}
		targetHint := strings.TrimSpace(item.TargetWalletHint)
		if targetHint == "" {
			targetHint = defaultTargetHint
		}

		pendingItems = append(pendingItems, PendingTransactionItem{
			Title:                     title,
			AmountIDR:                 item.AmountIDR,
			Type:                      itemType,
			CanonicalCategory:         catResult.CanonicalCategory,
			CanonicalMainCategory:     catResult.CanonicalMainCategory,
			Note:                      note,
			RequestedWalletHint:       walletHint,
			RequestedTargetWalletHint: targetHint,
			OccurredAt:                occurredAt,
		})

		// Resolve source wallet without substituting a different wallet when one was requested.
		var srcWallet WalletSummaryItem
		var srcMatched bool
		if item.WalletID != nil && *item.WalletID != uuid.Nil {
			srcWallet, srcMatched = matchWalletByID(*item.WalletID, walletsOut.Wallets)
			if !srcMatched && missingWallet == nil {
				missingWallet = buildMissingWalletDraft(walletHint, walletsOut.Wallets)
			}
		} else if walletHint != "" {
			srcWallet, srcMatched = matchWalletByHint(walletHint, walletsOut.Wallets)
			if !srcMatched && missingWallet == nil {
				missingWallet = buildMissingWalletDraft(walletHint, walletsOut.Wallets)
			}
		} else if len(walletsOut.Wallets) > 0 {
			srcWallet = walletsOut.Wallets[0]
			srcMatched = true
		} else if missingWallet == nil {
			missingWallet = buildMissingWalletDraft("cash", walletsOut.Wallets)
		}

		var targetWalletID *uuid.UUID
		var targetWalletName *string
		if itemType == "transfer" {
			if (item.TargetWalletID == nil || *item.TargetWalletID == uuid.Nil) && targetHint == "" {
				return nil, fmt.Errorf("%w: item %d transfer requires target wallet", ErrInvalidActionToolInput, i)
			}
			var dstWallet WalletSummaryItem
			var dstMatched bool
			if item.TargetWalletID != nil && *item.TargetWalletID != uuid.Nil {
				dstWallet, dstMatched = matchWalletByID(*item.TargetWalletID, walletsOut.Wallets)
			} else {
				dstWallet, dstMatched = matchWalletByHint(targetHint, walletsOut.Wallets)
			}
			if !dstMatched {
				if missingWallet == nil {
					missingWallet = buildMissingWalletDraft(targetHint, walletsOut.Wallets)
				}
			} else {
				if srcMatched && dstWallet.ID == srcWallet.ID {
					return nil, fmt.Errorf("%w: item %d target wallet must differ from source wallet", ErrInvalidActionToolInput, i)
				}
				idCopy := dstWallet.ID
				nameCopy := dstWallet.Name
				targetWalletID = &idCopy
				targetWalletName = &nameCopy
			}
		}

		if srcMatched && missingWallet == nil {
			totalAmount += item.AmountIDR
			draftItems = append(draftItems, TransactionDraftItem{
				Title:                 title,
				AmountIDR:             item.AmountIDR,
				Type:                  itemType,
				CanonicalCategory:     catResult.CanonicalCategory,
				CanonicalMainCategory: catResult.CanonicalMainCategory,
				WalletID:              srcWallet.ID,
				WalletName:            srcWallet.Name,
				TargetWalletID:        targetWalletID,
				TargetWalletName:      targetWalletName,
				Note:                  note,
				OccurredAt:            occurredAt,
			})
		}
	}

	if missingWallet != nil {
		return &PrepareTransactionResult{
			Status:              "missing_wallet",
			TransactionDraft:    nil,
			WalletCreationDraft: missingWallet,
			PendingItems:        pendingItems,
		}, nil
	}

	return &PrepareTransactionResult{
		Status: "ready",
		TransactionDraft: &TransactionDraftPayload{
			Items:          draftItems,
			TotalAmountIDR: totalAmount,
			ItemCount:      len(draftItems),
		},
	}, nil
}

// ProposeGoalDraft validates goal inputs and deterministically calculates monthly saving estimates in Go.
func (t *ActionTools) ProposeGoalDraft(
	ctx context.Context,
	userID uuid.UUID,
	input GoalDraftInput,
) (*GoalDraftPayload, error) {
	if err := t.requireInitialized(userID); err != nil {
		return nil, err
	}

	title := strings.TrimSpace(input.Title)
	if title == "" {
		return nil, fmt.Errorf("%w: goal title is required", ErrInvalidActionToolInput)
	}
	if input.TargetAmountIDR <= 0 {
		return nil, fmt.Errorf("%w: target_amount_idr must be > 0", ErrInvalidActionToolInput)
	}
	if input.SavedAmountIDR < 0 {
		return nil, fmt.Errorf("%w: saved_amount_idr must be >= 0", ErrInvalidActionToolInput)
	}

	priority := strings.ToLower(strings.TrimSpace(input.Priority))
	if priority == "" {
		priority = "wants"
	}
	if _, ok := validActionGoalPriorities[priority]; !ok {
		return nil, fmt.Errorf("%w: unsupported goal priority %q", ErrInvalidActionToolInput, input.Priority)
	}

	nowWIB := t.nowFn().In(t.jakartaLoc)
	todayWIB := time.Date(nowWIB.Year(), nowWIB.Month(), nowWIB.Day(), 0, 0, 0, 0, t.jakartaLoc)

	var targetDateStr *string
	monthsRemaining := 0

	if input.TargetDate != nil && strings.TrimSpace(*input.TargetDate) != "" {
		rawDate := strings.TrimSpace(*input.TargetDate)
		parsed, err := time.ParseInLocation("2006-01-02", rawDate, t.jakartaLoc)
		if err != nil {
			return nil, fmt.Errorf("%w: target_date %q must use YYYY-MM-DD format", ErrInvalidActionToolInput, rawDate)
		}
		targetDay := time.Date(parsed.Year(), parsed.Month(), parsed.Day(), 0, 0, 0, 0, t.jakartaLoc)
		if targetDay.Before(todayWIB) {
			return nil, fmt.Errorf("%w: target_date %q cannot be in the past", ErrInvalidActionToolInput, rawDate)
		}
		monthsRemaining = (targetDay.Year()-todayWIB.Year())*12 + int(targetDay.Month()-todayWIB.Month())
		if monthsRemaining < 1 {
			monthsRemaining = 1
		}
		formatted := targetDay.Format("2006-01-02")
		targetDateStr = &formatted
	} else if input.Months != nil {
		if *input.Months <= 0 {
			return nil, fmt.Errorf("%w: months must be >= 1", ErrInvalidActionToolInput)
		}
		monthsRemaining = *input.Months
		targetDay := clampedAddMonths(todayWIB.Year(), todayWIB.Month(), monthsRemaining, todayWIB.Day(), t.jakartaLoc)
		formatted := targetDay.Format("2006-01-02")
		targetDateStr = &formatted
	}

	var linkedWalletID *uuid.UUID
	var linkedWalletName *string
	var sourceAssetLabel *string

	if (input.LinkedWalletID != nil && *input.LinkedWalletID != uuid.Nil) || strings.TrimSpace(input.LinkedWalletHint) != "" {
		walletsOut, err := t.financialTools.GetUserWallets(ctx, userID)
		if err != nil {
			return nil, fmt.Errorf("fetch user wallets for goal: %w", err)
		}
		if input.LinkedWalletID != nil && *input.LinkedWalletID != uuid.Nil {
			w, ok := matchWalletByID(*input.LinkedWalletID, walletsOut.Wallets)
			if !ok {
				return nil, fmt.Errorf("%w: linked_wallet_id not found for user", ErrInvalidActionToolInput)
			}
			idCopy := w.ID
			nameCopy := w.Name
			linkedWalletID = &idCopy
			linkedWalletName = &nameCopy
			sourceAssetLabel = &nameCopy
		} else {
			hint := strings.TrimSpace(input.LinkedWalletHint)
			if w, ok := matchWalletByHint(hint, walletsOut.Wallets); ok {
				idCopy := w.ID
				nameCopy := w.Name
				linkedWalletID = &idCopy
				linkedWalletName = &nameCopy
				sourceAssetLabel = &nameCopy
			} else {
				sourceAssetLabel = &hint
			}
		}
	}

	remaining := max(input.TargetAmountIDR-input.SavedAmountIDR, 0)
	var monthlyEstimate int64
	if remaining > 0 && monthsRemaining > 0 {
		m := int64(monthsRemaining)
		monthlyEstimate = (remaining + m - 1) / m
	}

	return &GoalDraftPayload{
		Title:                    title,
		TargetAmountIDR:          input.TargetAmountIDR,
		SavedAmountIDR:           input.SavedAmountIDR,
		RemainingAmountIDR:       remaining,
		TargetDate:               targetDateStr,
		MonthsRemaining:          monthsRemaining,
		MonthlySavingEstimateIDR: monthlyEstimate,
		Priority:                 priority,
		LinkedWalletID:           linkedWalletID,
		LinkedWalletName:         linkedWalletName,
		SourceAssetLabel:         sourceAssetLabel,
	}, nil
}

// ProposeBudgetDraft normalizes category to a top-level canonical main category matching
// syncedBudgetsProvider and attaches real Postgres spend totals for the current month and last 30 days.
func (t *ActionTools) ProposeBudgetDraft(
	ctx context.Context,
	userID uuid.UUID,
	input BudgetDraftInput,
) (*BudgetDraftPayload, error) {
	if err := t.requireInitialized(userID); err != nil {
		return nil, err
	}
	if strings.TrimSpace(input.Category) == "" {
		return nil, fmt.Errorf("%w: budget category is required", ErrInvalidActionToolInput)
	}
	if input.LimitAmountIDR <= 0 {
		return nil, fmt.Errorf("%w: limit_amount_idr must be > 0", ErrInvalidActionToolInput)
	}

	monthYear, err := t.resolveActionMonthYear(input.MonthYear)
	if err != nil {
		return nil, err
	}

	catRes := NormalizeCanonicalCategory(input.Category, "expense", input.ContextHint)
	if catRes.Type != "expense" {
		return nil, fmt.Errorf("%w: budget category must be an expense category, got %s (%s)", ErrInvalidActionToolInput, catRes.CanonicalCategory, catRes.Type)
	}
	mainCat := catRes.CanonicalMainCategory

	monthSummary, err := t.financialTools.GetCashflowSummary(ctx, userID, CashflowQueryInput{
		Period:  monthYear,
		GroupBy: "category",
	})
	if err != nil {
		return nil, fmt.Errorf("query budget month cashflow: %w", err)
	}

	avg30Summary, err := t.financialTools.GetCashflowSummary(ctx, userID, CashflowQueryInput{
		Period:  "last_30_days",
		GroupBy: "category",
	})
	if err != nil {
		return nil, fmt.Errorf("query budget 30d cashflow: %w", err)
	}

	existingBudgets, err := t.store.ListBudgetsWithSpent(ctx, repository.ListBudgetsWithSpentParams{
		UserID:    userID,
		MonthYear: monthYear,
	})
	if err != nil {
		return nil, fmt.Errorf("check existing budgets: %w", err)
	}

	var existingLimit *int64
	isUpdate := false
	for _, b := range existingBudgets {
		if strings.EqualFold(b.Category, mainCat) {
			lim := b.LimitAmount
			existingLimit = &lim
			isUpdate = true
			break
		}
	}

	return &BudgetDraftPayload{
		Category:             mainCat,
		MonthYear:            monthYear,
		LimitAmountIDR:       input.LimitAmountIDR,
		CurrentMonthSpendIDR: sumExpenseForMainCategory(monthSummary.CategoryRows, mainCat),
		Avg30DSpendIDR:       sumExpenseForMainCategory(avg30Summary.CategoryRows, mainCat),
		ExistingLimitIDR:     existingLimit,
		IsUpdate:             isUpdate,
	}, nil
}

// ProposeBillDraft normalizes category, validates amount/due_day/frequency, and computes next WIB due date.
func (t *ActionTools) ProposeBillDraft(
	ctx context.Context,
	userID uuid.UUID,
	input BillDraftInput,
) (*BillDraftPayload, error) {
	if err := t.requireInitialized(userID); err != nil {
		return nil, err
	}

	title := strings.TrimSpace(input.Title)
	if title == "" {
		return nil, fmt.Errorf("%w: bill title is required", ErrInvalidActionToolInput)
	}
	if input.AmountIDR <= 0 {
		return nil, fmt.Errorf("%w: amount_idr must be > 0", ErrInvalidActionToolInput)
	}

	frequency := strings.ToLower(strings.TrimSpace(input.Frequency))
	if frequency == "" {
		frequency = "monthly"
	}
	if _, ok := validActionBillFrequencies[frequency]; !ok {
		return nil, fmt.Errorf("%w: unsupported bill frequency %q (expected weekly, monthly, or yearly)", ErrInvalidActionToolInput, input.Frequency)
	}

	nowWIB := t.nowFn().In(t.jakartaLoc)
	todayWIB := time.Date(nowWIB.Year(), nowWIB.Month(), nowWIB.Day(), 0, 0, 0, 0, t.jakartaLoc)

	dueDay := input.DueDay
	var explicitDueDate *time.Time
	if input.DueDate != nil && strings.TrimSpace(*input.DueDate) != "" {
		rawDate := strings.TrimSpace(*input.DueDate)
		parsed, err := time.ParseInLocation("2006-01-02", rawDate, t.jakartaLoc)
		if err != nil {
			return nil, fmt.Errorf("%w: due_date %q must use YYYY-MM-DD format", ErrInvalidActionToolInput, rawDate)
		}
		dayOnly := time.Date(parsed.Year(), parsed.Month(), parsed.Day(), 0, 0, 0, 0, t.jakartaLoc)
		explicitDueDate = &dayOnly
		if dueDay == 0 {
			dueDay = dayOnly.Day()
		}
	}

	if dueDay < 1 || dueDay > 31 {
		return nil, fmt.Errorf("%w: due_day %d must be between 1 and 31", ErrInvalidActionToolInput, dueDay)
	}

	var nextDue time.Time
	if explicitDueDate != nil {
		nextDue = computeNextDueFromDate(todayWIB, *explicitDueDate, dueDay, frequency, t.jakartaLoc)
	} else {
		nextDue = computeNextDueFromDay(todayWIB, dueDay, frequency, t.jakartaLoc)
	}

	catRes := NormalizeCanonicalCategory(input.Category, "expense", title)
	if catRes.Type != "expense" {
		return nil, fmt.Errorf("%w: bill category must be an expense category, got %s (%s)", ErrInvalidActionToolInput, catRes.CanonicalCategory, catRes.Type)
	}

	return &BillDraftPayload{
		Title:                 title,
		CanonicalCategory:     catRes.CanonicalCategory,
		CanonicalMainCategory: catRes.CanonicalMainCategory,
		AmountIDR:             input.AmountIDR,
		DueDay:                dueDay,
		NextDueDate:           nextDue.Format("2006-01-02"),
		Frequency:             frequency,
		AutoPay:               input.AutoPay,
	}, nil
}

func (t *ActionTools) requireInitialized(userID uuid.UUID) error {
	if t == nil || t.store == nil || t.financialTools == nil {
		return errors.New("action tools store is not initialized")
	}
	if userID == uuid.Nil {
		return fmt.Errorf("%w: user_id is required", ErrInvalidActionToolInput)
	}
	return nil
}

func (t *ActionTools) resolveActionMonthYear(raw string) (string, error) {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return t.nowFn().In(t.jakartaLoc).Format("2006-01"), nil
	}
	if len(trimmed) != 7 || trimmed[4] != '-' {
		return "", fmt.Errorf("%w: month_year must use YYYY-MM format", ErrInvalidActionToolInput)
	}
	if _, err := time.Parse("2006-01", trimmed); err != nil {
		return "", fmt.Errorf("%w: invalid month_year %q", ErrInvalidActionToolInput, raw)
	}
	return trimmed, nil
}

func sumExpenseForMainCategory(rows []CategoryBreakdownRow, mainCategory string) int64 {
	target := strings.ToLower(strings.TrimSpace(mainCategory))
	var total int64
	for _, r := range rows {
		if r.TxType != "expense" {
			continue
		}
		if matchesCanonicalMainCategory(r.Category, target) {
			total += r.TotalAmount
		}
	}
	return total
}

func matchesCanonicalMainCategory(rawCategory string, targetLower string) bool {
	cat := strings.ToLower(strings.TrimSpace(rawCategory))
	if cat == targetLower {
		return true
	}
	return strings.HasPrefix(cat, targetLower+" •") ||
		strings.HasPrefix(cat, targetLower+" -") ||
		strings.HasPrefix(cat, targetLower+":")
}

func matchWalletByID(id uuid.UUID, wallets []WalletSummaryItem) (WalletSummaryItem, bool) {
	for _, w := range wallets {
		if w.ID == id {
			return w, true
		}
	}
	return WalletSummaryItem{}, false
}

func matchWalletByHint(hint string, wallets []WalletSummaryItem) (WalletSummaryItem, bool) {
	trimmed := strings.TrimSpace(hint)
	if trimmed == "" || len(wallets) == 0 {
		return WalletSummaryItem{}, false
	}

	// 1. Exact case-insensitive match against wallet name.
	for _, w := range wallets {
		if strings.EqualFold(strings.TrimSpace(w.Name), trimmed) {
			return w, true
		}
	}

	spec, hasSpec := resolveInstitutionSpec(trimmed)

	// 2. Match against explicit institution_code.
	if hasSpec {
		for _, w := range wallets {
			if w.InstitutionCode != nil && strings.EqualFold(strings.TrimSpace(*w.InstitutionCode), spec.id) {
				return w, true
			}
		}
		// 3. Match wallet name against any known alias only when institution_code is unset,
		// so a wallet tagged with another institution (e.g. "blu" named "blu by BCA Digital")
		// is never matched when requesting "bca".
		for _, w := range wallets {
			if w.InstitutionCode != nil && strings.TrimSpace(*w.InstitutionCode) != "" {
				continue
			}
			nameTokens := tokenizeForMatch(w.Name)
			for _, alias := range spec.aliases {
				if matchTokenSequence(nameTokens, tokenizeForMatch(alias)) {
					return w, true
				}
			}
		}
		// 4. Physical cash wallet fallback when user asked for cash/tunai and owns a type="cash" wallet.
		if spec.id == "cash" {
			for _, w := range wallets {
				if w.InstitutionCode != nil && strings.TrimSpace(*w.InstitutionCode) != "" && !strings.EqualFold(strings.TrimSpace(*w.InstitutionCode), "cash") {
					continue
				}
				if strings.EqualFold(w.Type, "cash") {
					return w, true
				}
			}
		}
		return WalletSummaryItem{}, false
	}

	// 5. Custom unlisted wallet hint: match distinctive non-generic tokens in wallet name.
	hintTokens := filterGenericWalletTokens(tokenizeForMatch(trimmed))
	if len(hintTokens) == 0 {
		return WalletSummaryItem{}, false
	}
	for _, w := range wallets {
		nameTokens := tokenizeForMatch(w.Name)
		if matchTokenSequence(nameTokens, hintTokens) {
			return w, true
		}
	}
	return WalletSummaryItem{}, false
}

func resolveInstitutionSpec(hint string) (institutionSpec, bool) {
	tokens := tokenizeForMatch(hint)
	if len(tokens) == 0 {
		return institutionSpec{}, false
	}

	bestLen := 0
	var best institutionSpec
	matched := false
	for _, spec := range institutionCatalog {
		for _, alias := range spec.aliases {
			aliasToks := tokenizeForMatch(alias)
			if matchTokenSequence(tokens, aliasToks) {
				if !matched || len(aliasToks) > bestLen {
					bestLen = len(aliasToks)
					best = spec
					matched = true
				}
			}
		}
	}
	return best, matched
}

func buildMissingWalletDraft(hint string, wallets []WalletSummaryItem) *WalletCreationDraft {
	chips := make([]ExistingWalletChip, 0, len(wallets))
	for _, w := range wallets {
		chips = append(chips, ExistingWalletChip{
			ID:              w.ID,
			Name:            w.Name,
			Type:            w.Type,
			InstitutionCode: w.InstitutionCode,
			BalanceIDR:      w.BalanceIDR,
		})
	}

	trimmedHint := strings.TrimSpace(hint)
	if spec, ok := resolveInstitutionSpec(trimmedHint); ok {
		return &WalletCreationDraft{
			InstitutionID:     spec.id,
			InstitutionName:   spec.name,
			InstitutionType:   spec.wType,
			MissingWalletHint: trimmedHint,
			ExistingWallets:   chips,
		}
	}

	instName := toDisplayTitle(trimmedHint)
	if instName == "" {
		instName = "Dompet Baru"
	}
	instID := slugifyIdentifier(trimmedHint)
	if instID == "" {
		instID = "custom_wallet"
	}
	instType := inferInstitutionType(trimmedHint)

	return &WalletCreationDraft{
		InstitutionID:     instID,
		InstitutionName:   instName,
		InstitutionType:   instType,
		MissingWalletHint: trimmedHint,
		ExistingWallets:   chips,
	}
}

func filterGenericWalletTokens(tokens []string) []string {
	generic := map[string]struct{}{
		"bank":     {},
		"ewallet":  {},
		"wallet":   {},
		"dompet":   {},
		"rekening": {},
		"akun":     {},
		"kartu":    {},
	}
	out := make([]string, 0, len(tokens))
	for _, tok := range tokens {
		if _, skip := generic[tok]; !skip {
			out = append(out, tok)
		}
	}
	return out
}

func inferInstitutionType(hint string) string {
	lower := strings.ToLower(hint)
	switch {
	case strings.Contains(lower, "bank"):
		return "bank"
	case strings.Contains(lower, "pay") || strings.Contains(lower, "ewallet") || strings.Contains(lower, "e-wallet"):
		return "ewallet"
	case strings.Contains(lower, "cash") || strings.Contains(lower, "tunai"):
		return "cash"
	default:
		return "other"
	}
}

func slugifyIdentifier(s string) string {
	tokens := tokenizeForMatch(s)
	return strings.Join(tokens, "_")
}

func toDisplayTitle(s string) string {
	fields := strings.Fields(strings.TrimSpace(s))
	for i, f := range fields {
		runes := []rune(strings.ToLower(f))
		if len(runes) > 0 {
			runes[0] = unicode.ToUpper(runes[0])
		}
		fields[i] = string(runes)
	}
	return strings.Join(fields, " ")
}

func computeNextDueFromDay(todayWIB time.Time, dueDay int, frequency string, loc *time.Location) time.Time {
	candidate := clampedDate(todayWIB.Year(), todayWIB.Month(), dueDay, loc)
	if !candidate.Before(todayWIB) {
		return candidate
	}

	switch frequency {
	case "weekly":
		for candidate.Before(todayWIB) {
			candidate = candidate.AddDate(0, 0, 7)
		}
		return candidate
	case "yearly":
		return clampedDate(todayWIB.Year()+1, todayWIB.Month(), dueDay, loc)
	default: // "monthly"
		return clampedAddMonths(todayWIB.Year(), todayWIB.Month(), 1, dueDay, loc)
	}
}

func computeNextDueFromDate(todayWIB, baseDate time.Time, dueDay int, frequency string, loc *time.Location) time.Time {
	if !baseDate.Before(todayWIB) {
		return baseDate
	}
	candidate := baseDate
	switch frequency {
	case "weekly":
		for candidate.Before(todayWIB) {
			candidate = candidate.AddDate(0, 0, 7)
		}
		return candidate
	case "yearly":
		for yearOffset := 1; ; yearOffset++ {
			next := clampedDate(baseDate.Year()+yearOffset, baseDate.Month(), dueDay, loc)
			if !next.Before(todayWIB) {
				return next
			}
		}
	default: // "monthly"
		for monthOffset := 1; ; monthOffset++ {
			next := clampedAddMonths(baseDate.Year(), baseDate.Month(), monthOffset, dueDay, loc)
			if !next.Before(todayWIB) {
				return next
			}
		}
	}
}

func clampedAddMonths(year int, month time.Month, addMonths int, desiredDay int, loc *time.Location) time.Time {
	totalMonths := year*12 + (int(month) - 1) + addMonths
	targetYear := totalMonths / 12
	targetMonth := time.Month((totalMonths % 12) + 1)
	return clampedDate(targetYear, targetMonth, desiredDay, loc)
}

func clampedDate(year int, month time.Month, desiredDay int, loc *time.Location) time.Time {
	maxDay := daysInMonth(year, month)
	day := min(max(desiredDay, 1), maxDay)
	return time.Date(year, month, day, 0, 0, 0, 0, loc)
}

func daysInMonth(year int, month time.Month) int {
	// Day 0 of the following month is the last calendar day of (year, month).
	return time.Date(year, month+1, 0, 0, 0, 0, 0, time.UTC).Day()
}
