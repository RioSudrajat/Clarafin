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
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/clarafin/api/internal/ai"
	"github.com/clarafin/api/internal/repository"
)

func TestPractitionerCodeHelpers_RoundTrip(t *testing.T) {
	wib := time.FixedZone("WIB", 7*3600)
	_ = wib

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
	store, ctx := openAITestStore(t)
	user := createTempAIUser(t, ctx, store, "match-override")

	if _, err := store.UpsertUserPreferences(ctx, repository.UpsertUserPreferencesParams{
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
	if _, err := store.CreateMatchExpertSubmission(ctx, repository.CreateMatchExpertSubmissionParams{
		UserID:             user.ID,
		AnswersJson:        answersBytes,
		TopPractitionerIds: []uuid.UUID{uuid.MustParse("00000000-0000-4000-8000-0000000000c3")},
	}); err != nil {
		t.Fatalf("CreateMatchExpertSubmission: %v", err)
	}

	wib := time.FixedZone("WIB", 7*3600)
	// Monday 2026-11-23 08:00 WIB
	fixedNow := time.Date(2026, 11, 23, 8, 0, 0, 0, wib)
	tool := ai.NewMatchingTool(
		store,
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

func TestMatchingTool_DBFallback40Percent_WhenChatSignalsEmpty(t *testing.T) {
	store, ctx := openAITestStore(t)
	user := createTempAIUser(t, ctx, store, "match-db-fallback")

	if _, err := store.UpsertUserPreferences(ctx, repository.UpsertUserPreferencesParams{
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
	if _, err := store.CreateMatchExpertSubmission(ctx, repository.CreateMatchExpertSubmissionParams{
		UserID:             user.ID,
		AnswersJson:        answersBytes,
		TopPractitionerIds: []uuid.UUID{uuid.MustParse("00000000-0000-4000-8000-0000000000c2")},
	}); err != nil {
		t.Fatalf("CreateMatchExpertSubmission: %v", err)
	}

	wib := time.FixedZone("WIB", 7*3600)
	fixedNow := time.Date(2026, 11, 23, 8, 0, 0, 0, wib)
	tool := ai.NewMatchingTool(
		store,
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
	store, ctx := openAITestStore(t)
	user := createTempAIUser(t, ctx, store, "match-tier")

	c3ID := uuid.MustParse("00000000-0000-4000-8000-0000000000c3")
	c4ID := uuid.MustParse("00000000-0000-4000-8000-0000000000c4")
	sahamTagID := uuid.MustParse("30000000-0000-4000-8000-000000000007")

	// Temporarily replace priority 1 pin on 'saham' (min_tier = medium) with basic practitioner c3.
	if _, err := store.Pool.Exec(ctx, `
		UPDATE staff_practitioner_pins
		SET practitioner_id = $1
		WHERE problem_tag_id = $2 AND priority_order = 1
	`, c3ID, sahamTagID); err != nil {
		t.Fatalf("override saham pin: %v", err)
	}
	t.Cleanup(func() {
		cleanupCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_, _ = store.Pool.Exec(cleanupCtx, `
			UPDATE staff_practitioner_pins
			SET practitioner_id = $1
			WHERE problem_tag_id = $2 AND priority_order = 1
		`, c4ID, sahamTagID)
	})

	wib := time.FixedZone("WIB", 7*3600)
	fixedNow := time.Date(2026, 11, 23, 8, 0, 0, 0, wib)
	tool := ai.NewMatchingTool(
		store,
		ai.WithMatchingNowFunc(func() time.Time { return fixedNow }),
		ai.WithMatchingJakartaLocation(wib),
	)

	out, err := tool.MatchExpertsAndPackage(ctx, user.ID, ai.MatchSignals{
		MainTopic:    "investment",
		SpecificTags: []string{"saham"},
		BudgetTier:   "low",
	})
	if err != nil {
		t.Fatalf("MatchExpertsAndPackage: %v", err)
	}
	for _, c := range out.Consultants {
		if c.ConsultantID == "c3" {
			t.Fatal("basic practitioner c3 must be excluded at Step 2 for medium tag 'saham' even when pinned")
		}
	}
	if len(out.Consultants) == 0 || out.Consultants[0].ConsultantID != "c1" {
		t.Fatalf("expected eligible pinned c1 to rank first when c3 failed Step 2, got %+v", out.Consultants)
	}
}

func TestMatchingTool_Step4Availability_ExcludesFullyBookedHeldAndSessionBlocked(t *testing.T) {
	store, ctx := openAITestStore(t)
	user := createTempAIUser(t, ctx, store, "match-slots")

	c1ID := uuid.MustParse("00000000-0000-4000-8000-0000000000c1")
	c2ID := uuid.MustParse("00000000-0000-4000-8000-0000000000c2")
	c5ID := uuid.MustParse("00000000-0000-4000-8000-0000000000c5")

	wib := time.FixedZone("WIB", 7*3600)
	fixedNow := time.Date(2026, 11, 23, 8, 0, 0, 0, wib) // Monday
	tool := ai.NewMatchingTool(
		store,
		ai.WithMatchingNowFunc(func() time.Time { return fixedNow }),
		ai.WithMatchingJakartaLocation(wib),
	)

	// Subtest A: is_fully_booked = true excludes c2 even though pinned #1 on pinjol.
	if _, err := store.Pool.Exec(ctx, `UPDATE practitioner_profiles SET is_fully_booked = TRUE WHERE user_id = $1`, c2ID); err != nil {
		t.Fatalf("mark c2 fully booked: %v", err)
	}
	t.Cleanup(func() {
		cleanupCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_, _ = store.Pool.Exec(cleanupCtx, `UPDATE practitioner_profiles SET is_fully_booked = FALSE WHERE user_id = $1`, c2ID)
	})

	outPinjol, err := tool.MatchExpertsAndPackage(ctx, user.ID, ai.MatchSignals{
		MainTopic:    "debt_cashflow",
		SpecificTags: []string{"pinjol"},
	})
	if err != nil {
		t.Fatalf("MatchExpertsAndPackage(pinjol): %v", err)
	}
	for _, c := range outPinjol.Consultants {
		if c.ConsultantID == "c2" {
			t.Fatal("c2 with is_fully_booked=true must be excluded even if staff-pinned")
		}
	}
	if len(outPinjol.Consultants) != 2 || outPinjol.Consultants[0].ConsultantID != "c3" || outPinjol.Consultants[1].ConsultantID != "c1" {
		t.Fatalf("expected [c3, c1] after excluding fully booked c2, got %+v", outPinjol.Consultants)
	}

	// Subtest B: holding ALL 14-day slots of c1 excludes c1 even when pinned #1 on budget_nikah.
	c1Avail, err := store.ListActiveAvailabilityByPractitioners(ctx, []uuid.UUID{c1ID})
	if err != nil {
		t.Fatalf("ListActiveAvailabilityByPractitioners(c1): %v", err)
	}
	var insertedHoldIDs []uuid.UUID
	for dayOffset := 0; dayOffset < 14; dayOffset++ {
		d := fixedNow.AddDate(0, 0, dayOffset)
		for _, av := range c1Avail {
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
			var holdID uuid.UUID
			if err := store.Pool.QueryRow(ctx, `
				INSERT INTO booking_slot_holds (practitioner_id, slot_start_at, slot_end_at, status, expires_at)
				VALUES ($1, $2, $3, 'held', $4)
				RETURNING id
			`, c1ID, slotStart, slotEnd, fixedNow.Add(15*time.Minute)).Scan(&holdID); err != nil {
				t.Fatalf("insert hold for c1 (%s): %v", slotStart, err)
			}
			insertedHoldIDs = append(insertedHoldIDs, holdID)
		}
	}
	t.Cleanup(func() {
		cleanupCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		for _, id := range insertedHoldIDs {
			_, _ = store.Pool.Exec(cleanupCtx, `DELETE FROM booking_slot_holds WHERE id = $1`, id)
		}
	})

	// Subtest C: block c5's earliest slot (Monday 2026-11-23 20:00 WIB) via an active 'scheduled' session,
	// insert a 'cancelled' session on Tuesday 2026-11-24 19:00 WIB (must NOT block Tuesday),
	// and insert an expired 'held' hold on Tuesday 2026-11-24 19:00 WIB (must NOT block Tuesday).
	c5MonStart := time.Date(2026, 11, 23, 20, 0, 0, 0, wib)
	c5MonEnd := c5MonStart.Add(time.Hour)
	c5TueStart := time.Date(2026, 11, 24, 19, 0, 0, 0, wib)
	c5TueEnd := c5TueStart.Add(time.Hour)

	var schedSessionID, cancelSessionID, expiredHoldID uuid.UUID
	if err := store.Pool.QueryRow(ctx, `
		INSERT INTO sessions (
			client_user_id, practitioner_id, service_category, tier, package_title,
			delivery_mode, scheduled_start_at, scheduled_end_at, subtotal_price_idr,
			platform_fee_idr, discount_amount_idr, price_paid, platform_cut_pct, status
		) VALUES (
			$1, $2, 'couple', 'pre_marriage', 'Siap Menikah Tanpa Drama Finansial',
			'online', $3, $4, 349000, 15000, 0, 364000, 20, 'scheduled'
		) RETURNING id
	`, user.ID, c5ID, c5MonStart, c5MonEnd).Scan(&schedSessionID); err != nil {
		t.Fatalf("insert scheduled blocking session: %v", err)
	}
	if err := store.Pool.QueryRow(ctx, `
		INSERT INTO sessions (
			client_user_id, practitioner_id, service_category, tier, package_title,
			delivery_mode, scheduled_start_at, scheduled_end_at, subtotal_price_idr,
			platform_fee_idr, discount_amount_idr, price_paid, platform_cut_pct, status
		) VALUES (
			$1, $2, 'couple', 'pre_marriage', 'Siap Menikah Tanpa Drama Finansial',
			'online', $3, $4, 349000, 15000, 0, 364000, 20, 'cancelled'
		) RETURNING id
	`, user.ID, c5ID, c5TueStart, c5TueEnd).Scan(&cancelSessionID); err != nil {
		t.Fatalf("insert cancelled session: %v", err)
	}
	if err := store.Pool.QueryRow(ctx, `
		INSERT INTO booking_slot_holds (practitioner_id, slot_start_at, slot_end_at, status, expires_at)
		VALUES ($1, $2, $3, 'held', $4)
		RETURNING id
	`, c5ID, c5TueStart, c5TueEnd, fixedNow.Add(-1*time.Minute)).Scan(&expiredHoldID); err != nil {
		t.Fatalf("insert expired hold: %v", err)
	}
	t.Cleanup(func() {
		cleanupCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_, _ = store.Pool.Exec(cleanupCtx, `DELETE FROM booking_slot_holds WHERE id = $1`, expiredHoldID)
		_, _ = store.Pool.Exec(cleanupCtx, `DELETE FROM sessions WHERE id IN ($1, $2)`, schedSessionID, cancelSessionID)
	})

	outCouple, err := tool.MatchExpertsAndPackage(ctx, user.ID, ai.MatchSignals{
		Target:    "couple",
		MainTopic: "house_wedding",
	})
	if err != nil {
		t.Fatalf("MatchExpertsAndPackage(couple held/session): %v", err)
	}
	if len(outCouple.Consultants) != 1 || outCouple.Consultants[0].ConsultantID != "c5" {
		t.Fatalf("expected only c5 when all of c1 slots are held, got %+v", outCouple.Consultants)
	}
	gotSlot, parseErr := time.Parse(time.RFC3339, outCouple.Consultants[0].NextAvailableSlotISO)
	if parseErr != nil {
		t.Fatalf("parse c5 slot: %v", parseErr)
	}
	if !gotSlot.Equal(c5TueStart) {
		t.Fatalf("expected c5 next slot to skip blocked Mon 20:00 and pick Tue 19:00 (%s), got %s", c5TueStart, gotSlot)
	}
}

func TestMatchingTool_Step5And6_TieBreakerNeverUsesPlatformCutOrCheapestFee(t *testing.T) {
	store, ctx := openAITestStore(t)
	user := createTempAIUser(t, ctx, store, "match-tiebreak")

	wib := time.FixedZone("WIB", 7*3600)
	// Fixed Monday 2026-11-23 08:00 WIB
	fixedNow := time.Date(2026, 11, 23, 8, 0, 0, 0, wib)

	// Create 4 isolated verified practitioners + 1 custom tag with 1 staff pin to verify
	// Step 5 (pinned first) and Step 6 (earliest_slot ASC -> rating_avg DESC -> sessions DESC),
	// explicitly setting inverse platform_cut_pct and online_price_idr to prove they are NEVER used for sorting.
	tagID := uuid.New()
	tagSlug := "ztest_tiebreak_" + tagID.String()[:8]
	if _, err := store.Pool.Exec(ctx, `
		INSERT INTO problem_tags (id, slug, label, min_tier, is_active)
		VALUES ($1, $2, '#Test Tiebreak', 'basic', TRUE)
	`, tagID, tagSlug); err != nil {
		t.Fatalf("insert test tag: %v", err)
	}
	t.Cleanup(func() {
		cleanupCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_, _ = store.Pool.Exec(cleanupCtx, `DELETE FROM problem_tags WHERE id = $1`, tagID)
	})

	type spec struct {
		name        string
		price       int64
		platformCut int32
		rating      float32
		sessions    int32
		dayOfWeek   int32 // 1=Mon, 2=Tue, 3=Wed, 5=Fri
		startHour   string
		endHour     string
		pinned      bool
		id          uuid.UUID
	}

	specs := []spec{
		{name: "CheapHighCutSlow", price: 100000, platformCut: 35, rating: 4.99, sessions: 999, dayOfWeek: 5, startHour: "09:00:00", endHour: "10:00:00"},
		{name: "EarliestDay1", price: 500000, platformCut: 10, rating: 4.50, sessions: 20, dayOfWeek: 1, startHour: "10:00:00", endHour: "11:00:00"},
		{name: "Day2LowerSessions", price: 350000, platformCut: 15, rating: 4.90, sessions: 100, dayOfWeek: 2, startHour: "10:00:00", endHour: "11:00:00"},
		{name: "Day2MoreSessions", price: 450000, platformCut: 12, rating: 4.90, sessions: 400, dayOfWeek: 2, startHour: "10:00:00", endHour: "11:00:00"},
		{name: "PinnedSlow", price: 600000, platformCut: 10, rating: 4.40, sessions: 10, dayOfWeek: 6, startHour: "15:00:00", endHour: "16:00:00", pinned: true},
	}

	var catalogIndividualBasicID uuid.UUID
	if err := store.Pool.QueryRow(ctx, `SELECT id FROM catalog_packages WHERE code = 'personal_basic'`).Scan(&catalogIndividualBasicID); err != nil {
		t.Fatalf("lookup personal_basic id: %v", err)
	}

	for idx := range specs {
		id := uuid.New()
		specs[idx].id = id
		email := fmt.Sprintf("tiebreak-%d-%s@clarafin.test", idx, id.String()[:8])
		if _, err := store.Pool.Exec(ctx, `INSERT INTO auth.users (id, email) VALUES ($1, $2)`, id, email); err != nil {
			t.Fatalf("insert auth.users %s: %v", specs[idx].name, err)
		}
		pid := id
		t.Cleanup(func() {
			cleanupCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
			defer cancel()
			_, _ = store.Pool.Exec(cleanupCtx, `DELETE FROM auth.users WHERE id = $1`, pid)
		})
		if _, err := store.Pool.Exec(ctx, `INSERT INTO users (id, email, full_name, onboarding_completed) VALUES ($1, $2, $3, TRUE)`, id, email, specs[idx].name); err != nil {
			t.Fatalf("insert users %s: %v", specs[idx].name, err)
		}
		if _, err := store.Pool.Exec(ctx, `
			INSERT INTO practitioner_profiles (
				user_id, display_name, title_headline, bio, city, practitioner_tier,
				clients_handled_count, certifications, certificate_file_urls, ktp_file_url,
				specializations, languages, supported_methods, gender, birth_year, consulting_style,
				years_of_experience, is_fully_booked, status, platform_cut_pct, rating_avg, review_count,
				total_sessions_completed, verified_at
			) VALUES (
				$1, $2, 'Planner', 'Bio', 'Jakarta', 'medium',
				100, ARRAY['CFP®'], ARRAY['cert.pdf'], 'ktp.pdf',
				ARRAY[$3], ARRAY['Indonesia'], ARRAY['online'], 'Perempuan', 1990, 'Hangat dan suportif',
				3, FALSE, 'verified', $4, $5, 50, $6, NOW()
			)
		`, id, specs[idx].name, tagSlug, specs[idx].platformCut, specs[idx].rating, specs[idx].sessions); err != nil {
			t.Fatalf("insert practitioner_profiles %s: %v", specs[idx].name, err)
		}
		if _, err := store.Pool.Exec(ctx, `
			INSERT INTO practitioner_packages (
				practitioner_id, catalog_package_id, service_category, category_tag, tier,
				package_title, duration_minutes, online_price_idr, offline_price_idr,
				is_online_active, is_offline_active, is_active
			) VALUES (
				$1, $2, 'individual', 'Personal Advisory • Basic', 'basic',
				'Fondasi Arus Kas & Utang', 60, $3, $4, TRUE, TRUE, TRUE
			)
		`, id, catalogIndividualBasicID, specs[idx].price, specs[idx].price+150000); err != nil {
			t.Fatalf("insert practitioner_packages %s: %v", specs[idx].name, err)
		}
		if _, err := store.Pool.Exec(ctx, `
			INSERT INTO practitioner_availability (practitioner_id, day_of_week, start_time_wib, end_time_wib, is_active)
			VALUES ($1, $2, $3::time, $4::time, TRUE)
		`, id, specs[idx].dayOfWeek, specs[idx].startHour, specs[idx].endHour); err != nil {
			t.Fatalf("insert practitioner_availability %s: %v", specs[idx].name, err)
		}
		if specs[idx].pinned {
			if _, err := store.Pool.Exec(ctx, `
				INSERT INTO staff_practitioner_pins (problem_tag_id, practitioner_id, priority_order)
				VALUES ($1, $2, 1)
			`, tagID, id); err != nil {
				t.Fatalf("insert staff_practitioner_pins %s: %v", specs[idx].name, err)
			}
		}
	}

	tool := ai.NewMatchingTool(
		store,
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
	if _, err := store.Pool.Exec(ctx, `DELETE FROM staff_practitioner_pins WHERE problem_tag_id = $1`, tagID); err != nil {
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

func TestMatchingTool_Step3ChannelFilter_OnlineVsOffline(t *testing.T) {
	store, ctx := openAITestStore(t)
	user := createTempAIUser(t, ctx, store, "match-channel")

	c1PreMarriagePkgID := uuid.MustParse("21000000-0000-4000-8000-000000000002")
	if _, err := store.Pool.Exec(ctx, `
		UPDATE practitioner_packages
		SET is_offline_active = FALSE
		WHERE id = $1
	`, c1PreMarriagePkgID); err != nil {
		t.Fatalf("disable c1 offline couple_pre_marriage: %v", err)
	}
	t.Cleanup(func() {
		cleanupCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_, _ = store.Pool.Exec(cleanupCtx, `
			UPDATE practitioner_packages
			SET is_offline_active = TRUE
			WHERE id = $1
		`, c1PreMarriagePkgID)
	})

	wib := time.FixedZone("WIB", 7*3600)
	fixedNow := time.Date(2026, 11, 23, 8, 0, 0, 0, wib)
	tool := ai.NewMatchingTool(
		store,
		ai.WithMatchingNowFunc(func() time.Time { return fixedNow }),
		ai.WithMatchingJakartaLocation(wib),
	)

	out, err := tool.MatchExpertsAndPackage(ctx, user.ID, ai.MatchSignals{
		Method:    "offline",
		Target:    "couple",
		MainTopic: "house_wedding",
	})
	if err != nil {
		t.Fatalf("MatchExpertsAndPackage(offline couple): %v", err)
	}
	if len(out.Consultants) != 1 || out.Consultants[0].ConsultantID != "c5" {
		t.Fatalf("expected only c5 when c1 offline couple_pre_marriage is inactive, got %+v", out.Consultants)
	}
}
