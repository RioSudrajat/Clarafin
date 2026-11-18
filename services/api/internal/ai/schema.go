package ai

import (
	"errors"
	"fmt"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"github.com/google/uuid"
)

// ErrInvalidStructuredResponse indicates Pass 2 output failed JSON or schema validation.
var ErrInvalidStructuredResponse = errors.New("invalid structured AI response")

// ToolParameterSchema describes an SDK-agnostic OpenAPI 3.0 subset schema for Gemini tools and responseSchema.
type ToolParameterSchema struct {
	Type             string                          `json:"type"`
	Description      string                          `json:"description,omitempty"`
	Enum             []string                        `json:"enum,omitempty"`
	Format           string                          `json:"format,omitempty"`
	Nullable         *bool                           `json:"nullable,omitempty"`
	Items            *ToolParameterSchema            `json:"items,omitempty"`
	Properties       map[string]*ToolParameterSchema `json:"properties,omitempty"`
	Required         []string                        `json:"required,omitempty"`
	PropertyOrdering []string                        `json:"property_ordering,omitempty"`
}

// ToolDeclaration defines a callable backend function exposed in Pass 1.
type ToolDeclaration struct {
	Name        string               `json:"name"`
	Description string               `json:"description"`
	Parameters  *ToolParameterSchema `json:"parameters,omitempty"`
}

// ThinkingStep represents one transparent process step shown in AiThinkingTraceWidget.
type ThinkingStep struct {
	StepNumber int    `json:"step_number"`
	Title      string `json:"title"`
	Detail     string `json:"detail"`
	Status     string `json:"status"`
}

// MoneyFlowCardPayload holds Sankey cashflow metrics backed strictly by GetCashflowSummary.
type MoneyFlowCardPayload struct {
	Period            string                `json:"period"`
	PeriodLabel       string                `json:"period_label"`
	TotalIncomeIDR    int64                 `json:"total_income_idr"`
	TotalExpenseIDR   int64                 `json:"total_expense_idr"`
	NetCashflowIDR    int64                 `json:"net_cashflow_idr"`
	TransactionCount  int64                 `json:"transaction_count"`
	IncomeSources     []FlowSourceNode      `json:"income_sources"`
	ExpenseCategories []ExpenseCategoryNode `json:"expense_categories"`
	FlowEdges         []FlowEdge            `json:"flow_edges"`
}

// SpendingBreakdownTablePayload holds sorted 3-column merchant metrics backed strictly by GetCashflowSummary.
type SpendingBreakdownTablePayload struct {
	Title            string                 `json:"title"`
	Period           string                 `json:"period"`
	PeriodLabel      string                 `json:"period_label"`
	KeywordFilter    string                 `json:"keyword_filter,omitempty"`
	TotalAmountIDR   int64                  `json:"total_amount_idr"`
	TransactionCount int64                  `json:"transaction_count"`
	Rows             []MerchantBreakdownRow `json:"rows"`
	SourceWallets    []string               `json:"source_wallets"`
	CategoriesUsed   []string               `json:"categories_used"`
}

// WalletCreationDraftPayload suggests creating a missing wallet and preserves pending transaction items.
type WalletCreationDraftPayload struct {
	InstitutionID     string                   `json:"institution_id"`
	InstitutionName   string                   `json:"institution_name"`
	InstitutionType   string                   `json:"institution_type"`
	MissingWalletHint string                   `json:"missing_wallet_hint,omitempty"`
	ExistingWallets   []ExistingWalletChip     `json:"existing_wallets"`
	PendingItems      []PendingTransactionItem `json:"pending_items,omitempty"`
}

// PackageBannerPayload describes the recommended official Clarafin catalog package.
type PackageBannerPayload struct {
	ID                     uuid.UUID               `json:"id"`
	PackageCode            string                  `json:"package_code"`
	ServiceCategory        string                  `json:"service_category"`
	CategoryTag            string                  `json:"category_tag"`
	Tier                   string                  `json:"tier"`
	SelectedTierLabel      string                  `json:"selected_tier_label"`
	ParticipantType        string                  `json:"participant_type"`
	PackageTitle           string                  `json:"package_title"`
	ShortDesc              string                  `json:"short_desc"`
	OnlineDurationMinutes  int32                   `json:"online_duration_minutes"`
	OfflineDurationMinutes int32                   `json:"offline_duration_minutes"`
	OnlinePriceIDR         int64                   `json:"online_price_idr"`
	OfflinePriceIDR        int64                   `json:"offline_price_idr"`
	RecommendedMethod      string                  `json:"recommended_method"`
	PrefilledIntakeSummary *PrefilledIntakeSummary `json:"prefilled_intake_summary,omitempty"`
}

// ConsultantCardPayload describes one scheduled verified practitioner card shown inside chat.
type ConsultantCardPayload struct {
	ConsultantID           string    `json:"consultant_id"`
	PractitionerUUID       uuid.UUID `json:"practitioner_uuid"`
	DisplayName            string    `json:"display_name"`
	TitleHeadline          string    `json:"title_headline"`
	AvatarURL              *string   `json:"avatar_url,omitempty"`
	Certifications         []string  `json:"certifications"`
	Tier                   string    `json:"tier"`
	Rating                 float64   `json:"rating"`
	ReviewCount            int32     `json:"review_count"`
	TotalSessionsCompleted int32     `json:"total_sessions_completed"`
	MatchReason            string    `json:"match_reason"`
	IsStaffPinned          bool      `json:"is_staff_pinned"`
	NextAvailableSlotLabel string    `json:"next_available_slot_label"`
	NextAvailableSlotISO   string    `json:"next_available_slot_iso"`
	PreferredSlotLabel     string    `json:"preferred_slot_label,omitempty"`
	PreferredSlotISO       string    `json:"preferred_slot_iso,omitempty"`
	PackageCode            string    `json:"package_code"`
	PackageTitle           string    `json:"package_title"`
	OnlinePriceIDR         int64     `json:"online_price_idr"`
	OfflinePriceIDR        int64     `json:"offline_price_idr"`
}

// AiStructuredResponse defines the strict Pass 2 JSON contract matching Flutter ai_chat_models.dart.
type AiStructuredResponse struct {
	Narrative              string                         `json:"narrative"`
	ThinkingSummary        []ThinkingStep                 `json:"thinking_summary"`
	MoneyFlowCard          *MoneyFlowCardPayload          `json:"money_flow_card,omitempty"`
	SpendingBreakdownTable *SpendingBreakdownTablePayload `json:"spending_breakdown_table,omitempty"`
	WalletCreationDraft    *WalletCreationDraftPayload    `json:"wallet_creation_draft,omitempty"`
	TransactionDraft       *TransactionDraftPayload       `json:"transaction_draft,omitempty"`
	GoalDraft              *GoalDraftPayload              `json:"goal_draft,omitempty"`
	BudgetDraft            *BudgetDraftPayload            `json:"budget_draft,omitempty"`
	BillDraft              *BillDraftPayload              `json:"bill_draft,omitempty"`
	RecommendedPackage     *PackageBannerPayload          `json:"recommended_package,omitempty"`
	RecommendedConsultants []ConsultantCardPayload        `json:"recommended_consultants,omitempty"`
}

