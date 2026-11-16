-- name: ListVerifiedPractitionersWithPackages :many
SELECT
  pp.user_id AS practitioner_id,
  pp.display_name,
  pp.title_headline,
  pp.bio,
  pp.city,
  pp.practitioner_tier,
  pp.clients_handled_count,
  pp.certifications,
  pp.specializations,
  pp.languages,
  pp.supported_methods,
  pp.gender,
  pp.birth_year,
  pp.consulting_style,
  pp.years_of_experience,
  pp.is_fully_booked,
  pp.status,
  pp.rating_avg,
  pp.review_count,
  pp.total_sessions_completed,
  pp.verified_at,
  u.avatar_url,
  pkg.id AS package_id,
  pkg.catalog_package_id,
  pkg.service_category,
  pkg.category_tag,
  pkg.tier AS package_tier,
  pkg.package_title,
  pkg.duration_minutes,
  pkg.online_price_idr,
  pkg.offline_price_idr,
  pkg.is_online_active,
  pkg.is_offline_active
FROM practitioner_profiles pp
JOIN users u ON u.id = pp.user_id
JOIN practitioner_packages pkg
  ON pkg.practitioner_id = pp.user_id
 AND pkg.is_active = TRUE
WHERE pp.status = 'verified'
  AND u.deleted_at IS NULL
ORDER BY pp.rating_avg DESC, pp.total_sessions_completed DESC, pp.user_id ASC, pkg.tier ASC;

-- name: ListActiveAvailabilityByPractitioners :many
SELECT
  id,
  practitioner_id,
  day_of_week,
  start_time_wib,
  end_time_wib,
  is_active
FROM practitioner_availability
WHERE practitioner_id = ANY(sqlc.arg('practitioner_ids')::uuid[])
  AND is_active = TRUE
ORDER BY practitioner_id ASC, day_of_week ASC, start_time_wib ASC;

-- name: ListActiveSlotHoldsInRange :many
SELECT
  id,
  practitioner_id,
  order_id,
  session_id,
  slot_start_at,
  slot_end_at,
  status,
  expires_at,
  created_at
FROM booking_slot_holds
WHERE practitioner_id = ANY(sqlc.arg('practitioner_ids')::uuid[])
  AND (status = 'booked' OR (status = 'held' AND expires_at > NOW()))
  AND slot_end_at > sqlc.arg('range_start')::timestamptz
  AND slot_start_at < sqlc.arg('range_end')::timestamptz
ORDER BY practitioner_id ASC, slot_start_at ASC;

-- name: ListStaffPinsByTagSlug :many
SELECT
  pt.id AS problem_tag_id,
  pt.slug AS tag_slug,
  pt.label AS tag_label,
  pt.min_tier,
  spp.practitioner_id,
  spp.priority_order
FROM staff_practitioner_pins spp
JOIN problem_tags pt ON pt.id = spp.problem_tag_id
JOIN practitioner_profiles pp ON pp.user_id = spp.practitioner_id
WHERE pt.slug = $1
  AND pt.is_active = TRUE
  AND pp.status = 'verified'
ORDER BY spp.priority_order ASC;

-- name: ListStaffPinsByTagSlugs :many
SELECT
  pt.id AS problem_tag_id,
  pt.slug AS tag_slug,
  pt.label AS tag_label,
  pt.min_tier,
  spp.practitioner_id,
  spp.priority_order
FROM staff_practitioner_pins spp
JOIN problem_tags pt ON pt.id = spp.problem_tag_id
JOIN practitioner_profiles pp ON pp.user_id = spp.practitioner_id
WHERE pt.slug = ANY(sqlc.arg('tag_slugs')::text[])
  AND pt.is_active = TRUE
  AND pp.status = 'verified'
ORDER BY pt.slug ASC, spp.priority_order ASC;

-- name: ListCatalogPackages :many
SELECT
  id, code, service_category, category_tag, tier, participant_type,
  package_title, short_desc, full_desc, features,
  online_duration_minutes, offline_duration_minutes,
  base_online_price_idr, max_online_price_idr,
  base_offline_price_idr, max_offline_price_idr,
  is_active, created_at, updated_at
FROM catalog_packages
WHERE is_active = TRUE
ORDER BY service_category ASC, base_online_price_idr ASC;

