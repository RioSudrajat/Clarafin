package service

import (
	"context"
	"errors"
	"fmt"
	"math"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/clarafin/api/internal/repository"
)

var (
	// ErrInvalidInput indicates request validation failure mapped to HTTP 400 INVALID_REQUEST.
	ErrInvalidInput = errors.New("invalid tracker input")
	// ErrNotFound indicates the requested entity does not exist or is not owned by the caller.
	ErrNotFound = errors.New("resource not found")
	// ErrConflict indicates a state conflict such as FK restrict delete or duplicate draft confirmation.
	ErrConflict = errors.New("resource state conflict")
	// ErrInsufficientBalance indicates an expense or transfer would drive the source wallet balance negative.
	ErrInsufficientBalance = errors.New("insufficient wallet balance")
)

var validWalletTypes = map[string]struct{}{
	"bank":        {},
	"ewallet":     {},
	"cash":        {},
	"deposit":     {},
	"mutual_fund": {},
	"bond":        {},
	"stock":       {},
	"cex":         {},
	"dex":         {},
	"web3_wallet": {},
	"crypto":      {},
	"investment":  {},
	"other":       {},
}

var validTxTypes = map[string]struct{}{
	"income":   {},
	"expense":  {},
	"transfer": {},
}

var validTxSources = map[string]struct{}{
	"manual":   {},
	"ai_text":  {},
	"ai_voice": {},
	"ocr":      {},
	"gmail":    {},
}

var validGoalPriorities = map[string]struct{}{
	"urgent": {},
	"needs":  {},
	"wants":  {},
}

var validGoalStatuses = map[string]struct{}{
	"active":    {},
	"completed": {},
	"archived":  {},
}

var validBillFrequencies = map[string]struct{}{
	"once":    {},
	"weekly":  {},
	"monthly": {},
	"yearly":  {},
}

var validHistorySources = map[string]struct{}{
	"fresh_start": {},
	"other_app":   {},
	"spreadsheet": {},
}

var validCurrencies = map[string]struct{}{
	"IDR": {},
	"USD": {},
	"SGD": {},
	"MYR": {},
	"EUR": {},
	"JPY": {},
}

var validLanguages = map[string]struct{}{
	"Bahasa Indonesia": {},
	"English":          {},
}

// TrackerOption customizes TrackerService dependencies and clocks.
type TrackerOption func(*TrackerService)

// WithTrackerNowFunc overrides the clock used by TrackerService.
func WithTrackerNowFunc(fn func() time.Time) TrackerOption {
	return func(s *TrackerService) {
		if fn != nil {
			s.nowFn = fn
		}
	}
}

// WithTrackerJakartaLocation overrides the Asia/Jakarta location used by TrackerService.
func WithTrackerJakartaLocation(loc *time.Location) TrackerOption {
	return func(s *TrackerService) {
		if loc != nil {
			s.jakartaLoc = loc
		}
	}
}

// WithTrackerQuotaProvider attaches QuotaService so /v1/me includes current AI quota details.
func WithTrackerQuotaProvider(qp *QuotaService) TrackerOption {
	return func(s *TrackerService) {
		s.quotaService = qp
	}
}

// TrackerService coordinates JWT-scoped personal finance CRUD and ACID balance updates.
type TrackerService struct {
	store        *repository.Store
	nowFn        func() time.Time
	jakartaLoc   *time.Location
	quotaService *QuotaService
}

// NewTrackerService constructs a TrackerService backed by PostgreSQL Store.
func NewTrackerService(store *repository.Store, opts ...TrackerOption) *TrackerService {
	loc, err := time.LoadLocation("Asia/Jakarta")
	if err != nil {
		loc = time.FixedZone("WIB", 7*3600)
	}

	svc := &TrackerService{
		store:      store,
		nowFn:      time.Now,
		jakartaLoc: loc,
	}
	for _, opt := range opts {
		if opt != nil {
			opt(svc)
		}
	}
	return svc
}

// UserProfileDTO serializes public.users fields in Clarafin snake_case.
type UserProfileDTO struct {
	ID                  uuid.UUID `json:"id"`
	Email               string    `json:"email"`
	FullName            string    `json:"full_name"`
	BirthDate           *string   `json:"birth_date,omitempty"`
	Phone               *string   `json:"phone,omitempty"`
	AvatarURL           *string   `json:"avatar_url,omitempty"`
	SelectedAvatarIndex *int32    `json:"selected_avatar_index,omitempty"`
	MonthlyBudgetLimit  int64     `json:"monthly_budget_limit"`
	OnboardingCompleted bool      `json:"onboarding_completed"`
	CreatedAt           time.Time `json:"created_at"`
	UpdatedAt           time.Time `json:"updated_at"`
}

// UserPreferencesDTO serializes user_preferences fields.
type UserPreferencesDTO struct {
	NotificationsEnabled    bool      `json:"notifications_enabled"`
	SessionRemindersEnabled bool      `json:"session_reminders_enabled"`
	BillRemindersEnabled    bool      `json:"bill_reminders_enabled"`
	PromoAlertsEnabled      bool      `json:"promo_alerts_enabled"`
	DailyReminderEnabled    bool      `json:"daily_reminder_enabled"`
	DailyReminderTimeWIB    string    `json:"daily_reminder_time_wib"`
	TrackingHistorySource   string    `json:"tracking_history_source"`
	TrackerFocuses          []string  `json:"tracker_focuses"`
	AdvisoryFocuses         []string  `json:"advisory_focuses"`
	BiometricEnabled        bool      `json:"biometric_enabled"`
	PreferredCurrency       string    `json:"preferred_currency"`
	PreferredLanguage       string    `json:"preferred_language"`
	UpdatedAt               time.Time `json:"updated_at"`
}

// GmailStatusDTO exposes non-sensitive Gmail connection metadata.
type GmailStatusDTO struct {
	Connected     bool       `json:"connected"`
	GmailAddress  *string    `json:"gmail_address,omitempty"`
	Status        *string    `json:"status,omitempty"`
	LastScannedAt *time.Time `json:"last_scanned_at,omitempty"`
}

// MeResponse represents the GET/PATCH /v1/me payload.
type MeResponse struct {
	User               UserProfileDTO     `json:"user"`
	Preferences        UserPreferencesDTO `json:"preferences"`
	PractitionerStatus *string            `json:"practitioner_status,omitempty"`
	GmailConnection    GmailStatusDTO     `json:"gmail_connection"`
	AIQuota            *QuotaStatus       `json:"ai_quota,omitempty"`
}

// UpdateMeInput represents optional profile and preference updates for PATCH /v1/me.
type UpdateMeInput struct {
	FullName                *string   `json:"full_name"`
	BirthDate               *string   `json:"birth_date"`
	Phone                   *string   `json:"phone"`
	AvatarURL               *string   `json:"avatar_url"`
	SelectedAvatarIndex     *int32    `json:"selected_avatar_index"`
	MonthlyBudgetLimit      *int64    `json:"monthly_budget_limit"`
	OnboardingCompleted     *bool     `json:"onboarding_completed"`
	NotificationsEnabled    *bool     `json:"notifications_enabled"`
	SessionRemindersEnabled *bool     `json:"session_reminders_enabled"`
	BillRemindersEnabled    *bool     `json:"bill_reminders_enabled"`
	PromoAlertsEnabled      *bool     `json:"promo_alerts_enabled"`
	DailyReminderEnabled    *bool     `json:"daily_reminder_enabled"`
	DailyReminderTimeWIB    *string   `json:"daily_reminder_time_wib"`
	TrackingHistorySource   *string   `json:"tracking_history_source"`
	TrackerFocuses          *[]string `json:"tracker_focuses"`
	AdvisoryFocuses         *[]string `json:"advisory_focuses"`
	BiometricEnabled        *bool     `json:"biometric_enabled"`
	PreferredCurrency       *string   `json:"preferred_currency"`
	PreferredLanguage       *string   `json:"preferred_language"`
}

// CategoryDTO represents a canonical transaction category or subcategory.
type CategoryDTO struct {
	ID            uuid.UUID     `json:"id"`
	Slug          string        `json:"slug"`
	Name          string        `json:"name"`
	ParentID      *uuid.UUID    `json:"parent_id,omitempty"`
	GroupName     string        `json:"group_name"`
	Type          string        `json:"type"`
	Emoji         string        `json:"emoji"`
	IconKey       string        `json:"icon_key"`
	ColorHex      string        `json:"color_hex"`
	BgColorHex    string        `json:"bg_color_hex"`
	SortOrder     int32         `json:"sort_order"`
	Subcategories []CategoryDTO `json:"subcategories,omitempty"`
}

// CategoriesResponse represents GET /v1/categories.
type CategoriesResponse struct {
	Categories     []CategoryDTO `json:"categories"`
	FlatCategories []CategoryDTO `json:"flat_categories"`
	Total          int           `json:"total"`
}

// WalletDTO represents an active or archived user wallet.
type WalletDTO struct {
	ID                  uuid.UUID  `json:"id"`
	UserID              uuid.UUID  `json:"user_id"`
	Name                string     `json:"name"`
	Type                string     `json:"type"`
	InstitutionCode     *string    `json:"institution_code,omitempty"`
	AccountNumberMasked *string    `json:"account_number_masked,omitempty"`
	Balance             int64      `json:"balance"`
	SharePct            float64    `json:"share_pct,omitempty"`
	IsAutoSync          bool       `json:"is_auto_sync"`
	CustomColorHex      *string    `json:"custom_color_hex,omitempty"`
	ReturnPercentage    *float32   `json:"return_percentage,omitempty"`
	DividendDropDate    *time.Time `json:"dividend_drop_date,omitempty"`
	IsVolatile          bool       `json:"is_volatile"`
	HasClaimedDividend  bool       `json:"has_claimed_dividend"`
	IsArchived          bool       `json:"is_archived"`
	CreatedAt           time.Time  `json:"created_at"`
	UpdatedAt           time.Time  `json:"updated_at"`
}

// WalletsResponse represents GET /v1/wallets.
type WalletsResponse struct {
	Wallets         []WalletDTO `json:"wallets"`
	TotalBalanceIDR int64       `json:"total_balance_idr"`
}

// CreateWalletInput creates a new user wallet.
type CreateWalletInput struct {
	Name                string     `json:"name"`
	Type                string     `json:"type"`
	InstitutionCode     *string    `json:"institution_code"`
	AccountNumberMasked *string    `json:"account_number_masked"`
	Balance             int64      `json:"balance"`
	IsAutoSync          bool       `json:"is_auto_sync"`
	CustomColorHex      *string    `json:"custom_color_hex"`
	ReturnPercentage    *float32   `json:"return_percentage"`
	DividendDropDate    *time.Time `json:"dividend_drop_date"`
	IsVolatile          bool       `json:"is_volatile"`
	HasClaimedDividend  bool       `json:"has_claimed_dividend"`
}

// UpdateWalletInput partially updates a user wallet.
type UpdateWalletInput struct {
	Name                *string    `json:"name"`
	Type                *string    `json:"type"`
	InstitutionCode     *string    `json:"institution_code"`
	AccountNumberMasked *string    `json:"account_number_masked"`
	Balance             *int64     `json:"balance"`
	IsAutoSync          *bool      `json:"is_auto_sync"`
	CustomColorHex      *string    `json:"custom_color_hex"`
	ReturnPercentage    *float32   `json:"return_percentage"`
	DividendDropDate    *time.Time `json:"dividend_drop_date"`
	IsVolatile          *bool      `json:"is_volatile"`
	HasClaimedDividend  *bool      `json:"has_claimed_dividend"`
	IsArchived          *bool      `json:"is_archived"`
}

// TransactionDTO represents a ledger transaction.
type TransactionDTO struct {
	ID                  uuid.UUID  `json:"id"`
	UserID              uuid.UUID  `json:"user_id"`
	WalletID            uuid.UUID  `json:"wallet_id"`
	DestinationWalletID *uuid.UUID `json:"destination_wallet_id,omitempty"`
	TargetGoalID        *uuid.UUID `json:"target_goal_id,omitempty"`
	CategoryID          *uuid.UUID `json:"category_id,omitempty"`
	Type                string     `json:"type"`
	Category            string     `json:"category"`
	Amount              int64      `json:"amount"`
	Title               string     `json:"title"`
	Note                *string    `json:"note,omitempty"`
	OccurredAt          time.Time  `json:"occurred_at"`
	Source              string     `json:"source"`
	ClientMutationID    *string    `json:"client_mutation_id,omitempty"`
	CreatedAt           time.Time  `json:"created_at"`
}