// CanonicalCategoryEnum returns all verbatim TransactionCategories names plus Transfer in deterministic order.
func CanonicalCategoryEnum() []string {
	seen := make(map[string]struct{}, len(canonicalCatalog)+2)
	out := make([]string, 0, len(canonicalCatalog)+1)
	for _, def := range canonicalCatalog {
		if _, dup := seen[def.canonicalName]; dup {
			continue
		}
		seen[def.canonicalName] = struct{}{}
		out = append(out, def.canonicalName)
	}
	if _, ok := seen["Transfer"]; !ok {
		out = append(out, "Transfer")
	}
	sort.Strings(out)
	return out
}

// CanonicalExpenseMainCategoryEnum returns all 18 top-level expense category names for BudgetDraft.
func CanonicalExpenseMainCategoryEnum() []string {
	seen := make(map[string]struct{})
	out := make([]string, 0, 18)
	for _, def := range canonicalCatalog {
		if def.txType != "expense" || !def.isParent {
			continue
		}
		if _, dup := seen[def.mainName]; dup {
			continue
		}
		seen[def.mainName] = struct{}{}
		out = append(out, def.mainName)
	}
	sort.Strings(out)
	return out
}

// BuildStructuredResponseSchema constructs the strict OpenAPI schema used in Pass 2 responseSchema.
func BuildStructuredResponseSchema() *ToolParameterSchema {
	catEnum := CanonicalCategoryEnum()
	expenseMainEnum := CanonicalExpenseMainCategoryEnum()

	return &ToolParameterSchema{
		Type: "OBJECT",
		Properties: map[string]*ToolParameterSchema{
			"narrative": {
				Type:        "STRING",
				Description: "Natural Indonesian response formatted with integer IDR Rp X.XXX and zero em dashes.",
			},
			"thinking_summary": {
				Type: "ARRAY",
				Items: &ToolParameterSchema{
					Type: "OBJECT",
					Properties: map[string]*ToolParameterSchema{
						"step_number": {Type: "INTEGER"},
						"title":       {Type: "STRING"},
						"detail":      {Type: "STRING"},
						"status":      {Type: "STRING", Enum: []string{"completed", "in_progress", "failed"}},
					},
					Required: []string{"step_number", "title", "detail", "status"},
				},
			},
			"money_flow_card": nullableSchema(&ToolParameterSchema{
				Type: "OBJECT",
				Properties: map[string]*ToolParameterSchema{
					"period":            {Type: "STRING"},
					"period_label":      {Type: "STRING"},
					"total_income_idr":  {Type: "INTEGER"},
					"total_expense_idr": {Type: "INTEGER"},
					"net_cashflow_idr":  {Type: "INTEGER"},
					"transaction_count": {Type: "INTEGER"},
					"income_sources": {
						Type: "ARRAY",
						Items: &ToolParameterSchema{
							Type: "OBJECT",
							Properties: map[string]*ToolParameterSchema{
								"category":  {Type: "STRING"},
								"amount":    {Type: "INTEGER"},
								"share_pct": {Type: "NUMBER"},
								"tx_count":  {Type: "INTEGER"},
							},
							Required: []string{"category", "amount", "share_pct", "tx_count"},
						},
					},
					"expense_categories": {
						Type: "ARRAY",
						Items: &ToolParameterSchema{
							Type: "OBJECT",
							Properties: map[string]*ToolParameterSchema{
								"category":  {Type: "STRING"},
								"amount":    {Type: "INTEGER"},
								"share_pct": {Type: "NUMBER"},
								"tx_count":  {Type: "INTEGER"},
							},
							Required: []string{"category", "amount", "share_pct", "tx_count"},
						},
					},
					"flow_edges": {
						Type: "ARRAY",
						Items: &ToolParameterSchema{
							Type: "OBJECT",
							Properties: map[string]*ToolParameterSchema{
								"source_category":  {Type: "STRING"},
								"target_category":  {Type: "STRING"},
								"flow_amount":      {Type: "INTEGER"},
								"source_total":     {Type: "INTEGER"},
								"target_total":     {Type: "INTEGER"},
								"expense_tx_count": {Type: "INTEGER"},
							},
							Required: []string{"source_category", "target_category", "flow_amount"},
						},
					},
				},
				Required: []string{"period", "period_label", "total_income_idr", "total_expense_idr", "net_cashflow_idr", "transaction_count"},
			}),
			"spending_breakdown_table": nullableSchema(&ToolParameterSchema{
				Type: "OBJECT",
				Properties: map[string]*ToolParameterSchema{
					"title":             {Type: "STRING"},
					"period":            {Type: "STRING"},
					"period_label":      {Type: "STRING"},
					"keyword_filter":    {Type: "STRING"},
					"total_amount_idr":  {Type: "INTEGER"},
					"transaction_count": {Type: "INTEGER"},
					"rows": {
						Type: "ARRAY",
						Items: &ToolParameterSchema{
							Type: "OBJECT",
							Properties: map[string]*ToolParameterSchema{
								"merchant":     {Type: "STRING"},
								"tx_count":     {Type: "INTEGER"},
								"total_amount": {Type: "INTEGER"},
								"wallet_names": {Type: "ARRAY", Items: &ToolParameterSchema{Type: "STRING"}},
								"categories":   {Type: "ARRAY", Items: &ToolParameterSchema{Type: "STRING"}},
							},
							Required: []string{"merchant", "tx_count", "total_amount"},
						},
					},
					"source_wallets":  {Type: "ARRAY", Items: &ToolParameterSchema{Type: "STRING"}},
					"categories_used": {Type: "ARRAY", Items: &ToolParameterSchema{Type: "STRING"}},
				},
				Required: []string{"title", "period", "total_amount_idr", "transaction_count", "rows"},
			}),
			"wallet_creation_draft": nullableSchema(&ToolParameterSchema{
				Type: "OBJECT",
				Properties: map[string]*ToolParameterSchema{
					"institution_id":      {Type: "STRING"},
					"institution_name":    {Type: "STRING"},
					"institution_type":    {Type: "STRING"},
					"missing_wallet_hint": {Type: "STRING"},
					"existing_wallets": {
						Type: "ARRAY",
						Items: &ToolParameterSchema{
							Type: "OBJECT",
							Properties: map[string]*ToolParameterSchema{
								"id":               {Type: "STRING"},
								"name":             {Type: "STRING"},
								"type":             {Type: "STRING"},
								"institution_code": {Type: "STRING", Nullable: boolPtr(true)},
								"balance_idr":      {Type: "INTEGER"},
							},
							Required: []string{"name", "type", "balance_idr"},
						},
					},
					"pending_items": {
						Type: "ARRAY",
						Items: &ToolParameterSchema{
							Type: "OBJECT",
							Properties: map[string]*ToolParameterSchema{
								"title":                   {Type: "STRING"},
								"amount_idr":              {Type: "INTEGER"},
								"type":                    {Type: "STRING", Enum: []string{"income", "expense", "transfer"}},
								"canonical_category":      {Type: "STRING", Enum: catEnum},
								"canonical_main_category": {Type: "STRING"},
							},
							Required: []string{"title", "amount_idr", "type", "canonical_category", "canonical_main_category"},
						},
					},
				},
				Required: []string{"institution_id", "institution_name", "institution_type"},
			}),
			"transaction_draft": nullableSchema(&ToolParameterSchema{
				Type: "OBJECT",
				Properties: map[string]*ToolParameterSchema{
					"total_amount_idr": {Type: "INTEGER"},
					"item_count":       {Type: "INTEGER"},
					"items": {
						Type: "ARRAY",
						Items: &ToolParameterSchema{
							Type: "OBJECT",
							Properties: map[string]*ToolParameterSchema{
								"title":                   {Type: "STRING"},
								"amount_idr":              {Type: "INTEGER"},
								"type":                    {Type: "STRING", Enum: []string{"income", "expense", "transfer"}},
								"canonical_category":      {Type: "STRING", Enum: catEnum},
								"canonical_main_category": {Type: "STRING"},
								"wallet_id":               {Type: "STRING"},
								"wallet_name":             {Type: "STRING"},
								"target_wallet_id":        {Type: "STRING", Nullable: boolPtr(true)},
								"target_wallet_name":      {Type: "STRING", Nullable: boolPtr(true)},
								"note":                    {Type: "STRING"},
							},
							Required: []string{"title", "amount_idr", "type", "canonical_category", "canonical_main_category", "wallet_name"},
						},
					},
				},
				Required: []string{"total_amount_idr", "item_count", "items"},
			}),
			"goal_draft": nullableSchema(&ToolParameterSchema{
				Type: "OBJECT",
				Properties: map[string]*ToolParameterSchema{
					"title":                       {Type: "STRING"},
					"target_amount_idr":           {Type: "INTEGER"},
					"saved_amount_idr":            {Type: "INTEGER"},
					"remaining_amount_idr":        {Type: "INTEGER"},
					"target_date":                 {Type: "STRING", Nullable: boolPtr(true)},
					"months_remaining":            {Type: "INTEGER"},
					"monthly_saving_estimate_idr": {Type: "INTEGER"},
					"priority":                    {Type: "STRING", Enum: []string{"urgent", "needs", "wants"}},
					"linked_wallet_id":            {Type: "STRING", Nullable: boolPtr(true)},
					"linked_wallet_name":          {Type: "STRING", Nullable: boolPtr(true)},
					"source_asset_label":          {Type: "STRING", Nullable: boolPtr(true)},
				},
				Required: []string{"title", "target_amount_idr", "priority"},
			}),
			"budget_draft": nullableSchema(&ToolParameterSchema{
				Type: "OBJECT",
				Properties: map[string]*ToolParameterSchema{
					"category":                {Type: "STRING", Enum: expenseMainEnum},
					"month_year":              {Type: "STRING"},
					"limit_amount_idr":        {Type: "INTEGER"},
					"current_month_spend_idr": {Type: "INTEGER"},
					"avg_30d_spend_idr":       {Type: "INTEGER"},
					"existing_limit_idr":      {Type: "INTEGER", Nullable: boolPtr(true)},
					"is_update":               {Type: "BOOLEAN"},
				},
				Required: []string{"category", "month_year", "limit_amount_idr"},
			}),
			"bill_draft": nullableSchema(&ToolParameterSchema{
				Type: "OBJECT",
				Properties: map[string]*ToolParameterSchema{
					"title":                   {Type: "STRING"},
					"canonical_category":      {Type: "STRING", Enum: catEnum},
					"canonical_main_category": {Type: "STRING"},
					"amount_idr":              {Type: "INTEGER"},
					"due_day":                 {Type: "INTEGER"},
					"next_due_date":           {Type: "STRING"},
					"frequency":               {Type: "STRING", Enum: []string{"weekly", "monthly", "yearly"}},
					"auto_pay":                {Type: "BOOLEAN"},
				},
				Required: []string{"title", "canonical_category", "amount_idr", "due_day", "next_due_date", "frequency"},
			}),
			"recommended_package": nullableSchema(&ToolParameterSchema{
				Type: "OBJECT",
				Properties: map[string]*ToolParameterSchema{
					"package_code":       {Type: "STRING"},
					"service_category":   {Type: "STRING"},
					"category_tag":       {Type: "STRING"},
					"tier":               {Type: "STRING"},
					"package_title":      {Type: "STRING"},
					"short_desc":         {Type: "STRING"},
					"online_price_idr":   {Type: "INTEGER"},
					"offline_price_idr":  {Type: "INTEGER"},
					"recommended_method": {Type: "STRING"},
				},
				Required: []string{"package_code", "category_tag", "package_title", "online_price_idr"},
			}),
			"recommended_consultants": nullableSchema(&ToolParameterSchema{
				Type: "ARRAY",
				Items: &ToolParameterSchema{
					Type: "OBJECT",
					Properties: map[string]*ToolParameterSchema{
						"consultant_id":             {Type: "STRING"},
						"display_name":              {Type: "STRING"},
						"title_headline":            {Type: "STRING"},
						"tier":                      {Type: "STRING"},
						"rating":                    {Type: "NUMBER"},
						"match_reason":              {Type: "STRING"},
						"next_available_slot_label": {Type: "STRING"},
						"next_available_slot_iso":   {Type: "STRING"},
						"package_code":              {Type: "STRING"},
						"online_price_idr":          {Type: "INTEGER"},
					},
					Required: []string{"consultant_id", "display_name", "tier", "match_reason", "next_available_slot_label"},
				},
			}),
		},
		Required: []string{"narrative", "thinking_summary"},
	}
}

