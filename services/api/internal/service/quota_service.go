package service

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"

	"github.com/clarafin/api/internal/repository"
)

const (
	// FreeMonthlyQuotaLimit is the monthly AI action allowance for Free tier accounts (resets 1st 00:00 WIB).
	FreeMonthlyQuotaLimit = 40
	maxRequestIDLength    = 128
)

var (
	// ErrQuotaExceeded indicates the user has exhausted their active AI action quota.
	ErrQuotaExceeded = errors.New("monthly AI quota exceeded")
	// ErrInvalidQuotaRequest indicates invalid reservation inputs (nil user, empty request_id, or unsupported enum).
	ErrInvalidQuotaRequest = errors.New("invalid quota reservation request")
	// ErrRequestIDConflict indicates a request_id already belongs to a different user or collided concurrently.
	ErrRequestIDConflict = errors.New("request_id already claimed by another user")
	// ErrReservationNotFound indicates no ledger reservation exists for the supplied request_id.
	ErrReservationNotFound = errors.New("AI usage reservation not found")
	// ErrReservationFinalized indicates the ledger reservation already reached a conflicting terminal status.
	ErrReservationFinalized = errors.New("AI usage reservation already finalized")
	// ErrUserNotFound indicates the target user does not exist or has been soft-deleted.
	ErrUserNotFound = errors.New("user not found")
)

var validActionTypes = map[string]struct{}{
	"chat":       {},
	"quick_add":  {},
	"voice":      {},
	"ocr":        {},
	"gmail_sync": {},
}

var validSurfaceModes = map[string]struct{}{
	"quick_sheet": {},
	"full_screen": {},
	"voice":       {},
	"ocr":         {},
	"gmail":       {},
}

// QuotaStatus describes the user's effective AI plan and remaining monthly/subscription allowance.
type QuotaStatus struct {
	PlanType       string `json:"plan_type"`
	QuotaTotal     int    `json:"quota_total"`
	QuotaUsed      int    `json:"quota_used"`
	QuotaRemaining int    `json:"quota_remaining"`
	RenewalDate    string `json:"renewal_date"`
}

// QuotaReservation captures the outcome of an atomic AI action reservation.
type QuotaReservation struct {
	LedgerID       uuid.UUID   `json:"ledger_id"`
	UserID         uuid.UUID   `json:"user_id"`
	RequestID      string      `json:"request_id"`
	MonthYear      string      `json:"month_year"`
	ActionType     string      `json:"action_type"`
	SurfaceMode    string      `json:"surface_mode"`
	Bucket         string      `json:"bucket"`
	Status         string      `json:"status"`
	SubscriptionID *uuid.UUID  `json:"subscription_id,omitempty"`
	Reused         bool        `json:"reused"`
	QuotaStatus    QuotaStatus `json:"quota_status"`
}

// QuotaOption customizes QuotaService clocks or timezone configuration.
type QuotaOption func(*QuotaService)

// WithNowFunc overrides the clock source used for WIB rollover and subscription active checks.
func WithNowFunc(fn func() time.Time) QuotaOption {
	return func(s *QuotaService) {
		if fn != nil {
			s.nowFn = fn
		}
	}
}

// WithJakartaLocation overrides the Asia/Jakarta location used for monthly rollover calculations.
func WithJakartaLocation(loc *time.Location) QuotaOption {
	return func(s *QuotaService) {
		if loc != nil {
			s.jakartaLoc = loc
		}
	}
}

// QuotaService enforces atomic AI action quota reservation, commit, compensation, and status reads.
type QuotaService struct {
	store      *repository.Store
	nowFn      func() time.Time
	jakartaLoc *time.Location
}