// ListTransactionsFilter scopes GET /v1/transactions queries.
type ListTransactionsFilter struct {
	WalletID *uuid.UUID
	Type     *string
	Category *string
	DateFrom *time.Time
	DateTo   *time.Time
	Keyword  *string
	Limit    int32
	Offset   int32
}

// TransactionsResponse represents GET /v1/transactions.
type TransactionsResponse struct {
	Transactions []TransactionDTO `json:"transactions"`
	Limit        int32            `json:"limit"`
	Offset       int32            `json:"offset"`
}

// CreateTransactionInput creates a new income, expense, or transfer transaction.
type CreateTransactionInput struct {
	WalletID            uuid.UUID  `json:"wallet_id"`
	DestinationWalletID *uuid.UUID `json:"destination_wallet_id"`
	TargetGoalID        *uuid.UUID `json:"target_goal_id"`
	CategoryID          *uuid.UUID `json:"category_id"`
	Type                string     `json:"type"`
	Category            string     `json:"category"`
	Amount              int64      `json:"amount"`
	Title               string     `json:"title"`
	Note                *string    `json:"note"`
	OccurredAt          *time.Time `json:"occurred_at"`
	Source              string     `json:"source"`
	ClientMutationID    *string    `json:"client_mutation_id"`
}

// TransactionMutationResult returns the persisted transaction, idempotency flag, and updated balances.
type TransactionMutationResult struct {
	Transaction      TransactionDTO `json:"transaction"`
	IdempotentReplay bool           `json:"idempotent_replay"`
	WalletBalanceIDR int64          `json:"wallet_balance_idr"`
	DestBalanceIDR   *int64         `json:"destination_wallet_balance_idr,omitempty"`
}

// AIDraftDTO represents a staged AI or Gmail transaction draft.
type AIDraftDTO struct {
	ID                  uuid.UUID  `json:"id"`
	UserID              uuid.UUID  `json:"user_id"`
	WalletID            *uuid.UUID `json:"wallet_id,omitempty"`
	DestinationWalletID *uuid.UUID `json:"destination_wallet_id,omitempty"`
	BatchID             *uuid.UUID `json:"batch_id,omitempty"`
	Source              string     `json:"source"`
	ExternalRefID       *string    `json:"external_ref_id,omitempty"`
	ClientMutationID    *string    `json:"client_mutation_id,omitempty"`
	Type                string     `json:"type"`
	Category            string     `json:"category"`
	Amount              int64      `json:"amount"`
	Title               string     `json:"title"`
	MerchantOrNote      string     `json:"merchant_or_note"`
	OccurredAt          time.Time  `json:"occurred_at"`
	ConfidenceScore     float32    `json:"confidence_score"`
	Status              string     `json:"status"`
	CreatedAt           time.Time  `json:"created_at"`
	UpdatedAt           time.Time  `json:"updated_at"`
}

// ConfirmAIDraftInput optionally overrides draft attributes before confirming into transactions.
type ConfirmAIDraftInput struct {
	WalletID            *uuid.UUID `json:"wallet_id"`
	DestinationWalletID *uuid.UUID `json:"destination_wallet_id"`
	TargetGoalID        *uuid.UUID `json:"target_goal_id"`
	CategoryID          *uuid.UUID `json:"category_id"`
	Category            *string    `json:"category"`
	Amount              *int64     `json:"amount"`
	Title               *string    `json:"title"`
	MerchantOrNote      *string    `json:"merchant_or_note"`
	Note                *string    `json:"note"`
	OccurredAt          *time.Time `json:"occurred_at"`
	ClientMutationID    *string    `json:"client_mutation_id"`
}

// BudgetDTO represents a monthly category budget record.
type BudgetDTO struct {
	ID           uuid.UUID  `json:"id"`
	UserID       uuid.UUID  `json:"user_id"`
	CategoryID   *uuid.UUID `json:"category_id,omitempty"`
	Category     string     `json:"category"`
	MonthYear    string     `json:"month_year"`
	LimitAmount  int64      `json:"limit_amount"`
	IconKey      *string    `json:"icon_key,omitempty"`
	ColorHex     *string    `json:"color_hex,omitempty"`
	BgColorHex   *string    `json:"bg_color_hex,omitempty"`
	Alert80Sent  bool       `json:"alert_80_sent"`
	Alert100Sent bool       `json:"alert_100_sent"`
	CreatedAt    time.Time  `json:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at"`
}

// BudgetWithSpentDTO includes computed monthly spending against the budget limit.
type BudgetWithSpentDTO struct {
	ID              uuid.UUID  `json:"id"`
	UserID          uuid.UUID  `json:"user_id"`
	CategoryID      *uuid.UUID `json:"category_id,omitempty"`
	Category        string     `json:"category"`
	MonthYear       string     `json:"month_year"`
	LimitAmount     int64      `json:"limit_amount"`
	SpentAmount     int64      `json:"spent_amount"`
	RemainingAmount int64      `json:"remaining_amount"`
	TxCount         int64      `json:"tx_count"`
	IconKey         *string    `json:"icon_key,omitempty"`
	ColorHex        *string    `json:"color_hex,omitempty"`
	BgColorHex      *string    `json:"bg_color_hex,omitempty"`
	Alert80Sent     bool       `json:"alert_80_sent"`
	Alert100Sent    bool       `json:"alert_100_sent"`
	CreatedAt       time.Time  `json:"created_at"`
	UpdatedAt       time.Time  `json:"updated_at"`
}

// UpsertBudgetInput creates or updates a monthly category budget.
type UpsertBudgetInput struct {
	CategoryID  *uuid.UUID `json:"category_id"`
	Category    string     `json:"category"`
	MonthYear   string     `json:"month_year"`
	LimitAmount int64      `json:"limit_amount"`
	IconKey     *string    `json:"icon_key"`
	ColorHex    *string    `json:"color_hex"`
	BgColorHex  *string    `json:"bg_color_hex"`
}

// GoalContributionDTO represents a wallet's allocated contribution to a savings goal.
type GoalContributionDTO struct {
	ID                uuid.UUID `json:"id"`
	GoalID            uuid.UUID `json:"goal_id"`
	WalletID          uuid.UUID `json:"wallet_id"`
	ContributedAmount int64     `json:"contributed_amount"`
	UpdatedAt         time.Time `json:"updated_at"`
}

// GoalDTO represents a savings goal and its wallet allocations.
type GoalDTO struct {
	ID               uuid.UUID             `json:"id"`
	UserID           uuid.UUID             `json:"user_id"`
	LinkedWalletID   *uuid.UUID            `json:"linked_wallet_id,omitempty"`
	Title            string                `json:"title"`
	TargetAmount     int64                 `json:"target_amount"`
	SavedAmount      int64                 `json:"saved_amount"`
	TargetDate       *string               `json:"target_date,omitempty"`
	Priority         string                `json:"priority"`
	SourceAssetLabel *string               `json:"source_asset_label,omitempty"`
	IconKey          *string               `json:"icon_key,omitempty"`
	TagColorHex      *string               `json:"tag_color_hex,omitempty"`
	TagTextColorHex  *string               `json:"tag_text_color_hex,omitempty"`
	Status           string                `json:"status"`
	Contributions    []GoalContributionDTO `json:"contributions"`
	CreatedAt        time.Time             `json:"created_at"`
	UpdatedAt        time.Time             `json:"updated_at"`
}

// CreateGoalInput creates a new savings goal.
type CreateGoalInput struct {
	LinkedWalletID   *uuid.UUID `json:"linked_wallet_id"`
	Title            string     `json:"title"`
	TargetAmount     int64      `json:"target_amount"`
	SavedAmount      int64      `json:"saved_amount"`
	TargetDate       *string    `json:"target_date"`
	Priority         string     `json:"priority"`
	SourceAssetLabel *string    `json:"source_asset_label"`
	IconKey          *string    `json:"icon_key"`
	TagColorHex      *string    `json:"tag_color_hex"`
	TagTextColorHex  *string    `json:"tag_text_color_hex"`
}

// UpdateGoalInput updates fields on an existing goal.
type UpdateGoalInput struct {
	LinkedWalletID *uuid.UUID `json:"linked_wallet_id"`
	Title          *string    `json:"title"`
	TargetAmount   *int64     `json:"target_amount"`
	SavedAmount    *int64     `json:"saved_amount"`
	TargetDate     *string    `json:"target_date"`
	Priority       *string    `json:"priority"`
	Status         *string    `json:"status"`
}

// AddGoalContributionInput allocates funds from wallet_id into a goal.
type AddGoalContributionInput struct {
	WalletID uuid.UUID `json:"wallet_id"`
	Amount   int64     `json:"amount"`
}

// GoalContributionResult returns the updated goal, contribution, and wallet balance.
type GoalContributionResult struct {
	Goal             GoalDTO             `json:"goal"`
	Contribution     GoalContributionDTO `json:"contribution"`
	WalletBalanceIDR int64               `json:"wallet_balance_idr"`
}

// BillDTO represents a recurring or one-time bill reminder.
type BillDTO struct {
	ID             uuid.UUID  `json:"id"`
	UserID         uuid.UUID  `json:"user_id"`
	Title          string     `json:"title"`
	Category       *string    `json:"category,omitempty"`
	Amount         int64      `json:"amount"`
	DueDate        *string    `json:"due_date,omitempty"`
	Frequency      string     `json:"frequency"`
	IsPaid         bool       `json:"is_paid"`
	AutoPay        bool       `json:"auto_pay"`
	IconKey        *string    `json:"icon_key,omitempty"`
	IconColorHex   *string    `json:"icon_color_hex,omitempty"`
	IconBgColorHex *string    `json:"icon_bg_color_hex,omitempty"`
	PaidAt         *time.Time `json:"paid_at,omitempty"`
	CreatedAt      time.Time  `json:"created_at"`
	UpdatedAt      time.Time  `json:"updated_at"`
}

// CreateBillInput creates a new bill reminder.
type CreateBillInput struct {
	Title          string  `json:"title"`
	Category       *string `json:"category"`
	Amount         int64   `json:"amount"`
	DueDate        *string `json:"due_date"`
	Frequency      string  `json:"frequency"`
	AutoPay        bool    `json:"auto_pay"`
	IconKey        *string `json:"icon_key"`
	IconColorHex   *string `json:"icon_color_hex"`
	IconBgColorHex *string `json:"icon_bg_color_hex"`
}

// UpdateBillInput updates bill attributes and optionally marks it paid from wallet_id.
type UpdateBillInput struct {
	Title            *string    `json:"title"`
	Category         *string    `json:"category"`
	Amount           *int64     `json:"amount"`
	DueDate          *string    `json:"due_date"`
	Frequency        *string    `json:"frequency"`
	AutoPay          *bool      `json:"auto_pay"`
	IsPaid           *bool      `json:"is_paid"`
	WalletID         *uuid.UUID `json:"wallet_id"`
	ClientMutationID *string    `json:"client_mutation_id"`
}

// BillUpdateResult returns the updated bill and optional generated payment transaction.
type BillUpdateResult struct {
	Bill             BillDTO         `json:"bill"`
	Transaction      *TransactionDTO `json:"transaction,omitempty"`
	WalletBalanceIDR *int64          `json:"wallet_balance_idr,omitempty"`
	IdempotentReplay bool            `json:"idempotent_replay,omitempty"`
}

// PlanningSummaryResponse combines budgets, goals, and bills for GET /v1/planning.
type PlanningSummaryResponse struct {
	MonthYear string               `json:"month_year"`
	Budgets   []BudgetWithSpentDTO `json:"budgets"`
	Goals     []GoalDTO            `json:"goals"`
	Bills     []BillDTO            `json:"bills"`
}

// NotificationDTO represents an in-app notification row.
type NotificationDTO struct {
	ID          uuid.UUID `json:"id"`
	UserID      uuid.UUID `json:"user_id"`
	Category    string    `json:"category"`
	Title       string    `json:"title"`
	Body        string    `json:"body"`
	ActionRoute *string   `json:"action_route,omitempty"`
	ActionLabel *string   `json:"action_label,omitempty"`
	IsRead      bool      `json:"is_read"`
	CreatedAt   time.Time `json:"created_at"`
}

