package ai

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"

	"github.com/clarafin/api/internal/repository"
)

var (
	// ErrInvalidMatchingInput indicates invalid practitioner IDs, filters, or user IDs.
	ErrInvalidMatchingInput = errors.New("invalid matching input")
	// ErrPractitionerNotFound indicates no verified public practitioner exists for the supplied identifier.
	ErrPractitionerNotFound = errors.New("practitioner not found")
)

var canonicalCodeToUUID = map[string]uuid.UUID{
	"c1": uuid.MustParse("00000000-0000-4000-8000-0000000000c1"),
	"c2": uuid.MustParse("00000000-0000-4000-8000-0000000000c2"),
	"c3": uuid.MustParse("00000000-0000-4000-8000-0000000000c3"),
	"c4": uuid.MustParse("00000000-0000-4000-8000-0000000000c4"),
	"c5": uuid.MustParse("00000000-0000-4000-8000-0000000000c5"),
	"c6": uuid.MustParse("00000000-0000-4000-8000-0000000000c6"),
}

var canonicalUUIDToCode = map[uuid.UUID]string{
	canonicalCodeToUUID["c1"]: "c1",
	canonicalCodeToUUID["c2"]: "c2",
	canonicalCodeToUUID["c3"]: "c3",
	canonicalCodeToUUID["c4"]: "c4",
	canonicalCodeToUUID["c5"]: "c5",
	canonicalCodeToUUID["c6"]: "c6",
}

// PractitionerCodeFromUUID maps canonical practitioner UUIDs to "c1".."c6" for Flutter ConsultantRepository compatibility.
func PractitionerCodeFromUUID(id uuid.UUID) string {
	if id == uuid.Nil {
		return ""
	}
	if code, ok := canonicalUUIDToCode[id]; ok {
		return code
	}
	return id.String()
}

// PractitionerUUIDFromCode resolves "c1".."c6" (case-insensitive) or a valid UUID string into a practitioner UUID.
func PractitionerUUIDFromCode(code string) (uuid.UUID, error) {
	trimmed := strings.TrimSpace(code)
	if trimmed == "" {
		return uuid.Nil, fmt.Errorf("%w: practitioner id is required", ErrInvalidMatchingInput)
	}
	if id, ok := canonicalCodeToUUID[strings.ToLower(trimmed)]; ok {
		return id, nil
	}
	parsed, err := uuid.Parse(trimmed)
	if err != nil || parsed == uuid.Nil {
		return uuid.Nil, fmt.Errorf("%w: invalid practitioner identifier %q", ErrInvalidMatchingInput, code)
	}
	return parsed, nil
}

// MatchingToolOption customizes MatchingTool clocks or timezone behavior.
type MatchingToolOption func(*MatchingTool)

// WithMatchingNowFunc overrides the clock source used for deterministic 14-day slot windows.
func WithMatchingNowFunc(fn func() time.Time) MatchingToolOption {
	return func(t *MatchingTool) {
		if fn != nil {
			t.nowFn = fn
		}
	}
}

// WithMatchingJakartaLocation overrides the Asia/Jakarta location used for WIB scheduling.
func WithMatchingJakartaLocation(loc *time.Location) MatchingToolOption {
	return func(t *MatchingTool) {
		if loc != nil {
			t.jakartaLoc = loc
		}
	}
}

// MatchingTool runs the 6-step deterministic practitioner & catalog matching engine and public catalog queries.
type MatchingTool struct {
	store      *repository.Store
	nowFn      func() time.Time
	jakartaLoc *time.Location
}

// NewMatchingTool constructs a MatchingTool backed by PostgreSQL Store.
func NewMatchingTool(store *repository.Store, opts ...MatchingToolOption) *MatchingTool {
	loc, err := time.LoadLocation("Asia/Jakarta")
	if err != nil {
		loc = time.FixedZone("WIB", 7*3600)
	}
	tool := &MatchingTool{
		store:      store,
		nowFn:      time.Now,
		jakartaLoc: loc,
	}
	for _, opt := range opts {
		if opt != nil {
			opt(tool)
		}
	}
	return tool
}

// MatchSignals aligns with the 12 dimensions of MatchExpertQuestionsData plus freeform chat summary.
type MatchSignals struct {
	Method             string   `json:"method,omitempty"`
	Target             string   `json:"target,omitempty"`
	Languages          []string `json:"languages,omitempty"`
	SessionTime        []string `json:"session_time,omitempty"`
	BudgetTier         string   `json:"budget_tier,omitempty"`
	MainTopic          string   `json:"main_topic,omitempty"`
	Outcomes           []string `json:"outcomes,omitempty"`
	Gender             string   `json:"gender,omitempty"`
	ApproachStyle      []string `json:"approach_style,omitempty"`
	AgePreference      string   `json:"age_preference,omitempty"`
	CommunicationStyle string   `json:"communication_style,omitempty"`
	SpecificTags       []string `json:"specific_tags,omitempty"`
	UserGoalSummary    string   `json:"user_goal_summary,omitempty"`
}

// RecommendedPackageOutput describes the single best official catalog package selected by the matching engine.
type RecommendedPackageOutput struct {
	ID                     uuid.UUID `json:"id"`
	PackageCode            string    `json:"package_code"`
	ServiceCategory        string    `json:"service_category"`
	CategoryTag            string    `json:"category_tag"`
	Tier                   string    `json:"tier"`
	SelectedTierLabel      string    `json:"selected_tier_label"`
	ParticipantType        string    `json:"participant_type"`
	PackageTitle           string    `json:"package_title"`
	ShortDesc              string    `json:"short_desc"`
	OnlineDurationMinutes  int32     `json:"online_duration_minutes"`
	OfflineDurationMinutes int32     `json:"offline_duration_minutes"`
	OnlinePriceIDR         int64     `json:"online_price_idr"`
	OfflinePriceIDR        int64     `json:"offline_price_idr"`
	RecommendedMethod      string    `json:"recommended_method"`
}