// NewQuotaService constructs a QuotaService backed by PostgreSQL transactions via store.
func NewQuotaService(store *repository.Store, opts ...QuotaOption) *QuotaService {
	loc, err := time.LoadLocation("Asia/Jakarta")
	if err != nil {
		loc = time.FixedZone("WIB", 7*3600)
	}

	svc := &QuotaService{
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

// ReserveAction atomically reserves 1 AI action for userID under requestID inside a user-locked DB transaction.
// Retrying the same requestID in 'reserved' or 'success' state returns the existing reservation with Reused=true
// without double-charging pro_subscriptions or inserting duplicate ledger rows.
func (s *QuotaService) ReserveAction(ctx context.Context, userID uuid.UUID, requestID, actionType, surfaceMode string) (*QuotaReservation, error) {
	if s == nil || s.store == nil {
		return nil, errors.New("quota service store is not initialized")
	}

	reqID := strings.TrimSpace(requestID)
	if userID == uuid.Nil || reqID == "" || len(reqID) > maxRequestIDLength {
		return nil, fmt.Errorf("%w: valid user_id and non-empty request_id (<= %d chars) are required", ErrInvalidQuotaRequest, maxRequestIDLength)
	}
	if _, ok := validActionTypes[actionType]; !ok {
		return nil, fmt.Errorf("%w: unsupported action_type %q", ErrInvalidQuotaRequest, actionType)
	}
	if _, ok := validSurfaceModes[surfaceMode]; !ok {
		return nil, fmt.Errorf("%w: unsupported surface_mode %q", ErrInvalidQuotaRequest, surfaceMode)
	}

	var out *QuotaReservation
	err := s.store.WithTx(ctx, func(q *repository.Queries) error {
		if _, err := q.LockUserForQuota(ctx, userID); err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return ErrUserNotFound
			}
			return fmt.Errorf("lock user for quota: %w", err)
		}

		now := s.nowFn()
		existing, err := q.GetAIUsageByRequestIDOnly(ctx, reqID)
		if err == nil {
			if existing.UserID != userID {
				return ErrRequestIDConflict
			}
			if existing.Status == "failed" {
				return fmt.Errorf("%w: cannot reuse failed request_id %q", ErrReservationFinalized, reqID)
			}

			status, statusErr := s.computeQuotaStatus(ctx, q, userID, now)
			if statusErr != nil {
				return statusErr
			}
			out = &QuotaReservation{
				LedgerID:    existing.ID,
				UserID:      existing.UserID,
				RequestID:   existing.RequestID,
				MonthYear:   existing.MonthYear,
				ActionType:  existing.ActionType,
				SurfaceMode: existing.SurfaceMode,
				Bucket:      existing.Bucket,
				Status:      existing.Status,
				Reused:      true,
				QuotaStatus: status,
			}
			return nil
		}
		if !errors.Is(err, pgx.ErrNoRows) {
			return fmt.Errorf("lookup existing request_id: %w", err)
		}

		nowWIB := now.In(s.jakartaLoc)
		monthYear := nowWIB.Format("2006-01")

		bucket, subID, err := s.allocateBucketLocked(ctx, q, userID, monthYear, now)
		if err != nil {
			return err
		}

		reserved, err := q.ReserveAIUsage(ctx, repository.ReserveAIUsageParams{
			UserID:      userID,
			RequestID:   reqID,
			MonthYear:   monthYear,
			ActionType:  actionType,
			SurfaceMode: surfaceMode,
			Bucket:      bucket,
		})
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				// Another user simultaneously claimed the same globally unique request_id.
				return ErrRequestIDConflict
			}
			return fmt.Errorf("insert ai_usage_ledger reservation: %w", err)
		}

		status, err := s.computeQuotaStatus(ctx, q, userID, now)
		if err != nil {
			return err
		}

		out = &QuotaReservation{
			LedgerID:       reserved.ID,
			UserID:         reserved.UserID,
			RequestID:      reserved.RequestID,
			MonthYear:      reserved.MonthYear,
			ActionType:     reserved.ActionType,
			SurfaceMode:    reserved.SurfaceMode,
			Bucket:         reserved.Bucket,
			Status:         reserved.Status,
			SubscriptionID: subID,
			Reused:         false,
			QuotaStatus:    status,
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return out, nil
}

// CommitSuccess finalizes a 'reserved' ledger row as 'success'. Repeated calls for an already-succeeded
// requestID are idempotent and return nil.
func (s *QuotaService) CommitSuccess(ctx context.Context, requestID string) error {
	if s == nil || s.store == nil {
		return errors.New("quota service store is not initialized")
	}

	reqID := strings.TrimSpace(requestID)
	if reqID == "" {
		return fmt.Errorf("%w: request_id is required", ErrInvalidQuotaRequest)
	}

	return s.store.WithTx(ctx, func(q *repository.Queries) error {
		existing, err := q.GetAIUsageByRequestIDOnly(ctx, reqID)
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return ErrReservationNotFound
			}
			return fmt.Errorf("lookup reservation for commit: %w", err)
		}

		if existing.Status == "success" {
			return nil
		}
		if existing.Status == "failed" {
			return fmt.Errorf("%w: reservation %q is already failed", ErrReservationFinalized, reqID)
		}

		// Acquire user lock in the same order as ReserveAction to prevent cross-transaction deadlocks.
		if _, err := q.LockUserForQuota(ctx, existing.UserID); err != nil && !errors.Is(err, pgx.ErrNoRows) {
			return fmt.Errorf("lock user for commit: %w", err)
		}

		if _, err := q.MarkAIUsageSuccessByRequestID(ctx, reqID); err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				latest, checkErr := q.GetAIUsageByRequestIDOnly(ctx, reqID)
				if checkErr != nil {
					if errors.Is(checkErr, pgx.ErrNoRows) {
						return ErrReservationNotFound
					}
					return fmt.Errorf("re-read reservation after commit miss: %w", checkErr)
				}
				if latest.Status == "success" {
					return nil
				}
				return fmt.Errorf("%w: reservation %q status is %q", ErrReservationFinalized, reqID, latest.Status)
			}
			return fmt.Errorf("mark ai_usage_ledger success: %w", err)
		}
		return nil
	})
}