// GetMe fetches the authenticated user's profile, preferences, practitioner status, Gmail status, and AI quota.
func (s *TrackerService) GetMe(ctx context.Context, userID uuid.UUID) (*MeResponse, error) {
	if err := s.requireStore(userID); err != nil {
		return nil, err
	}

	user, err := s.store.GetUserProfileByID(ctx, userID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrUserNotFound
		}
		return nil, fmt.Errorf("get user profile: %w", err)
	}

	prefs, err := s.store.GetUserPreferences(ctx, userID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			prefs, err = s.store.EnsureUserPreferences(ctx, userID)
			if err != nil {
				return nil, fmt.Errorf("ensure user preferences: %w", err)
			}
		} else {
			return nil, fmt.Errorf("get user preferences: %w", err)
		}
	}

	return s.assembleMeResponse(ctx, user, prefs)
}

// UpdateMe updates profile fields and user preferences atomically for userID.
func (s *TrackerService) UpdateMe(ctx context.Context, userID uuid.UUID, input UpdateMeInput) (*MeResponse, error) {
	if err := s.requireStore(userID); err != nil {
		return nil, err
	}

	if input.FullName != nil && strings.TrimSpace(*input.FullName) == "" {
		return nil, fmt.Errorf("%w: full_name cannot be blank", ErrInvalidInput)
	}
	if input.SelectedAvatarIndex != nil && (*input.SelectedAvatarIndex < 1 || *input.SelectedAvatarIndex > 6) {
		return nil, fmt.Errorf("%w: selected_avatar_index must be between 1 and 6", ErrInvalidInput)
	}
	if input.MonthlyBudgetLimit != nil && *input.MonthlyBudgetLimit < 0 {
		return nil, fmt.Errorf("%w: monthly_budget_limit must be >= 0", ErrInvalidInput)
	}

	var birthDatePtr *time.Time
	if input.BirthDate != nil {
		parsed, err := parseISODate(*input.BirthDate)
		if err != nil {
			return nil, err
		}
		birthDatePtr = &parsed
	}

	if input.TrackingHistorySource != nil {
		if _, ok := validHistorySources[*input.TrackingHistorySource]; !ok {
			return nil, fmt.Errorf("%w: unsupported tracking_history_source %q", ErrInvalidInput, *input.TrackingHistorySource)
		}
	}
	if input.PreferredCurrency != nil {
		if _, ok := validCurrencies[*input.PreferredCurrency]; !ok {
			return nil, fmt.Errorf("%w: unsupported preferred_currency %q", ErrInvalidInput, *input.PreferredCurrency)
		}
	}
	if input.PreferredLanguage != nil {
		if _, ok := validLanguages[*input.PreferredLanguage]; !ok {
			return nil, fmt.Errorf("%w: unsupported preferred_language %q", ErrInvalidInput, *input.PreferredLanguage)
		}
	}

	var reminderTime *pgtype.Time
	if input.DailyReminderTimeWIB != nil {
		parsed, err := parseWIBTime(*input.DailyReminderTimeWIB)
		if err != nil {
			return nil, err
		}
		reminderTime = &parsed
	}

	var updatedUser repository.User
	var updatedPrefs repository.UserPreference

	err := s.store.WithTx(ctx, func(q *repository.Queries) error {
		var fullNamePtr *string
		if input.FullName != nil {
			trimmed := strings.TrimSpace(*input.FullName)
			fullNamePtr = &trimmed
		}

		u, err := q.UpdateUserProfile(ctx, repository.UpdateUserProfileParams{
			FullName:            fullNamePtr,
			BirthDate:           birthDatePtr,
			Phone:               trimOptionalPtr(input.Phone),
			AvatarUrl:           trimOptionalPtr(input.AvatarURL),
			SelectedAvatarIndex: input.SelectedAvatarIndex,
			MonthlyBudgetLimit:  input.MonthlyBudgetLimit,
			OnboardingCompleted: input.OnboardingCompleted,
			UserID:              userID,
		})
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return ErrUserNotFound
			}
			return fmt.Errorf("update user profile: %w", err)
		}

		currentPrefs, err := q.EnsureUserPreferences(ctx, userID)
		if err != nil {
			return fmt.Errorf("ensure user preferences: %w", err)
		}

		upsertParams := repository.UpsertUserPreferencesParams{
			UserID:                  userID,
			NotificationsEnabled:    currentPrefs.NotificationsEnabled,
			SessionRemindersEnabled: currentPrefs.SessionRemindersEnabled,
			BillRemindersEnabled:    currentPrefs.BillRemindersEnabled,
			PromoAlertsEnabled:      currentPrefs.PromoAlertsEnabled,
			DailyReminderEnabled:    currentPrefs.DailyReminderEnabled,
			DailyReminderTimeWib:    currentPrefs.DailyReminderTimeWib,
			TrackingHistorySource:   currentPrefs.TrackingHistorySource,
			TrackerFocuses:          nonNilStrings(currentPrefs.TrackerFocuses),
			AdvisoryFocuses:         nonNilStrings(currentPrefs.AdvisoryFocuses),
			BiometricEnabled:        currentPrefs.BiometricEnabled,
			PreferredCurrency:       currentPrefs.PreferredCurrency,
			PreferredLanguage:       currentPrefs.PreferredLanguage,
		}
		if input.NotificationsEnabled != nil {
			upsertParams.NotificationsEnabled = *input.NotificationsEnabled
		}
		if input.SessionRemindersEnabled != nil {
			upsertParams.SessionRemindersEnabled = *input.SessionRemindersEnabled
		}
		if input.BillRemindersEnabled != nil {
			upsertParams.BillRemindersEnabled = *input.BillRemindersEnabled
		}
		if input.PromoAlertsEnabled != nil {
			upsertParams.PromoAlertsEnabled = *input.PromoAlertsEnabled
		}
		if input.DailyReminderEnabled != nil {
			upsertParams.DailyReminderEnabled = *input.DailyReminderEnabled
		}
		if reminderTime != nil {
			upsertParams.DailyReminderTimeWib = *reminderTime
		}
		if input.TrackingHistorySource != nil {
			upsertParams.TrackingHistorySource = *input.TrackingHistorySource
		}
		if input.TrackerFocuses != nil {
			upsertParams.TrackerFocuses = nonNilStrings(*input.TrackerFocuses)
		}
		if input.AdvisoryFocuses != nil {
			upsertParams.AdvisoryFocuses = nonNilStrings(*input.AdvisoryFocuses)
		}
		if input.BiometricEnabled != nil {
			upsertParams.BiometricEnabled = *input.BiometricEnabled
		}
		if input.PreferredCurrency != nil {
			upsertParams.PreferredCurrency = *input.PreferredCurrency
		}
		if input.PreferredLanguage != nil {
			upsertParams.PreferredLanguage = *input.PreferredLanguage
		}

		p, err := q.UpsertUserPreferences(ctx, upsertParams)
		if err != nil {
			return fmt.Errorf("upsert user preferences: %w", err)
		}

		updatedUser = u
		updatedPrefs = p
		return nil
	})
	if err != nil {
		return nil, err
	}

	return s.assembleMeResponse(ctx, updatedUser, updatedPrefs)
}

func (s *TrackerService) assembleMeResponse(ctx context.Context, user repository.User, prefs repository.UserPreference) (*MeResponse, error) {
	var pracStatus *string
	if st, err := s.store.GetPractitionerStatusByUserID(ctx, user.ID); err == nil {
		pracStatus = &st
	} else if !errors.Is(err, pgx.ErrNoRows) {
		return nil, fmt.Errorf("get practitioner status: %w", err)
	}

	gmailStatus := GmailStatusDTO{Connected: false}
	if gc, err := s.store.GetGmailConnectionSummaryByUserID(ctx, user.ID); err == nil {
		addr := gc.GmailAddress
		st := gc.Status
		gmailStatus = GmailStatusDTO{
			Connected:     gc.Status == "active",
			GmailAddress:  &addr,
			Status:        &st,
			LastScannedAt: gc.LastScannedAt,
		}
	} else if !errors.Is(err, pgx.ErrNoRows) {
		return nil, fmt.Errorf("get gmail connection: %w", err)
	}

	var quota *QuotaStatus
	if s.quotaService != nil {
		q, err := s.quotaService.GetQuotaStatus(ctx, user.ID)
		if err != nil {
			return nil, fmt.Errorf("get ai quota status: %w", err)
		}
		quota = q
	}

	var birthDateStr *string
	if user.BirthDate != nil {
		formatted := user.BirthDate.Format("2006-01-02")
		birthDateStr = &formatted
	}

	return &MeResponse{
		User: UserProfileDTO{
			ID:                  user.ID,
			Email:               user.Email,
			FullName:            user.FullName,
			BirthDate:           birthDateStr,
			Phone:               user.Phone,
			AvatarURL:           user.AvatarUrl,
			SelectedAvatarIndex: user.SelectedAvatarIndex,
			MonthlyBudgetLimit:  user.MonthlyBudgetLimit,
			OnboardingCompleted: user.OnboardingCompleted,
			CreatedAt:           user.CreatedAt,
			UpdatedAt:           user.UpdatedAt,
		},
		Preferences: UserPreferencesDTO{
			NotificationsEnabled:    prefs.NotificationsEnabled,
			SessionRemindersEnabled: prefs.SessionRemindersEnabled,
			BillRemindersEnabled:    prefs.BillRemindersEnabled,
			PromoAlertsEnabled:      prefs.PromoAlertsEnabled,
			DailyReminderEnabled:    prefs.DailyReminderEnabled,
			DailyReminderTimeWIB:    formatPGTime(prefs.DailyReminderTimeWib),
			TrackingHistorySource:   prefs.TrackingHistorySource,
			TrackerFocuses:          nonNilStrings(prefs.TrackerFocuses),
			AdvisoryFocuses:         nonNilStrings(prefs.AdvisoryFocuses),
			BiometricEnabled:        prefs.BiometricEnabled,
			PreferredCurrency:       prefs.PreferredCurrency,
			PreferredLanguage:       prefs.PreferredLanguage,
			UpdatedAt:               prefs.UpdatedAt,
		},
		PractitionerStatus: pracStatus,
		GmailConnection:    gmailStatus,
		AIQuota:            quota,
	}, nil
}

// ListCategories returns all active canonical parent categories and subcategories.
func (s *TrackerService) ListCategories(ctx context.Context) (*CategoriesResponse, error) {
	if s == nil || s.store == nil {
		return nil, errors.New("tracker service store is not initialized")
	}

	rows, err := s.store.ListCategories(ctx)
	if err != nil {
		return nil, fmt.Errorf("list categories: %w", err)
	}

	flat := make([]CategoryDTO, 0, len(rows))
	parents := make([]CategoryDTO, 0, 24)
	parentIndex := make(map[uuid.UUID]int)

	for _, r := range rows {
		dto := CategoryDTO{
			ID:         r.ID,
			Slug:       r.Slug,
			Name:       r.Name,
			ParentID:   r.ParentID,
			GroupName:  r.GroupName,
			Type:       r.Type,
			Emoji:      r.Emoji,
			IconKey:    r.IconKey,
			ColorHex:   r.ColorHex,
			BgColorHex: r.BgColorHex,
			SortOrder:  r.SortOrder,
		}
		flat = append(flat, dto)
		if r.ParentID == nil {
			dto.Subcategories = []CategoryDTO{}
			parentIndex[r.ID] = len(parents)
			parents = append(parents, dto)
		}
	}

	for _, r := range rows {
		if r.ParentID == nil {
			continue
		}
		if idx, ok := parentIndex[*r.ParentID]; ok {
			parents[idx].Subcategories = append(parents[idx].Subcategories, CategoryDTO{
				ID:         r.ID,
				Slug:       r.Slug,
				Name:       r.Name,
				ParentID:   r.ParentID,
				GroupName:  r.GroupName,
				Type:       r.Type,
				Emoji:      r.Emoji,
				IconKey:    r.IconKey,
				ColorHex:   r.ColorHex,
				BgColorHex: r.BgColorHex,
				SortOrder:  r.SortOrder,
			})
		}
	}

	return &CategoriesResponse{
		Categories:     parents,
		FlatCategories: flat,
		Total:          len(flat),
	}, nil
}

// ListWallets returns active wallets owned by userID alongside total balance and asset distribution %.
func (s *TrackerService) ListWallets(ctx context.Context, userID uuid.UUID) (*WalletsResponse, error) {
	if err := s.requireStore(userID); err != nil {
		return nil, err
	}

	rows, err := s.store.ListActiveWalletsByUser(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("list active wallets: %w", err)
	}

	var totalBalance int64
	for _, w := range rows {
		totalBalance += w.Balance
	}

	items := make([]WalletDTO, 0, len(rows))
	for _, w := range rows {
		dto := walletToDTO(w)
		if totalBalance > 0 && w.Balance > 0 {
			dto.SharePct = math.Round((float64(w.Balance)*1000.0)/float64(totalBalance)) / 10.0
		}
		items = append(items, dto)
	}

	return &WalletsResponse{
		Wallets:         items,
		TotalBalanceIDR: totalBalance,
	}, nil
}