// BuildQuickDraftExtractionSchema constructs the strict JSON schema for quick-add and OCR receipt extraction.
func BuildQuickDraftExtractionSchema() *ToolParameterSchema {
	return &ToolParameterSchema{
		Type: "OBJECT",
		Properties: map[string]*ToolParameterSchema{
			"default_wallet_hint": {Type: "STRING"},
			"confidence_score":    {Type: "NUMBER"},
			"items": {
				Type: "ARRAY",
				Items: &ToolParameterSchema{
					Type: "OBJECT",
					Properties: map[string]*ToolParameterSchema{
						"title":              {Type: "STRING"},
						"amount_idr":         {Type: "INTEGER"},
						"type":               {Type: "STRING", Enum: []string{"income", "expense", "transfer"}},
						"raw_category":       {Type: "STRING"},
						"note":               {Type: "STRING"},
						"wallet_hint":        {Type: "STRING"},
						"target_wallet_hint": {Type: "STRING"},
					},
					Required: []string{"title", "amount_idr", "type", "raw_category"},
				},
			},
		},
		Required: []string{"items"},
	}
}

// ValidateStructuredResponse checks structural validity of Pass 2 output before anti-hallucination reconciliation.
func ValidateStructuredResponse(resp *AiStructuredResponse) error {
	if resp == nil {
		return fmt.Errorf("%w: response is nil", ErrInvalidStructuredResponse)
	}
	if strings.TrimSpace(resp.Narrative) == "" {
		return fmt.Errorf("%w: narrative must not be empty", ErrInvalidStructuredResponse)
	}
	if resp.ThinkingSummary == nil {
		resp.ThinkingSummary = []ThinkingStep{}
	}
	if resp.TransactionDraft != nil {
		if len(resp.TransactionDraft.Items) == 0 {
			return fmt.Errorf("%w: transaction_draft.items must not be empty", ErrInvalidStructuredResponse)
		}
		for i, item := range resp.TransactionDraft.Items {
			if strings.TrimSpace(item.Title) == "" || item.AmountIDR <= 0 {
				return fmt.Errorf("%w: transaction_draft.items[%d] has invalid title or amount_idr", ErrInvalidStructuredResponse, i)
			}
			switch strings.ToLower(strings.TrimSpace(item.Type)) {
			case "income", "expense", "transfer":
			default:
				return fmt.Errorf("%w: transaction_draft.items[%d] unsupported type %q", ErrInvalidStructuredResponse, i, item.Type)
			}
		}
	}
	if resp.GoalDraft != nil {
		if strings.TrimSpace(resp.GoalDraft.Title) == "" || resp.GoalDraft.TargetAmountIDR <= 0 {
			return fmt.Errorf("%w: goal_draft has invalid title or target_amount_idr", ErrInvalidStructuredResponse)
		}
	}
	if resp.BudgetDraft != nil {
		if strings.TrimSpace(resp.BudgetDraft.Category) == "" || resp.BudgetDraft.LimitAmountIDR <= 0 {
			return fmt.Errorf("%w: budget_draft has invalid category or limit_amount_idr", ErrInvalidStructuredResponse)
		}
	}
	if resp.BillDraft != nil {
		if strings.TrimSpace(resp.BillDraft.Title) == "" || resp.BillDraft.AmountIDR <= 0 {
			return fmt.Errorf("%w: bill_draft has invalid title or amount_idr", ErrInvalidStructuredResponse)
		}
	}
	if len(resp.RecommendedConsultants) > 3 {
		return fmt.Errorf("%w: recommended_consultants exceeds max 3 items", ErrInvalidStructuredResponse)
	}
	return nil
}