// MatchedConsultantOutput describes one ranked verified practitioner with concrete next 14-day slot info.
type MatchedConsultantOutput struct {
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

// PrefilledIntakeSummary carries context-aware pre-assessment values for BookingStep3IntakeView.
type PrefilledIntakeSummary struct {
	RecommendedTopics     []string `json:"recommended_topics"`
	PrefilledDescription  string   `json:"prefilled_description"`
	PrefilledExpectations string   `json:"prefilled_expectations"`
}

// MatchingOutput is the deterministic output returned by match_experts_and_package.
type MatchingOutput struct {
	RecommendedPackage     RecommendedPackageOutput  `json:"recommended_package"`
	Consultants            []MatchedConsultantOutput `json:"consultants"`
	PrefilledIntakeSummary PrefilledIntakeSummary    `json:"prefilled_intake_summary"`
	ResolvedSignals        MatchSignals              `json:"resolved_signals"`
	MatchedProblemTags     []string                  `json:"matched_problem_tags"`
}

// PublicPractitionerFilter filters GET /v1/practitioners queries.
type PublicPractitionerFilter struct {
	Tier   string
	Method string
	Tag    string
	City   string
}

// PublicSlotDTO represents a concrete upcoming 14-day WIB availability window.
type PublicSlotDTO struct {
	SlotStartISO string `json:"slot_start_iso"`
	SlotEndISO   string `json:"slot_end_iso"`
	Label        string `json:"label"`
	DayOfWeek    int32  `json:"day_of_week"`
}

// PublicPractitionerPackageDTO represents an active public practitioner package without private cut info.
type PublicPractitionerPackageDTO struct {
	ID               uuid.UUID  `json:"id"`
	CatalogPackageID *uuid.UUID `json:"catalog_package_id,omitempty"`
	PackageCode      string     `json:"package_code,omitempty"`
	ServiceCategory  string     `json:"service_category"`
	CategoryTag      string     `json:"category_tag"`
	Tier             string     `json:"tier"`
	PackageTitle     string     `json:"package_title"`
	DurationMinutes  int32      `json:"duration_minutes"`
	OnlinePriceIDR   *int64     `json:"online_price_idr,omitempty"`
	OfflinePriceIDR  *int64     `json:"offline_price_idr,omitempty"`
	IsOnlineActive   bool       `json:"is_online_active"`
	IsOfflineActive  bool       `json:"is_offline_active"`
}

// PublicPractitionerDTO exposes safe public practitioner fields for GET /v1/practitioners.
type PublicPractitionerDTO struct {
	ConsultantID           string                         `json:"consultant_id"`
	PractitionerUUID       uuid.UUID                      `json:"practitioner_uuid"`
	DisplayName            string                         `json:"display_name"`
	TitleHeadline          string                         `json:"title_headline"`
	Bio                    string                         `json:"bio"`
	City                   string                         `json:"city"`
	Tier                   string                         `json:"tier"`
	ClientsHandledCount    int32                          `json:"clients_handled_count"`
	Certifications         []string                       `json:"certifications"`
	Specializations        []string                       `json:"specializations"`
	Languages              []string                       `json:"languages"`
	SupportedMethods       []string                       `json:"supported_methods"`
	Gender                 *string                        `json:"gender,omitempty"`
	BirthYear              *int32                         `json:"birth_year,omitempty"`
	ConsultingStyle        *string                        `json:"consulting_style,omitempty"`
	YearsOfExperience      int32                          `json:"years_of_experience"`
	IsFullyBooked          bool                           `json:"is_fully_booked"`
	Rating                 float64                        `json:"rating"`
	ReviewCount            int32                          `json:"review_count"`
	TotalSessionsCompleted int32                          `json:"total_sessions_completed"`
	AvatarURL              *string                        `json:"avatar_url,omitempty"`
	FeePerSessionIDR       int64                          `json:"fee_per_session_idr"`
	NextAvailableSlotLabel string                         `json:"next_available_slot_label,omitempty"`
	NextAvailableSlotISO   string                         `json:"next_available_slot_iso,omitempty"`
	Packages               []PublicPractitionerPackageDTO `json:"packages"`
	UpcomingSlots          []PublicSlotDTO                `json:"upcoming_slots"`
}

// PublicReviewDTO exposes safe client feedback for GET /v1/practitioners/{id}.
type PublicReviewDTO struct {
	SessionID    uuid.UUID `json:"session_id"`
	Rating       int32     `json:"rating"`
	Comment      *string   `json:"comment,omitempty"`
	IsAnonymized bool      `json:"is_anonymized"`
	ReviewerName string    `json:"reviewer_name"`
	CreatedAt    time.Time `json:"created_at"`
}

// PublicPractitionerDetailDTO wraps PublicPractitionerDTO with recent anonymized-safe reviews.
type PublicPractitionerDetailDTO struct {
	PublicPractitionerDTO
	Reviews []PublicReviewDTO `json:"reviews"`
}

// CatalogPackageDTO exposes an official Clarafin catalog package for GET /v1/catalog-packages.
type CatalogPackageDTO struct {
	ID                     uuid.UUID `json:"id"`
	Code                   string    `json:"code"`
	ServiceCategory        string    `json:"service_category"`
	CategoryTag            string    `json:"category_tag"`
	Tier                   string    `json:"tier"`
	SelectedTierLabel      string    `json:"selected_tier_label"`
	ParticipantType        string    `json:"participant_type"`
	PackageTitle           string    `json:"package_title"`
	ShortDesc              string    `json:"short_desc"`
	FullDesc               string    `json:"full_desc"`
	Features               []string  `json:"features"`
	OnlineDurationMinutes  int32     `json:"online_duration_minutes"`
	OfflineDurationMinutes int32     `json:"offline_duration_minutes"`
	BaseOnlinePriceIDR     int64     `json:"base_online_price_idr"`
	MaxOnlinePriceIDR      int64     `json:"max_online_price_idr"`
	BaseOfflinePriceIDR    int64     `json:"base_offline_price_idr"`
	MaxOfflinePriceIDR     int64     `json:"max_offline_price_idr"`
}

type slotWindow struct {
	start time.Time
	end   time.Time
	day   int32
}

type timeInterval struct {
	start time.Time
	end   time.Time
}

type practitionerBundle struct {
	id                     uuid.UUID
	code                   string
	displayName            string
	titleHeadline          string
	bio                    string
	city                   string
	tier                   string
	clientsHandledCount    int32
	certifications         []string
	specializations        []string
	languages              []string
	supportedMethods       []string
	gender                 *string
	birthYear              *int32
	consultingStyle        *string
	yearsOfExperience      int32
	isFullyBooked          bool
	ratingAvg              float64
	reviewCount            int32
	totalSessionsCompleted int32
	avatarURL              *string
	packages               []repository.PractitionerPackage
}

// MatchExpertsAndPackage executes the Chat 60% / DB 40% signal merge and the 6-step deterministic matching engine.
func (t *MatchingTool) MatchExpertsAndPackage(
	ctx context.Context,
	userID uuid.UUID,
	chatSignals MatchSignals,
) (*MatchingOutput, error) {
	if t == nil || t.store == nil {
		return nil, errors.New("matching tool store is not initialized")
	}
	if userID == uuid.Nil {
		return nil, fmt.Errorf("%w: user_id is required", ErrInvalidMatchingInput)
	}

	nowWIB := t.nowFn().In(t.jakartaLoc)

	dbSignals, err := t.loadDBSignals(ctx, userID, nowWIB)
	if err != nil {
		return nil, err
	}

	problemTags, err := t.store.ListProblemTags(ctx)
	if err != nil {
		return nil, fmt.Errorf("list problem tags: %w", err)
	}
	tagBySlug := make(map[string]repository.ProblemTag, len(problemTags))
	for _, pt := range problemTags {
		tagBySlug[pt.Slug] = pt
	}

	catalogPkgs, err := t.store.ListCatalogPackages(ctx)
	if err != nil {
		return nil, fmt.Errorf("list catalog packages: %w", err)
	}
	if len(catalogPkgs) == 0 {
		return nil, errors.New("no active catalog packages configured")
	}
	catalogCodeByID := buildCatalogCodeIndex(catalogPkgs)

	resolved := mergeChatAndDBSignals(chatSignals, dbSignals, tagBySlug)
	matchedTags := resolveMatchedProblemTags(resolved, tagBySlug)
	recommendedPkg, requiredMinTierRank := selectBestCatalogPackage(resolved, matchedTags, tagBySlug, catalogPkgs)

	rows, err := t.store.ListVerifiedPractitionersWithPackages(ctx)
	if err != nil {
		return nil, fmt.Errorf("list verified practitioners: %w", err)
	}
	candidates := groupPractitionerBundles(rows)
	if len(candidates) == 0 {
		return nil, errors.New("no verified practitioners with active packages found")
	}

	pracIDs := make([]uuid.UUID, 0, len(candidates))
	for _, c := range candidates {
		pracIDs = append(pracIDs, c.id)
	}

	rangeStart := nowWIB
	rangeEnd := nowWIB.Add(14 * 24 * time.Hour)
	slotsByPractitioner, err := t.loadOpenSlots14Days(ctx, pracIDs, nowWIB, rangeStart, rangeEnd)
	if err != nil {
		return nil, err
	}

	pinsByPractitioner := make(map[uuid.UUID]pinRank)
	if len(matchedTags) > 0 {
		pins, err := t.store.ListStaffPinsByTagSlugs(ctx, matchedTags)
		if err != nil {
			return nil, fmt.Errorf("list staff pins: %w", err)
		}
		tagPriorityIdx := make(map[string]int, len(matchedTags))
		for i, slug := range matchedTags {
			tagPriorityIdx[slug] = i
		}
		for _, p := range pins {
			idx := tagPriorityIdx[p.TagSlug]
			rank := pinRank{tagIndex: idx, priorityOrder: int(p.PriorityOrder)}
			if existing, ok := pinsByPractitioner[p.PractitionerID]; !ok || rank.less(existing) {
				pinsByPractitioner[p.PractitionerID] = rank
			}
		}
	}

	// Step 1: Tag & Topic filter (plus non-blocking language/gender filter when matching candidates exist).
	step1 := filterStep1TagAndTopic(candidates, matchedTags, resolved, recommendedPkg.ServiceCategory, pinsByPractitioner)
	step1 = applySoftLanguageAndGenderFilters(step1, resolved)

	// Step 2: Tier eligibility (never allow lower-tier practitioners on higher-tier tags or packages).
	step2 := make([]practitionerBundle, 0, len(step1))
	for _, p := range step1 {
		if tierRank(p.tier) >= requiredMinTierRank {
			step2 = append(step2, p)
		}
	}

	// Step 3: Active package in requested channel (Online vs Tatap Muka).
	type channelCandidate struct {
		bundle practitionerBundle
		pkg    repository.PractitionerPackage
	}
	step3 := make([]channelCandidate, 0, len(step2))
	for _, p := range step2 {
		pkg, ok := selectPractitionerPackageForChannel(p, recommendedPkg, requiredMinTierRank, resolved.Method)
		if ok {
			step3 = append(step3, channelCandidate{bundle: p, pkg: pkg})
		}
	}

	// Step 4: Available slot within next 14 days (excludes is_fully_booked = true and held/booked/session-blocked slots).
	type rankedCandidate struct {
		bundle           practitionerBundle
		pkg              repository.PractitionerPackage
		earliestSlot     slotWindow
		preferredSlot    slotWindow
		hasPreferredSlot bool
		pin              pinRank
		hasPin           bool
	}
	step4 := make([]rankedCandidate, 0, len(step3))
	for _, c := range step3 {
		if c.bundle.isFullyBooked {
			continue
		}
		slots := slotsByPractitioner[c.bundle.id]
		if len(slots) == 0 {
			continue
		}
		prefSlot, hasPrefSlot := findPreferredSlot(slots, resolved.SessionTime, t.jakartaLoc)
		pin, hasPin := pinsByPractitioner[c.bundle.id]
		step4 = append(step4, rankedCandidate{
			bundle:           c.bundle,
			pkg:              c.pkg,
			earliestSlot:     slots[0],
			preferredSlot:    prefSlot,
			hasPreferredSlot: hasPrefSlot,
			pin:              pin,
			hasPin:           hasPin,
		})
	}

	// Step 5 & Step 6: Staff pins passing steps 1-4 rank first (max 3),
	// remaining candidates sort strictly by earliest_available_slot_at ASC -> rating_avg DESC -> total_sessions_completed DESC.
	// NEVER sort by platform_cut_pct or cheapest price.
	var pinned []rankedCandidate
	var unpinned []rankedCandidate
	for _, c := range step4 {
		if c.hasPin {
			pinned = append(pinned, c)
		} else {
			unpinned = append(unpinned, c)
		}
	}

	sort.SliceStable(pinned, func(i, j int) bool {
		if pinned[i].pin != pinned[j].pin {
			return pinned[i].pin.less(pinned[j].pin)
		}
		return compareTieBreaker(
			pinned[i].earliestSlot.start, pinned[i].bundle,
			pinned[j].earliestSlot.start, pinned[j].bundle,
		)
	})
	if len(pinned) > 3 {
		for i := 3; i < len(pinned); i++ {
			pinned[i].hasPin = false
		}
		unpinned = append(unpinned, pinned[3:]...)
		pinned = pinned[:3]
	}

	sort.SliceStable(unpinned, func(i, j int) bool {
		return compareTieBreaker(
			unpinned[i].earliestSlot.start, unpinned[i].bundle,
			unpinned[j].earliestSlot.start, unpinned[j].bundle,
		)
	})

	ordered := make([]rankedCandidate, 0, 3)
	ordered = append(ordered, pinned...)
	ordered = append(ordered, unpinned...)
	if len(ordered) > 3 {
		ordered = ordered[:3]
	}

	consultants := make([]MatchedConsultantOutput, 0, len(ordered))
	for _, item := range ordered {
		pkgCode := ""
		if item.pkg.CatalogPackageID != nil {
			pkgCode = catalogCodeByID[*item.pkg.CatalogPackageID]
		}
		onlinePrice := recommendedPkg.BaseOnlinePriceIdr
		if item.pkg.OnlinePriceIdr != nil && *item.pkg.OnlinePriceIdr > 0 {
			onlinePrice = *item.pkg.OnlinePriceIdr
		}
		offlinePrice := recommendedPkg.BaseOfflinePriceIdr
		if item.pkg.OfflinePriceIdr != nil && *item.pkg.OfflinePriceIdr > 0 {
			offlinePrice = *item.pkg.OfflinePriceIdr
		}

		var prefLabel, prefISO string
		if item.hasPreferredSlot {
			prefLabel = formatWIBSlotLabel(item.preferredSlot.start, nowWIB, t.jakartaLoc)
			prefISO = item.preferredSlot.start.In(t.jakartaLoc).Format(time.RFC3339)
		}

		consultants = append(consultants, MatchedConsultantOutput{
			ConsultantID:           item.bundle.code,
			PractitionerUUID:       item.bundle.id,
			DisplayName:            item.bundle.displayName,
			TitleHeadline:          item.bundle.titleHeadline,
			AvatarURL:              item.bundle.avatarURL,
			Certifications:         nonNilStrings(item.bundle.certifications),
			Tier:                   item.bundle.tier,
			Rating:                 roundRating(item.bundle.ratingAvg),
			ReviewCount:            item.bundle.reviewCount,
			TotalSessionsCompleted: item.bundle.totalSessionsCompleted,
			MatchReason:            buildMatchReason(item.bundle, item.hasPin, matchedTags, tagBySlug, resolved),
			IsStaffPinned:          item.hasPin,
			NextAvailableSlotLabel: formatWIBSlotLabel(item.earliestSlot.start, nowWIB, t.jakartaLoc),
			NextAvailableSlotISO:   item.earliestSlot.start.In(t.jakartaLoc).Format(time.RFC3339),
			PreferredSlotLabel:     prefLabel,
			PreferredSlotISO:       prefISO,
			PackageCode:            pkgCode,
			PackageTitle:           item.pkg.PackageTitle,
			OnlinePriceIDR:         onlinePrice,
			OfflinePriceIDR:        offlinePrice,
		})
	}

	return &MatchingOutput{
		RecommendedPackage: RecommendedPackageOutput{
			ID:                     recommendedPkg.ID,
			PackageCode:            recommendedPkg.Code,
			ServiceCategory:        recommendedPkg.ServiceCategory,
			CategoryTag:            recommendedPkg.CategoryTag,
			Tier:                   recommendedPkg.Tier,
			SelectedTierLabel:      formatSelectedTierLabel(recommendedPkg),
			ParticipantType:        recommendedPkg.ParticipantType,
			PackageTitle:           recommendedPkg.PackageTitle,
			ShortDesc:              recommendedPkg.ShortDesc,
			OnlineDurationMinutes:  recommendedPkg.OnlineDurationMinutes,
			OfflineDurationMinutes: recommendedPkg.OfflineDurationMinutes,
			OnlinePriceIDR:         recommendedPkg.BaseOnlinePriceIdr,
			OfflinePriceIDR:        recommendedPkg.BaseOfflinePriceIdr,
			RecommendedMethod:      resolved.Method,
		},
		Consultants:            consultants,
		PrefilledIntakeSummary: buildPrefilledIntakeSummary(resolved, matchedTags, recommendedPkg),
		ResolvedSignals:        resolved,
		MatchedProblemTags:     nonNilStrings(matchedTags),
	}, nil
}

// ListPublicPractitioners serves GET /v1/practitioners with optional tier, method, tag, and city filters.
func (t *MatchingTool) ListPublicPractitioners(ctx context.Context, filter PublicPractitionerFilter) ([]PublicPractitionerDTO, error) {
	if t == nil || t.store == nil {
		return nil, errors.New("matching tool store is not initialized")
	}

	tierFilter := strings.ToLower(strings.TrimSpace(filter.Tier))
	if tierFilter != "" {
		switch tierFilter {
		case "basic", "medium", "premium":
		default:
			return nil, fmt.Errorf("%w: unsupported tier filter %q", ErrInvalidMatchingInput, filter.Tier)
		}
	}

	methodFilter := normalizeMethod(filter.Method)
	if strings.TrimSpace(filter.Method) != "" && methodFilter == "" {
		return nil, fmt.Errorf("%w: unsupported method filter %q", ErrInvalidMatchingInput, filter.Method)
	}

	tagFilter := strings.TrimSpace(filter.Tag)
	cityFilter := strings.ToLower(strings.TrimSpace(filter.City))

	catalogPkgs, err := t.store.ListCatalogPackages(ctx)
	if err != nil {
		return nil, fmt.Errorf("list catalog packages: %w", err)
	}
	catalogCodeByID := buildCatalogCodeIndex(catalogPkgs)

	problemTags, err := t.store.ListProblemTags(ctx)
	if err != nil {
		return nil, fmt.Errorf("list problem tags: %w", err)
	}
	tagBySlug := make(map[string]repository.ProblemTag, len(problemTags))
	for _, pt := range problemTags {
		tagBySlug[pt.Slug] = pt
	}

	rows, err := t.store.ListVerifiedPractitionersWithPackages(ctx)
	if err != nil {
		return nil, fmt.Errorf("list verified practitioners: %w", err)
	}
	bundles := groupPractitionerBundles(rows)
	if len(bundles) == 0 {
		return []PublicPractitionerDTO{}, nil
	}

	var matchedTagSlug string
	var minTagTierRank int
	pinsMap := make(map[uuid.UUID]pinRank)
	if tagFilter != "" {
		slugs := normalizeProblemTagList([]string{tagFilter}, tagBySlug)
		if len(slugs) > 0 {
			matchedTagSlug = slugs[0]
			if pt, ok := tagBySlug[matchedTagSlug]; ok {
				minTagTierRank = tierRank(pt.MinTier)
			}
			pins, err := t.store.ListStaffPinsByTagSlug(ctx, matchedTagSlug)
			if err != nil {
				return nil, fmt.Errorf("list staff pins for tag: %w", err)
			}
			for _, p := range pins {
				pinsMap[p.PractitionerID] = pinRank{priorityOrder: int(p.PriorityOrder)}
			}
		}
	}

	pracIDs := make([]uuid.UUID, 0, len(bundles))
	for _, b := range bundles {
		pracIDs = append(pracIDs, b.id)
	}

	nowWIB := t.nowFn().In(t.jakartaLoc)
	slotsByPrac, err := t.loadOpenSlots14Days(ctx, pracIDs, nowWIB, nowWIB, nowWIB.Add(14*24*time.Hour))
	if err != nil {
		return nil, err
	}

	out := make([]PublicPractitionerDTO, 0, len(bundles))
	for _, b := range bundles {
		if tierFilter != "" && strings.ToLower(b.tier) != tierFilter {
			continue
		}
		if cityFilter != "" && !strings.Contains(strings.ToLower(b.city), cityFilter) {
			continue
		}
		if methodFilter != "" && !practitionerSupportsMethodFilter(b, methodFilter) {
			continue
		}
		if tagFilter != "" {
			if minTagTierRank > 0 && tierRank(b.tier) < minTagTierRank {
				continue
			}
			if matchedTagSlug != "" {
				_, isPinned := pinsMap[b.id]
				if !isPinned && !practitionerMatchesTagKeywords(b, matchedTagSlug) {
					continue
				}
			} else if !practitionerMatchesFreeKeyword(b, tagFilter) {
				continue
			}
		}

		slots := slotsByPrac[b.id]
		if b.isFullyBooked {
			slots = nil
		}
		out = append(out, buildPublicPractitionerDTO(b, slots, nowWIB, t.jakartaLoc, catalogCodeByID))
	}

	sort.SliceStable(out, func(i, j int) bool {
		if matchedTagSlug != "" {
			pi, okI := pinsMap[out[i].PractitionerUUID]
			pj, okJ := pinsMap[out[j].PractitionerUUID]
			if okI != okJ {
				return okI
			}
			if okI && okJ && pi.priorityOrder != pj.priorityOrder {
				return pi.priorityOrder < pj.priorityOrder
			}
		}
		if out[i].Rating != out[j].Rating {
			return out[i].Rating > out[j].Rating
		}
		if out[i].TotalSessionsCompleted != out[j].TotalSessionsCompleted {
			return out[i].TotalSessionsCompleted > out[j].TotalSessionsCompleted
		}
		return out[i].ConsultantID < out[j].ConsultantID
	})

	return out, nil
}

// GetPublicPractitioner serves GET /v1/practitioners/{id} accepting "c1".."c6" or UUID.
func (t *MatchingTool) GetPublicPractitioner(ctx context.Context, idOrCode string) (*PublicPractitionerDetailDTO, error) {
	if t == nil || t.store == nil {
		return nil, errors.New("matching tool store is not initialized")
	}

	pracUUID, err := PractitionerUUIDFromCode(idOrCode)
	if err != nil {
		return nil, err
	}

	profile, err := t.store.GetPublicPractitionerByID(ctx, pracUUID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, fmt.Errorf("%w: practitioner %q", ErrPractitionerNotFound, idOrCode)
		}
		return nil, fmt.Errorf("get public practitioner: %w", err)
	}

	pkgs, err := t.store.ListActivePackagesByPractitioner(ctx, pracUUID)
	if err != nil {
		return nil, fmt.Errorf("list practitioner packages: %w", err)
	}

	catalogPkgs, err := t.store.ListCatalogPackages(ctx)
	if err != nil {
		return nil, fmt.Errorf("list catalog packages: %w", err)
	}
	catalogCodeByID := buildCatalogCodeIndex(catalogPkgs)

	nowWIB := t.nowFn().In(t.jakartaLoc)
	slotsByPrac, err := t.loadOpenSlots14Days(ctx, []uuid.UUID{pracUUID}, nowWIB, nowWIB, nowWIB.Add(14*24*time.Hour))
	if err != nil {
		return nil, err
	}
	slots := slotsByPrac[pracUUID]
	if profile.IsFullyBooked {
		slots = nil
	}

	reviewsRows, err := t.store.ListPublicReviewsByPractitioner(ctx, repository.ListPublicReviewsByPractitionerParams{
		PractitionerID: pracUUID,
		Limit:          20,
	})
	if err != nil {
		return nil, fmt.Errorf("list practitioner reviews: %w", err)
	}

	reviews := make([]PublicReviewDTO, 0, len(reviewsRows))
	for _, r := range reviewsRows {
		reviews = append(reviews, PublicReviewDTO{
			SessionID:    r.SessionID,
			Rating:       r.Rating,
			Comment:      r.Comment,
			IsAnonymized: r.IsAnonymized,
			ReviewerName: r.ReviewerName,
			CreatedAt:    r.CreatedAt.In(t.jakartaLoc),
		})
	}

	bundle := practitionerBundle{
		id:                     profile.PractitionerID,
		code:                   PractitionerCodeFromUUID(profile.PractitionerID),
		displayName:            profile.DisplayName,
		titleHeadline:          profile.TitleHeadline,
		bio:                    profile.Bio,
		city:                   profile.City,
		tier:                   profile.PractitionerTier,
		clientsHandledCount:    profile.ClientsHandledCount,
		certifications:         profile.Certifications,
		specializations:        profile.Specializations,
		languages:              profile.Languages,
		supportedMethods:       profile.SupportedMethods,
		gender:                 profile.Gender,
		birthYear:              profile.BirthYear,
		consultingStyle:        profile.ConsultingStyle,
		yearsOfExperience:      profile.YearsOfExperience,
		isFullyBooked:          profile.IsFullyBooked,
		ratingAvg:              float64(profile.RatingAvg),
		reviewCount:            profile.ReviewCount,
		totalSessionsCompleted: profile.TotalSessionsCompleted,
		avatarURL:              profile.AvatarUrl,
		packages:               pkgs,
	}

	return &PublicPractitionerDetailDTO{
		PublicPractitionerDTO: buildPublicPractitionerDTO(bundle, slots, nowWIB, t.jakartaLoc, catalogCodeByID),
		Reviews:               reviews,
	}, nil
}

