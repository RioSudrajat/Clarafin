package ai_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/clarafin/api/internal/ai"
	"github.com/clarafin/api/internal/repository"
)

func openMatchingTxTest(t *testing.T) (*repository.Store, pgx.Tx, context.Context) {
	t.Helper()

	store, ctx := openAITestStore(t)
	tx, err := store.Pool.Begin(ctx)
	if err != nil {
		t.Fatalf("begin matching test tx: %v", err)
	}
	t.Cleanup(func() {
		rollbackCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = tx.Rollback(rollbackCtx)
	})
	return &repository.Store{Queries: repository.New(tx)}, tx, ctx
}

func createTempTxUser(t *testing.T, ctx context.Context, txStore *repository.Store, tx pgx.Tx, label string) repository.User {
	t.Helper()

	userID := uuid.New()
	email := fmt.Sprintf("ai-match-%s-%s@clarafin.test", label, userID.String()[:8])

	if _, err := tx.Exec(ctx, `INSERT INTO auth.users (id, email) VALUES ($1, $2)`, userID, email); err != nil {
		t.Fatalf("insert auth.users(%s): %v", label, err)
	}
	user, err := txStore.EnsureDevUser(ctx, repository.EnsureDevUserParams{
		ID:       userID,
		Email:    email,
		FullName: "AI Tool " + label,
	})
	if err != nil {
		t.Fatalf("EnsureDevUser(%s): %v", label, err)
	}
	if _, err := txStore.EnsureUserPreferences(ctx, userID); err != nil {
		t.Fatalf("EnsureUserPreferences(%s): %v", label, err)
	}
	return user
}

type isolatedSlotSpec struct {
	dayOfWeek int32
	startHour string
	endHour   string
}

type isolatedPractitionerSpec struct {
	name          string
	tier          string
	tagSlug       string
	catalogCode   string
	priceIDR      int64
	platformCut   int32
	rating        float32
	sessions      int32
	isFullyBooked bool
	onlineActive  bool
	offlineActive bool
	slots         []isolatedSlotSpec
	pinTagID      uuid.UUID
	pinOrder      int32
}

func insertIsolatedPractitioner(t *testing.T, ctx context.Context, tx pgx.Tx, sp isolatedPractitionerSpec) uuid.UUID {
	t.Helper()

	id := uuid.New()
	email := fmt.Sprintf("iso-prac-%s@clarafin.test", id.String()[:8])

	if _, err := tx.Exec(ctx, `INSERT INTO auth.users (id, email) VALUES ($1, $2)`, id, email); err != nil {
		t.Fatalf("insert auth.users %s: %v", sp.name, err)
	}
	if _, err := tx.Exec(ctx, `
		INSERT INTO users (id, email, full_name, onboarding_completed)
		VALUES ($1, $2, $3, TRUE)
	`, id, email, sp.name); err != nil {
		t.Fatalf("insert users %s: %v", sp.name, err)
	}
	if _, err := tx.Exec(ctx, `
		INSERT INTO practitioner_profiles (
			user_id, display_name, title_headline, bio, city, practitioner_tier,
			clients_handled_count, certifications, certificate_file_urls, ktp_file_url,
			specializations, languages, supported_methods, gender, birth_year, consulting_style,
			years_of_experience, is_fully_booked, status, platform_cut_pct, rating_avg, review_count,
			total_sessions_completed, verified_at
		) VALUES (
			$1, $2, 'Planner', 'Bio', 'Jakarta', $3,
			100, ARRAY['CFP'], ARRAY['cert.pdf'], 'ktp.pdf',
			ARRAY[$4], ARRAY['Indonesia'], ARRAY['online', 'offline'], 'Perempuan', 1990, 'Hangat dan suportif',
			4, $5, 'verified', $6, $7, 50, $8, NOW()
		)
	`, id, sp.name, sp.tier, sp.tagSlug, sp.isFullyBooked, sp.platformCut, sp.rating, sp.sessions); err != nil {
		t.Fatalf("insert practitioner_profiles %s: %v", sp.name, err)
	}

	var cpID uuid.UUID
	var serviceCategory, categoryTag, pkgTier, pkgTitle string
	var durationMinutes int32
	if err := tx.QueryRow(ctx, `
		SELECT id, service_category, category_tag, tier, package_title, online_duration_minutes
		FROM catalog_packages
		WHERE code = $1
	`, sp.catalogCode).Scan(&cpID, &serviceCategory, &categoryTag, &pkgTier, &pkgTitle, &durationMinutes); err != nil {
		t.Fatalf("lookup catalog_package %q: %v", sp.catalogCode, err)
	}

	if _, err := tx.Exec(ctx, `
		INSERT INTO practitioner_packages (
			practitioner_id, catalog_package_id, service_category, category_tag, tier,
			package_title, duration_minutes, online_price_idr, offline_price_idr,
			is_online_active, is_offline_active, is_active
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, TRUE)
	`, id, cpID, serviceCategory, categoryTag, pkgTier, pkgTitle, durationMinutes, sp.priceIDR, sp.priceIDR+150000, sp.onlineActive, sp.offlineActive); err != nil {
		t.Fatalf("insert practitioner_packages %s: %v", sp.name, err)
	}

	for _, sl := range sp.slots {
		if _, err := tx.Exec(ctx, `
			INSERT INTO practitioner_availability (practitioner_id, day_of_week, start_time_wib, end_time_wib, is_active)
			VALUES ($1, $2, $3::time, $4::time, TRUE)
		`, id, sl.dayOfWeek, sl.startHour, sl.endHour); err != nil {
			t.Fatalf("insert practitioner_availability %s: %v", sp.name, err)
		}
	}

	if sp.pinTagID != uuid.Nil && sp.pinOrder > 0 {
		if _, err := tx.Exec(ctx, `
			INSERT INTO staff_practitioner_pins (problem_tag_id, practitioner_id, priority_order)
			VALUES ($1, $2, $3)
		`, sp.pinTagID, id, sp.pinOrder); err != nil {
			t.Fatalf("insert staff_practitioner_pins %s: %v", sp.name, err)
		}
	}

	return id
}