// Pass1ToolBundle stores deterministic Pass 1 Go tool outputs used to guard Pass 2 against numeric drift.
type Pass1ToolBundle struct {
	Wallets          *WalletsToolOutput
	FlowCashflow     *CashflowSummaryOutput
	MerchantCashflow *CashflowSummaryOutput
	CategoryCashflow *CashflowSummaryOutput
	WalletCashflow   *CashflowSummaryOutput
	BudgetBills      *BudgetBillsOutput
	PrepareTx        *PrepareTransactionResult
	TxChecks         []*PrepareTransactionResult
	GoalDraft        *GoalDraftPayload
	BudgetDraft      *BudgetDraftPayload
	BillDraft        *BillDraftPayload
	Matching         *MatchingOutput
	SearchSummaries  []string
	SearchSources    []string
	ExecutedSteps    []ThinkingStep
}

// ValidateAndReconcileStructuredResponse enforces numeric and entity alignment between Pass 2 JSON and Pass 1 deterministic tools.
// Any drifted numbers, missing IDs, or fabricated ungrounded cards are corrected or stripped deterministically.
func ValidateAndReconcileStructuredResponse(resp *AiStructuredResponse, bundle *Pass1ToolBundle) ([]string, error) {
	if resp == nil {
		return nil, fmt.Errorf("%w: response is nil", ErrInvalidStructuredResponse)
	}
	if strings.TrimSpace(resp.Narrative) == "" {
		return nil, fmt.Errorf("%w: narrative must not be empty", ErrInvalidStructuredResponse)
	}
	if resp.ThinkingSummary == nil {
		resp.ThinkingSummary = []ThinkingStep{}
	}

	var corrections []string

	// Enforce R-02 (no em dashes) and Rp X.XXX integer IDR narrative formatting.
	cleanedNarrative := NormalizeNarrativeIDR(sanitizeNoEmDash(resp.Narrative))
	if cleanedNarrative != resp.Narrative {
		resp.Narrative = cleanedNarrative
		corrections = append(corrections, "normalized narrative formatting")
	}

	for i := range resp.ThinkingSummary {
		resp.ThinkingSummary[i].Title = sanitizeNoEmDash(resp.ThinkingSummary[i].Title)
		resp.ThinkingSummary[i].Detail = sanitizeNoEmDash(resp.ThinkingSummary[i].Detail)
	}

	if bundle == nil {
		if err := ValidateStructuredResponse(resp); err != nil {
			return nil, err
		}
		return corrections, nil
	}

	if len(resp.ThinkingSummary) == 0 && len(bundle.ExecutedSteps) > 0 {
		resp.ThinkingSummary = append([]ThinkingStep(nil), bundle.ExecutedSteps...)
	}

	// 1. Reconcile TransactionDraft vs WalletCreationDraft (prerequisite wallet check).
	if bundle.PrepareTx != nil {
		if bundle.PrepareTx.Status == "missing_wallet" {
			if resp.TransactionDraft != nil {
				resp.TransactionDraft = nil
				corrections = append(corrections, "withheld transaction_draft due to missing_wallet")
			}
			if bundle.PrepareTx.WalletCreationDraft != nil {
				expectedWalletDraft := &WalletCreationDraftPayload{
					InstitutionID:     bundle.PrepareTx.WalletCreationDraft.InstitutionID,
					InstitutionName:   bundle.PrepareTx.WalletCreationDraft.InstitutionName,
					InstitutionType:   bundle.PrepareTx.WalletCreationDraft.InstitutionType,
					MissingWalletHint: bundle.PrepareTx.WalletCreationDraft.MissingWalletHint,
					ExistingWallets:   append([]ExistingWalletChip(nil), bundle.PrepareTx.WalletCreationDraft.ExistingWallets...),
					PendingItems:      append([]PendingTransactionItem(nil), bundle.PrepareTx.PendingItems...),
				}
				if !walletCreationDraftsEqual(resp.WalletCreationDraft, expectedWalletDraft) {
					corrections = append(corrections, "hydrated wallet_creation_draft from Pass 1")
				}
				resp.WalletCreationDraft = expectedWalletDraft
			}
		} else if bundle.PrepareTx.TransactionDraft != nil {
			if resp.WalletCreationDraft != nil {
				resp.WalletCreationDraft = nil
				corrections = append(corrections, "cleared wallet_creation_draft for ready wallet")
			}
			if !txDraftsEqual(resp.TransactionDraft, bundle.PrepareTx.TransactionDraft) {
				corrections = append(corrections, "reconciled transaction_draft numbers/ids from Pass 1")
			}
			resp.TransactionDraft = cloneTransactionDraft(bundle.PrepareTx.TransactionDraft)
		}
	} else {
		if resp.TransactionDraft != nil {
			resp.TransactionDraft = nil
			corrections = append(corrections, "stripped ungrounded transaction_draft")
		}
		if resp.WalletCreationDraft != nil {
			resp.WalletCreationDraft = nil
			corrections = append(corrections, "stripped ungrounded wallet_creation_draft")
		}
	}

	// 2. Reconcile MoneyFlowCard against SQL income_to_expense_flow output.
	if bundle.FlowCashflow != nil {
		expected := buildMoneyFlowCard(bundle.FlowCashflow)
		if !moneyFlowCardsEqual(resp.MoneyFlowCard, expected) {
			corrections = append(corrections, "reconciled money_flow_card from Pass 1 SQL summary")
		}
		resp.MoneyFlowCard = expected
	} else if resp.MoneyFlowCard != nil {
		resp.MoneyFlowCard = nil
		corrections = append(corrections, "stripped ungrounded money_flow_card")
	}

	// 3. Reconcile SpendingBreakdownTable against SQL merchant, category, or wallet output.
	if bundle.MerchantCashflow != nil {
		customTitle := ""
		if resp.SpendingBreakdownTable != nil {
			customTitle = strings.TrimSpace(sanitizeNoEmDash(resp.SpendingBreakdownTable.Title))
		}
		expected := buildSpendingBreakdownTable(bundle.MerchantCashflow, customTitle)
		if !spendingTablesEqual(resp.SpendingBreakdownTable, expected) {
			corrections = append(corrections, "reconciled spending_breakdown_table from Pass 1 SQL summary")
		}
		resp.SpendingBreakdownTable = expected
	} else if bundle.FlowCashflow == nil && (bundle.CategoryCashflow != nil || bundle.WalletCashflow != nil) {
		customTitle := ""
		if resp.SpendingBreakdownTable != nil {
			customTitle = strings.TrimSpace(sanitizeNoEmDash(resp.SpendingBreakdownTable.Title))
		}
		var expected *SpendingBreakdownTablePayload
		if bundle.CategoryCashflow != nil {
			expected = buildCategorySpendingBreakdownTable(bundle.CategoryCashflow, customTitle)
		} else if bundle.WalletCashflow != nil {
			expected = buildWalletSpendingBreakdownTable(bundle.WalletCashflow, customTitle)
		}
		if expected != nil {
			if !spendingTablesEqual(resp.SpendingBreakdownTable, expected) {
				corrections = append(corrections, "reconciled spending_breakdown_table from Pass 1 SQL summary")
			}
			resp.SpendingBreakdownTable = expected
		} else if resp.SpendingBreakdownTable != nil {
			resp.SpendingBreakdownTable = nil
			corrections = append(corrections, "stripped ungrounded spending_breakdown_table")
		}
	} else if resp.SpendingBreakdownTable != nil {
		resp.SpendingBreakdownTable = nil
		corrections = append(corrections, "stripped ungrounded spending_breakdown_table")
	}

	// 4. Reconcile GoalDraft, BudgetDraft, BillDraft against deterministic ActionTools outputs.
	if bundle.GoalDraft != nil {
		if !goalDraftsEqual(resp.GoalDraft, bundle.GoalDraft) {
			corrections = append(corrections, "reconciled goal_draft from Pass 1")
		}
		cp := *bundle.GoalDraft
		resp.GoalDraft = &cp
	} else if resp.GoalDraft != nil {
		resp.GoalDraft = nil
		corrections = append(corrections, "stripped ungrounded goal_draft")
	}

	if bundle.BudgetDraft != nil {
		if !budgetDraftsEqual(resp.BudgetDraft, bundle.BudgetDraft) {
			corrections = append(corrections, "reconciled budget_draft from Pass 1")
		}
		cp := *bundle.BudgetDraft
		resp.BudgetDraft = &cp
	} else if resp.BudgetDraft != nil {
		resp.BudgetDraft = nil
		corrections = append(corrections, "stripped ungrounded budget_draft")
	}

	if bundle.BillDraft != nil {
		if !billDraftsEqual(resp.BillDraft, bundle.BillDraft) {
			corrections = append(corrections, "reconciled bill_draft from Pass 1")
		}
		cp := *bundle.BillDraft
		resp.BillDraft = &cp
	} else if resp.BillDraft != nil {
		resp.BillDraft = nil
		corrections = append(corrections, "stripped ungrounded bill_draft")
	}

	// 5. Reconcile RecommendedPackage and RecommendedConsultants against MatchingTool output.
	if bundle.Matching != nil {
		expectedPkg := buildPackageBannerPayload(bundle.Matching)
		if !packageBannersEqual(resp.RecommendedPackage, expectedPkg) {
			corrections = append(corrections, "reconciled recommended_package from Pass 1")
		}
		resp.RecommendedPackage = expectedPkg

		expectedCons := buildConsultantCardPayloads(bundle.Matching, resp.RecommendedConsultants)
		if !consultantSlicesEqual(resp.RecommendedConsultants, expectedCons) {
			corrections = append(corrections, "reconciled recommended_consultants from Pass 1")
		}
		resp.RecommendedConsultants = expectedCons
	} else {
		if resp.RecommendedPackage != nil {
			resp.RecommendedPackage = nil
			corrections = append(corrections, "stripped ungrounded recommended_package")
		}
		if len(resp.RecommendedConsultants) > 0 {
			resp.RecommendedConsultants = nil
			corrections = append(corrections, "stripped ungrounded recommended_consultants")
		}
	}

	if err := ValidateStructuredResponse(resp); err != nil {
		return nil, err
	}

	return corrections, nil
}