// ListCatalogPackages serves GET /v1/catalog-packages.
func (t *MatchingTool) ListCatalogPackages(ctx context.Context, serviceCategory string) ([]CatalogPackageDTO, error) {
	if t == nil || t.store == nil {
		return nil, errors.New("matching tool store is not initialized")
	}

	catFilter := strings.ToLower(strings.TrimSpace(serviceCategory))
	if catFilter != "" {
		switch catFilter {
		case "individual", "couple", "umkm", "corporate", "financial_checkup":
		default:
			return nil, fmt.Errorf("%w: unsupported service_category %q", ErrInvalidMatchingInput, serviceCategory)
		}
	}

	rows, err := t.store.ListCatalogPackages(ctx)
	if err != nil {
		return nil, fmt.Errorf("list catalog packages: %w", err)
	}

	out := make([]CatalogPackageDTO, 0, len(rows))
	for _, cp := range rows {
		if catFilter != "" && cp.ServiceCategory != catFilter {
			continue
		}
		out = append(out, CatalogPackageDTO{
			ID:                     cp.ID,
			Code:                   cp.Code,
			ServiceCategory:        cp.ServiceCategory,
			CategoryTag:            cp.CategoryTag,
			Tier:                   cp.Tier,
			SelectedTierLabel:      formatSelectedTierLabel(cp),
			ParticipantType:        cp.ParticipantType,
			PackageTitle:           cp.PackageTitle,
			ShortDesc:              cp.ShortDesc,
			FullDesc:               cp.FullDesc,
			Features:               nonNilStrings(cp.Features),
			OnlineDurationMinutes:  cp.OnlineDurationMinutes,
			OfflineDurationMinutes: cp.OfflineDurationMinutes,
			BaseOnlinePriceIDR:     cp.BaseOnlinePriceIdr,
			MaxOnlinePriceIDR:      cp.MaxOnlinePriceIdr,
			BaseOfflinePriceIDR:    cp.BaseOfflinePriceIdr,
			MaxOfflinePriceIDR:     cp.MaxOfflinePriceIdr,
		})
	}
	return out, nil
}