// CompensateFailure transitions a 'reserved' ledger row to 'failed' and restores pro_subscriptions.quota_used
// when the reservation consumed a paid subscription bucket. Repeated calls for an already-failed requestID
// are idempotent and never double-decrement.
func (s *QuotaService) CompensateFailure(ctx context.Context, requestID string) error {
	if s == nil || s.store == nil {
		return errors.New("quota service store is not initialized")
	}

	reqID := strings.TrimSpace(requestID)
	if reqID == "" {
		return fmt.Errorf("%w: request_id is required", ErrInvalidQuotaRequest)
	}

	return s.store.WithTx(ctx, func(q *repository.Queries) error {
		existing, err := q.GetAIUsageByRequestIDOnly(ctx, reqID)
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return ErrReservationNotFound
			}
			return fmt.Errorf("lookup reservation for compensation: %w", err)
		}

		if existing.Status == "failed" {
			return nil
		}
		if existing.Status == "success" {
			return fmt.Errorf("%w: reservation %q is already committed as success", ErrReservationFinalized, reqID)
		}

		// Acquire user lock before modifying ledger or pro_subscriptions to match ReserveAction lock order.
		if _, err := q.LockUserForQuota(ctx, existing.UserID); err != nil && !errors.Is(err, pgx.ErrNoRows) {
			return fmt.Errorf("lock user for compensation: %w", err)
		}

		updated, err := q.MarkAIUsageFailedByRequestID(ctx, reqID)
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				latest, checkErr := q.GetAIUsageByRequestIDOnly(ctx, reqID)
				if checkErr != nil {
					if errors.Is(checkErr, pgx.ErrNoRows) {
						return ErrReservationNotFound
					}
					return fmt.Errorf("re-read reservation after compensation miss: %w", checkErr)
				}
				if latest.Status == "failed" {
					return nil
				}
				return fmt.Errorf("%w: reservation %q status is %q", ErrReservationFinalized, reqID, latest.Status)
			}
			return fmt.Errorf("mark ai_usage_ledger failed: %w", err)
		}

		var planType string
		switch updated.Bucket {
		case "pro":
			planType = "pro_monthly"
		case "bonus":
			planType = "consult_bonus"
		default:
			return nil
		}

		sub, err := q.FindProSubscriptionForCompensation(ctx, repository.FindProSubscriptionForCompensationParams{
			UserID:   updated.UserID,
			PlanType: planType,
		})
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return nil
			}
			return fmt.Errorf("find pro_subscription for compensation: %w", err)
		}

		if _, err := q.DecrementProSubscriptionUsage(ctx, repository.DecrementProSubscriptionUsageParams{
			UserID: updated.UserID,
			ID:     sub.ID,
		}); err != nil && !errors.Is(err, pgx.ErrNoRows) {
			return fmt.Errorf("decrement pro_subscription quota_used: %w", err)
		}
		return nil
	})
}

// GetQuotaStatus returns the user's current effective plan, quota totals/remaining, and WIB renewal timestamp.
func (s *QuotaService) GetQuotaStatus(ctx context.Context, userID uuid.UUID) (*QuotaStatus, error) {
	if s == nil || s.store == nil {
		return nil, errors.New("quota service store is not initialized")
	}
	if userID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrInvalidQuotaRequest)
	}

	if _, err := s.store.GetUserProfileByID(ctx, userID); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrUserNotFound
		}
		return nil, fmt.Errorf("verify user profile: %w", err)
	}

	status, err := s.computeQuotaStatus(ctx, s.store.Queries, userID, s.nowFn())
	if err != nil {
		return nil, err
	}
	return &status, nil
}