-- name: ListProblemTags :many
SELECT id, slug, label, min_tier, is_active
FROM problem_tags
WHERE is_active = TRUE
ORDER BY slug ASC;

-- name: ListActiveVenues :many
SELECT id, name, city, address, maps_url, is_active, created_at
FROM venues
WHERE is_active = TRUE
ORDER BY city ASC, name ASC;

-- name: ListActiveVouchers :many
SELECT
  id, code, title, description, category, discount_type, discount_value,
  max_discount_idr, min_transaction_idr, valid_until, usage_limit, is_active, created_at
FROM vouchers
WHERE is_active = TRUE
  AND valid_until > NOW()
ORDER BY code ASC;

-- name: CreateMatchExpertSubmission :one
INSERT INTO match_expert_submissions (
  user_id,
  answers_json,
  top_practitioner_ids
) VALUES (
  $1, $2, $3
)
RETURNING id, user_id, answers_json, top_practitioner_ids, created_at;

-- name: ListActiveSlotHoldsInRangeAt :many
SELECT
  id,
  practitioner_id,
  order_id,
  session_id,
  slot_start_at,
  slot_end_at,
  status,
  expires_at,
  created_at
FROM booking_slot_holds
WHERE practitioner_id = ANY(sqlc.arg('practitioner_ids')::uuid[])
  AND (status = 'booked' OR (status = 'held' AND expires_at > sqlc.arg('at_time')::timestamptz))
  AND slot_end_at > sqlc.arg('range_start')::timestamptz
  AND slot_start_at < sqlc.arg('range_end')::timestamptz
ORDER BY practitioner_id ASC, slot_start_at ASC;

-- name: ListBlockingSessionsInRange :many
SELECT
  id,
  practitioner_id,
  scheduled_start_at,
  scheduled_end_at,
  status
FROM sessions
WHERE practitioner_id = ANY(sqlc.arg('practitioner_ids')::uuid[])
  AND status IN ('waiting_partner', 'waiting_payment', 'scheduled', 'ongoing')
  AND scheduled_end_at > sqlc.arg('range_start')::timestamptz
  AND scheduled_start_at < sqlc.arg('range_end')::timestamptz
ORDER BY practitioner_id ASC, scheduled_start_at ASC;

-- name: GetPublicPractitionerByID :one
SELECT
  pp.user_id AS practitioner_id,
  pp.display_name,
  pp.title_headline,
  pp.bio,
  pp.city,
  pp.practitioner_tier,
  pp.clients_handled_count,
  pp.certifications,
  pp.specializations,
  pp.languages,
  pp.supported_methods,
  pp.gender,
  pp.birth_year,
  pp.consulting_style,
  pp.years_of_experience,
  pp.is_fully_booked,
  pp.status,
  pp.rating_avg,
  pp.review_count,
  pp.total_sessions_completed,
  pp.verified_at,
  u.avatar_url
FROM practitioner_profiles pp
JOIN users u ON u.id = pp.user_id
WHERE pp.user_id = $1
  AND pp.status = 'verified'
  AND u.deleted_at IS NULL;

-- name: ListActivePackagesByPractitioner :many
SELECT
  id,
  practitioner_id,
  catalog_package_id,
  service_category,
  category_tag,
  tier,
  package_title,
  duration_minutes,
  online_price_idr,
  offline_price_idr,
  is_online_active,
  is_offline_active,
  is_active,
  created_at,
  updated_at
FROM practitioner_packages
WHERE practitioner_id = $1
  AND is_active = TRUE
ORDER BY tier ASC, service_category ASC, id ASC;

-- name: ListPublicReviewsByPractitioner :many
SELECT
  sr.session_id,
  sr.rating,
  sr.comment,
  sr.is_anonymized,
  CASE
    WHEN sr.is_anonymized THEN 'Klien Clarafin'
    ELSE COALESCE(NULLIF(TRIM(u.full_name), ''), 'Klien Clarafin')
  END::text AS reviewer_name,
  sr.created_at
FROM session_reviews sr
JOIN sessions s ON s.id = sr.session_id
JOIN users u ON u.id = sr.reviewer_user_id
WHERE s.practitioner_id = $1
ORDER BY sr.created_at DESC
LIMIT $2;