func TestPractitionerCodeHelpers_RoundTrip(t *testing.T) {
	cases := []struct {
		code string
		uuid string
	}{
		{"c1", "00000000-0000-4000-8000-0000000000c1"},
		{"c2", "00000000-0000-4000-8000-0000000000c2"},
		{"c3", "00000000-0000-4000-8000-0000000000c3"},
		{"c4", "00000000-0000-4000-8000-0000000000c4"},
		{"c5", "00000000-0000-4000-8000-0000000000c5"},
		{"c6", "00000000-0000-4000-8000-0000000000c6"},
	}

	for _, tc := range cases {
		id := uuid.MustParse(tc.uuid)
		if got := ai.PractitionerCodeFromUUID(id); got != tc.code {
			t.Fatalf("PractitionerCodeFromUUID(%s) = %q, want %q", id, got, tc.code)
		}

		parsed, err := ai.PractitionerUUIDFromCode(strings.ToUpper(tc.code))
		if err != nil || parsed != id {
			t.Fatalf("PractitionerUUIDFromCode(%q) = (%s, %v), want %s", tc.code, parsed, err, id)
		}

		parsedFromUUID, err := ai.PractitionerUUIDFromCode(tc.uuid)
		if err != nil || parsedFromUUID != id {
			t.Fatalf("PractitionerUUIDFromCode(%q) = (%s, %v), want %s", tc.uuid, parsedFromUUID, err, id)
		}
	}

	customID := uuid.New()
	if got := ai.PractitionerCodeFromUUID(customID); got != customID.String() {
		t.Fatalf("PractitionerCodeFromUUID(custom) = %q, want %q", got, customID.String())
	}

	if _, err := ai.PractitionerUUIDFromCode("c99"); !errors.Is(err, ai.ErrInvalidMatchingInput) {
		t.Fatalf("expected ErrInvalidMatchingInput for c99, got %v", err)
	}
	if _, err := ai.PractitionerUUIDFromCode(""); !errors.Is(err, ai.ErrInvalidMatchingInput) {
		t.Fatalf("expected ErrInvalidMatchingInput for empty code, got %v", err)
	}
	if _, err := ai.PractitionerUUIDFromCode(uuid.Nil.String()); !errors.Is(err, ai.ErrInvalidMatchingInput) {
		t.Fatalf("expected ErrInvalidMatchingInput for nil uuid, got %v", err)
	}
}

func TestMatchingTool_SignalOverride_ChatContextWinsOverOnboardingAndQuiz(t *testing.T) {
	txStore, tx, ctx := openMatchingTxTest(t)
	user := createTempTxUser(t, ctx, txStore, tx, "match-override")

	if _, err := txStore.UpsertUserPreferences(ctx, repository.UpsertUserPreferencesParams{
		UserID:                  user.ID,
		NotificationsEnabled:    true,
		SessionRemindersEnabled: true,
		BillRemindersEnabled:    true,
		PromoAlertsEnabled:      true,
		DailyReminderEnabled:    false,
		DailyReminderTimeWib:    pgtype.Time{Microseconds: 20 * 3_600_000_000, Valid: true},
		TrackingHistorySource:   "fresh_start",
		TrackerFocuses:          []string{"expenses"},
		AdvisoryFocuses:         []string{"basic", "individual"},
		PreferredCurrency:       "IDR",
		PreferredLanguage:       "Bahasa Indonesia",
	}); err != nil {
		t.Fatalf("UpsertUserPreferences: %v", err)
	}

	answersBytes, _ := json.Marshal(map[string]any{
		"method":        "online",
		"target":        "self",
		"budget_tier":   "low",
		"main_topic":    "debt_cashflow",
		"specific_tags": []string{"pinjol"},
		"languages":     []string{"id"},
	})
	if _, err := txStore.CreateMatchExpertSubmission(ctx, repository.CreateMatchExpertSubmissionParams{
		UserID:             user.ID,
		AnswersJson:        answersBytes,
		TopPractitionerIds: []uuid.UUID{uuid.MustParse("00000000-0000-4000-8000-0000000000c3")},
	}); err != nil {
		t.Fatalf("CreateMatchExpertSubmission: %v", err)
	}

	wib := time.FixedZone("WIB", 7*3600)
	fixedNow := time.Date(2026, 11, 23, 8, 0, 0, 0, wib)
	tool := ai.NewMatchingTool(
		txStore,
		ai.WithMatchingNowFunc(func() time.Time { return fixedNow }),
		ai.WithMatchingJakartaLocation(wib),
	)

	out, err := tool.MatchExpertsAndPackage(ctx, user.ID, ai.MatchSignals{
		Target:          "couple",
		MainTopic:       "house_wedding",
		UserGoalSummary: "Kami rencana menikah tahun depan, ingin buka-bukaan gaji, cicilan, dan atur rekening bersama.",
	})
	if err != nil {
		t.Fatalf("MatchExpertsAndPackage: %v", err)
	}

	if out.RecommendedPackage.PackageCode != "couple_pre_marriage" {
		t.Fatalf("expected package couple_pre_marriage, got %q", out.RecommendedPackage.PackageCode)
	}
	if out.RecommendedPackage.OnlinePriceIDR != 349000 {
		t.Fatalf("expected couple_pre_marriage online price 349000, got %d", out.RecommendedPackage.OnlinePriceIDR)
	}
	if out.RecommendedPackage.ServiceCategory != "couple" || out.RecommendedPackage.SelectedTierLabel == "" {
		t.Fatalf("unexpected package metadata: %+v", out.RecommendedPackage)
	}

	if len(out.Consultants) != 2 {
		t.Fatalf("expected 2 couple consultants (c1, c5), got %d (%+v)", len(out.Consultants), out.Consultants)
	}
	if out.Consultants[0].ConsultantID != "c1" || out.Consultants[1].ConsultantID != "c5" {
		t.Fatalf("expected [c1, c5] ordered by budget_nikah pins, got [%s, %s]", out.Consultants[0].ConsultantID, out.Consultants[1].ConsultantID)
	}
	for _, c := range out.Consultants {
		if c.ConsultantID == "c3" {
			t.Fatal("c3 must never be returned for couple_pre_marriage")
		}
		if c.OnlinePriceIDR != 349000 {
			t.Fatalf("expected consultant %s couple_pre_marriage price 349000, got %d", c.ConsultantID, c.OnlinePriceIDR)
		}
		if c.NextAvailableSlotISO == "" || c.NextAvailableSlotLabel == "" {
			t.Fatalf("expected concrete slot ISO & label for %s, got %+v", c.ConsultantID, c)
		}
		slotTime, parseErr := time.Parse(time.RFC3339, c.NextAvailableSlotISO)
		if parseErr != nil {
			t.Fatalf("invalid NextAvailableSlotISO %q: %v", c.NextAvailableSlotISO, parseErr)
		}
		if slotTime.Before(fixedNow) || !slotTime.Before(fixedNow.Add(14*24*time.Hour)) {
			t.Fatalf("slot %s outside 14-day window from %s", slotTime, fixedNow)
		}
	}

	if len(out.PrefilledIntakeSummary.RecommendedTopics) == 0 ||
		out.PrefilledIntakeSummary.PrefilledDescription == "" ||
		out.PrefilledIntakeSummary.PrefilledExpectations == "" {
		t.Fatalf("expected populated PrefilledIntakeSummary, got %+v", out.PrefilledIntakeSummary)
	}

	rawJSON, err := json.Marshal(out)
	if err != nil {
		t.Fatalf("marshal MatchingOutput: %v", err)
	}
	jsonStr := string(rawJSON)
	for _, forbidden := range []string{"ktp_file_url", "platform_cut_pct", "violation_count", "bank_account", "bank_name"} {
		if strings.Contains(jsonStr, forbidden) {
			t.Fatalf("MatchingOutput leaked forbidden private field %q", forbidden)
		}
	}
}