// GetWallet fetches a single wallet strictly owned by userID.
func (s *TrackerService) GetWallet(ctx context.Context, userID, walletID uuid.UUID) (*WalletDTO, error) {
	if err := s.requireStore(userID); err != nil {
		return nil, err
	}
	if walletID == uuid.Nil {
		return nil, fmt.Errorf("%w: wallet_id is required", ErrInvalidInput)
	}

	w, err := s.store.GetWalletByID(ctx, repository.GetWalletByIDParams{
		UserID: userID,
		ID:     walletID,
	})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("get wallet: %w", err)
	}
	dto := walletToDTO(w)
	return &dto, nil
}

// CreateWallet validates and inserts a new wallet for userID.
func (s *TrackerService) CreateWallet(ctx context.Context, userID uuid.UUID, input CreateWalletInput) (*WalletDTO, error) {
	if err := s.requireStore(userID); err != nil {
		return nil, err
	}

	name := strings.TrimSpace(input.Name)
	if name == "" {
		return nil, fmt.Errorf("%w: wallet name is required", ErrInvalidInput)
	}
	wType := strings.TrimSpace(input.Type)
	if _, ok := validWalletTypes[wType]; !ok {
		return nil, fmt.Errorf("%w: unsupported wallet type %q", ErrInvalidInput, input.Type)
	}

	w, err := s.store.CreateWallet(ctx, repository.CreateWalletParams{
		UserID:              userID,
		Name:                name,
		Type:                wType,
		InstitutionCode:     trimOptionalPtr(input.InstitutionCode),
		AccountNumberMasked: trimOptionalPtr(input.AccountNumberMasked),
		Balance:             input.Balance,
		IsAutoSync:          input.IsAutoSync,
		CustomColorHex:      trimOptionalPtr(input.CustomColorHex),
		ReturnPercentage:    input.ReturnPercentage,
		DividendDropDate:    input.DividendDropDate,
		IsVolatile:          input.IsVolatile,
		HasClaimedDividend:  input.HasClaimedDividend,
	})
	if err != nil {
		return nil, fmt.Errorf("create wallet: %w", err)
	}
	dto := walletToDTO(w)
	return &dto, nil
}

// UpdateWallet updates wallet metadata, archival state, and optional balance for userID.
func (s *TrackerService) UpdateWallet(ctx context.Context, userID, walletID uuid.UUID, input UpdateWalletInput) (*WalletDTO, error) {
	if err := s.requireStore(userID); err != nil {
		return nil, err
	}
	if walletID == uuid.Nil {
		return nil, fmt.Errorf("%w: wallet_id is required", ErrInvalidInput)
	}

	var namePtr *string
	if input.Name != nil {
		trimmed := strings.TrimSpace(*input.Name)
		if trimmed == "" {
			return nil, fmt.Errorf("%w: wallet name cannot be blank", ErrInvalidInput)
		}
		namePtr = &trimmed
	}
	var typePtr *string
	if input.Type != nil {
		trimmed := strings.TrimSpace(*input.Type)
		if _, ok := validWalletTypes[trimmed]; !ok {
			return nil, fmt.Errorf("%w: unsupported wallet type %q", ErrInvalidInput, *input.Type)
		}
		typePtr = &trimmed
	}

	var updated repository.Wallet
	err := s.store.WithTx(ctx, func(q *repository.Queries) error {
		w, err := q.UpdateWallet(ctx, repository.UpdateWalletParams{
			Name:                namePtr,
			Type:                typePtr,
			InstitutionCode:     trimOptionalPtr(input.InstitutionCode),
			AccountNumberMasked: trimOptionalPtr(input.AccountNumberMasked),
			IsAutoSync:          input.IsAutoSync,
			CustomColorHex:      trimOptionalPtr(input.CustomColorHex),
			ReturnPercentage:    input.ReturnPercentage,
			DividendDropDate:    input.DividendDropDate,
			IsVolatile:          input.IsVolatile,
			HasClaimedDividend:  input.HasClaimedDividend,
			IsArchived:          input.IsArchived,
			UserID:              userID,
			ID:                  walletID,
		})
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return ErrNotFound
			}
			return fmt.Errorf("update wallet: %w", err)
		}

		if input.Balance != nil {
			w, err = q.SetWalletBalance(ctx, repository.SetWalletBalanceParams{
				UserID:  userID,
				ID:      walletID,
				Balance: *input.Balance,
			})
			if err != nil {
				if errors.Is(err, pgx.ErrNoRows) {
					return ErrNotFound
				}
				return fmt.Errorf("set wallet balance: %w", err)
			}
		}

		updated = w
		return nil
	})
	if err != nil {
		return nil, err
	}

	dto := walletToDTO(updated)
	return &dto, nil
}

// DeleteWallet permanently removes an unused wallet owned by userID or returns ErrConflict when referenced.
func (s *TrackerService) DeleteWallet(ctx context.Context, userID, walletID uuid.UUID) error {
	if err := s.requireStore(userID); err != nil {
		return err
	}
	if walletID == uuid.Nil {
		return fmt.Errorf("%w: wallet_id is required", ErrInvalidInput)
	}

	rows, err := s.store.DeleteWallet(ctx, repository.DeleteWalletParams{
		UserID: userID,
		ID:     walletID,
	})
	if err != nil {
		if isPGCode(err, "23503") {
			return fmt.Errorf("%w: wallet has linked transactions or goal contributions; archive it instead", ErrConflict)
		}
		return fmt.Errorf("delete wallet: %w", err)
	}
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

// ListTransactions returns filtered transaction history scoped strictly to userID.
func (s *TrackerService) ListTransactions(ctx context.Context, userID uuid.UUID, filter ListTransactionsFilter) (*TransactionsResponse, error) {
	if err := s.requireStore(userID); err != nil {
		return nil, err
	}

	if filter.Type != nil {
		t := strings.TrimSpace(*filter.Type)
		if t == "" {
			filter.Type = nil
		} else if _, ok := validTxTypes[t]; !ok {
			return nil, fmt.Errorf("%w: unsupported transaction type %q", ErrInvalidInput, t)
		} else {
			filter.Type = &t
		}
	}

	limit := filter.Limit
	if limit <= 0 {
		limit = 50
	}
	if limit > 200 {
		limit = 200
	}
	offset := max(filter.Offset, 0)

	rows, err := s.store.ListTransactionsByUser(ctx, repository.ListTransactionsByUserParams{
		UserID:     userID,
		WalletID:   filter.WalletID,
		TxType:     filter.Type,
		Category:   trimOptionalPtr(filter.Category),
		DateFrom:   filter.DateFrom,
		DateTo:     filter.DateTo,
		Keyword:    trimOptionalPtr(filter.Keyword),
		OffsetRows: offset,
		LimitRows:  limit,
	})
	if err != nil {
		return nil, fmt.Errorf("list transactions: %w", err)
	}

	items := make([]TransactionDTO, 0, len(rows))
	for _, r := range rows {
		items = append(items, txToDTO(r))
	}

	return &TransactionsResponse{
		Transactions: items,
		Limit:        limit,
		Offset:       offset,
	}, nil
}

// GetTransaction returns a single transaction strictly owned by userID.
func (s *TrackerService) GetTransaction(ctx context.Context, userID, txID uuid.UUID) (*TransactionDTO, error) {
	if err := s.requireStore(userID); err != nil {
		return nil, err
	}
	if txID == uuid.Nil {
		return nil, fmt.Errorf("%w: transaction id is required", ErrInvalidInput)
	}

	row, err := s.store.GetTransactionByID(ctx, repository.GetTransactionByIDParams{
		UserID: userID,
		ID:     txID,
	})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("get transaction: %w", err)
	}
	dto := txToDTO(row)
	return &dto, nil
}