var (
	idrTokenRegexp           = regexp.MustCompile(`(?i)\b(?:rp\.?|idr)\s*([0-9]+(?:\.[0-9]{3})*)(?:(?:,[0-9]{1,2}\b)|(?:\.[0-9]{1,2}\b))?`)
	idrScaleUnitPrefixRegexp = regexp.MustCompile(`(?i)^[ \t]*(?:rb|ribu|k|jt|juta|m|miliar|milyar|t|triliun)\b`)
)

// FormatIDR formats an integer Rupiah amount with Indonesian thousand dot separators (Rp X.XXX).
func FormatIDR(amount int64) string {
	neg := amount < 0
	abs := amount
	if neg {
		abs = -abs
	}
	digits := strconv.FormatInt(abs, 10)
	if len(digits) <= 3 {
		if neg {
			return "-Rp " + digits
		}
		return "Rp " + digits
	}

	var b strings.Builder
	if neg {
		b.WriteString("-Rp ")
	} else {
		b.WriteString("Rp ")
	}
	rem := len(digits) % 3
	if rem > 0 {
		b.WriteString(digits[:rem])
		if len(digits) > rem {
			b.WriteByte('.')
		}
	}
	for i := rem; i < len(digits); i += 3 {
		if i > rem {
			b.WriteByte('.')
		}
		b.WriteString(digits[i : i+3])
	}
	return b.String()
}