func TestMatchingTool_GoalSummaryOnlyOverride_OverridesUMKMOnboardingToCouplePreMarriage(t *testing.T) {
	wib := time.FixedZone("WIB", 7*3600)
	fixedNow := time.Date(2026, 11, 23, 8, 0, 0, 0, wib)

	t.Run("umkm_onboarding_low_budget_overridden_by_nikah_goal_summary", func(t *testing.T) {
		txStore, tx, ctx := openMatchingTxTest(t)
		user := createTempTxUser(t, ctx, txStore, tx, "goal-override-umkm")

		if _, err := txStore.UpsertUserPreferences(ctx, repository.UpsertUserPreferencesParams{
			UserID:                  user.ID,
			NotificationsEnabled:    true,
			SessionRemindersEnabled: true,
			BillRemindersEnabled:    true,
			PromoAlertsEnabled:      true,
			DailyReminderEnabled:    false,
			DailyReminderTimeWib:    pgtype.Time{Microseconds: 20 * 3_600_000_000, Valid: true},
			TrackingHistorySource:   "fresh_start",
			TrackerFocuses:          []string{"business"},
			AdvisoryFocuses:         []string{"umkm", "basic"},
			PreferredCurrency:       "IDR",
			PreferredLanguage:       "Bahasa Indonesia",
		}); err != nil {
			t.Fatalf("UpsertUserPreferences: %v", err)
		}

		answersBytes, _ := json.Marshal(map[string]any{
			"method":        "online",
			"target":        "business",
			"budget_tier":   "low",
			"main_topic":    "sme",
			"specific_tags": []string{"kas_bisnis"},
		})
		if _, err := txStore.CreateMatchExpertSubmission(ctx, repository.CreateMatchExpertSubmissionParams{
			UserID:             user.ID,
			AnswersJson:        answersBytes,
			TopPractitionerIds: []uuid.UUID{uuid.MustParse("00000000-0000-4000-8000-0000000000c6")},
		}); err != nil {
			t.Fatalf("CreateMatchExpertSubmission: %v", err)
		}

		tool := ai.NewMatchingTool(
			txStore,
			ai.WithMatchingNowFunc(func() time.Time { return fixedNow }),
			ai.WithMatchingJakartaLocation(wib),
		)

		out, err := tool.MatchExpertsAndPackage(ctx, user.ID, ai.MatchSignals{
			UserGoalSummary: "kami mau nikah tahun depan",
		})
		if err != nil {
			t.Fatalf("MatchExpertsAndPackage: %v", err)
		}

		if out.RecommendedPackage.PackageCode != "couple_pre_marriage" {
			t.Fatalf("expected couple_pre_marriage, got %q", out.RecommendedPackage.PackageCode)
		}
		if out.RecommendedPackage.OnlinePriceIDR != 349000 {
			t.Fatalf("expected couple_pre_marriage online price 349000, got %d", out.RecommendedPackage.OnlinePriceIDR)
		}
		if out.ResolvedSignals.Target != "couple" {
			t.Fatalf("expected resolved Target 'couple', got %q", out.ResolvedSignals.Target)
		}
		if out.ResolvedSignals.MainTopic != "house_wedding" {
			t.Fatalf("expected resolved MainTopic 'house_wedding', got %q", out.ResolvedSignals.MainTopic)
		}
		if out.ResolvedSignals.BudgetTier != "" {
			t.Fatalf("expected stale DB BudgetTier to be dropped, got %q", out.ResolvedSignals.BudgetTier)
		}
		if len(out.Consultants) != 2 || out.Consultants[0].ConsultantID != "c1" || out.Consultants[1].ConsultantID != "c5" {
			t.Fatalf("expected [c1, c5], got %+v", out.Consultants)
		}
	})

	t.Run("umkm_onboarding_overridden_by_personal_pinjol_goal_summary", func(t *testing.T) {
		txStore, tx, ctx := openMatchingTxTest(t)
		user := createTempTxUser(t, ctx, txStore, tx, "goal-override-pinjol")

		if _, err := txStore.UpsertUserPreferences(ctx, repository.UpsertUserPreferencesParams{
			UserID:                  user.ID,
			NotificationsEnabled:    true,
			SessionRemindersEnabled: true,
			BillRemindersEnabled:    true,
			PromoAlertsEnabled:      true,
			DailyReminderEnabled:    false,
			DailyReminderTimeWib:    pgtype.Time{Microseconds: 20 * 3_600_000_000, Valid: true},
			TrackingHistorySource:   "fresh_start",
			TrackerFocuses:          []string{"business"},
			AdvisoryFocuses:         []string{"umkm", "high"},
			PreferredCurrency:       "IDR",
			PreferredLanguage:       "Bahasa Indonesia",
		}); err != nil {
			t.Fatalf("UpsertUserPreferences: %v", err)
		}

		tool := ai.NewMatchingTool(
			txStore,
			ai.WithMatchingNowFunc(func() time.Time { return fixedNow }),
			ai.WithMatchingJakartaLocation(wib),
		)

		out, err := tool.MatchExpertsAndPackage(ctx, user.ID, ai.MatchSignals{
			UserGoalSummary: "gaji habis buat cicilan pinjol pribadi, bantu rapikan cashflow",
		})
		if err != nil {
			t.Fatalf("MatchExpertsAndPackage: %v", err)
		}

		if out.RecommendedPackage.PackageCode != "personal_basic" {
			t.Fatalf("expected personal_basic when shifting away from umkm high, got %q", out.RecommendedPackage.PackageCode)
		}
		if out.ResolvedSignals.Target != "self" {
			t.Fatalf("expected resolved Target 'self', got %q", out.ResolvedSignals.Target)
		}
		if out.ResolvedSignals.MainTopic != "debt_cashflow" {
			t.Fatalf("expected resolved MainTopic 'debt_cashflow', got %q", out.ResolvedSignals.MainTopic)
		}
		if out.ResolvedSignals.BudgetTier != "" {
			t.Fatalf("expected stale DB BudgetTier 'high' dropped, got %q", out.ResolvedSignals.BudgetTier)
		}
	})
}