// CreateTransaction validates inputs, enforces client_mutation_id idempotency, and updates wallet/goal balances atomically.
func (s *TrackerService) CreateTransaction(ctx context.Context, userID uuid.UUID, input CreateTransactionInput) (*TransactionMutationResult, error) {
	if err := s.requireStore(userID); err != nil {
		return nil, err
	}

	if err := validateTransactionInput(&input, s.nowFn()); err != nil {
		return nil, err
	}

	var out *TransactionMutationResult
	err := s.store.WithTx(ctx, func(q *repository.Queries) error {
		res, err := s.createTransactionInTx(ctx, q, userID, input)
		if err != nil {
			return err
		}
		out = res
		return nil
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

// DeleteTransaction deletes a transaction owned by userID and atomically reverses wallet and goal balance mutations.
func (s *TrackerService) DeleteTransaction(ctx context.Context, userID, txID uuid.UUID) error {
	if err := s.requireStore(userID); err != nil {
		return err
	}
	if txID == uuid.Nil {
		return fmt.Errorf("%w: transaction id is required", ErrInvalidInput)
	}

	return s.store.WithTx(ctx, func(q *repository.Queries) error {
		deleted, err := q.DeleteTransaction(ctx, repository.DeleteTransactionParams{
			UserID: userID,
			ID:     txID,
		})
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return ErrNotFound
			}
			return fmt.Errorf("delete transaction: %w", err)
		}

		switch deleted.Type {
		case "expense":
			if _, err := q.UpdateWalletBalanceDelta(ctx, repository.UpdateWalletBalanceDeltaParams{
				UserID: userID,
				ID:     deleted.WalletID,
				Delta:  deleted.Amount,
			}); err != nil {
				if errors.Is(err, pgx.ErrNoRows) {
					return fmt.Errorf("%w: source wallet is archived or unavailable for reversal", ErrConflict)
				}
				return fmt.Errorf("reverse expense wallet balance: %w", err)
			}
		case "income":
			if _, err := q.UpdateWalletBalanceDelta(ctx, repository.UpdateWalletBalanceDeltaParams{
				UserID: userID,
				ID:     deleted.WalletID,
				Delta:  -deleted.Amount,
			}); err != nil {
				if errors.Is(err, pgx.ErrNoRows) {
					return fmt.Errorf("%w: source wallet is archived or unavailable for reversal", ErrConflict)
				}
				return fmt.Errorf("reverse income wallet balance: %w", err)
			}
		case "transfer":
			if _, err := q.UpdateWalletBalanceDelta(ctx, repository.UpdateWalletBalanceDeltaParams{
				UserID: userID,
				ID:     deleted.WalletID,
				Delta:  deleted.Amount,
			}); err != nil {
				if errors.Is(err, pgx.ErrNoRows) {
					return fmt.Errorf("%w: source wallet is archived or unavailable for reversal", ErrConflict)
				}
				return fmt.Errorf("reverse transfer source balance: %w", err)
			}
			if deleted.DestinationWalletID != nil {
				if _, err := q.UpdateWalletBalanceDelta(ctx, repository.UpdateWalletBalanceDeltaParams{
					UserID: userID,
					ID:     *deleted.DestinationWalletID,
					Delta:  -deleted.Amount,
				}); err != nil {
					if errors.Is(err, pgx.ErrNoRows) {
						return fmt.Errorf("%w: destination wallet is archived or unavailable for reversal", ErrConflict)
					}
					return fmt.Errorf("reverse transfer destination balance: %w", err)
				}
			}
			if deleted.TargetGoalID != nil {
				contribWalletID := deleted.WalletID
				if deleted.DestinationWalletID != nil {
					contribWalletID = *deleted.DestinationWalletID
				}
				if _, err := q.AdjustGoalContributionDelta(ctx, repository.AdjustGoalContributionDeltaParams{
					UserID:   userID,
					GoalID:   *deleted.TargetGoalID,
					WalletID: contribWalletID,
					Delta:    -deleted.Amount,
				}); err != nil {
					return fmt.Errorf("reverse goal contribution: %w", err)
				}
				if _, err := q.AdjustGoalSavedAmount(ctx, repository.AdjustGoalSavedAmountParams{
					UserID: userID,
					ID:     *deleted.TargetGoalID,
					Delta:  -deleted.Amount,
				}); err != nil && !errors.Is(err, pgx.ErrNoRows) {
					return fmt.Errorf("reverse goal saved amount: %w", err)
				}
			}
		}
		return nil
	})
}

// ListPendingAIDrafts returns pending_review drafts strictly owned by userID.
func (s *TrackerService) ListPendingAIDrafts(ctx context.Context, userID uuid.UUID) ([]AIDraftDTO, error) {
	if err := s.requireStore(userID); err != nil {
		return nil, err
	}

	rows, err := s.store.ListPendingAIDraftsByUser(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("list pending ai drafts: %w", err)
	}

	items := make([]AIDraftDTO, 0, len(rows))
	for _, r := range rows {
		items = append(items, draftToDTO(r))
	}
	return items, nil
}

// ConfirmAIDraft confirms a pending_review draft into a final transaction and updates wallet balances atomically.
func (s *TrackerService) ConfirmAIDraft(ctx context.Context, userID, draftID uuid.UUID, input ConfirmAIDraftInput) (*TransactionMutationResult, error) {
	if err := s.requireStore(userID); err != nil {
		return nil, err
	}
	if draftID == uuid.Nil {
		return nil, fmt.Errorf("%w: draft id is required", ErrInvalidInput)
	}

	var out *TransactionMutationResult
	err := s.store.WithTx(ctx, func(q *repository.Queries) error {
		draft, err := q.GetAIDraftByID(ctx, repository.GetAIDraftByIDParams{
			UserID: userID,
			ID:     draftID,
		})
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return ErrNotFound
			}
			return fmt.Errorf("lookup ai draft: %w", err)
		}
		if draft.Status != "pending_review" {
			return fmt.Errorf("%w: draft is already %s", ErrConflict, draft.Status)
		}

		walletIDPtr := draft.WalletID
		if input.WalletID != nil {
			walletIDPtr = input.WalletID
		}
		if walletIDPtr == nil || *walletIDPtr == uuid.Nil {
			return fmt.Errorf("%w: wallet_id is required to confirm draft", ErrInvalidInput)
		}

		destWalletPtr := draft.DestinationWalletID
		if input.DestinationWalletID != nil {
			destWalletPtr = input.DestinationWalletID
		}

		category := draft.Category
		if input.Category != nil {
			category = strings.TrimSpace(*input.Category)
		}
		title := draft.Title
		if input.Title != nil {
			title = strings.TrimSpace(*input.Title)
		}
		amount := draft.Amount
		if input.Amount != nil {
			amount = *input.Amount
		}
		note := draft.MerchantOrNote
		if input.MerchantOrNote != nil {
			note = strings.TrimSpace(*input.MerchantOrNote)
		} else if input.Note != nil {
			note = strings.TrimSpace(*input.Note)
		}
		occurredAt := draft.OccurredAt
		if input.OccurredAt != nil && !input.OccurredAt.IsZero() {
			occurredAt = *input.OccurredAt
		}

		mutID := "draft_confirm:" + draftID.String()
		if trimmed := trimOptionalPtr(input.ClientMutationID); trimmed != nil {
			mutID = *trimmed
		} else if trimmed := trimOptionalPtr(draft.ClientMutationID); trimmed != nil {
			mutID = *trimmed
		}

		txInput := CreateTransactionInput{
			WalletID:            *walletIDPtr,
			DestinationWalletID: destWalletPtr,
			TargetGoalID:        input.TargetGoalID,
			CategoryID:          input.CategoryID,
			Type:                draft.Type,
			Category:            category,
			Amount:              amount,
			Title:               title,
			Note:                &note,
			OccurredAt:          &occurredAt,
			Source:              draft.Source,
			ClientMutationID:    &mutID,
		}
		if err := validateTransactionInput(&txInput, s.nowFn()); err != nil {
			return err
		}

		if err := s.verifyTransactionOwnership(ctx, q, userID, txInput); err != nil {
			return err
		}

		if _, err := q.ConfirmAIDraft(ctx, repository.ConfirmAIDraftParams{
			WalletID:            walletIDPtr,
			DestinationWalletID: destWalletPtr,
			Category:            &category,
			Amount:              &amount,
			Title:               &title,
			MerchantOrNote:      &note,
			ClientMutationID:    &mutID,
			UserID:              userID,
			ID:                  draftID,
		}); err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return fmt.Errorf("%w: draft was already processed", ErrConflict)
			}
			if isPGCode(err, "23505") {
				return fmt.Errorf("%w: duplicate client_mutation_id on draft confirm", ErrConflict)
			}
			return fmt.Errorf("confirm ai draft: %w", err)
		}

		res, err := s.createTransactionInTx(ctx, q, userID, txInput)
		if err != nil {
			return err
		}
		if res.IdempotentReplay {
			// A draft transitioning from pending_review to confirmed must never attach to a prior mutation silently.
			return fmt.Errorf("%w: client_mutation_id already applied", ErrConflict)
		}
		out = res
		return nil
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

// DiscardAIDraft transitions a pending_review draft owned by userID to discarded.
func (s *TrackerService) DiscardAIDraft(ctx context.Context, userID, draftID uuid.UUID) (*AIDraftDTO, error) {
	if err := s.requireStore(userID); err != nil {
		return nil, err
	}
	if draftID == uuid.Nil {
		return nil, fmt.Errorf("%w: draft id is required", ErrInvalidInput)
	}

	var out AIDraftDTO
	err := s.store.WithTx(ctx, func(q *repository.Queries) error {
		discarded, err := q.DiscardAIDraft(ctx, repository.DiscardAIDraftParams{
			UserID: userID,
			ID:     draftID,
		})
		if err != nil {
			if !errors.Is(err, pgx.ErrNoRows) {
				return fmt.Errorf("discard ai draft: %w", err)
			}
			existing, getErr := q.GetAIDraftByID(ctx, repository.GetAIDraftByIDParams{
				UserID: userID,
				ID:     draftID,
			})
			if getErr != nil {
				if errors.Is(getErr, pgx.ErrNoRows) {
					return ErrNotFound
				}
				return fmt.Errorf("lookup ai draft after discard miss: %w", getErr)
			}
			return fmt.Errorf("%w: draft is already %s", ErrConflict, existing.Status)
		}
		out = draftToDTO(discarded)
		return nil
	})
	if err != nil {
		return nil, err
	}
	return &out, nil
}

// GetPlanningSummary returns budgets, goals, and bills for the /budget screen.
func (s *TrackerService) GetPlanningSummary(ctx context.Context, userID uuid.UUID, monthYear string) (*PlanningSummaryResponse, error) {
	if err := s.requireStore(userID); err != nil {
		return nil, err
	}

	resolvedMonth, err := s.resolveMonthYear(monthYear)
	if err != nil {
		return nil, err
	}

	budgets, err := s.ListBudgets(ctx, userID, resolvedMonth)
	if err != nil {
		return nil, err
	}
	goals, err := s.ListGoals(ctx, userID)
	if err != nil {
		return nil, err
	}
	bills, err := s.ListBills(ctx, userID, nil)
	if err != nil {
		return nil, err
	}

	return &PlanningSummaryResponse{
		MonthYear: resolvedMonth,
		Budgets:   budgets,
		Goals:     goals,
		Bills:     bills,
	}, nil
}

// ListBudgets returns monthly budgets with computed spending totals for userID.
func (s *TrackerService) ListBudgets(ctx context.Context, userID uuid.UUID, monthYear string) ([]BudgetWithSpentDTO, error) {
	if err := s.requireStore(userID); err != nil {
		return nil, err
	}
	resolvedMonth, err := s.resolveMonthYear(monthYear)
	if err != nil {
		return nil, err
	}

	rows, err := s.store.ListBudgetsWithSpent(ctx, repository.ListBudgetsWithSpentParams{
		UserID:    userID,
		MonthYear: resolvedMonth,
	})
	if err != nil {
		return nil, fmt.Errorf("list budgets with spent: %w", err)
	}

	items := make([]BudgetWithSpentDTO, 0, len(rows))
	for _, r := range rows {
		items = append(items, BudgetWithSpentDTO{
			ID:              r.ID,
			UserID:          r.UserID,
			CategoryID:      r.CategoryID,
			Category:        r.Category,
			MonthYear:       r.MonthYear,
			LimitAmount:     r.LimitAmount,
			SpentAmount:     r.SpentAmount,
			RemainingAmount: r.RemainingAmount,
			TxCount:         r.TxCount,
			IconKey:         r.IconKey,
			ColorHex:        r.ColorHex,
			BgColorHex:      r.BgColorHex,
			Alert80Sent:     r.Alert80Sent,
			Alert100Sent:    r.Alert100Sent,
			CreatedAt:       r.CreatedAt,
			UpdatedAt:       r.UpdatedAt,
		})
	}
	return items, nil
}

// UpsertBudget creates or updates a monthly category budget for userID.
func (s *TrackerService) UpsertBudget(ctx context.Context, userID uuid.UUID, input UpsertBudgetInput) (*BudgetDTO, error) {
	if err := s.requireStore(userID); err != nil {
		return nil, err
	}

	category := strings.TrimSpace(input.Category)
	if category == "" {
		return nil, fmt.Errorf("%w: budget category is required", ErrInvalidInput)
	}
	if input.LimitAmount <= 0 {
		return nil, fmt.Errorf("%w: limit_amount must be > 0", ErrInvalidInput)
	}
	monthYear, err := s.resolveMonthYear(input.MonthYear)
	if err != nil {
		return nil, err
	}

	if input.CategoryID != nil {
		if _, err := s.store.GetCategoryByID(ctx, *input.CategoryID); err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return nil, fmt.Errorf("%w: unknown category_id", ErrInvalidInput)
			}
			return nil, fmt.Errorf("verify category_id: %w", err)
		}
	}

	b, err := s.store.UpsertBudget(ctx, repository.UpsertBudgetParams{
		UserID:      userID,
		CategoryID:  input.CategoryID,
		Category:    category,
		MonthYear:   monthYear,
		LimitAmount: input.LimitAmount,
		IconKey:     trimOptionalPtr(input.IconKey),
		ColorHex:    trimOptionalPtr(input.ColorHex),
		BgColorHex:  trimOptionalPtr(input.BgColorHex),
	})
	if err != nil {
		return nil, fmt.Errorf("upsert budget: %w", err)
	}

	return &BudgetDTO{
		ID:           b.ID,
		UserID:       b.UserID,
		CategoryID:   b.CategoryID,
		Category:     b.Category,
		MonthYear:    b.MonthYear,
		LimitAmount:  b.LimitAmount,
		IconKey:      b.IconKey,
		ColorHex:     b.ColorHex,
		BgColorHex:   b.BgColorHex,
		Alert80Sent:  b.Alert80Sent,
		Alert100Sent: b.Alert100Sent,
		CreatedAt:    b.CreatedAt,
		UpdatedAt:    b.UpdatedAt,
	}, nil
}