// NormalizeNarrativeIDR standardizes Rupiah amounts in narrative prose to integer "Rp X.XXX".
func NormalizeNarrativeIDR(text string) string {
	matches := idrTokenRegexp.FindAllStringSubmatchIndex(text, -1)
	if len(matches) == 0 {
		return text
	}

	var b strings.Builder
	lastIdx := 0
	for _, m := range matches {
		fullStart, fullEnd := m[0], m[1]
		numStart, numEnd := m[2], m[3]
		if fullEnd < len(text) {
			next := text[fullEnd]
			if next >= '0' && next <= '9' {
				continue
			}
			// Guard unmatched comma/dot numeric suffixes (e.g. "Rp 2,500" or "Rp 2000.5jt")
			// while still formatting tokens followed by prose punctuation (e.g. "Rp 8000000.00, detail").
			if (next == ',' || next == '.') && fullEnd+1 < len(text) && text[fullEnd+1] >= '0' && text[fullEnd+1] <= '9' {
				continue
			}
		}
		// Leave fractional scale expressions (e.g. "Rp 1,5 juta", "Rp 2.5 jt") untouched so
		// normalizing to integer Rupiah never silently drops the fractional magnitude.
		if fullEnd > numEnd && idrScaleUnitPrefixRegexp.MatchString(text[fullEnd:]) {
			continue
		}
		rawDigits := strings.ReplaceAll(text[numStart:numEnd], ".", "")
		val, err := strconv.ParseInt(rawDigits, 10, 64)
		if err != nil {
			continue
		}
		b.WriteString(text[lastIdx:fullStart])
		b.WriteString(FormatIDR(val))
		lastIdx = fullEnd
	}
	if lastIdx == 0 {
		return text
	}
	b.WriteString(text[lastIdx:])
	return b.String()
}

func sanitizeNoEmDash(s string) string {
	if !strings.Contains(s, "\u2014") {
		return s
	}
	replaced := strings.ReplaceAll(s, " \u2014 ", ", ")
	return strings.ReplaceAll(replaced, "\u2014", ", ")
}

func boolPtr(v bool) *bool {
	return &v
}

func nullableSchema(inner *ToolParameterSchema) *ToolParameterSchema {
	if inner == nil {
		return nil
	}
	inner.Nullable = boolPtr(true)
	return inner
}

func cloneTransactionDraft(src *TransactionDraftPayload) *TransactionDraftPayload {
	if src == nil {
		return nil
	}
	items := make([]TransactionDraftItem, len(src.Items))
	copy(items, src.Items)
	return &TransactionDraftPayload{
		Items:          items,
		TotalAmountIDR: src.TotalAmountIDR,
		ItemCount:      src.ItemCount,
	}
}

func walletCreationDraftsEqual(a, b *WalletCreationDraftPayload) bool {
	if a == nil || b == nil {
		return a == b
	}
	if a.InstitutionID != b.InstitutionID ||
		a.InstitutionName != b.InstitutionName ||
		a.InstitutionType != b.InstitutionType ||
		len(a.ExistingWallets) != len(b.ExistingWallets) ||
		len(a.PendingItems) != len(b.PendingItems) {
		return false
	}
	for i := range a.ExistingWallets {
		if a.ExistingWallets[i].ID != b.ExistingWallets[i].ID ||
			a.ExistingWallets[i].Name != b.ExistingWallets[i].Name ||
			a.ExistingWallets[i].BalanceIDR != b.ExistingWallets[i].BalanceIDR {
			return false
		}
	}
	for i := range a.PendingItems {
		if a.PendingItems[i].Title != b.PendingItems[i].Title ||
			a.PendingItems[i].AmountIDR != b.PendingItems[i].AmountIDR ||
			a.PendingItems[i].Type != b.PendingItems[i].Type ||
			a.PendingItems[i].CanonicalCategory != b.PendingItems[i].CanonicalCategory {
			return false
		}
	}
	return true
}

func uuidPtrEqual(a, b *uuid.UUID) bool {
	if a == nil || b == nil {
		return a == b
	}
	return *a == *b
}

func strPtrEqual(a, b *string) bool {
	if a == nil || b == nil {
		return a == b
	}
	return *a == *b
}

func txDraftsEqual(a, b *TransactionDraftPayload) bool {
	if a == nil || b == nil {
		return a == b
	}
	if a.TotalAmountIDR != b.TotalAmountIDR || a.ItemCount != b.ItemCount || len(a.Items) != len(b.Items) {
		return false
	}
	for i := range a.Items {
		if a.Items[i].Title != b.Items[i].Title ||
			a.Items[i].AmountIDR != b.Items[i].AmountIDR ||
			a.Items[i].Type != b.Items[i].Type ||
			a.Items[i].CanonicalCategory != b.Items[i].CanonicalCategory ||
			a.Items[i].CanonicalMainCategory != b.Items[i].CanonicalMainCategory ||
			a.Items[i].WalletID != b.Items[i].WalletID ||
			a.Items[i].WalletName != b.Items[i].WalletName ||
			!uuidPtrEqual(a.Items[i].TargetWalletID, b.Items[i].TargetWalletID) ||
			!strPtrEqual(a.Items[i].TargetWalletName, b.Items[i].TargetWalletName) {
			return false
		}
	}
	return true
}