func TestMatchingTool_DBFallback40Percent_WhenChatSignalsEmpty(t *testing.T) {
	txStore, tx, ctx := openMatchingTxTest(t)
	user := createTempTxUser(t, ctx, txStore, tx, "match-db-fallback")

	if _, err := txStore.UpsertUserPreferences(ctx, repository.UpsertUserPreferencesParams{
		UserID:                  user.ID,
		NotificationsEnabled:    true,
		SessionRemindersEnabled: true,
		BillRemindersEnabled:    true,
		PromoAlertsEnabled:      true,
		DailyReminderEnabled:    false,
		DailyReminderTimeWib:    pgtype.Time{Microseconds: 20 * 3_600_000_000, Valid: true},
		TrackingHistorySource:   "fresh_start",
		TrackerFocuses:          []string{},
		AdvisoryFocuses:         []string{"basic"},
		PreferredCurrency:       "IDR",
		PreferredLanguage:       "Bahasa Indonesia",
	}); err != nil {
		t.Fatalf("UpsertUserPreferences: %v", err)
	}

	answersBytes, _ := json.Marshal(map[string]any{
		"method":        "online",
		"target":        "self",
		"budget_tier":   "low",
		"main_topic":    "debt_cashflow",
		"specific_tags": []string{"pinjol"},
	})
	if _, err := txStore.CreateMatchExpertSubmission(ctx, repository.CreateMatchExpertSubmissionParams{
		UserID:             user.ID,
		AnswersJson:        answersBytes,
		TopPractitionerIds: []uuid.UUID{uuid.MustParse("00000000-0000-4000-8000-0000000000c2")},
	}); err != nil {
		t.Fatalf("CreateMatchExpertSubmission: %v", err)
	}

	wib := time.FixedZone("WIB", 7*3600)
	fixedNow := time.Date(2026, 11, 23, 8, 0, 0, 0, wib)
	tool := ai.NewMatchingTool(
		txStore,
		ai.WithMatchingNowFunc(func() time.Time { return fixedNow }),
		ai.WithMatchingJakartaLocation(wib),
	)

	out, err := tool.MatchExpertsAndPackage(ctx, user.ID, ai.MatchSignals{})
	if err != nil {
		t.Fatalf("MatchExpertsAndPackage: %v", err)
	}
	if out.RecommendedPackage.PackageCode != "personal_basic" {
		t.Fatalf("expected personal_basic from DB fallback, got %q", out.RecommendedPackage.PackageCode)
	}
	if len(out.Consultants) != 3 {
		t.Fatalf("expected 3 pinjol-pinned consultants (c2, c3, c1), got %d", len(out.Consultants))
	}
	if out.Consultants[0].ConsultantID != "c2" || out.Consultants[1].ConsultantID != "c3" || out.Consultants[2].ConsultantID != "c1" {
		t.Fatalf("unexpected pinjol ranking: [%s, %s, %s]", out.Consultants[0].ConsultantID, out.Consultants[1].ConsultantID, out.Consultants[2].ConsultantID)
	}
}