// DeleteBudget deletes a budget strictly owned by userID.
func (s *TrackerService) DeleteBudget(ctx context.Context, userID, budgetID uuid.UUID) error {
	if err := s.requireStore(userID); err != nil {
		return err
	}
	if budgetID == uuid.Nil {
		return fmt.Errorf("%w: budget_id is required", ErrInvalidInput)
	}

	rows, err := s.store.DeleteBudget(ctx, repository.DeleteBudgetParams{
		UserID: userID,
		ID:     budgetID,
	})
	if err != nil {
		return fmt.Errorf("delete budget: %w", err)
	}
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

// ListGoals returns non-archived goals and wallet contributions strictly owned by userID.
func (s *TrackerService) ListGoals(ctx context.Context, userID uuid.UUID) ([]GoalDTO, error) {
	if err := s.requireStore(userID); err != nil {
		return nil, err
	}

	goals, err := s.store.ListGoalsByUser(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("list goals: %w", err)
	}

	contribs, err := s.store.ListGoalContributionsByUser(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("list goal contributions: %w", err)
	}

	byGoal := make(map[uuid.UUID][]GoalContributionDTO)
	for _, c := range contribs {
		byGoal[c.GoalID] = append(byGoal[c.GoalID], GoalContributionDTO{
			ID:                c.ID,
			GoalID:            c.GoalID,
			WalletID:          c.WalletID,
			ContributedAmount: c.ContributedAmount,
			UpdatedAt:         c.UpdatedAt,
		})
	}

	items := make([]GoalDTO, 0, len(goals))
	for _, g := range goals {
		items = append(items, goalToDTO(g, byGoal[g.ID]))
	}
	return items, nil
}

// CreateGoal validates and creates a savings goal for userID.
func (s *TrackerService) CreateGoal(ctx context.Context, userID uuid.UUID, input CreateGoalInput) (*GoalDTO, error) {
	if err := s.requireStore(userID); err != nil {
		return nil, err
	}

	title := strings.TrimSpace(input.Title)
	if title == "" {
		return nil, fmt.Errorf("%w: goal title is required", ErrInvalidInput)
	}
	if input.TargetAmount <= 0 {
		return nil, fmt.Errorf("%w: target_amount must be > 0", ErrInvalidInput)
	}
	if input.SavedAmount < 0 {
		return nil, fmt.Errorf("%w: saved_amount must be >= 0", ErrInvalidInput)
	}

	priority := strings.TrimSpace(input.Priority)
	if priority == "" {
		priority = "wants"
	}
	if _, ok := validGoalPriorities[priority]; !ok {
		return nil, fmt.Errorf("%w: unsupported goal priority %q", ErrInvalidInput, input.Priority)
	}

	var targetDate *time.Time
	if input.TargetDate != nil {
		parsed, err := parseISODate(*input.TargetDate)
		if err != nil {
			return nil, err
		}
		targetDate = &parsed
	}

	if input.LinkedWalletID != nil {
		if _, err := s.store.GetWalletByID(ctx, repository.GetWalletByIDParams{
			UserID: userID,
			ID:     *input.LinkedWalletID,
		}); err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return nil, ErrNotFound
			}
			return nil, fmt.Errorf("verify linked wallet: %w", err)
		}
	}

	g, err := s.store.CreateGoal(ctx, repository.CreateGoalParams{
		UserID:           userID,
		LinkedWalletID:   input.LinkedWalletID,
		Title:            title,
		TargetAmount:     input.TargetAmount,
		SavedAmount:      input.SavedAmount,
		TargetDate:       targetDate,
		Priority:         priority,
		SourceAssetLabel: trimOptionalPtr(input.SourceAssetLabel),
		IconKey:          trimOptionalPtr(input.IconKey),
		TagColorHex:      trimOptionalPtr(input.TagColorHex),
		TagTextColorHex:  trimOptionalPtr(input.TagTextColorHex),
	})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("create goal: %w", err)
	}

	dto := goalToDTO(g, []GoalContributionDTO{})
	return &dto, nil
}

// UpdateGoal updates fields on a goal strictly owned by userID.
func (s *TrackerService) UpdateGoal(ctx context.Context, userID, goalID uuid.UUID, input UpdateGoalInput) (*GoalDTO, error) {
	if err := s.requireStore(userID); err != nil {
		return nil, err
	}
	if goalID == uuid.Nil {
		return nil, fmt.Errorf("%w: goal_id is required", ErrInvalidInput)
	}

	var titlePtr *string
	if input.Title != nil {
		trimmed := strings.TrimSpace(*input.Title)
		if trimmed == "" {
			return nil, fmt.Errorf("%w: goal title cannot be blank", ErrInvalidInput)
		}
		titlePtr = &trimmed
	}
	if input.TargetAmount != nil && *input.TargetAmount <= 0 {
		return nil, fmt.Errorf("%w: target_amount must be > 0", ErrInvalidInput)
	}
	if input.SavedAmount != nil && *input.SavedAmount < 0 {
		return nil, fmt.Errorf("%w: saved_amount must be >= 0", ErrInvalidInput)
	}
	if input.Priority != nil {
		if _, ok := validGoalPriorities[*input.Priority]; !ok {
			return nil, fmt.Errorf("%w: unsupported goal priority %q", ErrInvalidInput, *input.Priority)
		}
	}
	if input.Status != nil {
		if _, ok := validGoalStatuses[*input.Status]; !ok {
			return nil, fmt.Errorf("%w: unsupported goal status %q", ErrInvalidInput, *input.Status)
		}
	}

	var targetDate *time.Time
	if input.TargetDate != nil {
		parsed, err := parseISODate(*input.TargetDate)
		if err != nil {
			return nil, err
		}
		targetDate = &parsed
	}

	if input.LinkedWalletID != nil {
		if _, err := s.store.GetWalletByID(ctx, repository.GetWalletByIDParams{
			UserID: userID,
			ID:     *input.LinkedWalletID,
		}); err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return nil, ErrNotFound
			}
			return nil, fmt.Errorf("verify linked wallet: %w", err)
		}
	}

	g, err := s.store.UpdateGoal(ctx, repository.UpdateGoalParams{
		LinkedWalletID: input.LinkedWalletID,
		Title:          titlePtr,
		TargetAmount:   input.TargetAmount,
		SavedAmount:    input.SavedAmount,
		TargetDate:     targetDate,
		Priority:       input.Priority,
		Status:         input.Status,
		UserID:         userID,
		ID:             goalID,
	})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("update goal: %w", err)
	}

	dto := goalToDTO(g, []GoalContributionDTO{})
	return &dto, nil
}

// AddGoalContribution atomically allocates funds from an active owned wallet to an owned goal.
func (s *TrackerService) AddGoalContribution(ctx context.Context, userID, goalID uuid.UUID, input AddGoalContributionInput) (*GoalContributionResult, error) {
	if err := s.requireStore(userID); err != nil {
		return nil, err
	}
	if goalID == uuid.Nil || input.WalletID == uuid.Nil {
		return nil, fmt.Errorf("%w: goal_id and wallet_id are required", ErrInvalidInput)
	}
	if input.Amount <= 0 {
		return nil, fmt.Errorf("%w: amount must be > 0", ErrInvalidInput)
	}

	var result *GoalContributionResult
	err := s.store.WithTx(ctx, func(q *repository.Queries) error {
		goal, err := q.GetGoalByID(ctx, repository.GetGoalByIDParams{UserID: userID, ID: goalID})
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return ErrNotFound
			}
			return fmt.Errorf("get goal: %w", err)
		}
		if goal.Status == "archived" {
			return fmt.Errorf("%w: goal is archived", ErrConflict)
		}

		wallet, err := q.GetWalletByID(ctx, repository.GetWalletByIDParams{UserID: userID, ID: input.WalletID})
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return ErrNotFound
			}
			return fmt.Errorf("get wallet: %w", err)
		}
		if wallet.IsArchived {
			return fmt.Errorf("%w: wallet is archived", ErrConflict)
		}

		updatedWallet, err := q.UpdateWalletBalanceDelta(ctx, repository.UpdateWalletBalanceDeltaParams{
			UserID: userID,
			ID:     input.WalletID,
			Delta:  -input.Amount,
		})
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return ErrConflict
			}
			return fmt.Errorf("deduct wallet balance for goal: %w", err)
		}

		contrib, err := q.UpsertGoalContribution(ctx, repository.UpsertGoalContributionParams{
			UserID:            userID,
			GoalID:            goalID,
			WalletID:          input.WalletID,
			ContributedAmount: input.Amount,
		})
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return ErrNotFound
			}
			return fmt.Errorf("upsert goal contribution: %w", err)
		}

		updatedGoal, err := q.AddGoalSavedAmount(ctx, repository.AddGoalSavedAmountParams{
			UserID: userID,
			ID:     goalID,
			Delta:  input.Amount,
		})
		if err != nil {
			return fmt.Errorf("add goal saved amount: %w", err)
		}

		contribDTO := GoalContributionDTO{
			ID:                contrib.ID,
			GoalID:            contrib.GoalID,
			WalletID:          contrib.WalletID,
			ContributedAmount: contrib.ContributedAmount,
			UpdatedAt:         contrib.UpdatedAt,
		}
		result = &GoalContributionResult{
			Goal:             goalToDTO(updatedGoal, []GoalContributionDTO{contribDTO}),
			Contribution:     contribDTO,
			WalletBalanceIDR: updatedWallet.Balance,
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return result, nil
}

// ListBills returns user bills optionally filtered by is_paid.
func (s *TrackerService) ListBills(ctx context.Context, userID uuid.UUID, isPaidFilter *bool) ([]BillDTO, error) {
	if err := s.requireStore(userID); err != nil {
		return nil, err
	}

	rows, err := s.store.ListBillsByUser(ctx, repository.ListBillsByUserParams{
		UserID: userID,
		IsPaid: isPaidFilter,
	})
	if err != nil {
		return nil, fmt.Errorf("list bills: %w", err)
	}

	items := make([]BillDTO, 0, len(rows))
	for _, r := range rows {
		items = append(items, billToDTO(r))
	}
	return items, nil
}

// CreateBill validates and creates a bill reminder for userID.
func (s *TrackerService) CreateBill(ctx context.Context, userID uuid.UUID, input CreateBillInput) (*BillDTO, error) {
	if err := s.requireStore(userID); err != nil {
		return nil, err
	}

	title := strings.TrimSpace(input.Title)
	if title == "" {
		return nil, fmt.Errorf("%w: bill title is required", ErrInvalidInput)
	}
	if input.Amount <= 0 {
		return nil, fmt.Errorf("%w: bill amount must be > 0", ErrInvalidInput)
	}

	frequency := strings.TrimSpace(input.Frequency)
	if frequency == "" {
		frequency = "monthly"
	}
	if _, ok := validBillFrequencies[frequency]; !ok {
		return nil, fmt.Errorf("%w: unsupported bill frequency %q", ErrInvalidInput, input.Frequency)
	}

	var dueDate *time.Time
	if input.DueDate != nil {
		parsed, err := parseISODate(*input.DueDate)
		if err != nil {
			return nil, err
		}
		dueDate = &parsed
	}

	b, err := s.store.CreateBill(ctx, repository.CreateBillParams{
		UserID:         userID,
		Title:          title,
		Category:       trimOptionalPtr(input.Category),
		Amount:         input.Amount,
		DueDate:        dueDate,
		Frequency:      frequency,
		AutoPay:        input.AutoPay,
		IconKey:        trimOptionalPtr(input.IconKey),
		IconColorHex:   trimOptionalPtr(input.IconColorHex),
		IconBgColorHex: trimOptionalPtr(input.IconBgColorHex),
	})
	if err != nil {
		return nil, fmt.Errorf("create bill: %w", err)
	}

	dto := billToDTO(b)
	return &dto, nil
}