type dbSignalBundle struct {
	advisoryFocuses []string
	quizSignals     MatchSignals
	cashflowHint    MatchSignals
}

func (t *MatchingTool) loadDBSignals(ctx context.Context, userID uuid.UUID, nowWIB time.Time) (dbSignalBundle, error) {
	var out dbSignalBundle

	prefs, err := t.store.GetUserPreferences(ctx, userID)
	if err != nil && !errors.Is(err, pgx.ErrNoRows) {
		return out, fmt.Errorf("get user preferences: %w", err)
	}
	if err == nil {
		out.advisoryFocuses = prefs.AdvisoryFocuses
	}

	sub, err := t.store.GetLatestMatchExpertSubmission(ctx, userID)
	if err != nil && !errors.Is(err, pgx.ErrNoRows) {
		return out, fmt.Errorf("get latest match expert submission: %w", err)
	}
	if err == nil && len(sub.AnswersJson) > 0 {
		out.quizSignals = parseAnswersJSON(sub.AnswersJson)
	}

	endAt := nowWIB.Add(24 * time.Hour)
	startAt := nowWIB.AddDate(0, 0, -90)
	totals, err := t.store.GetCashflowPeriodTotals(ctx, repository.GetCashflowPeriodTotalsParams{
		UserID:  userID,
		StartAt: startAt,
		EndAt:   endAt,
	})
	if err != nil {
		return out, fmt.Errorf("get cashflow totals for matching: %w", err)
	}
	catRows, err := t.store.GetCashflowCategoryBreakdown(ctx, repository.GetCashflowCategoryBreakdownParams{
		UserID:  userID,
		StartAt: startAt,
		EndAt:   endAt,
	})
	if err != nil {
		return out, fmt.Errorf("get cashflow categories for matching: %w", err)
	}
	wallets, err := t.store.ListActiveWalletsByUser(ctx, userID)
	if err != nil {
		return out, fmt.Errorf("list wallets for matching: %w", err)
	}

	var hasBusiness, hasLoans, hasInvestment bool
	for _, r := range catRows {
		lower := strings.ToLower(r.Category)
		switch {
		case strings.Contains(lower, "business") || strings.Contains(lower, "bisnis"):
			hasBusiness = true
		case strings.Contains(lower, "loan") || strings.Contains(lower, "utang"):
			hasLoans = true
		case strings.Contains(lower, "invest"):
			hasInvestment = true
		}
	}
	var totalBalance int64
	for _, w := range wallets {
		totalBalance += w.Balance
		if w.IsVolatile || w.Type == "stock" || w.Type == "mutual_fund" || w.Type == "bond" || w.Type == "investment" {
			hasInvestment = true
		}
	}

	switch {
	case hasBusiness:
		out.cashflowHint.Target = "business"
		out.cashflowHint.MainTopic = "sme"
	case hasLoans || (totals.TotalExpense > totals.TotalIncome && totals.TotalExpense > 0):
		out.cashflowHint.MainTopic = "debt_cashflow"
	case hasInvestment:
		out.cashflowHint.MainTopic = "investment"
	}
	if totalBalance >= 50000000 || totals.TotalIncome >= 60000000 {
		out.cashflowHint.BudgetTier = "medium"
	}

	return out, nil
}

func parseAnswersJSON(raw []byte) MatchSignals {
	var m map[string]any
	if err := json.Unmarshal(raw, &m); err != nil {
		return MatchSignals{}
	}
	return MatchSignals{
		Method:             readJSONString(m["method"]),
		Target:             readJSONString(m["target"]),
		Languages:          readJSONStringSlice(m["languages"]),
		SessionTime:        readJSONStringSlice(m["session_time"]),
		BudgetTier:         readJSONString(m["budget_tier"]),
		MainTopic:          readJSONString(m["main_topic"]),
		Outcomes:           readJSONStringSlice(m["outcomes"]),
		Gender:             readJSONString(m["gender"]),
		ApproachStyle:      readJSONStringSlice(m["approach_style"]),
		AgePreference:      readJSONString(m["age_preference"]),
		CommunicationStyle: readJSONString(m["communication_style"]),
		SpecificTags:       readJSONStringSlice(m["specific_tags"]),
		UserGoalSummary:    readJSONString(m["user_goal_summary"]),
	}
}

func readJSONString(v any) string {
	s, ok := v.(string)
	if !ok {
		return ""
	}
	return strings.TrimSpace(s)
}

func readJSONStringSlice(v any) []string {
	switch typed := v.(type) {
	case string:
		trimmed := strings.TrimSpace(typed)
		if trimmed == "" {
			return nil
		}
		return []string{trimmed}
	case []any:
		out := make([]string, 0, len(typed))
		for _, item := range typed {
			if s, ok := item.(string); ok {
				if trimmed := strings.TrimSpace(s); trimmed != "" {
					out = append(out, trimmed)
				}
			}
		}
		return out
	default:
		return nil
	}
}

func parseAdvisoryFocusSignals(focuses []string) MatchSignals {
	var out MatchSignals
	for _, raw := range focuses {
		tok := strings.ToLower(strings.TrimSpace(raw))
		switch tok {
		case "basic", "low", "personal_basic", "umkm_basic", "checkup_basic":
			if out.BudgetTier == "" {
				out.BudgetTier = "low"
			}
		case "medium", "personal_medium", "umkm_medium", "checkup_medium":
			if out.BudgetTier == "" {
				out.BudgetTier = "medium"
			}
		case "premium", "high", "personal_premium", "couple_premium", "umkm_premium", "checkup_premium":
			if out.BudgetTier == "" {
				out.BudgetTier = "high"
			}
		case "individual", "personal", "self":
			if out.Target == "" {
				out.Target = "self"
			}
		case "couple", "pasangan", "pranikah", "couple_pre_marriage", "couple_marriage":
			out.Target = "couple"
		case "family", "keluarga":
			out.Target = "family"
		case "umkm", "business", "bisnis", "sme":
			out.Target = "business"
			if out.MainTopic == "" {
				out.MainTopic = "sme"
			}
		case "corporate", "korporasi":
			out.Target = "corporate"
		case "debt_cashflow", "utang", "pinjol", "cashflow":
			if out.MainTopic == "" {
				out.MainTopic = "debt_cashflow"
			}
		case "investment", "investasi":
			if out.MainTopic == "" {
				out.MainTopic = "investment"
			}
		case "financial_checkup", "checkup", "tes_finansial":
			if out.MainTopic == "" {
				out.MainTopic = "financial_checkup"
			}
		}
	}
	return out
}

func buildCatalogCodeIndex(catalogPkgs []repository.CatalogPackage) map[uuid.UUID]string {
	catalogCodeByID := make(map[uuid.UUID]string, len(catalogPkgs))
	for _, cp := range catalogPkgs {
		catalogCodeByID[cp.ID] = cp.Code
	}
	return catalogCodeByID
}

func inferGoalSignals(goal string, tagBySlug map[string]repository.ProblemTag) (string, string, []string) {
	goalLower := strings.ToLower(strings.TrimSpace(goal))
	if goalLower == "" {
		return "", "", nil
	}

	inferredTags := extractTagsFromGoalSummary(goalLower, tagBySlug)

	var inferredTarget string
	switch {
	case containsAny(goalLower, "korporasi", "karyawan", "hrd", "townhall", "perusahaan"):
		inferredTarget = "corporate"
	case containsAnyTag(inferredTags, "kas_bisnis", "runway_usaha") ||
		containsAny(goalLower, "umkm", "toko", "warung", "pembukuan", "hpp", "startup", "runway", "burn rate", "kas usaha", "bisnis", "usaha"):
		inferredTarget = "business"
	case containsAnyTag(inferredTags, "budget_nikah") ||
		containsAny(goalLower, "nikah", "pranikah", "pre-marriage", "tunangan", "pasutri", "suami", "istri", "pasangan", "rekening bersama"):
		inferredTarget = "couple"
	case containsAny(goalLower, "keluarga", "generasi sandwich", "sandwich", "pendidikan anak", "dana pendidikan"):
		inferredTarget = "family"
	case containsAny(goalLower, "pribadi", "individu", "sendiri"):
		inferredTarget = "self"
	}

	var inferredTopic string
	switch {
	case containsAny(goalLower, "korporasi", "karyawan", "hrd", "townhall", "perusahaan"):
		inferredTopic = "corporate"
	case containsAnyTag(inferredTags, "kas_bisnis", "runway_usaha") ||
		containsAny(goalLower, "umkm", "toko", "warung", "pembukuan", "hpp", "startup", "runway", "burn rate", "kas usaha", "bisnis", "usaha"):
		inferredTopic = "sme"
	case containsAny(goalLower, "check-up", "checkup", "check up", "mcu keuangan", "skor keuangan", "audit polis"):
		inferredTopic = "financial_checkup"
	case containsAnyTag(inferredTags, "budget_nikah", "kpr") ||
		containsAny(goalLower, "nikah", "pranikah", "pre-marriage", "tunangan", "sebelum akad", "kpr", "beli rumah", "dp rumah", "properti"):
		inferredTopic = "house_wedding"
	case containsAnyTag(inferredTags, "fire_pensiun") ||
		containsAny(goalLower, "fire", "pensiun", "kebebasan finansial", "financial freedom", "passive income", "waris"):
		inferredTopic = "retirement"
	case containsAny(goalLower, "pendidikan anak", "dana pendidikan", "biaya kuliah", "sekolah anak"):
		inferredTopic = "education"
	case containsAnyTag(inferredTags, "dana_darurat", "asuransi") ||
		containsAny(goalLower, "dana darurat", "emergency", "asuransi", "unitlink", "polis", "proteksi"):
		inferredTopic = "emergency_insurance"
	case containsAnyTag(inferredTags, "saham", "reksadana", "crypto") ||
		containsAny(goalLower, "saham", "dividen", "ihsg", "reksadana", "reksa dana", "sbn", "obligasi", "portofolio", "investasi", "crypto", "kripto", "bitcoin", "web3"):
		inferredTopic = "investment"
	case containsAnyTag(inferredTags, "pinjol", "restrukturisasi_utang", "pemetaan_utang", "cashflow") ||
		containsAny(goalLower, "pinjol", "paylater", "galbay", "restrukturisasi", "cicilan", "hutang", "utang", "kartu kredit", "cashflow", "arus kas", "gaji habis", "budget"):
		inferredTopic = "debt_cashflow"
	}

	return inferredTarget, inferredTopic, inferredTags
}

func slicesOverlapFold(a, b []string) bool {
	for _, x := range a {
		if sliceContainsFold(b, x) {
			return true
		}
	}
	return false
}