func TestMatchingTool_Step2TierEligibility_IgnoresIneligibleStaffPin(t *testing.T) {
	txStore, tx, ctx := openMatchingTxTest(t)
	user := createTempTxUser(t, ctx, txStore, tx, "match-tier")

	tagID := uuid.New()
	tagSlug := "ztest_step2_" + tagID.String()[:8]
	if _, err := tx.Exec(ctx, `
		INSERT INTO problem_tags (id, slug, label, min_tier, is_active)
		VALUES ($1, $2, '#Test Step2 Tier', 'medium', TRUE)
	`, tagID, tagSlug); err != nil {
		t.Fatalf("insert test tag: %v", err)
	}

	basicPinnedID := insertIsolatedPractitioner(t, ctx, tx, isolatedPractitionerSpec{
		name:          "BasicPinned",
		tier:          "basic",
		tagSlug:       tagSlug,
		catalogCode:   "personal_basic",
		priceIDR:      149000,
		platformCut:   20,
		rating:        4.99,
		sessions:      500,
		onlineActive:  true,
		offlineActive: true,
		slots:         []isolatedSlotSpec{{dayOfWeek: 1, startHour: "09:00:00", endHour: "10:00:00"}},
		pinTagID:      tagID,
		pinOrder:      1,
	})
	mediumPinnedID := insertIsolatedPractitioner(t, ctx, tx, isolatedPractitionerSpec{
		name:          "MediumPinned",
		tier:          "medium",
		tagSlug:       tagSlug,
		catalogCode:   "personal_medium",
		priceIDR:      299000,
		platformCut:   20,
		rating:        4.75,
		sessions:      120,
		onlineActive:  true,
		offlineActive: true,
		slots:         []isolatedSlotSpec{{dayOfWeek: 2, startHour: "10:00:00", endHour: "11:00:00"}},
		pinTagID:      tagID,
		pinOrder:      2,
	})
	insertIsolatedPractitioner(t, ctx, tx, isolatedPractitionerSpec{
		name:          "MediumUnpinned",
		tier:          "medium",
		tagSlug:       tagSlug,
		catalogCode:   "personal_medium",
		priceIDR:      299000,
		platformCut:   20,
		rating:        4.95,
		sessions:      300,
		onlineActive:  true,
		offlineActive: true,
		slots:         []isolatedSlotSpec{{dayOfWeek: 1, startHour: "10:00:00", endHour: "11:00:00"}},
	})

	wib := time.FixedZone("WIB", 7*3600)
	fixedNow := time.Date(2026, 11, 23, 8, 0, 0, 0, wib)
	tool := ai.NewMatchingTool(
		txStore,
		ai.WithMatchingNowFunc(func() time.Time { return fixedNow }),
		ai.WithMatchingJakartaLocation(wib),
	)

	out, err := tool.MatchExpertsAndPackage(ctx, user.ID, ai.MatchSignals{
		MainTopic:    "investment",
		SpecificTags: []string{tagSlug},
		BudgetTier:   "low",
	})
	if err != nil {
		t.Fatalf("MatchExpertsAndPackage: %v", err)
	}
	for _, c := range out.Consultants {
		if c.PractitionerUUID == basicPinnedID {
			t.Fatal("basic practitioner must be excluded at Step 2 for medium tag even when pinned #1")
		}
	}
	if len(out.Consultants) != 2 || out.Consultants[0].PractitionerUUID != mediumPinnedID {
		t.Fatalf("expected MediumPinned first and BasicPinned excluded, got %+v", out.Consultants)
	}
}

func TestMatchingTool_Step4Availability_ExcludesFullyBookedHeldAndSessionBlocked(t *testing.T) {
	txStore, tx, ctx := openMatchingTxTest(t)
	user := createTempTxUser(t, ctx, txStore, tx, "match-slots")

	tagID := uuid.New()
	tagSlug := "ztest_slots_" + tagID.String()[:8]
	if _, err := tx.Exec(ctx, `
		INSERT INTO problem_tags (id, slug, label, min_tier, is_active)
		VALUES ($1, $2, '#Test Slots', 'basic', TRUE)
	`, tagID, tagSlug); err != nil {
		t.Fatalf("insert test tag: %v", err)
	}

	fullyBookedID := insertIsolatedPractitioner(t, ctx, tx, isolatedPractitionerSpec{
		name:          "PracFullyBooked",
		tier:          "medium",
		tagSlug:       tagSlug,
		catalogCode:   "personal_medium",
		priceIDR:      299000,
		platformCut:   20,
		rating:        4.95,
		sessions:      400,
		isFullyBooked: true,
		onlineActive:  true,
		offlineActive: true,
		slots:         []isolatedSlotSpec{{dayOfWeek: 1, startHour: "09:00:00", endHour: "10:00:00"}},
		pinTagID:      tagID,
		pinOrder:      1,
	})
	allHeldID := insertIsolatedPractitioner(t, ctx, tx, isolatedPractitionerSpec{
		name:          "PracAllHeld",
		tier:          "medium",
		tagSlug:       tagSlug,
		catalogCode:   "personal_medium",
		priceIDR:      299000,
		platformCut:   20,
		rating:        4.92,
		sessions:      350,
		onlineActive:  true,
		offlineActive: true,
		slots: []isolatedSlotSpec{
			{dayOfWeek: 1, startHour: "10:00:00", endHour: "11:00:00"},
			{dayOfWeek: 3, startHour: "13:00:00", endHour: "14:00:00"},
		},
		pinTagID: tagID,
		pinOrder: 2,
	})
	partialID := insertIsolatedPractitioner(t, ctx, tx, isolatedPractitionerSpec{
		name:          "PracPartialBlocked",
		tier:          "medium",
		tagSlug:       tagSlug,
		catalogCode:   "personal_medium",
		priceIDR:      299000,
		platformCut:   20,
		rating:        4.85,
		sessions:      200,
		onlineActive:  true,
		offlineActive: true,
		slots: []isolatedSlotSpec{
			{dayOfWeek: 1, startHour: "20:00:00", endHour: "21:00:00"},
			{dayOfWeek: 2, startHour: "19:00:00", endHour: "20:00:00"},
		},
		pinTagID: tagID,
		pinOrder: 3,
	})

	wib := time.FixedZone("WIB", 7*3600)
	fixedNow := time.Date(2026, 11, 23, 8, 0, 0, 0, wib) // Monday

	// Hold ALL 14-day slots of PracAllHeld.
	heldAvail, err := txStore.ListActiveAvailabilityByPractitioners(ctx, []uuid.UUID{allHeldID})
	if err != nil {
		t.Fatalf("ListActiveAvailabilityByPractitioners(allHeld): %v", err)
	}
	for dayOffset := 0; dayOffset < 14; dayOffset++ {
		d := fixedNow.AddDate(0, 0, dayOffset)
		for _, av := range heldAvail {
			if int(av.DayOfWeek) != int(d.Weekday()) {
				continue
			}
			sh := int(av.StartTimeWib.Microseconds / 3_600_000_000)
			sm := int((av.StartTimeWib.Microseconds % 3_600_000_000) / 60_000_000)
			eh := int(av.EndTimeWib.Microseconds / 3_600_000_000)
			em := int((av.EndTimeWib.Microseconds % 3_600_000_000) / 60_000_000)

			slotStart := time.Date(d.Year(), d.Month(), d.Day(), sh, sm, 0, 0, wib)
			slotEnd := time.Date(d.Year(), d.Month(), d.Day(), eh, em, 0, 0, wib)
			if slotStart.Before(fixedNow) {
				continue
			}
			if _, err := tx.Exec(ctx, `
				INSERT INTO booking_slot_holds (practitioner_id, slot_start_at, slot_end_at, status, expires_at)
				VALUES ($1, $2, $3, 'held', $4)
			`, allHeldID, slotStart, slotEnd, fixedNow.Add(15*time.Minute)); err != nil {
				t.Fatalf("insert hold for PracAllHeld (%s): %v", slotStart, err)
			}
		}
	}

	// Block PracPartialBlocked's earliest slot (Mon 20:00 WIB) with a 'scheduled' session,
	// while inserting a 'cancelled' session and expired 'held' hold on Tue 19:00 WIB (neither must block).
	monStart := time.Date(2026, 11, 23, 20, 0, 0, 0, wib)
	monEnd := monStart.Add(time.Hour)
	tueStart := time.Date(2026, 11, 24, 19, 0, 0, 0, wib)
	tueEnd := tueStart.Add(time.Hour)

	if _, err := tx.Exec(ctx, `
		INSERT INTO sessions (
			client_user_id, practitioner_id, service_category, tier, package_title,
			delivery_mode, scheduled_start_at, scheduled_end_at, subtotal_price_idr,
			platform_fee_idr, discount_amount_idr, price_paid, platform_cut_pct, status
		) VALUES (
			$1, $2, 'individual', 'medium', 'Optimalisasi Aset & Proteksi',
			'online', $3, $4, 299000, 15000, 0, 314000, 20, 'scheduled'
		)
	`, user.ID, partialID, monStart, monEnd); err != nil {
		t.Fatalf("insert scheduled blocking session: %v", err)
	}
	if _, err := tx.Exec(ctx, `
		INSERT INTO sessions (
			client_user_id, practitioner_id, service_category, tier, package_title,
			delivery_mode, scheduled_start_at, scheduled_end_at, subtotal_price_idr,
			platform_fee_idr, discount_amount_idr, price_paid, platform_cut_pct, status
		) VALUES (
			$1, $2, 'individual', 'medium', 'Optimalisasi Aset & Proteksi',
			'online', $3, $4, 299000, 15000, 0, 314000, 20, 'cancelled'
		)
	`, user.ID, partialID, tueStart, tueEnd); err != nil {
		t.Fatalf("insert cancelled session: %v", err)
	}
	if _, err := tx.Exec(ctx, `
		INSERT INTO booking_slot_holds (practitioner_id, slot_start_at, slot_end_at, status, expires_at)
		VALUES ($1, $2, $3, 'held', $4)
	`, partialID, tueStart, tueEnd, fixedNow.Add(-1*time.Minute)); err != nil {
		t.Fatalf("insert expired hold: %v", err)
	}

	tool := ai.NewMatchingTool(
		txStore,
		ai.WithMatchingNowFunc(func() time.Time { return fixedNow }),
		ai.WithMatchingJakartaLocation(wib),
	)

	out, err := tool.MatchExpertsAndPackage(ctx, user.ID, ai.MatchSignals{
		SpecificTags: []string{tagSlug},
	})
	if err != nil {
		t.Fatalf("MatchExpertsAndPackage: %v", err)
	}
	for _, c := range out.Consultants {
		if c.PractitionerUUID == fullyBookedID {
			t.Fatal("fully booked practitioner must be excluded even if staff-pinned")
		}
		if c.PractitionerUUID == allHeldID {
			t.Fatal("practitioner with all 14-day slots held must be excluded even if staff-pinned")
		}
	}
	if len(out.Consultants) != 1 || out.Consultants[0].PractitionerUUID != partialID {
		t.Fatalf("expected only PracPartialBlocked, got %+v", out.Consultants)
	}
	gotSlot, parseErr := time.Parse(time.RFC3339, out.Consultants[0].NextAvailableSlotISO)
	if parseErr != nil {
		t.Fatalf("parse partial slot: %v", parseErr)
	}
	if !gotSlot.Equal(tueStart) {
		t.Fatalf("expected next slot to skip blocked Mon 20:00 and pick Tue 19:00 (%s), got %s", tueStart, gotSlot)
	}
}