// UpdateBill edits bill details and optionally records an atomic wallet payment when transitioning to is_paid=true.
func (s *TrackerService) UpdateBill(ctx context.Context, userID, billID uuid.UUID, input UpdateBillInput) (*BillUpdateResult, error) {
	if err := s.requireStore(userID); err != nil {
		return nil, err
	}
	if billID == uuid.Nil {
		return nil, fmt.Errorf("%w: bill_id is required", ErrInvalidInput)
	}

	var titlePtr *string
	if input.Title != nil {
		trimmed := strings.TrimSpace(*input.Title)
		if trimmed == "" {
			return nil, fmt.Errorf("%w: bill title cannot be blank", ErrInvalidInput)
		}
		titlePtr = &trimmed
	}
	if input.Amount != nil && *input.Amount <= 0 {
		return nil, fmt.Errorf("%w: bill amount must be > 0", ErrInvalidInput)
	}
	if input.Frequency != nil {
		if _, ok := validBillFrequencies[*input.Frequency]; !ok {
			return nil, fmt.Errorf("%w: unsupported bill frequency %q", ErrInvalidInput, *input.Frequency)
		}
	}

	var dueDate *time.Time
	if input.DueDate != nil {
		parsed, err := parseISODate(*input.DueDate)
		if err != nil {
			return nil, err
		}
		dueDate = &parsed
	}

	var out *BillUpdateResult
	err := s.store.WithTx(ctx, func(q *repository.Queries) error {
		existing, err := q.GetBillByIDForUpdate(ctx, repository.GetBillByIDForUpdateParams{UserID: userID, ID: billID})
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return ErrNotFound
			}
			return fmt.Errorf("lock bill for update: %w", err)
		}

		mutID := trimOptionalPtr(input.ClientMutationID)

		if input.IsPaid != nil && *input.IsPaid && existing.IsPaid {
			if mutID == nil {
				return fmt.Errorf("%w: bill is already paid", ErrConflict)
			}

			existingTx, txErr := q.GetTransactionByClientMutationID(ctx, repository.GetTransactionByClientMutationIDParams{
				UserID:           userID,
				ClientMutationID: mutID,
			})
			if txErr != nil {
				if errors.Is(txErr, pgx.ErrNoRows) {
					return fmt.Errorf("%w: bill is already paid", ErrConflict)
				}
				return fmt.Errorf("lookup bill payment transaction: %w", txErr)
			}

			if !billPaymentMatchesTx(existing, existingTx, input) {
				return fmt.Errorf("%w: client_mutation_id belongs to a different transaction", ErrConflict)
			}

			wallet, wErr := q.GetWalletByID(ctx, repository.GetWalletByIDParams{
				UserID: userID,
				ID:     existingTx.WalletID,
			})
			if wErr != nil {
				return fmt.Errorf("read wallet for idempotent bill replay: %w", wErr)
			}

			txDTO := txToDTO(existingTx)
			bal := wallet.Balance
			out = &BillUpdateResult{
				Bill:             billToDTO(existing),
				Transaction:      &txDTO,
				WalletBalanceIDR: &bal,
				IdempotentReplay: true,
			}
			return nil
		}

		// Reject a pre-existing unrelated client_mutation_id before marking an unpaid bill paid.
		if input.IsPaid != nil && *input.IsPaid && !existing.IsPaid && input.WalletID != nil && mutID != nil {
			if _, txErr := q.GetTransactionByClientMutationID(ctx, repository.GetTransactionByClientMutationIDParams{
				UserID:           userID,
				ClientMutationID: mutID,
			}); txErr == nil {
				return fmt.Errorf("%w: client_mutation_id already applied to another transaction", ErrConflict)
			} else if !errors.Is(txErr, pgx.ErrNoRows) {
				return fmt.Errorf("check client_mutation_id uniqueness: %w", txErr)
			}
		}

		currentBill := existing
		if hasBillMetadataUpdates(input) {
			updated, err := q.UpdateBill(ctx, repository.UpdateBillParams{
				Title:     titlePtr,
				Category:  trimOptionalPtr(input.Category),
				Amount:    input.Amount,
				DueDate:   dueDate,
				Frequency: input.Frequency,
				AutoPay:   input.AutoPay,
				UserID:    userID,
				ID:        billID,
			})
			if err != nil {
				return fmt.Errorf("update bill: %w", err)
			}
			currentBill = updated
		}

		res := &BillUpdateResult{Bill: billToDTO(currentBill)}

		if input.IsPaid != nil {
			if *input.IsPaid && !currentBill.IsPaid {
				paidBill, err := q.MarkBillPaidIfUnpaid(ctx, repository.MarkBillPaidIfUnpaidParams{
					UserID: userID,
					ID:     billID,
				})
				if err != nil {
					if errors.Is(err, pgx.ErrNoRows) {
						return fmt.Errorf("%w: bill is already paid", ErrConflict)
					}
					return fmt.Errorf("mark bill paid: %w", err)
				}
				res.Bill = billToDTO(paidBill)

				if input.WalletID != nil {
					billCategory := "Bills & Utilities"
					if paidBill.Category != nil && strings.TrimSpace(*paidBill.Category) != "" {
						billCategory = strings.TrimSpace(*paidBill.Category)
					}
					txRes, err := s.createTransactionInTx(ctx, q, userID, CreateTransactionInput{
						WalletID:         *input.WalletID,
						Type:             "expense",
						Category:         billCategory,
						Amount:           paidBill.Amount,
						Title:            paidBill.Title,
						Source:           "manual",
						ClientMutationID: mutID,
					})
					if err != nil {
						return err
					}
					txDTO := txRes.Transaction
					bal := txRes.WalletBalanceIDR
					res.Transaction = &txDTO
					res.WalletBalanceIDR = &bal
					res.IdempotentReplay = txRes.IdempotentReplay
				}
			} else if !*input.IsPaid && currentBill.IsPaid {
				unpaidBill, err := q.MarkBillPaid(ctx, repository.MarkBillPaidParams{
					UserID: userID,
					ID:     billID,
					IsPaid: false,
				})
				if err != nil {
					return fmt.Errorf("mark bill unpaid: %w", err)
				}
				res.Bill = billToDTO(unpaidBill)
			}
		}

		out = res
		return nil
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

// DeleteBill removes a bill strictly owned by userID.
func (s *TrackerService) DeleteBill(ctx context.Context, userID, billID uuid.UUID) error {
	if err := s.requireStore(userID); err != nil {
		return err
	}
	if billID == uuid.Nil {
		return fmt.Errorf("%w: bill_id is required", ErrInvalidInput)
	}

	rows, err := s.store.DeleteBill(ctx, repository.DeleteBillParams{
		UserID: userID,
		ID:     billID,
	})
	if err != nil {
		return fmt.Errorf("delete bill: %w", err)
	}
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

// ListNotifications returns recent in-app notifications for userID.
func (s *TrackerService) ListNotifications(ctx context.Context, userID uuid.UUID, limit int32) ([]NotificationDTO, error) {
	if err := s.requireStore(userID); err != nil {
		return nil, err
	}
	if limit <= 0 {
		limit = 50
	}
	if limit > 200 {
		limit = 200
	}

	rows, err := s.store.ListNotificationsByUser(ctx, repository.ListNotificationsByUserParams{
		UserID: userID,
		Limit:  limit,
	})
	if err != nil {
		return nil, fmt.Errorf("list notifications: %w", err)
	}

	items := make([]NotificationDTO, 0, len(rows))
	for _, r := range rows {
		items = append(items, NotificationDTO{
			ID:          r.ID,
			UserID:      r.UserID,
			Category:    r.Category,
			Title:       r.Title,
			Body:        r.Body,
			ActionRoute: r.ActionRoute,
			ActionLabel: r.ActionLabel,
			IsRead:      r.IsRead,
			CreatedAt:   r.CreatedAt,
		})
	}
	return items, nil
}

// MarkAllNotificationsRead marks all unread notifications for userID as read.
func (s *TrackerService) MarkAllNotificationsRead(ctx context.Context, userID uuid.UUID) (int64, error) {
	if err := s.requireStore(userID); err != nil {
		return 0, err
	}
	updated, err := s.store.MarkAllNotificationsRead(ctx, userID)
	if err != nil {
		return 0, fmt.Errorf("mark all notifications read: %w", err)
	}
	return updated, nil
}

func (s *TrackerService) createTransactionInTx(
	ctx context.Context,
	q *repository.Queries,
	userID uuid.UUID,
	input CreateTransactionInput,
) (*TransactionMutationResult, error) {
	mutID := trimOptionalPtr(input.ClientMutationID)

	if mutID != nil {
		existing, err := q.GetTransactionByClientMutationID(ctx, repository.GetTransactionByClientMutationIDParams{
			UserID:           userID,
			ClientMutationID: mutID,
		})
		if err == nil {
			return s.buildReplayResult(ctx, q, userID, existing)
		}
		if !errors.Is(err, pgx.ErrNoRows) {
			return nil, fmt.Errorf("lookup existing client_mutation_id: %w", err)
		}
	}

	if err := s.verifyTransactionOwnership(ctx, q, userID, input); err != nil {
		return nil, err
	}

	occurredAt := s.nowFn()
	if input.OccurredAt != nil && !input.OccurredAt.IsZero() {
		occurredAt = *input.OccurredAt
	}

	inserted, err := q.InsertTransactionIdempotent(ctx, repository.InsertTransactionIdempotentParams{
		UserID:              userID,
		WalletID:            input.WalletID,
		DestinationWalletID: input.DestinationWalletID,
		TargetGoalID:        input.TargetGoalID,
		CategoryID:          input.CategoryID,
		Type:                input.Type,
		Category:            strings.TrimSpace(input.Category),
		Amount:              input.Amount,
		Title:               strings.TrimSpace(input.Title),
		Note:                trimOptionalPtr(input.Note),
		OccurredAt:          occurredAt,
		Source:              input.Source,
		ClientMutationID:    mutID,
	})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			if mutID != nil {
				// Concurrent request committed the same client_mutation_id while this tx was running.
				existing, lookupErr := q.GetTransactionByClientMutationID(ctx, repository.GetTransactionByClientMutationIDParams{
					UserID:           userID,
					ClientMutationID: mutID,
				})
				if lookupErr == nil {
					return s.buildReplayResult(ctx, q, userID, existing)
				}
			}
			return nil, ErrNotFound
		}
		if isPGCode(err, "23503") {
			return nil, fmt.Errorf("%w: invalid category_id or foreign reference", ErrInvalidInput)
		}
		return nil, fmt.Errorf("insert transaction: %w", err)
	}

	var srcWallet repository.Wallet
	var destBalance *int64

	switch input.Type {
	case "expense":
		srcWallet, err = q.UpdateWalletBalanceDelta(ctx, repository.UpdateWalletBalanceDeltaParams{
			UserID: userID,
			ID:     input.WalletID,
			Delta:  -input.Amount,
		})
		if err != nil {
			return nil, mapBalanceUpdateErr("deduct source wallet balance", err)
		}
		if srcWallet.Balance < 0 && !isHistoricalSyncMutation(mutID) {
			return nil, fmt.Errorf("%w: wallet balance %d cannot cover expense %d", ErrInsufficientBalance, srcWallet.Balance+input.Amount, input.Amount)
		}
	case "income":
		srcWallet, err = q.UpdateWalletBalanceDelta(ctx, repository.UpdateWalletBalanceDeltaParams{
			UserID: userID,
			ID:     input.WalletID,
			Delta:  input.Amount,
		})
		if err != nil {
			return nil, mapBalanceUpdateErr("credit source wallet balance", err)
		}
	case "transfer":
		srcWallet, err = q.UpdateWalletBalanceDelta(ctx, repository.UpdateWalletBalanceDeltaParams{
			UserID: userID,
			ID:     input.WalletID,
			Delta:  -input.Amount,
		})
		if err != nil {
			return nil, mapBalanceUpdateErr("deduct transfer source wallet balance", err)
		}
		if srcWallet.Balance < 0 && !isHistoricalSyncMutation(mutID) {
			return nil, fmt.Errorf("%w: wallet balance %d cannot cover transfer %d", ErrInsufficientBalance, srcWallet.Balance+input.Amount, input.Amount)
		}
		if input.DestinationWalletID != nil {
			dstWallet, err := q.UpdateWalletBalanceDelta(ctx, repository.UpdateWalletBalanceDeltaParams{
				UserID: userID,
				ID:     *input.DestinationWalletID,
				Delta:  input.Amount,
			})
			if err != nil {
				return nil, mapBalanceUpdateErr("credit transfer destination wallet balance", err)
			}
			bal := dstWallet.Balance
			destBalance = &bal
		}
		if input.TargetGoalID != nil {
			contribWalletID := input.WalletID
			if input.DestinationWalletID != nil {
				contribWalletID = *input.DestinationWalletID
			}
			if _, err := q.UpsertGoalContribution(ctx, repository.UpsertGoalContributionParams{
				UserID:            userID,
				GoalID:            *input.TargetGoalID,
				WalletID:          contribWalletID,
				ContributedAmount: input.Amount,
			}); err != nil {
				if errors.Is(err, pgx.ErrNoRows) {
					return nil, ErrNotFound
				}
				return nil, fmt.Errorf("upsert goal contribution: %w", err)
			}
			if _, err := q.AddGoalSavedAmount(ctx, repository.AddGoalSavedAmountParams{
				UserID: userID,
				ID:     *input.TargetGoalID,
				Delta:  input.Amount,
			}); err != nil {
				if errors.Is(err, pgx.ErrNoRows) {
					return nil, ErrNotFound
				}
				return nil, fmt.Errorf("add goal saved amount: %w", err)
			}
		}
	}

	return &TransactionMutationResult{
		Transaction:      txToDTO(inserted),
		IdempotentReplay: false,
		WalletBalanceIDR: srcWallet.Balance,
		DestBalanceIDR:   destBalance,
	}, nil
}

// isHistoricalSyncMutation allows offline initial snapshot sync (sync_tx_* or sync:*)
// to replay older transactions before wallet balances are reconciled.
func isHistoricalSyncMutation(mutID *string) bool {
	if mutID == nil {
		return false
	}
	trimmed := strings.TrimSpace(*mutID)
	return strings.HasPrefix(trimmed, "sync:") || strings.HasPrefix(trimmed, "sync_tx_")
}

func (s *TrackerService) buildReplayResult(
	ctx context.Context,
	q *repository.Queries,
	userID uuid.UUID,
	existing repository.Transaction,
) (*TransactionMutationResult, error) {
	srcW, err := q.GetWalletByID(ctx, repository.GetWalletByIDParams{UserID: userID, ID: existing.WalletID})
	if err != nil {
		return nil, fmt.Errorf("read wallet for idempotent replay: %w", err)
	}
	var destBal *int64
	if existing.DestinationWalletID != nil {
		if dstW, err := q.GetWalletByID(ctx, repository.GetWalletByIDParams{UserID: userID, ID: *existing.DestinationWalletID}); err == nil {
			b := dstW.Balance
			destBal = &b
		}
	}
	return &TransactionMutationResult{
		Transaction:      txToDTO(existing),
		IdempotentReplay: true,
		WalletBalanceIDR: srcW.Balance,
		DestBalanceIDR:   destBal,
	}, nil
}