func mergeChatAndDBSignals(chat MatchSignals, db dbSignalBundle, tagBySlug map[string]repository.ProblemTag) MatchSignals {
	adv := parseAdvisoryFocusSignals(db.advisoryFocuses)
	quiz := db.quizSignals

	chatTarget := normalizeTarget(chat.Target)
	chatTopic := normalizeMainTopic(chat.MainTopic)
	chatTags := cleanNonEmpty(chat.SpecificTags)
	chatBudget := normalizeBudgetTier(chat.BudgetTier)
	chatGoal := strings.TrimSpace(chat.UserGoalSummary)
	chatMethod := normalizeMethod(chat.Method)

	inferredTarget, inferredTopic, inferredTags := inferGoalSignals(chatGoal, tagBySlug)
	effectiveChatTarget := firstNonEmpty(chatTarget, inferredTarget)
	effectiveChatTopic := firstNonEmpty(chatTopic, inferredTopic)

	dbTarget := firstNonEmpty(normalizeTarget(quiz.Target), normalizeTarget(adv.Target), normalizeTarget(db.cashflowHint.Target), "self")
	dbTopic := firstNonEmpty(normalizeMainTopic(quiz.MainTopic), normalizeMainTopic(adv.MainTopic), normalizeMainTopic(db.cashflowHint.MainTopic))
	dbBudget := firstNonEmpty(normalizeBudgetTier(quiz.BudgetTier), normalizeBudgetTier(adv.BudgetTier), normalizeBudgetTier(db.cashflowHint.BudgetTier))
	dbQuizTags := cleanNonEmpty(quiz.SpecificTags)

	// Detect whether active chat (explicit fields or UserGoalSummary) shifted intent away from stored onboarding/quiz context.
	intentOverriddenByChat := false
	if effectiveChatTarget != "" && effectiveChatTarget != dbTarget {
		intentOverriddenByChat = true
	}
	if effectiveChatTopic != "" && dbTopic != "" && effectiveChatTopic != dbTopic {
		intentOverriddenByChat = true
	}
	if (dbTarget == "business" || dbTarget == "corporate") && effectiveChatTopic != "" && effectiveChatTopic != "sme" && effectiveChatTopic != "corporate" {
		intentOverriddenByChat = true
	}
	if len(chatTags) > 0 {
		intentOverriddenByChat = true
	}
	if len(inferredTags) > 0 && len(dbQuizTags) > 0 && !slicesOverlapFold(inferredTags, dbQuizTags) {
		intentOverriddenByChat = true
	}

	resolvedTarget := firstNonEmpty(effectiveChatTarget, dbTarget, "self")
	if intentOverriddenByChat {
		resolvedTarget = firstNonEmpty(effectiveChatTarget, "self")
	}

	resolved := MatchSignals{
		Method:             firstNonEmpty(chatMethod, normalizeMethod(quiz.Method), "online"),
		Target:             resolvedTarget,
		Languages:          firstNonEmptySlice(cleanNonEmpty(chat.Languages), cleanNonEmpty(quiz.Languages)),
		SessionTime:        firstNonEmptySlice(cleanNonEmpty(chat.SessionTime), cleanNonEmpty(quiz.SessionTime)),
		Gender:             firstNonEmpty(normalizeGender(chat.Gender), normalizeGender(quiz.Gender)),
		ApproachStyle:      firstNonEmptySlice(cleanNonEmpty(chat.ApproachStyle), cleanNonEmpty(quiz.ApproachStyle)),
		AgePreference:      firstNonEmpty(strings.ToLower(strings.TrimSpace(chat.AgePreference)), strings.ToLower(strings.TrimSpace(quiz.AgePreference))),
		CommunicationStyle: firstNonEmpty(strings.ToLower(strings.TrimSpace(chat.CommunicationStyle)), strings.ToLower(strings.TrimSpace(quiz.CommunicationStyle))),
		Outcomes:           firstNonEmptySlice(cleanNonEmpty(chat.Outcomes), cleanNonEmpty(quiz.Outcomes)),
		UserGoalSummary:    chatGoal,
	}

	if effectiveChatTopic != "" {
		resolved.MainTopic = effectiveChatTopic
	} else if !intentOverriddenByChat {
		resolved.MainTopic = dbTopic
	}

	if len(chatTags) > 0 {
		resolved.SpecificTags = chatTags
	} else if !intentOverriddenByChat && chatGoal == "" && effectiveChatTopic == "" {
		resolved.SpecificTags = dbQuizTags
	}

	if chatBudget != "" {
		resolved.BudgetTier = chatBudget
	} else if !intentOverriddenByChat {
		resolved.BudgetTier = dbBudget
	}

	return resolved
}

func resolveMatchedProblemTags(signals MatchSignals, tagBySlug map[string]repository.ProblemTag) []string {
	if len(signals.SpecificTags) > 0 {
		if normalized := normalizeProblemTagList(signals.SpecificTags, tagBySlug); len(normalized) > 0 {
			return normalized
		}
	}

	goalTags := extractTagsFromGoalSummary(signals.UserGoalSummary, tagBySlug)
	if len(goalTags) > 0 {
		return goalTags
	}

	var derived []string
	switch signals.MainTopic {
	case "debt_cashflow":
		if signals.BudgetTier == "medium" || signals.BudgetTier == "high" {
			derived = []string{"restrukturisasi_utang", "pinjol", "cashflow"}
		} else {
			derived = []string{"pinjol", "cashflow", "pemetaan_utang"}
		}
	case "investment":
		derived = []string{"reksadana", "saham"}
	case "emergency_insurance":
		if signals.BudgetTier == "medium" || signals.BudgetTier == "high" {
			derived = []string{"dana_darurat", "asuransi"}
		} else {
			derived = []string{"dana_darurat"}
		}
	case "house_wedding":
		if signals.Target == "couple" || signals.Target == "family" {
			derived = []string{"budget_nikah"}
		} else {
			derived = []string{"kpr"}
		}
	case "education":
		if signals.Target == "couple" || signals.Target == "family" {
			derived = []string{"budget_nikah", "reksadana"}
		} else {
			derived = []string{"reksadana"}
		}
	case "sme":
		if signals.BudgetTier == "high" {
			derived = []string{"runway_usaha"}
		} else {
			derived = []string{"kas_bisnis"}
		}
	case "retirement":
		derived = []string{"fire_pensiun"}
	default:
		switch signals.Target {
		case "couple", "family":
			derived = []string{"budget_nikah"}
		case "business":
			derived = []string{"kas_bisnis"}
		}
	}

	return filterExistingTagSlugs(derived, tagBySlug)
}

func normalizeProblemTagList(rawTags []string, tagBySlug map[string]repository.ProblemTag) []string {
	seen := make(map[string]struct{})
	out := make([]string, 0, len(rawTags))

	add := func(slug string) {
		if slug == "" {
			return
		}
		if _, exists := tagBySlug[slug]; !exists {
			return
		}
		if _, dup := seen[slug]; dup {
			return
		}
		seen[slug] = struct{}{}
		out = append(out, slug)
	}

	for _, raw := range rawTags {
		cleaned := strings.ToLower(strings.TrimSpace(strings.TrimPrefix(raw, "#")))
		if cleaned == "" {
			continue
		}
		if _, ok := tagBySlug[cleaned]; ok {
			add(cleaned)
			continue
		}
		matchedLabel := false
		for slug, pt := range tagBySlug {
			labelClean := strings.ToLower(strings.TrimSpace(strings.TrimPrefix(pt.Label, "#")))
			if cleaned == labelClean || strings.Contains(labelClean, cleaned) {
				add(slug)
				matchedLabel = true
			}
		}
		if matchedLabel {
			continue
		}
		for _, slug := range extractTagsFromGoalSummary(cleaned, tagBySlug) {
			add(slug)
		}
	}
	return out
}

func extractTagsFromGoalSummary(text string, tagBySlug map[string]repository.ProblemTag) []string {
	lower := strings.ToLower(strings.TrimSpace(text))
	if lower == "" {
		return nil
	}
	type rule struct {
		slug     string
		keywords []string
	}
	rules := []rule{
		{slug: "budget_nikah", keywords: []string{"nikah", "pranikah", "pre-marriage", "pasutri", "tunangan", "rekening bersama", "pasangan"}},
		{slug: "runway_usaha", keywords: []string{"runway", "burn rate", "startup", "investor", "valuasi", "unit economics"}},
		{slug: "fire_pensiun", keywords: []string{"fire", "pensiun", "kebebasan finansial", "financial freedom", "passive income", "waris"}},
		{slug: "pinjol", keywords: []string{"pinjol", "paylater", "galbay"}},
		{slug: "restrukturisasi_utang", keywords: []string{"restrukturisasi", "negosiasi utang", "kreditur"}},
		{slug: "pemetaan_utang", keywords: []string{"pemetaan utang", "cicilan", "hutang", "utang", "kartu kredit"}},
		{slug: "cashflow", keywords: []string{"cashflow", "arus kas", "gaji habis", "bocor", "budget"}},
		{slug: "dana_darurat", keywords: []string{"dana darurat", "emergency"}},
		{slug: "kpr", keywords: []string{"kpr", "beli rumah", "dp rumah", "properti"}},
		{slug: "pajak", keywords: []string{"pajak", "spt", "pph", "pkp", "npwp"}},
		{slug: "asuransi", keywords: []string{"asuransi", "unitlink", "polis", "proteksi"}},
		{slug: "saham", keywords: []string{"saham", "dividen", "ihsg"}},
		{slug: "reksadana", keywords: []string{"reksadana", "reksa dana", "sbn", "obligasi", "portofolio", "investasi"}},
		{slug: "crypto", keywords: []string{"crypto", "kripto", "bitcoin", "web3"}},
		{slug: "kas_bisnis", keywords: []string{"umkm", "toko", "warung", "pembukuan", "hpp", "kas usaha", "bisnis", "usaha"}},
	}

	seen := make(map[string]struct{})
	var matched []string
	for _, r := range rules {
		if _, exists := tagBySlug[r.slug]; !exists {
			continue
		}
		for _, kw := range r.keywords {
			if strings.Contains(lower, kw) {
				if _, dup := seen[r.slug]; !dup {
					seen[r.slug] = struct{}{}
					matched = append(matched, r.slug)
				}
				break
			}
		}
	}
	return matched
}

func filterExistingTagSlugs(slugs []string, tagBySlug map[string]repository.ProblemTag) []string {
	out := make([]string, 0, len(slugs))
	seen := make(map[string]struct{}, len(slugs))
	for _, slug := range slugs {
		if _, ok := tagBySlug[slug]; !ok {
			continue
		}
		if _, dup := seen[slug]; dup {
			continue
		}
		seen[slug] = struct{}{}
		out = append(out, slug)
	}
	return out
}