func TestMatchingTool_Step5And6_TieBreakerNeverUsesPlatformCutOrCheapestFee(t *testing.T) {
	txStore, tx, ctx := openMatchingTxTest(t)
	user := createTempTxUser(t, ctx, txStore, tx, "match-tiebreak")

	wib := time.FixedZone("WIB", 7*3600)
	fixedNow := time.Date(2026, 11, 23, 8, 0, 0, 0, wib)

	tagID := uuid.New()
	tagSlug := "ztest_tiebreak_" + tagID.String()[:8]
	if _, err := tx.Exec(ctx, `
		INSERT INTO problem_tags (id, slug, label, min_tier, is_active)
		VALUES ($1, $2, '#Test Tiebreak', 'basic', TRUE)
	`, tagID, tagSlug); err != nil {
		t.Fatalf("insert test tag: %v", err)
	}

	type spec struct {
		name        string
		price       int64
		platformCut int32
		rating      float32
		sessions    int32
		dayOfWeek   int32
		startHour   string
		endHour     string
		pinOrder    int32
	}

	specs := []spec{
		{name: "CheapHighCutSlow", price: 100000, platformCut: 35, rating: 4.99, sessions: 999, dayOfWeek: 5, startHour: "09:00:00", endHour: "10:00:00"},
		{name: "EarliestDay1", price: 500000, platformCut: 10, rating: 4.50, sessions: 20, dayOfWeek: 1, startHour: "10:00:00", endHour: "11:00:00"},
		{name: "Day2LowerSessions", price: 350000, platformCut: 15, rating: 4.90, sessions: 100, dayOfWeek: 2, startHour: "10:00:00", endHour: "11:00:00"},
		{name: "Day2MoreSessions", price: 450000, platformCut: 12, rating: 4.90, sessions: 400, dayOfWeek: 2, startHour: "10:00:00", endHour: "11:00:00"},
		{name: "PinnedSlow", price: 600000, platformCut: 10, rating: 4.40, sessions: 10, dayOfWeek: 6, startHour: "15:00:00", endHour: "16:00:00", pinOrder: 1},
	}

	for _, sp := range specs {
		insertIsolatedPractitioner(t, ctx, tx, isolatedPractitionerSpec{
			name:          sp.name,
			tier:          "medium",
			tagSlug:       tagSlug,
			catalogCode:   "personal_basic",
			priceIDR:      sp.price,
			platformCut:   sp.platformCut,
			rating:        sp.rating,
			sessions:      sp.sessions,
			onlineActive:  true,
			offlineActive: true,
			slots:         []isolatedSlotSpec{{dayOfWeek: sp.dayOfWeek, startHour: sp.startHour, endHour: sp.endHour}},
			pinTagID:      tagID,
			pinOrder:      sp.pinOrder,
		})
	}

	tool := ai.NewMatchingTool(
		txStore,
		ai.WithMatchingNowFunc(func() time.Time { return fixedNow }),
		ai.WithMatchingJakartaLocation(wib),
	)

	// 1. With staff pin on PinnedSlow: rank 1 = PinnedSlow, rank 2 = EarliestDay1, rank 3 = Day2MoreSessions.
	outPinned, err := tool.MatchExpertsAndPackage(ctx, user.ID, ai.MatchSignals{
		SpecificTags: []string{tagSlug},
	})
	if err != nil {
		t.Fatalf("MatchExpertsAndPackage(pinned): %v", err)
	}
	if len(outPinned.Consultants) != 3 {
		t.Fatalf("expected 3 consultants, got %d", len(outPinned.Consultants))
	}
	gotNames := []string{
		outPinned.Consultants[0].DisplayName,
		outPinned.Consultants[1].DisplayName,
		outPinned.Consultants[2].DisplayName,
	}
	wantPinned := []string{"PinnedSlow", "EarliestDay1", "Day2MoreSessions"}
	for i := range wantPinned {
		if gotNames[i] != wantPinned[i] {
			t.Fatalf("pinned rank[%d] = %q, want %q (all=%v)", i, gotNames[i], wantPinned[i], gotNames)
		}
	}

	// 2. Remove pin -> pure Step 6 tie-breaker: EarliestDay1 -> Day2MoreSessions -> Day2LowerSessions.
	if _, err := tx.Exec(ctx, `DELETE FROM staff_practitioner_pins WHERE problem_tag_id = $1`, tagID); err != nil {
		t.Fatalf("remove test pin: %v", err)
	}
	outUnpinned, err := tool.MatchExpertsAndPackage(ctx, user.ID, ai.MatchSignals{
		SpecificTags: []string{tagSlug},
	})
	if err != nil {
		t.Fatalf("MatchExpertsAndPackage(unpinned): %v", err)
	}
	if len(outUnpinned.Consultants) != 3 {
		t.Fatalf("expected 3 unpinned consultants, got %d", len(outUnpinned.Consultants))
	}
	gotUnpinned := []string{
		outUnpinned.Consultants[0].DisplayName,
		outUnpinned.Consultants[1].DisplayName,
		outUnpinned.Consultants[2].DisplayName,
	}
	wantUnpinned := []string{"EarliestDay1", "Day2MoreSessions", "Day2LowerSessions"}
	for i := range wantUnpinned {
		if gotUnpinned[i] != wantUnpinned[i] {
			t.Fatalf("unpinned rank[%d] = %q, want %q (all=%v)", i, gotUnpinned[i], wantUnpinned[i], gotUnpinned)
		}
	}
}