func buildMoneyFlowCard(cf *CashflowSummaryOutput) *MoneyFlowCardPayload {
	return &MoneyFlowCardPayload{
		Period:            cf.Period,
		PeriodLabel:       cf.PeriodLabel,
		TotalIncomeIDR:    cf.TotalIncomeIDR,
		TotalExpenseIDR:   cf.TotalExpenseIDR,
		NetCashflowIDR:    cf.NetCashflowIDR,
		TransactionCount:  cf.TransactionCount,
		IncomeSources:     append([]FlowSourceNode(nil), cf.IncomeSources...),
		ExpenseCategories: append([]ExpenseCategoryNode(nil), cf.ExpenseCategories...),
		FlowEdges:         append([]FlowEdge(nil), cf.FlowEdges...),
	}
}

func moneyFlowCardsEqual(a, b *MoneyFlowCardPayload) bool {
	if a == nil || b == nil {
		return a == b
	}
	if a.Period != b.Period ||
		a.PeriodLabel != b.PeriodLabel ||
		a.TotalIncomeIDR != b.TotalIncomeIDR ||
		a.TotalExpenseIDR != b.TotalExpenseIDR ||
		a.NetCashflowIDR != b.NetCashflowIDR ||
		a.TransactionCount != b.TransactionCount ||
		len(a.IncomeSources) != len(b.IncomeSources) ||
		len(a.ExpenseCategories) != len(b.ExpenseCategories) ||
		len(a.FlowEdges) != len(b.FlowEdges) {
		return false
	}
	for i := range a.IncomeSources {
		if a.IncomeSources[i].Category != b.IncomeSources[i].Category ||
			a.IncomeSources[i].Amount != b.IncomeSources[i].Amount ||
			a.IncomeSources[i].TxCount != b.IncomeSources[i].TxCount {
			return false
		}
	}
	for i := range a.ExpenseCategories {
		if a.ExpenseCategories[i].Category != b.ExpenseCategories[i].Category ||
			a.ExpenseCategories[i].Amount != b.ExpenseCategories[i].Amount ||
			a.ExpenseCategories[i].TxCount != b.ExpenseCategories[i].TxCount {
			return false
		}
	}
	for i := range a.FlowEdges {
		if a.FlowEdges[i].SourceCategory != b.FlowEdges[i].SourceCategory ||
			a.FlowEdges[i].TargetCategory != b.FlowEdges[i].TargetCategory ||
			a.FlowEdges[i].FlowAmount != b.FlowEdges[i].FlowAmount {
			return false
		}
	}
	return true
}

func buildSpendingBreakdownTable(cf *CashflowSummaryOutput, customTitle string) *SpendingBreakdownTablePayload {
	title := customTitle
	if title == "" {
		if cf.KeywordFilter != "" {
			title = fmt.Sprintf("Rincian pengeluaran %s (%s)", cf.KeywordFilter, cf.PeriodLabel)
		} else {
			title = fmt.Sprintf("Rincian pengeluaran (%s)", cf.PeriodLabel)
		}
	}
	txCount := cf.ExpenseCount
	if txCount == 0 {
		txCount = cf.TransactionCount
	}
	return &SpendingBreakdownTablePayload{
		Title:            title,
		Period:           cf.Period,
		PeriodLabel:      cf.PeriodLabel,
		KeywordFilter:    cf.KeywordFilter,
		TotalAmountIDR:   cf.TotalExpenseIDR,
		TransactionCount: txCount,
		Rows:             append([]MerchantBreakdownRow(nil), cf.MerchantRows...),
		SourceWallets:    append([]string(nil), cf.SourceWallets...),
		CategoriesUsed:   append([]string(nil), cf.CategoriesUsed...),
	}
}

func buildCategorySpendingBreakdownTable(cf *CashflowSummaryOutput, customTitle string) *SpendingBreakdownTablePayload {
	if cf == nil || (len(cf.CategoryRows) == 0 && cf.TotalExpenseIDR <= 0) {
		return nil
	}
	sourceWallets := nonNilStrings(cf.SourceWallets)
	categoriesUsed := nonNilStrings(cf.CategoriesUsed)
	rows := make([]MerchantBreakdownRow, 0, len(cf.CategoryRows))
	for _, r := range cf.CategoryRows {
		if r.TxType != "expense" {
			continue
		}
		rows = append(rows, MerchantBreakdownRow{
			Merchant:    r.Category,
			TxCount:     r.TxCount,
			TotalAmount: r.TotalAmount,
			WalletNames: append([]string{}, sourceWallets...),
			Categories:  []string{r.Category},
		})
	}
	if len(rows) == 0 {
		return nil
	}
	title := customTitle
	if title == "" {
		if cf.PeriodLabel != "" {
			title = fmt.Sprintf("Rincian Pengeluaran per Kategori (%s)", cf.PeriodLabel)
		} else {
			title = "Rincian Pengeluaran per Kategori"
		}
	}
	txCount := cf.ExpenseCount
	if txCount == 0 {
		txCount = cf.TransactionCount
	}
	return &SpendingBreakdownTablePayload{
		Title:            title,
		Period:           cf.Period,
		PeriodLabel:      cf.PeriodLabel,
		KeywordFilter:    cf.KeywordFilter,
		TotalAmountIDR:   cf.TotalExpenseIDR,
		TransactionCount: txCount,
		Rows:             rows,
		SourceWallets:    sourceWallets,
		CategoriesUsed:   categoriesUsed,
	}
}

func buildWalletSpendingBreakdownTable(cf *CashflowSummaryOutput, customTitle string) *SpendingBreakdownTablePayload {
	if cf == nil || (len(cf.WalletRows) == 0 && cf.TotalExpenseIDR <= 0) {
		return nil
	}
	sourceWallets := nonNilStrings(cf.SourceWallets)
	categoriesUsed := nonNilStrings(cf.CategoriesUsed)
	rows := make([]MerchantBreakdownRow, 0, len(cf.WalletRows))
	for _, r := range cf.WalletRows {
		if r.TotalExpenseIDR <= 0 {
			continue
		}
		rows = append(rows, MerchantBreakdownRow{
			Merchant:    r.WalletName,
			TxCount:     r.TxCount,
			TotalAmount: r.TotalExpenseIDR,
			WalletNames: []string{r.WalletName},
			Categories:  append([]string{}, categoriesUsed...),
		})
	}
	if len(rows) == 0 {
		return nil
	}
	title := customTitle
	if title == "" {
		if cf.PeriodLabel != "" {
			title = fmt.Sprintf("Rincian Pengeluaran per Dompet (%s)", cf.PeriodLabel)
		} else {
			title = "Rincian Pengeluaran per Dompet"
		}
	}
	txCount := cf.ExpenseCount
	if txCount == 0 {
		txCount = cf.TransactionCount
	}
	return &SpendingBreakdownTablePayload{
		Title:            title,
		Period:           cf.Period,
		PeriodLabel:      cf.PeriodLabel,
		KeywordFilter:    cf.KeywordFilter,
		TotalAmountIDR:   cf.TotalExpenseIDR,
		TransactionCount: txCount,
		Rows:             rows,
		SourceWallets:    sourceWallets,
		CategoriesUsed:   categoriesUsed,
	}
}