func selectBestCatalogPackage(
	signals MatchSignals,
	matchedTags []string,
	tagBySlug map[string]repository.ProblemTag,
	catalogPkgs []repository.CatalogPackage,
) (repository.CatalogPackage, int) {
	goalLower := strings.ToLower(signals.UserGoalSummary)

	serviceCategory := "individual"
	switch {
	case signals.Target == "corporate" || signals.MainTopic == "corporate" ||
		containsAny(goalLower, "korporasi", "karyawan", "hrd", "townhall", "perusahaan"):
		serviceCategory = "corporate"
	case signals.Target == "business" || signals.MainTopic == "sme" ||
		containsAnyTag(matchedTags, "kas_bisnis", "runway_usaha") ||
		containsAny(goalLower, "umkm", "toko", "warung", "pembukuan", "hpp", "startup", "runway", "burn rate"):
		serviceCategory = "umkm"
	case signals.Target == "couple" || signals.Target == "family" ||
		containsAnyTag(matchedTags, "budget_nikah") ||
		containsAny(goalLower, "nikah", "pranikah", "pasutri", "suami", "istri", "pasangan", "keluarga"):
		serviceCategory = "couple"
	case signals.MainTopic == "financial_checkup" ||
		containsAny(goalLower, "check-up", "checkup", "check up", "mcu keuangan", "skor keuangan", "audit polis"):
		serviceCategory = "financial_checkup"
	}

	minRank := 1
	for _, slug := range matchedTags {
		if pt, ok := tagBySlug[slug]; ok {
			if r := tierRank(pt.MinTier); r > minRank {
				minRank = r
			}
		}
	}
	switch signals.MainTopic {
	case "investment", "house_wedding", "education":
		if minRank < 2 {
			minRank = 2
		}
	case "retirement":
		if minRank < 3 {
			minRank = 3
		}
	}

	desiredRank := minRank
	switch signals.BudgetTier {
	case "high":
		if desiredRank < 3 {
			desiredRank = 3
		}
	case "medium":
		if desiredRank < 2 {
			desiredRank = 2
		}
	}

	targetTier := "basic"
	if serviceCategory == "couple" {
		isPreMarriage := signals.MainTopic == "house_wedding" ||
			containsAny(goalLower, "nikah", "pranikah", "pre-marriage", "tunangan", "sebelum akad")
		switch {
		case isPreMarriage && signals.Target != "family":
			targetTier = "pre_marriage"
			if minRank < 2 {
				minRank = 2
			}
		case desiredRank >= 3 && (signals.MainTopic == "retirement" || containsAny(goalLower, "waris", "hibah", "lintas generasi", "eksekutif") || signals.BudgetTier == "high"):
			targetTier = "premium"
			if minRank < 3 {
				minRank = 3
			}
		default:
			targetTier = "marriage"
			if minRank < 2 {
				minRank = 2
			}
		}
	} else {
		switch {
		case desiredRank >= 3:
			targetTier = "premium"
			if minRank < 3 && signals.BudgetTier == "high" {
				minRank = 3
			}
		case desiredRank == 2:
			targetTier = "medium"
			if minRank < 2 && signals.BudgetTier == "medium" {
				minRank = 2
			}
		default:
			targetTier = "basic"
		}
	}

	for _, cp := range catalogPkgs {
		if cp.ServiceCategory == serviceCategory && cp.Tier == targetTier {
			return cp, minRank
		}
	}
	for _, cp := range catalogPkgs {
		if cp.ServiceCategory == serviceCategory {
			return cp, minRank
		}
	}
	return catalogPkgs[0], minRank
}

func groupPractitionerBundles(rows []repository.ListVerifiedPractitionersWithPackagesRow) []practitionerBundle {
	order := make([]uuid.UUID, 0, 8)
	byID := make(map[uuid.UUID]*practitionerBundle)

	for _, r := range rows {
		b, ok := byID[r.PractitionerID]
		if !ok {
			b = &practitionerBundle{
				id:                     r.PractitionerID,
				code:                   PractitionerCodeFromUUID(r.PractitionerID),
				displayName:            r.DisplayName,
				titleHeadline:          r.TitleHeadline,
				bio:                    r.Bio,
				city:                   r.City,
				tier:                   r.PractitionerTier,
				clientsHandledCount:    r.ClientsHandledCount,
				certifications:         r.Certifications,
				specializations:        r.Specializations,
				languages:              r.Languages,
				supportedMethods:       r.SupportedMethods,
				gender:                 r.Gender,
				birthYear:              r.BirthYear,
				consultingStyle:        r.ConsultingStyle,
				yearsOfExperience:      r.YearsOfExperience,
				isFullyBooked:          r.IsFullyBooked,
				ratingAvg:              float64(r.RatingAvg),
				reviewCount:            r.ReviewCount,
				totalSessionsCompleted: r.TotalSessionsCompleted,
				avatarURL:              r.AvatarUrl,
			}
			byID[r.PractitionerID] = b
			order = append(order, r.PractitionerID)
		}
		b.packages = append(b.packages, repository.PractitionerPackage{
			ID:               r.PackageID,
			PractitionerID:   r.PractitionerID,
			CatalogPackageID: r.CatalogPackageID,
			ServiceCategory:  r.ServiceCategory,
			CategoryTag:      r.CategoryTag,
			Tier:             r.PackageTier,
			PackageTitle:     r.PackageTitle,
			DurationMinutes:  r.DurationMinutes,
			OnlinePriceIdr:   r.OnlinePriceIdr,
			OfflinePriceIdr:  r.OfflinePriceIdr,
			IsOnlineActive:   r.IsOnlineActive,
			IsOfflineActive:  r.IsOfflineActive,
			IsActive:         true,
		})
	}

	out := make([]practitionerBundle, 0, len(order))
	for _, id := range order {
		out = append(out, *byID[id])
	}
	return out
}

func (t *MatchingTool) loadOpenSlots14Days(
	ctx context.Context,
	pracIDs []uuid.UUID,
	nowWIB, rangeStart, rangeEnd time.Time,
) (map[uuid.UUID][]slotWindow, error) {
	result := make(map[uuid.UUID][]slotWindow, len(pracIDs))
	if len(pracIDs) == 0 {
		return result, nil
	}

	availRows, err := t.store.ListActiveAvailabilityByPractitioners(ctx, pracIDs)
	if err != nil {
		return nil, fmt.Errorf("list practitioner availability: %w", err)
	}
	holds, err := t.store.ListActiveSlotHoldsInRangeAt(ctx, repository.ListActiveSlotHoldsInRangeAtParams{
		PractitionerIds: pracIDs,
		AtTime:          nowWIB,
		RangeStart:      rangeStart,
		RangeEnd:        rangeEnd,
	})
	if err != nil {
		return nil, fmt.Errorf("list active slot holds: %w", err)
	}
	sessions, err := t.store.ListBlockingSessionsInRange(ctx, repository.ListBlockingSessionsInRangeParams{
		PractitionerIds: pracIDs,
		RangeStart:      rangeStart,
		RangeEnd:        rangeEnd,
	})
	if err != nil {
		return nil, fmt.Errorf("list blocking sessions: %w", err)
	}

	availByPrac := make(map[uuid.UUID][]repository.PractitionerAvailability, len(pracIDs))
	for _, av := range availRows {
		if !av.IsActive || !av.StartTimeWib.Valid || !av.EndTimeWib.Valid || av.EndTimeWib.Microseconds <= av.StartTimeWib.Microseconds {
			continue
		}
		availByPrac[av.PractitionerID] = append(availByPrac[av.PractitionerID], av)
	}

	blockedByPrac := make(map[uuid.UUID][]timeInterval, len(pracIDs))
	for _, h := range holds {
		blockedByPrac[h.PractitionerID] = append(blockedByPrac[h.PractitionerID], timeInterval{
			start: h.SlotStartAt,
			end:   h.SlotEndAt,
		})
	}
	for _, s := range sessions {
		blockedByPrac[s.PractitionerID] = append(blockedByPrac[s.PractitionerID], timeInterval{
			start: s.ScheduledStartAt,
			end:   s.ScheduledEndAt,
		})
	}

	for _, id := range pracIDs {
		avails := availByPrac[id]
		if len(avails) == 0 {
			continue
		}
		blocked := blockedByPrac[id]
		var openSlots []slotWindow
		for dayOffset := 0; dayOffset <= 14; dayOffset++ {
			dayDate := time.Date(nowWIB.Year(), nowWIB.Month(), nowWIB.Day()+dayOffset, 0, 0, 0, 0, t.jakartaLoc)
			dow := int32(dayDate.Weekday())
			for _, av := range avails {
				if av.DayOfWeek != dow {
					continue
				}
				slotStart := combineDateAndPgTime(dayDate, av.StartTimeWib, t.jakartaLoc)
				slotEnd := combineDateAndPgTime(dayDate, av.EndTimeWib, t.jakartaLoc)
				if slotStart.Before(rangeStart) || !slotStart.Before(rangeEnd) {
					continue
				}
				if hasIntervalOverlap(slotStart, slotEnd, blocked) {
					continue
				}
				openSlots = append(openSlots, slotWindow{
					start: slotStart,
					end:   slotEnd,
					day:   dow,
				})
			}
		}
		sort.Slice(openSlots, func(i, j int) bool {
			return openSlots[i].start.Before(openSlots[j].start)
		})
		result[id] = openSlots
	}

	return result, nil
}

func combineDateAndPgTime(day time.Time, pgTime pgtype.Time, loc *time.Location) time.Time {
	h := int(pgTime.Microseconds / 3_600_000_000)
	m := int((pgTime.Microseconds % 3_600_000_000) / 60_000_000)
	s := int((pgTime.Microseconds % 60_000_000) / 1_000_000)
	return time.Date(day.Year(), day.Month(), day.Day(), h, m, s, 0, loc)
}

func hasIntervalOverlap(start, end time.Time, intervals []timeInterval) bool {
	for _, iv := range intervals {
		if start.Before(iv.end) && end.After(iv.start) {
			return true
		}
	}
	return false
}

type pinRank struct {
	tagIndex      int
	priorityOrder int
}

func (p pinRank) less(other pinRank) bool {
	if p.tagIndex != other.tagIndex {
		return p.tagIndex < other.tagIndex
	}
	return p.priorityOrder < other.priorityOrder
}

func filterStep1TagAndTopic(
	candidates []practitionerBundle,
	matchedTags []string,
	signals MatchSignals,
	serviceCategory string,
	pinsByPrac map[uuid.UUID]pinRank,
) []practitionerBundle {
	if len(matchedTags) == 0 && signals.MainTopic == "" {
		return candidates
	}

	matched := make([]practitionerBundle, 0, len(candidates))
	for _, p := range candidates {
		if _, pinned := pinsByPrac[p.id]; pinned {
			matched = append(matched, p)
			continue
		}
		tagMatched := false
		for _, slug := range matchedTags {
			if practitionerMatchesTagKeywords(p, slug) {
				tagMatched = true
				break
			}
		}
		if tagMatched {
			matched = append(matched, p)
			continue
		}
		if len(matchedTags) == 0 && practitionerHasServiceCategory(p, serviceCategory) {
			matched = append(matched, p)
		}
	}

	if len(matched) == 0 && len(pinsByPrac) == 0 {
		// Unpinned niche tag fallback within the target service_category only.
		var catFallback []practitionerBundle
		for _, p := range candidates {
			if practitionerHasServiceCategory(p, serviceCategory) {
				catFallback = append(catFallback, p)
			}
		}
		if len(catFallback) > 0 {
			return catFallback
		}
	}

	return matched
}