func TestMatchingTool_Step6_SortsStrictlyByRealEarliestSlot_EvenWithSessionTimePreference(t *testing.T) {
	txStore, tx, ctx := openMatchingTxTest(t)
	user := createTempTxUser(t, ctx, txStore, tx, "match-slot-sort")

	wib := time.FixedZone("WIB", 7*3600)
	fixedNow := time.Date(2026, 11, 23, 8, 0, 0, 0, wib) // Monday

	tagID := uuid.New()
	tagSlug := "ztest_slotsort_" + tagID.String()[:8]
	if _, err := tx.Exec(ctx, `
		INSERT INTO problem_tags (id, slug, label, min_tier, is_active)
		VALUES ($1, $2, '#Test Slot Sort', 'basic', TRUE)
	`, tagID, tagSlug); err != nil {
		t.Fatalf("insert test tag: %v", err)
	}

	// Practitioner A: earliest real slot Mon 09:00 WIB (morning only, does NOT match night preference).
	insertIsolatedPractitioner(t, ctx, tx, isolatedPractitionerSpec{
		name:          "EarliestMorningA",
		tier:          "medium",
		tagSlug:       tagSlug,
		catalogCode:   "personal_basic",
		priceIDR:      149000,
		platformCut:   20,
		rating:        4.50,
		sessions:      20,
		onlineActive:  true,
		offlineActive: true,
		slots: []isolatedSlotSpec{
			{dayOfWeek: 1, startHour: "09:00:00", endHour: "10:00:00"},
		},
	})
	// Practitioner B: highest rating/sessions and has night slot Tue 20:00, earliest real slot is Tue 14:00.
	insertIsolatedPractitioner(t, ctx, tx, isolatedPractitionerSpec{
		name:          "LaterNightPreferredB",
		tier:          "medium",
		tagSlug:       tagSlug,
		catalogCode:   "personal_basic",
		priceIDR:      149000,
		platformCut:   20,
		rating:        4.95,
		sessions:      500,
		onlineActive:  true,
		offlineActive: true,
		slots: []isolatedSlotSpec{
			{dayOfWeek: 2, startHour: "14:00:00", endHour: "15:00:00"},
			{dayOfWeek: 2, startHour: "20:00:00", endHour: "21:00:00"},
		},
	})
	// Practitioner C: has Mon 10:00 morning slot AND Wed 19:00 night slot.
	insertIsolatedPractitioner(t, ctx, tx, isolatedPractitionerSpec{
		name:          "MixedMorningAndNightC",
		tier:          "medium",
		tagSlug:       tagSlug,
		catalogCode:   "personal_basic",
		priceIDR:      149000,
		platformCut:   20,
		rating:        4.80,
		sessions:      100,
		onlineActive:  true,
		offlineActive: true,
		slots: []isolatedSlotSpec{
			{dayOfWeek: 1, startHour: "10:00:00", endHour: "11:00:00"},
			{dayOfWeek: 3, startHour: "19:00:00", endHour: "20:00:00"},
		},
	})

	tool := ai.NewMatchingTool(
		txStore,
		ai.WithMatchingNowFunc(func() time.Time { return fixedNow }),
		ai.WithMatchingJakartaLocation(wib),
	)

	out, err := tool.MatchExpertsAndPackage(ctx, user.ID, ai.MatchSignals{
		SpecificTags: []string{tagSlug},
		SessionTime:  []string{"night"},
	})
	if err != nil {
		t.Fatalf("MatchExpertsAndPackage: %v", err)
	}
	if len(out.Consultants) != 3 {
		t.Fatalf("expected 3 consultants, got %d", len(out.Consultants))
	}

	wantOrder := []string{"EarliestMorningA", "MixedMorningAndNightC", "LaterNightPreferredB"}
	wantEarliest := []time.Time{
		time.Date(2026, 11, 23, 9, 0, 0, 0, wib),
		time.Date(2026, 11, 23, 10, 0, 0, 0, wib),
		time.Date(2026, 11, 24, 14, 0, 0, 0, wib),
	}
	wantPreferred := []string{
		"",
		time.Date(2026, 11, 25, 19, 0, 0, 0, wib).Format(time.RFC3339),
		time.Date(2026, 11, 24, 20, 0, 0, 0, wib).Format(time.RFC3339),
	}
	for i := range wantOrder {
		got := out.Consultants[i]
		if got.DisplayName != wantOrder[i] {
			t.Fatalf("rank[%d] = %q, want %q (all=%+v)", i, got.DisplayName, wantOrder[i], out.Consultants)
		}
		gotISO, parseErr := time.Parse(time.RFC3339, got.NextAvailableSlotISO)
		if parseErr != nil {
			t.Fatalf("parse NextAvailableSlotISO for %s: %v", got.DisplayName, parseErr)
		}
		if !gotISO.Equal(wantEarliest[i]) {
			t.Fatalf("%s NextAvailableSlotISO = %s, want real slots[0] %s", got.DisplayName, gotISO, wantEarliest[i])
		}
		if wantPreferred[i] == "" {
			if got.PreferredSlotISO != "" || got.PreferredSlotLabel != "" {
				t.Fatalf("%s expected empty PreferredSlot when no night slot exists, got (%q, %q)", got.DisplayName, got.PreferredSlotISO, got.PreferredSlotLabel)
			}
		} else {
			gotPrefISO, prefErr := time.Parse(time.RFC3339, got.PreferredSlotISO)
			if prefErr != nil {
				t.Fatalf("parse PreferredSlotISO for %s: %v", got.DisplayName, prefErr)
			}
			wantPrefTime, _ := time.Parse(time.RFC3339, wantPreferred[i])
			if !gotPrefISO.Equal(wantPrefTime) || got.PreferredSlotLabel == "" {
				t.Fatalf("%s PreferredSlot = (%s, %q), want %s", got.DisplayName, gotPrefISO, got.PreferredSlotLabel, wantPrefTime)
			}
		}
	}
}