func (s *QuotaService) allocateBucketLocked(
	ctx context.Context,
	q *repository.Queries,
	userID uuid.UUID,
	monthYear string,
	now time.Time,
) (string, *uuid.UUID, error) {
	subs, err := q.ListActiveProSubscriptionsAt(ctx, repository.ListActiveProSubscriptionsAtParams{
		UserID: userID,
		AtTime: now.UTC(),
	})
	if err != nil {
		return "", nil, fmt.Errorf("list active pro_subscriptions: %w", err)
	}

	hasActiveProMonthly := false
	for _, sub := range subs {
		if sub.QuotaTotal == -1 {
			subID := sub.ID
			return "unlimited", &subID, nil
		}
		if sub.PlanType == "pro_monthly" {
			hasActiveProMonthly = true
		}
		if sub.QuotaUsed < sub.QuotaTotal {
			bucket := "bonus"
			if sub.PlanType == "pro_monthly" {
				bucket = "pro"
			}
			updated, err := q.IncrementProSubscriptionUsageAt(ctx, repository.IncrementProSubscriptionUsageAtParams{
				UserID: userID,
				ID:     sub.ID,
				AtTime: now.UTC(),
			})
			if err != nil {
				if errors.Is(err, pgx.ErrNoRows) {
					return "", nil, ErrQuotaExceeded
				}
				return "", nil, fmt.Errorf("increment pro_subscription usage: %w", err)
			}
			subID := updated.ID
			return bucket, &subID, nil
		}
	}

	if hasActiveProMonthly {
		// Active Pro Monthly subscription exists with 0 remaining quota; do not silently bypass to Free tier.
		return "", nil, ErrQuotaExceeded
	}

	usedCount, err := q.GetMonthlyFreeUsageCount(ctx, repository.GetMonthlyFreeUsageCountParams{
		UserID:    userID,
		MonthYear: monthYear,
	})
	if err != nil {
		return "", nil, fmt.Errorf("count monthly free AI usage: %w", err)
	}
	if usedCount >= FreeMonthlyQuotaLimit {
		return "", nil, ErrQuotaExceeded
	}
	return "free", nil, nil
}

func (s *QuotaService) computeQuotaStatus(
	ctx context.Context,
	q *repository.Queries,
	userID uuid.UUID,
	now time.Time,
) (QuotaStatus, error) {
	nowWIB := now.In(s.jakartaLoc)
	monthYear := nowWIB.Format("2006-01")

	subs, err := q.ListActiveProSubscriptionsAt(ctx, repository.ListActiveProSubscriptionsAtParams{
		UserID: userID,
		AtTime: now.UTC(),
	})
	if err != nil {
		return QuotaStatus{}, fmt.Errorf("list active pro_subscriptions for status: %w", err)
	}

	var firstExhaustedPro *repository.ProSubscription
	for i := range subs {
		sub := subs[i]
		if sub.QuotaTotal == -1 {
			usedUnlimited, err := q.GetMonthlyUsageCountByBucket(ctx, repository.GetMonthlyUsageCountByBucketParams{
				UserID:    userID,
				MonthYear: monthYear,
				Bucket:    "unlimited",
			})
			if err != nil {
				return QuotaStatus{}, fmt.Errorf("count monthly unlimited usage: %w", err)
			}
			return QuotaStatus{
				PlanType:       "unlimited",
				QuotaTotal:     -1,
				QuotaUsed:      int(usedUnlimited),
				QuotaRemaining: -1,
				RenewalDate:    formatOptionalWIBTimestamp(sub.ExpiresAt, s.jakartaLoc),
			}, nil
		}
		if sub.QuotaUsed < sub.QuotaTotal {
			remaining := max(int(sub.QuotaTotal-sub.QuotaUsed), 0)
			return QuotaStatus{
				PlanType:       "pro_monthly",
				QuotaTotal:     int(sub.QuotaTotal),
				QuotaUsed:      int(sub.QuotaUsed),
				QuotaRemaining: remaining,
				RenewalDate:    formatOptionalWIBTimestamp(sub.ExpiresAt, s.jakartaLoc),
			}, nil
		}
		if sub.PlanType == "pro_monthly" && firstExhaustedPro == nil {
			firstExhaustedPro = &sub
		}
	}

	if firstExhaustedPro != nil {
		return QuotaStatus{
			PlanType:       "pro_monthly",
			QuotaTotal:     int(firstExhaustedPro.QuotaTotal),
			QuotaUsed:      int(firstExhaustedPro.QuotaUsed),
			QuotaRemaining: 0,
			RenewalDate:    formatOptionalWIBTimestamp(firstExhaustedPro.ExpiresAt, s.jakartaLoc),
		}, nil
	}

	freeUsed, err := q.GetMonthlyFreeUsageCount(ctx, repository.GetMonthlyFreeUsageCountParams{
		UserID:    userID,
		MonthYear: monthYear,
	})
	if err != nil {
		return QuotaStatus{}, fmt.Errorf("count monthly free usage for status: %w", err)
	}

	used := int(freeUsed)
	remaining := max(FreeMonthlyQuotaLimit-used, 0)
	nextReset := time.Date(nowWIB.Year(), nowWIB.Month()+1, 1, 0, 0, 0, 0, s.jakartaLoc)

	return QuotaStatus{
		PlanType:       "free",
		QuotaTotal:     FreeMonthlyQuotaLimit,
		QuotaUsed:      used,
		QuotaRemaining: remaining,
		RenewalDate:    nextReset.Format(time.RFC3339),
	}, nil
}

func formatOptionalWIBTimestamp(ts *time.Time, loc *time.Location) string {
	if ts == nil {
		return ""
	}
	return ts.In(loc).Format(time.RFC3339)
}