func applySoftLanguageAndGenderFilters(candidates []practitionerBundle, signals MatchSignals) []practitionerBundle {
	out := candidates

	if langs := cleanNonFlexible(signals.Languages); len(langs) > 0 {
		var langFiltered []practitionerBundle
		for _, p := range out {
			if practitionerSpeaksAny(p, langs) {
				langFiltered = append(langFiltered, p)
			}
		}
		if len(langFiltered) > 0 {
			out = langFiltered
		}
	}

	if signals.Gender == "male" || signals.Gender == "female" {
		var genderFiltered []practitionerBundle
		for _, p := range out {
			if matchesPractitionerGender(p.gender, signals.Gender) {
				genderFiltered = append(genderFiltered, p)
			}
		}
		if len(genderFiltered) > 0 {
			out = genderFiltered
		}
	}

	return out
}

func selectPractitionerPackageForChannel(
	p practitionerBundle,
	recommendedPkg repository.CatalogPackage,
	requiredMinTierRank int,
	method string,
) (repository.PractitionerPackage, bool) {
	if !practitionerSupportsMethodFilter(p, method) {
		return repository.PractitionerPackage{}, false
	}

	var best repository.PractitionerPackage
	found := false

	for _, pkg := range p.packages {
		if pkg.ServiceCategory != recommendedPkg.ServiceCategory {
			continue
		}
		if tierRank(pkg.Tier) < requiredMinTierRank {
			continue
		}
		if recommendedPkg.Code == "couple_pre_marriage" && pkg.Tier != "pre_marriage" {
			continue
		}
		if !packageActiveForMethod(pkg, method) {
			continue
		}

		if pkg.CatalogPackageID != nil && *pkg.CatalogPackageID == recommendedPkg.ID {
			return pkg, true
		}
		if !found || tierRank(pkg.Tier) < tierRank(best.Tier) {
			best = pkg
			found = true
		}
	}
	return best, found
}

func practitionerSupportsMethodFilter(p practitionerBundle, method string) bool {
	hasOnlinePkg := false
	hasOfflinePkg := false
	for _, pkg := range p.packages {
		if pkg.IsOnlineActive {
			hasOnlinePkg = true
		}
		if pkg.IsOfflineActive {
			hasOfflinePkg = true
		}
	}
	supportsOnline := sliceContainsFold(p.supportedMethods, "online") && hasOnlinePkg
	supportsOffline := (sliceContainsFold(p.supportedMethods, "offline") || sliceContainsFold(p.supportedMethods, "tatap muka")) && hasOfflinePkg

	switch method {
	case "offline":
		return supportsOffline
	case "both":
		return supportsOnline || supportsOffline
	default:
		return supportsOnline
	}
}

func packageActiveForMethod(pkg repository.PractitionerPackage, method string) bool {
	onlineOK := pkg.IsOnlineActive && (pkg.OnlinePriceIdr == nil || *pkg.OnlinePriceIdr > 0)
	offlineOK := pkg.IsOfflineActive && (pkg.OfflinePriceIdr == nil || *pkg.OfflinePriceIdr > 0)

	switch method {
	case "offline":
		return offlineOK
	case "both":
		return onlineOK || offlineOK
	default:
		return onlineOK
	}
}

func findPreferredSlot(slots []slotWindow, sessionTimes []string, loc *time.Location) (slotWindow, bool) {
	preferred := cleanNonFlexible(sessionTimes)
	if len(preferred) == 0 {
		return slotWindow{}, false
	}
	for _, s := range slots {
		h := s.start.In(loc).Hour()
		for _, p := range preferred {
			switch strings.ToLower(p) {
			case "morning", "pagi":
				if h >= 8 && h < 12 {
					return s, true
				}
			case "afternoon", "siang":
				if h >= 12 && h < 17 {
					return s, true
				}
			case "night", "malam", "evening":
				if h >= 17 && h <= 21 {
					return s, true
				}
			}
		}
	}
	return slotWindow{}, false
}

func compareTieBreaker(slotA time.Time, a practitionerBundle, slotB time.Time, b practitionerBundle) bool {
	if !slotA.Equal(slotB) {
		return slotA.Before(slotB)
	}
	if a.ratingAvg != b.ratingAvg {
		return a.ratingAvg > b.ratingAvg
	}
	if a.totalSessionsCompleted != b.totalSessionsCompleted {
		return a.totalSessionsCompleted > b.totalSessionsCompleted
	}
	return a.code < b.code
}

func practitionerMatchesTagKeywords(p practitionerBundle, slug string) bool {
	keywords := map[string][]string{
		"cashflow":              {"arus kas", "cashflow", "budgeting", "fondasi arus kas"},
		"pinjol":                {"pinjol", "paylater", "hutang", "utang"},
		"dana_darurat":          {"dana darurat", "arus kas", "cashflow"},
		"pemetaan_utang":        {"utang", "hutang", "paylater", "cashflow"},
		"restrukturisasi_utang": {"restrukturisasi", "utang", "hutang", "pinjol"},
		"reksadana":             {"reksadana", "reksa dana", "investasi", "portofolio"},
		"saham":                 {"saham", "investasi", "portofolio", "dividen"},
		"kpr":                   {"kpr", "properti", "rumah"},
		"pajak":                 {"pajak", "bkp", "cpa", "spt"},
		"asuransi":              {"asuransi", "proteksi", "unitlink"},
		"budget_nikah":          {"pasangan", "pranikah", "keluarga", "pasutri", "nikah"},
		"kas_bisnis":            {"umkm", "bisnis", "pembukuan", "kas usaha", "audit"},
		"runway_usaha":          {"runway", "startup", "valuasi", "corporate treasury", "umkm"},
		"fire_pensiun":          {"fire", "pensiun", "financial freedom", "wealth", "waris"},
		"crypto":                {"crypto", "web3", "portofolio", "investasi"},
	}

	corpus := strings.ToLower(strings.Join(append(append([]string{}, p.specializations...), p.titleHeadline, p.bio), " "))
	if strings.Contains(corpus, strings.ToLower(slug)) {
		return true
	}
	for _, kw := range keywords[slug] {
		if strings.Contains(corpus, kw) {
			return true
		}
	}
	return false
}

func practitionerMatchesFreeKeyword(p practitionerBundle, query string) bool {
	q := strings.ToLower(strings.TrimSpace(query))
	if q == "" {
		return true
	}
	corpus := strings.ToLower(strings.Join(append(append([]string{}, p.specializations...), p.displayName, p.titleHeadline, p.bio, p.city), " "))
	return strings.Contains(corpus, q)
}

func practitionerHasServiceCategory(p practitionerBundle, serviceCategory string) bool {
	for _, pkg := range p.packages {
		if pkg.ServiceCategory == serviceCategory {
			return true
		}
	}
	return false
}

func practitionerSpeaksAny(p practitionerBundle, requested []string) bool {
	for _, req := range requested {
		normReq := normalizeLanguage(req)
		for _, lang := range p.languages {
			if strings.EqualFold(lang, normReq) || strings.EqualFold(lang, req) {
				return true
			}
		}
	}
	return false
}

func matchesPractitionerGender(dbGender *string, want string) bool {
	if dbGender == nil {
		return false
	}
	lower := strings.ToLower(strings.TrimSpace(*dbGender))
	switch want {
	case "male":
		return lower == "laki-laki" || lower == "male" || lower == "pria"
	case "female":
		return lower == "perempuan" || lower == "female" || lower == "wanita"
	default:
		return true
	}
}

func buildMatchReason(
	p practitionerBundle,
	isPinned bool,
	matchedTags []string,
	tagBySlug map[string]repository.ProblemTag,
	signals MatchSignals,
) string {
	var parts []string
	if len(p.specializations) > 0 {
		parts = append(parts, "Spesialis "+p.specializations[0])
	}
	if len(matchedTags) > 0 {
		if pt, ok := tagBySlug[matchedTags[0]]; ok {
			parts = append(parts, "relevan untuk "+strings.TrimPrefix(pt.Label, "#"))
		}
	}
	if len(signals.ApproachStyle) > 0 && p.consultingStyle != nil && *p.consultingStyle != "" {
		parts = append(parts, "gaya "+strings.ToLower(*p.consultingStyle))
	}
	if isPinned {
		parts = append(parts, "pilihan kurasi Clarafin")
	}
	if len(parts) == 0 {
		return fmt.Sprintf("Praktisi terverifikasi tier %s dengan %d sesi selesai", formatTierTitle(p.tier), p.totalSessionsCompleted)
	}
	return strings.Join(parts, ", ")
}

func buildPrefilledIntakeSummary(
	signals MatchSignals,
	matchedTags []string,
	pkg repository.CatalogPackage,
) PrefilledIntakeSummary {
	topicSet := make(map[string]struct{})
	var topics []string
	addTopic := func(t string) {
		if _, ok := topicSet[t]; !ok && len(topics) < 4 {
			topicSet[t] = struct{}{}
			topics = append(topics, t)
		}
	}

	for _, slug := range matchedTags {
		switch slug {
		case "budget_nikah":
			addTopic("Transparansi Uang Pranikah")
			addTopic("Pos Budgeting Rumah Tangga")
			addTopic("Model Rekening 1 vs 2 Pintu")
		case "pinjol", "pemetaan_utang", "restrukturisasi_utang":
			addTopic("Pelunasan Cicilan & PayLater")
			addTopic("Cashflow Bulanan")
			addTopic("Dana Darurat Pertama")
		case "cashflow":
			addTopic("Cashflow Bulanan")
			addTopic("Action Plan 30 Hari")
		case "dana_darurat":
			addTopic("Dana Darurat Pertama")
			addTopic("Cashflow Bulanan")
		case "reksadana", "saham":
			addTopic("Review Portofolio Investasi")
			addTopic("Alokasi Reksadana & SBN")
			addTopic("Strategi DCA Saham")
		case "kpr":
			addTopic("Simulasi Kelayakan KPR")
			addTopic("Kalkulasi DP Rumah Pertama")
			addTopic("Strategi Lunas KPR Cepat")
		case "pajak":
			addTopic("Kepatuhan SPT Tahunan")
			addTopic("Efisiensi Pajak Penghasilan")
			addTopic("Pajak UMKM & Usaha")
		case "asuransi":
			addTopic("Audit Polis Asuransi")
			addTopic("Proteksi Penghasilan Keluarga")
		case "kas_bisnis":
			addTopic("Pisah Rekening Usaha & Pribadi")
			addTopic("Hitung HPP & Margin Bersih")
			addTopic("Dana Cadangan Operasional")
		case "runway_usaha":
			addTopic("Pengendalian Burn Rate & Runway")
			addTopic("Unit Economics CAC/LTV")
		case "fire_pensiun":
			addTopic("Peta Jalan FIRE (Pensiun Dini)")
			addTopic("Passive Income Dividen/Properti")
		case "crypto":
			addTopic("Audit Portofolio Aset Kripto")
			addTopic("Manajemen Risiko Volatilitas")
		}
	}

	if len(topics) == 0 {
		switch pkg.ServiceCategory {
		case "couple":
			addTopic("Pos Budgeting Rumah Tangga")
			addTopic("Transparansi Uang Pranikah")
			addTopic("Model Rekening 1 vs 2 Pintu")
		case "umkm":
			addTopic("Pisah Rekening Usaha & Pribadi")
			addTopic("Hitung HPP & Margin Bersih")
		case "corporate":
			addTopic("Program Financial Wellness Karyawan")
			addTopic("Corporate Treasury & Likuiditas")
		default:
			addTopic("Cashflow Bulanan")
			addTopic("Dana Darurat Pertama")
			addTopic("Review Portofolio Investasi")
		}
	}

	desc := strings.TrimSpace(signals.UserGoalSummary)
	if desc == "" {
		desc = fmt.Sprintf("Konsultasi %s: %s.", pkg.CategoryTag, pkg.ShortDesc)
	}

	var expParts []string
	for _, o := range signals.Outcomes {
		switch strings.ToLower(strings.TrimSpace(o)) {
		case "action_plan":
			expParts = append(expParts, "Action plan konkret 30 hari yang siap dieksekusi")
		case "debt_free":
			expParts = append(expParts, "Strategi terukur pelunasan cicilan dan utang")
		case "low_risk_portfolio":
			expParts = append(expParts, "Alokasi instrumen investasi terarah sesuai profil risiko")
		case "peace_of_mind":
			expParts = append(expParts, "Kejelasan arah dan rasa aman terhadap rencana keuangan")
		case "specific_goal":
			expParts = append(expParts, "Deteksi pos kebocoran dana dan target terukur")
		}
	}
	expectations := strings.Join(expParts, "; ")
	if expectations == "" {
		expectations = fmt.Sprintf("Mendapatkan rencana aksi terstruktur untuk %s (%s).", pkg.PackageTitle, pkg.CategoryTag)
	}

	return PrefilledIntakeSummary{
		RecommendedTopics:     topics,
		PrefilledDescription:  desc,
		PrefilledExpectations: expectations,
	}
}