func spendingTablesEqual(a, b *SpendingBreakdownTablePayload) bool {
	if a == nil || b == nil {
		return a == b
	}
	if a.Period != b.Period ||
		a.TotalAmountIDR != b.TotalAmountIDR ||
		a.TransactionCount != b.TransactionCount ||
		len(a.Rows) != len(b.Rows) ||
		len(a.SourceWallets) != len(b.SourceWallets) ||
		len(a.CategoriesUsed) != len(b.CategoriesUsed) {
		return false
	}
	for i := range a.Rows {
		if a.Rows[i].Merchant != b.Rows[i].Merchant ||
			a.Rows[i].TxCount != b.Rows[i].TxCount ||
			a.Rows[i].TotalAmount != b.Rows[i].TotalAmount {
			return false
		}
	}
	return true
}

func goalDraftsEqual(a, b *GoalDraftPayload) bool {
	if a == nil || b == nil {
		return a == b
	}
	return a.Title == b.Title &&
		a.TargetAmountIDR == b.TargetAmountIDR &&
		a.SavedAmountIDR == b.SavedAmountIDR &&
		a.RemainingAmountIDR == b.RemainingAmountIDR &&
		a.MonthsRemaining == b.MonthsRemaining &&
		a.MonthlySavingEstimateIDR == b.MonthlySavingEstimateIDR &&
		a.Priority == b.Priority
}

func budgetDraftsEqual(a, b *BudgetDraftPayload) bool {
	if a == nil || b == nil {
		return a == b
	}
	return a.Category == b.Category &&
		a.MonthYear == b.MonthYear &&
		a.LimitAmountIDR == b.LimitAmountIDR &&
		a.CurrentMonthSpendIDR == b.CurrentMonthSpendIDR &&
		a.Avg30DSpendIDR == b.Avg30DSpendIDR &&
		a.IsUpdate == b.IsUpdate
}

func billDraftsEqual(a, b *BillDraftPayload) bool {
	if a == nil || b == nil {
		return a == b
	}
	return a.Title == b.Title &&
		a.CanonicalCategory == b.CanonicalCategory &&
		a.AmountIDR == b.AmountIDR &&
		a.DueDay == b.DueDay &&
		a.NextDueDate == b.NextDueDate &&
		a.Frequency == b.Frequency &&
		a.AutoPay == b.AutoPay
}

func buildPackageBannerPayload(m *MatchingOutput) *PackageBannerPayload {
	intake := m.PrefilledIntakeSummary
	return &PackageBannerPayload{
		ID:                     m.RecommendedPackage.ID,
		PackageCode:            m.RecommendedPackage.PackageCode,
		ServiceCategory:        m.RecommendedPackage.ServiceCategory,
		CategoryTag:            m.RecommendedPackage.CategoryTag,
		Tier:                   m.RecommendedPackage.Tier,
		SelectedTierLabel:      m.RecommendedPackage.SelectedTierLabel,
		ParticipantType:        m.RecommendedPackage.ParticipantType,
		PackageTitle:           m.RecommendedPackage.PackageTitle,
		ShortDesc:              m.RecommendedPackage.ShortDesc,
		OnlineDurationMinutes:  m.RecommendedPackage.OnlineDurationMinutes,
		OfflineDurationMinutes: m.RecommendedPackage.OfflineDurationMinutes,
		OnlinePriceIDR:         m.RecommendedPackage.OnlinePriceIDR,
		OfflinePriceIDR:        m.RecommendedPackage.OfflinePriceIDR,
		RecommendedMethod:      m.RecommendedPackage.RecommendedMethod,
		PrefilledIntakeSummary: &intake,
	}
}

func packageBannersEqual(a, b *PackageBannerPayload) bool {
	if a == nil || b == nil {
		return a == b
	}
	return a.ID == b.ID &&
		a.PackageCode == b.PackageCode &&
		a.OnlinePriceIDR == b.OnlinePriceIDR &&
		a.OfflinePriceIDR == b.OfflinePriceIDR &&
		a.PrefilledIntakeSummary != nil
}

func buildConsultantCardPayloads(m *MatchingOutput, existing []ConsultantCardPayload) []ConsultantCardPayload {
	reasonsByID := make(map[string]string, len(existing))
	for _, c := range existing {
		clean := strings.TrimSpace(sanitizeNoEmDash(c.MatchReason))
		if clean != "" {
			reasonsByID[c.ConsultantID] = clean
		}
	}

	out := make([]ConsultantCardPayload, 0, len(m.Consultants))
	for _, c := range m.Consultants {
		reason := c.MatchReason
		if custom, ok := reasonsByID[c.ConsultantID]; ok {
			reason = custom
		}
		out = append(out, ConsultantCardPayload{
			ConsultantID:           c.ConsultantID,
			PractitionerUUID:       c.PractitionerUUID,
			DisplayName:            c.DisplayName,
			TitleHeadline:          c.TitleHeadline,
			AvatarURL:              c.AvatarURL,
			Certifications:         append([]string(nil), c.Certifications...),
			Tier:                   c.Tier,
			Rating:                 c.Rating,
			ReviewCount:            c.ReviewCount,
			TotalSessionsCompleted: c.TotalSessionsCompleted,
			MatchReason:            sanitizeNoEmDash(reason),
			IsStaffPinned:          c.IsStaffPinned,
			NextAvailableSlotLabel: c.NextAvailableSlotLabel,
			NextAvailableSlotISO:   c.NextAvailableSlotISO,
			PreferredSlotLabel:     c.PreferredSlotLabel,
			PreferredSlotISO:       c.PreferredSlotISO,
			PackageCode:            c.PackageCode,
			PackageTitle:           c.PackageTitle,
			OnlinePriceIDR:         c.OnlinePriceIDR,
			OfflinePriceIDR:        c.OfflinePriceIDR,
		})
	}
	return out
}

func consultantSlicesEqual(a, b []ConsultantCardPayload) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i].ConsultantID != b[i].ConsultantID ||
			a[i].PractitionerUUID != b[i].PractitionerUUID ||
			a[i].DisplayName != b[i].DisplayName ||
			a[i].Tier != b[i].Tier ||
			a[i].PackageCode != b[i].PackageCode ||
			a[i].OnlinePriceIDR != b[i].OnlinePriceIDR ||
			a[i].OfflinePriceIDR != b[i].OfflinePriceIDR ||
			a[i].NextAvailableSlotLabel != b[i].NextAvailableSlotLabel ||
			a[i].NextAvailableSlotISO != b[i].NextAvailableSlotISO {
			return false
		}
	}
	return true
}