func (s *TrackerService) verifyTransactionOwnership(
	ctx context.Context,
	q *repository.Queries,
	userID uuid.UUID,
	input CreateTransactionInput,
) error {
	srcWallet, err := q.GetWalletByID(ctx, repository.GetWalletByIDParams{
		UserID: userID,
		ID:     input.WalletID,
	})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrNotFound
		}
		return fmt.Errorf("verify source wallet: %w", err)
	}
	if srcWallet.IsArchived {
		return fmt.Errorf("%w: source wallet is archived", ErrConflict)
	}

	if input.DestinationWalletID != nil {
		dstWallet, err := q.GetWalletByID(ctx, repository.GetWalletByIDParams{
			UserID: userID,
			ID:     *input.DestinationWalletID,
		})
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return ErrNotFound
			}
			return fmt.Errorf("verify destination wallet: %w", err)
		}
		if dstWallet.IsArchived {
			return fmt.Errorf("%w: destination wallet is archived", ErrConflict)
		}
	}

	if input.TargetGoalID != nil {
		goal, err := q.GetGoalByID(ctx, repository.GetGoalByIDParams{
			UserID: userID,
			ID:     *input.TargetGoalID,
		})
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return ErrNotFound
			}
			return fmt.Errorf("verify target goal: %w", err)
		}
		if goal.Status == "archived" {
			return fmt.Errorf("%w: target goal is archived", ErrConflict)
		}
	}

	return nil
}

func validateTransactionInput(input *CreateTransactionInput, now time.Time) error {
	if input.WalletID == uuid.Nil {
		return fmt.Errorf("%w: wallet_id is required", ErrInvalidInput)
	}
	if input.Amount <= 0 {
		return fmt.Errorf("%w: amount must be > 0", ErrInvalidInput)
	}

	txType := strings.TrimSpace(input.Type)
	if _, ok := validTxTypes[txType]; !ok {
		return fmt.Errorf("%w: invalid transaction type %q", ErrInvalidInput, input.Type)
	}
	input.Type = txType

	if strings.TrimSpace(input.Category) == "" {
		return fmt.Errorf("%w: category is required", ErrInvalidInput)
	}
	if strings.TrimSpace(input.Title) == "" {
		return fmt.Errorf("%w: title is required", ErrInvalidInput)
	}

	source := strings.TrimSpace(input.Source)
	if source == "" {
		source = "manual"
	}
	if _, ok := validTxSources[source]; !ok {
		return fmt.Errorf("%w: unsupported source %q", ErrInvalidInput, input.Source)
	}
	input.Source = source

	if input.ClientMutationID != nil && len(strings.TrimSpace(*input.ClientMutationID)) > 128 {
		return fmt.Errorf("%w: client_mutation_id exceeds 128 characters", ErrInvalidInput)
	}

	if input.CategoryID != nil && *input.CategoryID == uuid.Nil {
		return fmt.Errorf("%w: category_id cannot be nil UUID", ErrInvalidInput)
	}

	if txType == "transfer" {
		if input.DestinationWalletID == nil && input.TargetGoalID == nil {
			return fmt.Errorf("%w: transfer requires destination_wallet_id or target_goal_id", ErrInvalidInput)
		}
		if input.DestinationWalletID != nil {
			if *input.DestinationWalletID == uuid.Nil {
				return fmt.Errorf("%w: destination_wallet_id cannot be nil UUID", ErrInvalidInput)
			}
			if *input.DestinationWalletID == input.WalletID {
				return fmt.Errorf("%w: destination_wallet_id must differ from wallet_id", ErrInvalidInput)
			}
		}
		if input.TargetGoalID != nil && *input.TargetGoalID == uuid.Nil {
			return fmt.Errorf("%w: target_goal_id cannot be nil UUID", ErrInvalidInput)
		}
	} else {
		if input.DestinationWalletID != nil {
			return fmt.Errorf("%w: destination_wallet_id is only allowed for transfer transactions", ErrInvalidInput)
		}
		if input.TargetGoalID != nil {
			return fmt.Errorf("%w: target_goal_id is only allowed for transfer transactions", ErrInvalidInput)
		}
	}

	if input.OccurredAt == nil || input.OccurredAt.IsZero() {
		t := now
		input.OccurredAt = &t
	}
	return nil
}

func hasBillMetadataUpdates(input UpdateBillInput) bool {
	return input.Title != nil ||
		input.Category != nil ||
		input.Amount != nil ||
		input.DueDate != nil ||
		input.Frequency != nil ||
		input.AutoPay != nil
}

func billPaymentMatchesTx(bill repository.Bill, tx repository.Transaction, input UpdateBillInput) bool {
	if tx.Type != "expense" || tx.Amount != bill.Amount || tx.Title != bill.Title {
		return false
	}
	if input.WalletID != nil && tx.WalletID != *input.WalletID {
		return false
	}
	if input.Amount != nil && *input.Amount != bill.Amount {
		return false
	}
	if input.Title != nil && strings.TrimSpace(*input.Title) != bill.Title {
		return false
	}
	if input.Category != nil && strings.TrimSpace(*input.Category) != tx.Category {
		return false
	}
	return true
}

func (s *TrackerService) requireStore(userID uuid.UUID) error {
	if s == nil || s.store == nil {
		return errors.New("tracker service store is not initialized")
	}
	if userID == uuid.Nil {
		return fmt.Errorf("%w: user_id is required", ErrInvalidInput)
	}
	return nil
}

func (s *TrackerService) resolveMonthYear(raw string) (string, error) {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return s.nowFn().In(s.jakartaLoc).Format("2006-01"), nil
	}
	if len(trimmed) != 7 || trimmed[4] != '-' {
		return "", fmt.Errorf("%w: month_year must use YYYY-MM format", ErrInvalidInput)
	}
	if _, err := time.Parse("2006-01", trimmed); err != nil {
		return "", fmt.Errorf("%w: invalid month_year %q", ErrInvalidInput, raw)
	}
	return trimmed, nil
}

func parseISODate(raw string) (time.Time, error) {
	trimmed := strings.TrimSpace(raw)
	parsed, err := time.Parse("2006-01-02", trimmed)
	if err != nil {
		return time.Time{}, fmt.Errorf("%w: date %q must use YYYY-MM-DD format", ErrInvalidInput, raw)
	}
	return parsed, nil
}

func parseWIBTime(raw string) (pgtype.Time, error) {
	trimmed := strings.TrimSpace(raw)
	for _, layout := range []string{"15:04:05", "15:04"} {
		if t, err := time.Parse(layout, trimmed); err == nil {
			us := int64(t.Hour())*3600_000_000 + int64(t.Minute())*60_000_000 + int64(t.Second())*1_000_000
			return pgtype.Time{Microseconds: us, Valid: true}, nil
		}
	}
	return pgtype.Time{}, fmt.Errorf("%w: daily_reminder_time_wib %q must use HH:MM or HH:MM:SS", ErrInvalidInput, raw)
}

func formatPGTime(t pgtype.Time) string {
	if !t.Valid {
		return "20:00:00"
	}
	totalSec := t.Microseconds / 1_000_000
	hrs := totalSec / 3600
	mins := (totalSec % 3600) / 60
	secs := totalSec % 60
	return fmt.Sprintf("%02d:%02d:%02d", hrs, mins, secs)
}

func trimOptionalPtr(ptr *string) *string {
	if ptr == nil {
		return nil
	}
	trimmed := strings.TrimSpace(*ptr)
	if trimmed == "" {
		return nil
	}
	return &trimmed
}

func nonNilStrings(s []string) []string {
	if s == nil {
		return []string{}
	}
	out := make([]string, len(s))
	copy(out, s)
	return out
}

func isPGCode(err error, code string) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == code
}

func mapBalanceUpdateErr(op string, err error) error {
	if errors.Is(err, pgx.ErrNoRows) {
		return fmt.Errorf("%w: wallet is archived or missing", ErrConflict)
	}
	return fmt.Errorf("%s: %w", op, err)
}

func walletToDTO(w repository.Wallet) WalletDTO {
	return WalletDTO{
		ID:                  w.ID,
		UserID:              w.UserID,
		Name:                w.Name,
		Type:                w.Type,
		InstitutionCode:     w.InstitutionCode,
		AccountNumberMasked: w.AccountNumberMasked,
		Balance:             w.Balance,
		IsAutoSync:          w.IsAutoSync,
		CustomColorHex:      w.CustomColorHex,
		ReturnPercentage:    w.ReturnPercentage,
		DividendDropDate:    w.DividendDropDate,
		IsVolatile:          w.IsVolatile,
		HasClaimedDividend:  w.HasClaimedDividend,
		IsArchived:          w.IsArchived,
		CreatedAt:           w.CreatedAt,
		UpdatedAt:           w.UpdatedAt,
	}
}

func txToDTO(t repository.Transaction) TransactionDTO {
	return TransactionDTO{
		ID:                  t.ID,
		UserID:              t.UserID,
		WalletID:            t.WalletID,
		DestinationWalletID: t.DestinationWalletID,
		TargetGoalID:        t.TargetGoalID,
		CategoryID:          t.CategoryID,
		Type:                t.Type,
		Category:            t.Category,
		Amount:              t.Amount,
		Title:               t.Title,
		Note:                t.Note,
		OccurredAt:          t.OccurredAt,
		Source:              t.Source,
		ClientMutationID:    t.ClientMutationID,
		CreatedAt:           t.CreatedAt,
	}
}

func draftToDTO(d repository.AiDraft) AIDraftDTO {
	return AIDraftDTO{
		ID:                  d.ID,
		UserID:              d.UserID,
		WalletID:            d.WalletID,
		DestinationWalletID: d.DestinationWalletID,
		BatchID:             d.BatchID,
		Source:              d.Source,
		ExternalRefID:       d.ExternalRefID,
		ClientMutationID:    d.ClientMutationID,
		Type:                d.Type,
		Category:            d.Category,
		Amount:              d.Amount,
		Title:               d.Title,
		MerchantOrNote:      d.MerchantOrNote,
		OccurredAt:          d.OccurredAt,
		ConfidenceScore:     d.ConfidenceScore,
		Status:              d.Status,
		CreatedAt:           d.CreatedAt,
		UpdatedAt:           d.UpdatedAt,
	}
}

func goalToDTO(g repository.Goal, contribs []GoalContributionDTO) GoalDTO {
	var targetDateStr *string
	if g.TargetDate != nil {
		formatted := g.TargetDate.Format("2006-01-02")
		targetDateStr = &formatted
	}
	if contribs == nil {
		contribs = []GoalContributionDTO{}
	}
	return GoalDTO{
		ID:               g.ID,
		UserID:           g.UserID,
		LinkedWalletID:   g.LinkedWalletID,
		Title:            g.Title,
		TargetAmount:     g.TargetAmount,
		SavedAmount:      g.SavedAmount,
		TargetDate:       targetDateStr,
		Priority:         g.Priority,
		SourceAssetLabel: g.SourceAssetLabel,
		IconKey:          g.IconKey,
		TagColorHex:      g.TagColorHex,
		TagTextColorHex:  g.TagTextColorHex,
		Status:           g.Status,
		Contributions:    contribs,
		CreatedAt:        g.CreatedAt,
		UpdatedAt:        g.UpdatedAt,
	}
}

func billToDTO(b repository.Bill) BillDTO {
	var dueDateStr *string
	if b.DueDate != nil {
		formatted := b.DueDate.Format("2006-01-02")
		dueDateStr = &formatted
	}
	return BillDTO{
		ID:             b.ID,
		UserID:         b.UserID,
		Title:          b.Title,
		Category:       b.Category,
		Amount:         b.Amount,
		DueDate:        dueDateStr,
		Frequency:      b.Frequency,
		IsPaid:         b.IsPaid,
		AutoPay:        b.AutoPay,
		IconKey:        b.IconKey,
		IconColorHex:   b.IconColorHex,
		IconBgColorHex: b.IconBgColorHex,
		PaidAt:         b.PaidAt,
		CreatedAt:      b.CreatedAt,
		UpdatedAt:      b.UpdatedAt,
	}
}