func buildPublicPractitionerDTO(
	b practitionerBundle,
	slots []slotWindow,
	nowWIB time.Time,
	loc *time.Location,
	catalogCodeByID map[uuid.UUID]string,
) PublicPractitionerDTO {
	pkgs := make([]PublicPractitionerPackageDTO, 0, len(b.packages))
	var feePerSession int64
	for _, p := range b.packages {
		code := ""
		if p.CatalogPackageID != nil {
			code = catalogCodeByID[*p.CatalogPackageID]
		}
		if p.IsOnlineActive && p.OnlinePriceIdr != nil && *p.OnlinePriceIdr > 0 {
			if feePerSession == 0 || *p.OnlinePriceIdr < feePerSession {
				feePerSession = *p.OnlinePriceIdr
			}
		}
		pkgs = append(pkgs, PublicPractitionerPackageDTO{
			ID:               p.ID,
			CatalogPackageID: p.CatalogPackageID,
			PackageCode:      code,
			ServiceCategory:  p.ServiceCategory,
			CategoryTag:      p.CategoryTag,
			Tier:             p.Tier,
			PackageTitle:     p.PackageTitle,
			DurationMinutes:  p.DurationMinutes,
			OnlinePriceIDR:   p.OnlinePriceIdr,
			OfflinePriceIDR:  p.OfflinePriceIdr,
			IsOnlineActive:   p.IsOnlineActive,
			IsOfflineActive:  p.IsOfflineActive,
		})
	}

	slotDTOs := make([]PublicSlotDTO, 0, len(slots))
	for _, s := range slots {
		slotDTOs = append(slotDTOs, PublicSlotDTO{
			SlotStartISO: s.start.In(loc).Format(time.RFC3339),
			SlotEndISO:   s.end.In(loc).Format(time.RFC3339),
			Label:        formatWIBSlotLabel(s.start, nowWIB, loc),
			DayOfWeek:    s.day,
		})
	}

	var nextLabel, nextISO string
	if len(slotDTOs) > 0 {
		nextLabel = slotDTOs[0].Label
		nextISO = slotDTOs[0].SlotStartISO
	}

	return PublicPractitionerDTO{
		ConsultantID:           b.code,
		PractitionerUUID:       b.id,
		DisplayName:            b.displayName,
		TitleHeadline:          b.titleHeadline,
		Bio:                    b.bio,
		City:                   b.city,
		Tier:                   b.tier,
		ClientsHandledCount:    b.clientsHandledCount,
		Certifications:         nonNilStrings(b.certifications),
		Specializations:        nonNilStrings(b.specializations),
		Languages:              nonNilStrings(b.languages),
		SupportedMethods:       nonNilStrings(b.supportedMethods),
		Gender:                 b.gender,
		BirthYear:              b.birthYear,
		ConsultingStyle:        b.consultingStyle,
		YearsOfExperience:      b.yearsOfExperience,
		IsFullyBooked:          b.isFullyBooked,
		Rating:                 roundRating(b.ratingAvg),
		ReviewCount:            b.reviewCount,
		TotalSessionsCompleted: b.totalSessionsCompleted,
		AvatarURL:              b.avatarURL,
		FeePerSessionIDR:       feePerSession,
		NextAvailableSlotLabel: nextLabel,
		NextAvailableSlotISO:   nextISO,
		Packages:               pkgs,
		UpcomingSlots:          slotDTOs,
	}
}

func formatWIBSlotLabel(slotStart, nowWIB time.Time, loc *time.Location) string {
	s := slotStart.In(loc)
	n := nowWIB.In(loc)
	slotDay := time.Date(s.Year(), s.Month(), s.Day(), 0, 0, 0, 0, loc)
	today := time.Date(n.Year(), n.Month(), n.Day(), 0, 0, 0, 0, loc)
	diffDays := int(slotDay.Sub(today).Hours() / 24)

	switch diffDays {
	case 0:
		return fmt.Sprintf("Hari ini, %s WIB", s.Format("15:04"))
	case 1:
		return fmt.Sprintf("Besok, %s WIB", s.Format("15:04"))
	default:
		return fmt.Sprintf("%s, %d %s %s WIB", indoWeekday(s.Weekday()), s.Day(), indoShortMonth(s.Month()), s.Format("15:04"))
	}
}

func indoWeekday(d time.Weekday) string {
	switch d {
	case time.Sunday:
		return "Min"
	case time.Monday:
		return "Sen"
	case time.Tuesday:
		return "Sel"
	case time.Wednesday:
		return "Rab"
	case time.Thursday:
		return "Kam"
	case time.Friday:
		return "Jum"
	case time.Saturday:
		return "Sab"
	default:
		return ""
	}
}

func indoShortMonth(m time.Month) string {
	months := [...]string{"", "Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des"}
	if int(m) >= 1 && int(m) < len(months) {
		return months[m]
	}
	return m.String()
}

func formatSelectedTierLabel(cp repository.CatalogPackage) string {
	return fmt.Sprintf("%s (%s)", cp.PackageTitle, formatTierTitle(cp.Tier))
}

func formatTierTitle(tier string) string {
	switch strings.ToLower(strings.TrimSpace(tier)) {
	case "basic":
		return "Basic"
	case "medium":
		return "Medium"
	case "premium":
		return "Premium"
	case "pre_marriage":
		return "Pre-Marriage"
	case "marriage":
		return "Marriage"
	default:
		return tier
	}
}

func tierRank(tier string) int {
	switch strings.ToLower(strings.TrimSpace(tier)) {
	case "basic":
		return 1
	case "medium", "pre_marriage", "marriage":
		return 2
	case "premium":
		return 3
	default:
		return 0
	}
}

func normalizeMethod(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "":
		return ""
	case "online", "call", "video", "chat":
		return "online"
	case "offline", "tatap muka", "tatap_muka":
		return "offline"
	case "both", "keduanya":
		return "both"
	default:
		return ""
	}
}

func normalizeTarget(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "":
		return ""
	case "self", "individual", "personal", "individu":
		return "self"
	case "couple", "pasangan", "pranikah", "pre_marriage":
		return "couple"
	case "family", "keluarga":
		return "family"
	case "business", "umkm", "bisnis", "sme":
		return "business"
	case "corporate", "korporasi":
		return "corporate"
	default:
		return ""
	}
}

func normalizeMainTopic(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "":
		return ""
	case "debt_cashflow", "debt", "cashflow", "utang", "pinjol":
		return "debt_cashflow"
	case "investment", "investasi":
		return "investment"
	case "emergency_insurance", "emergency", "insurance", "asuransi":
		return "emergency_insurance"
	case "house_wedding", "kpr", "wedding", "nikah", "pranikah":
		return "house_wedding"
	case "education", "pendidikan":
		return "education"
	case "sme", "umkm", "business", "bisnis":
		return "sme"
	case "retirement", "fire", "pensiun":
		return "retirement"
	case "financial_checkup", "checkup", "tes_finansial":
		return "financial_checkup"
	case "corporate", "korporasi":
		return "corporate"
	default:
		return ""
	}
}

func normalizeBudgetTier(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "":
		return ""
	case "low", "basic":
		return "low"
	case "medium":
		return "medium"
	case "high", "premium":
		return "high"
	case "flexible":
		return "flexible"
	default:
		return ""
	}
}

func normalizeGender(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "":
		return ""
	case "male", "laki-laki", "pria":
		return "male"
	case "female", "perempuan", "wanita":
		return "female"
	case "flexible":
		return "flexible"
	default:
		return ""
	}
}

func normalizeLanguage(raw string) string {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "id", "indonesia", "bahasa indonesia":
		return "Indonesia"
	case "en", "english", "inggris":
		return "Inggris"
	case "zh", "mandarin":
		return "Mandarin"
	case "ar", "arab":
		return "Arab"
	case "jawa":
		return "Jawa"
	default:
		return strings.TrimSpace(raw)
	}
}

func cleanNonEmpty(items []string) []string {
	var out []string
	for _, s := range items {
		if trimmed := strings.TrimSpace(s); trimmed != "" {
			out = append(out, trimmed)
		}
	}
	return out
}

func cleanNonFlexible(items []string) []string {
	var out []string
	for _, s := range items {
		trimmed := strings.TrimSpace(s)
		if trimmed != "" && !strings.EqualFold(trimmed, "flexible") && !strings.EqualFold(trimmed, "fleksibel") {
			out = append(out, trimmed)
		}
	}
	return out
}

func firstNonEmpty(vals ...string) string {
	for _, v := range vals {
		if strings.TrimSpace(v) != "" {
			return strings.TrimSpace(v)
		}
	}
	return ""
}

func firstNonEmptySlice(slices ...[]string) []string {
	for _, s := range slices {
		if len(s) > 0 {
			return s
		}
	}
	return nil
}

func sliceContainsFold(items []string, target string) bool {
	for _, item := range items {
		if strings.EqualFold(strings.TrimSpace(item), target) {
			return true
		}
	}
	return false
}

func containsAny(haystack string, needles ...string) bool {
	for _, n := range needles {
		if strings.Contains(haystack, n) {
			return true
		}
	}
	return false
}

func containsAnyTag(tags []string, candidates ...string) bool {
	for _, t := range tags {
		for _, c := range candidates {
			if t == c {
				return true
			}
		}
	}
	return false
}

func nonNilStrings(s []string) []string {
	if s == nil {
		return []string{}
	}
	return s
}

func roundRating(r float64) float64 {
	return float64(int(r*100+0.5)) / 100
}