func TestMatchingTool_Step3ChannelFilter_OnlineVsOffline(t *testing.T) {
	txStore, tx, ctx := openMatchingTxTest(t)
	user := createTempTxUser(t, ctx, txStore, tx, "match-channel")

	tagID := uuid.New()
	tagSlug := "ztest_chan_" + tagID.String()[:8]
	if _, err := tx.Exec(ctx, `
		INSERT INTO problem_tags (id, slug, label, min_tier, is_active)
		VALUES ($1, $2, '#Test Channel', 'medium', TRUE)
	`, tagID, tagSlug); err != nil {
		t.Fatalf("insert test tag: %v", err)
	}

	onlineOnlyID := insertIsolatedPractitioner(t, ctx, tx, isolatedPractitionerSpec{
		name:          "CoupleOnlineOnly",
		tier:          "medium",
		tagSlug:       tagSlug,
		catalogCode:   "couple_pre_marriage",
		priceIDR:      349000,
		platformCut:   20,
		rating:        4.95,
		sessions:      300,
		onlineActive:  true,
		offlineActive: false,
		slots:         []isolatedSlotSpec{{dayOfWeek: 1, startHour: "09:00:00", endHour: "10:00:00"}},
		pinTagID:      tagID,
		pinOrder:      1,
	})
	bothChannelsID := insertIsolatedPractitioner(t, ctx, tx, isolatedPractitionerSpec{
		name:          "CoupleBothChannels",
		tier:          "premium",
		tagSlug:       tagSlug,
		catalogCode:   "couple_pre_marriage",
		priceIDR:      349000,
		platformCut:   20,
		rating:        4.90,
		sessions:      250,
		onlineActive:  true,
		offlineActive: true,
		slots:         []isolatedSlotSpec{{dayOfWeek: 2, startHour: "19:00:00", endHour: "20:00:00"}},
		pinTagID:      tagID,
		pinOrder:      2,
	})

	wib := time.FixedZone("WIB", 7*3600)
	fixedNow := time.Date(2026, 11, 23, 8, 0, 0, 0, wib)
	tool := ai.NewMatchingTool(
		txStore,
		ai.WithMatchingNowFunc(func() time.Time { return fixedNow }),
		ai.WithMatchingJakartaLocation(wib),
	)

	outOffline, err := tool.MatchExpertsAndPackage(ctx, user.ID, ai.MatchSignals{
		Method:       "offline",
		Target:       "couple",
		MainTopic:    "house_wedding",
		SpecificTags: []string{tagSlug},
	})
	if err != nil {
		t.Fatalf("MatchExpertsAndPackage(offline couple): %v", err)
	}
	if len(outOffline.Consultants) != 1 || outOffline.Consultants[0].PractitionerUUID != bothChannelsID {
		t.Fatalf("expected only CoupleBothChannels for offline, got %+v", outOffline.Consultants)
	}

	outOnline, err := tool.MatchExpertsAndPackage(ctx, user.ID, ai.MatchSignals{
		Method:       "online",
		Target:       "couple",
		MainTopic:    "house_wedding",
		SpecificTags: []string{tagSlug},
	})
	if err != nil {
		t.Fatalf("MatchExpertsAndPackage(online couple): %v", err)
	}
	if len(outOnline.Consultants) != 2 ||
		outOnline.Consultants[0].PractitionerUUID != onlineOnlyID ||
		outOnline.Consultants[1].PractitionerUUID != bothChannelsID {
		t.Fatalf("expected [CoupleOnlineOnly, CoupleBothChannels] for online, got %+v", outOnline.Consultants)
	}
}
