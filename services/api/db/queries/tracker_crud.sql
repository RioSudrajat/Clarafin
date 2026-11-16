-- name: EnsureDevUser :one
INSERT INTO users (id, email, full_name)
VALUES ($1, $2, $3)
ON CONFLICT (id) DO UPDATE SET
  full_name = COALESCE(NULLIF(users.full_name, ''), EXCLUDED.full_name),
  updated_at = NOW()
RETURNING id, email, full_name, birth_date, phone, avatar_url, selected_avatar_index, monthly_budget_limit, onboarding_completed, created_at, updated_at, deleted_at;

-- name: EnsureUserPreferences :one
INSERT INTO user_preferences (user_id)
VALUES ($1)
ON CONFLICT (user_id) DO UPDATE SET
  user_id = EXCLUDED.user_id
RETURNING user_id, notifications_enabled, session_reminders_enabled, bill_reminders_enabled, promo_alerts_enabled, daily_reminder_enabled, daily_reminder_time_wib, tracking_history_source, tracker_focuses, advisory_focuses, biometric_enabled, pin_hash, preferred_currency, preferred_language, updated_at;

-- name: GetUserProfileByID :one
SELECT
  id, email, full_name, birth_date, phone, avatar_url,
  selected_avatar_index, monthly_budget_limit, onboarding_completed,
  created_at, updated_at, deleted_at
FROM users
WHERE id = $1
  AND deleted_at IS NULL;

-- name: GetUserPreferences :one
SELECT
  user_id, notifications_enabled, session_reminders_enabled, bill_reminders_enabled,
  promo_alerts_enabled, daily_reminder_enabled, daily_reminder_time_wib,
  tracking_history_source, tracker_focuses, advisory_focuses,
  biometric_enabled, pin_hash, preferred_currency, preferred_language, updated_at
FROM user_preferences
WHERE user_id = $1;

-- name: UpdateUserProfile :one
UPDATE users
SET
  full_name = COALESCE(sqlc.narg('full_name')::text, full_name),
  birth_date = COALESCE(sqlc.narg('birth_date')::date, birth_date),
  phone = COALESCE(sqlc.narg('phone')::text, phone),
  avatar_url = COALESCE(sqlc.narg('avatar_url')::text, avatar_url),
  selected_avatar_index = COALESCE(sqlc.narg('selected_avatar_index')::integer, selected_avatar_index),
  monthly_budget_limit = COALESCE(sqlc.narg('monthly_budget_limit')::bigint, monthly_budget_limit),
  onboarding_completed = COALESCE(sqlc.narg('onboarding_completed')::boolean, onboarding_completed),
  updated_at = NOW()
WHERE id = sqlc.arg('user_id')
  AND deleted_at IS NULL
RETURNING id, email, full_name, birth_date, phone, avatar_url, selected_avatar_index, monthly_budget_limit, onboarding_completed, created_at, updated_at, deleted_at;

-- name: UpsertUserPreferences :one
INSERT INTO user_preferences (
  user_id,
  notifications_enabled,
  session_reminders_enabled,
  bill_reminders_enabled,
  promo_alerts_enabled,
  daily_reminder_enabled,
  daily_reminder_time_wib,
  tracking_history_source,
  tracker_focuses,
  advisory_focuses,
  biometric_enabled,
  preferred_currency,
  preferred_language
) VALUES (
  $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13
)
ON CONFLICT (user_id) DO UPDATE SET
  notifications_enabled = EXCLUDED.notifications_enabled,
  session_reminders_enabled = EXCLUDED.session_reminders_enabled,
  bill_reminders_enabled = EXCLUDED.bill_reminders_enabled,
  promo_alerts_enabled = EXCLUDED.promo_alerts_enabled,
  daily_reminder_enabled = EXCLUDED.daily_reminder_enabled,
  daily_reminder_time_wib = EXCLUDED.daily_reminder_time_wib,
  tracking_history_source = EXCLUDED.tracking_history_source,
  tracker_focuses = EXCLUDED.tracker_focuses,
  advisory_focuses = EXCLUDED.advisory_focuses,
  biometric_enabled = EXCLUDED.biometric_enabled,
  preferred_currency = EXCLUDED.preferred_currency,
  preferred_language = EXCLUDED.preferred_language,
  updated_at = NOW()
RETURNING user_id, notifications_enabled, session_reminders_enabled, bill_reminders_enabled, promo_alerts_enabled, daily_reminder_enabled, daily_reminder_time_wib, tracking_history_source, tracker_focuses, advisory_focuses, biometric_enabled, pin_hash, preferred_currency, preferred_language, updated_at;

-- name: ListCategories :many
SELECT
  id, slug, name, parent_id, group_name, type, emoji, icon_key,
  color_hex, bg_color_hex, sort_order, is_active, created_at, updated_at
FROM categories
WHERE is_active = TRUE
ORDER BY sort_order ASC, name ASC;

-- name: GetCategoryBySlug :one
SELECT
  id, slug, name, parent_id, group_name, type, emoji, icon_key,
  color_hex, bg_color_hex, sort_order, is_active, created_at, updated_at
FROM categories
WHERE slug = $1
  AND is_active = TRUE;

-- name: CreateWallet :one
INSERT INTO wallets (
  user_id,
  name,
  type,
  institution_code,
  account_number_masked,
  balance,
  is_auto_sync,
  custom_color_hex,
  return_percentage,
  dividend_drop_date,
  is_volatile,
  has_claimed_dividend
) VALUES (
  $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12
)
RETURNING id, user_id, name, type, institution_code, account_number_masked, balance, is_auto_sync, custom_color_hex, return_percentage, dividend_drop_date, is_volatile, has_claimed_dividend, is_archived, created_at, updated_at;

-- name: GetWalletByID :one
SELECT
  id, user_id, name, type, institution_code, account_number_masked,
  balance, is_auto_sync, custom_color_hex, return_percentage,
  dividend_drop_date, is_volatile, has_claimed_dividend, is_archived,
  created_at, updated_at
FROM wallets
WHERE user_id = $1
  AND id = $2;

-- name: UpdateWallet :one
UPDATE wallets
SET
  name = COALESCE(sqlc.narg('name')::text, name),
  type = COALESCE(sqlc.narg('type')::text, type),
  institution_code = COALESCE(sqlc.narg('institution_code')::text, institution_code),
  account_number_masked = COALESCE(sqlc.narg('account_number_masked')::text, account_number_masked),
  is_auto_sync = COALESCE(sqlc.narg('is_auto_sync')::boolean, is_auto_sync),
  custom_color_hex = COALESCE(sqlc.narg('custom_color_hex')::text, custom_color_hex),
  return_percentage = COALESCE(sqlc.narg('return_percentage')::real, return_percentage),
  dividend_drop_date = COALESCE(sqlc.narg('dividend_drop_date')::timestamptz, dividend_drop_date),
  is_volatile = COALESCE(sqlc.narg('is_volatile')::boolean, is_volatile),
  has_claimed_dividend = COALESCE(sqlc.narg('has_claimed_dividend')::boolean, has_claimed_dividend),
  is_archived = COALESCE(sqlc.narg('is_archived')::boolean, is_archived),
  updated_at = NOW()
WHERE user_id = sqlc.arg('user_id')
  AND id = sqlc.arg('id')
RETURNING id, user_id, name, type, institution_code, account_number_masked, balance, is_auto_sync, custom_color_hex, return_percentage, dividend_drop_date, is_volatile, has_claimed_dividend, is_archived, created_at, updated_at;

-- name: UpdateWalletBalanceDelta :one
UPDATE wallets
SET
  balance = balance + sqlc.arg('delta')::bigint,
  updated_at = NOW()
WHERE user_id = sqlc.arg('user_id')
  AND id = sqlc.arg('id')
  AND is_archived = FALSE
RETURNING id, user_id, name, type, institution_code, account_number_masked, balance, is_auto_sync, custom_color_hex, return_percentage, dividend_drop_date, is_volatile, has_claimed_dividend, is_archived, created_at, updated_at;

-- name: ArchiveWallet :one
UPDATE wallets
SET
  is_archived = TRUE,
  updated_at = NOW()
WHERE user_id = $1
  AND id = $2
RETURNING id, user_id, name, type, institution_code, account_number_masked, balance, is_auto_sync, custom_color_hex, return_percentage, dividend_drop_date, is_volatile, has_claimed_dividend, is_archived, created_at, updated_at;

-- name: DeleteWallet :execrows
DELETE FROM wallets
WHERE user_id = $1
  AND id = $2;

-- name: InsertTransactionIdempotent :one
INSERT INTO transactions (
  user_id,
  wallet_id,
  destination_wallet_id,
  target_goal_id,
  category_id,
  type,
  category,
  amount,
  title,
  note,
  occurred_at,
  source,
  client_mutation_id
) VALUES (
  $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13
)
ON CONFLICT (user_id, client_mutation_id) WHERE client_mutation_id IS NOT NULL DO NOTHING
RETURNING id, user_id, wallet_id, destination_wallet_id, target_goal_id, category_id, type, category, amount, title, note, occurred_at, source, client_mutation_id, created_at;

-- name: GetTransactionByID :one
SELECT
  id, user_id, wallet_id, destination_wallet_id, target_goal_id, category_id,
  type, category, amount, title, note, occurred_at, source, client_mutation_id, created_at
FROM transactions
WHERE user_id = $1
  AND id = $2;

-- name: GetTransactionByClientMutationID :one
SELECT
  id, user_id, wallet_id, destination_wallet_id, target_goal_id, category_id,
  type, category, amount, title, note, occurred_at, source, client_mutation_id, created_at
FROM transactions
WHERE user_id = $1
  AND client_mutation_id = $2;

-- name: ListTransactionsByUser :many
SELECT
  id, user_id, wallet_id, destination_wallet_id, target_goal_id, category_id,
  type, category, amount, title, note, occurred_at, source, client_mutation_id, created_at
FROM transactions
WHERE user_id = sqlc.arg('user_id')
  AND (sqlc.narg('wallet_id')::uuid IS NULL OR wallet_id = sqlc.narg('wallet_id')::uuid OR destination_wallet_id = sqlc.narg('wallet_id')::uuid)
  AND (sqlc.narg('tx_type')::text IS NULL OR type = sqlc.narg('tx_type')::text)
  AND (sqlc.narg('category')::text IS NULL OR LOWER(category) = LOWER(sqlc.narg('category')::text))
  AND (sqlc.narg('date_from')::timestamptz IS NULL OR occurred_at >= sqlc.narg('date_from')::timestamptz)
  AND (sqlc.narg('date_to')::timestamptz IS NULL OR occurred_at < sqlc.narg('date_to')::timestamptz)
  AND (
    sqlc.narg('keyword')::text IS NULL
    OR sqlc.narg('keyword')::text = ''
    OR POSITION(LOWER(sqlc.narg('keyword')::text) IN LOWER(title)) > 0
    OR POSITION(LOWER(sqlc.narg('keyword')::text) IN LOWER(COALESCE(note, ''))) > 0
  )
ORDER BY occurred_at DESC, created_at DESC
LIMIT sqlc.arg('limit_rows')
OFFSET sqlc.arg('offset_rows');

-- name: DeleteTransaction :one
DELETE FROM transactions
WHERE user_id = $1
  AND id = $2
RETURNING id, user_id, wallet_id, destination_wallet_id, target_goal_id, category_id, type, category, amount, title, note, occurred_at, source, client_mutation_id, created_at;

-- name: CreateAIDraft :one
INSERT INTO ai_drafts (
  user_id,
  wallet_id,
  destination_wallet_id,
  batch_id,
  source,
  external_ref_id,
  client_mutation_id,
  type,
  category,
  amount,
  title,
  merchant_or_note,
  occurred_at,
  confidence_score
) VALUES (
  $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14
)
ON CONFLICT DO NOTHING
RETURNING id, user_id, wallet_id, destination_wallet_id, batch_id, source, external_ref_id, client_mutation_id, type, category, amount, title, merchant_or_note, occurred_at, confidence_score, status, created_at, updated_at;

-- name: ListPendingAIDraftsByUser :many
SELECT
  id, user_id, wallet_id, destination_wallet_id, batch_id, source,
  external_ref_id, client_mutation_id, type, category, amount, title,
  merchant_or_note, occurred_at, confidence_score, status, created_at, updated_at
FROM ai_drafts
WHERE user_id = $1
  AND status = 'pending_review'
ORDER BY created_at DESC;

-- name: GetAIDraftByID :one
SELECT
  id, user_id, wallet_id, destination_wallet_id, batch_id, source,
  external_ref_id, client_mutation_id, type, category, amount, title,
  merchant_or_note, occurred_at, confidence_score, status, created_at, updated_at
FROM ai_drafts
WHERE user_id = $1
  AND id = $2;

-- name: GetAIDraftByClientMutationID :one
SELECT
  id, user_id, wallet_id, destination_wallet_id, batch_id, source,
  external_ref_id, client_mutation_id, type, category, amount, title,
  merchant_or_note, occurred_at, confidence_score, status, created_at, updated_at
FROM ai_drafts
WHERE user_id = $1
  AND client_mutation_id = $2;

-- name: ConfirmAIDraft :one
UPDATE ai_drafts
SET
  status = 'confirmed',
  wallet_id = COALESCE(sqlc.narg('wallet_id')::uuid, wallet_id),
  destination_wallet_id = COALESCE(sqlc.narg('destination_wallet_id')::uuid, destination_wallet_id),
  category = COALESCE(sqlc.narg('category')::text, category),
  amount = COALESCE(sqlc.narg('amount')::bigint, amount),
  title = COALESCE(sqlc.narg('title')::text, title),
  merchant_or_note = COALESCE(sqlc.narg('merchant_or_note')::text, merchant_or_note),
  client_mutation_id = COALESCE(sqlc.narg('client_mutation_id')::text, client_mutation_id),
  updated_at = NOW()
WHERE user_id = sqlc.arg('user_id')
  AND id = sqlc.arg('id')
  AND status = 'pending_review'
RETURNING id, user_id, wallet_id, destination_wallet_id, batch_id, source, external_ref_id, client_mutation_id, type, category, amount, title, merchant_or_note, occurred_at, confidence_score, status, created_at, updated_at;

-- name: DiscardAIDraft :one
UPDATE ai_drafts
SET
  status = 'discarded',
  updated_at = NOW()
WHERE user_id = $1
  AND id = $2
  AND status = 'pending_review'
RETURNING id, user_id, wallet_id, destination_wallet_id, batch_id, source, external_ref_id, client_mutation_id, type, category, amount, title, merchant_or_note, occurred_at, confidence_score, status, created_at, updated_at;

-- name: UpsertBudget :one
INSERT INTO budgets (
  user_id,
  category_id,
  category,
  month_year,
  limit_amount,
  icon_key,
  color_hex,
  bg_color_hex
) VALUES (
  $1, $2, $3, $4, $5, $6, $7, $8
)
ON CONFLICT (user_id, category, month_year) DO UPDATE SET
  category_id = COALESCE(EXCLUDED.category_id, budgets.category_id),
  limit_amount = EXCLUDED.limit_amount,
  icon_key = COALESCE(EXCLUDED.icon_key, budgets.icon_key),
  color_hex = COALESCE(EXCLUDED.color_hex, budgets.color_hex),
  bg_color_hex = COALESCE(EXCLUDED.bg_color_hex, budgets.bg_color_hex),
  updated_at = NOW()
RETURNING id, user_id, category_id, category, month_year, limit_amount, icon_key, color_hex, bg_color_hex, alert_80_sent, alert_100_sent, created_at, updated_at;

-- name: DeleteBudget :execrows
DELETE FROM budgets
WHERE user_id = $1
  AND id = $2;

-- name: CreateGoal :one
INSERT INTO goals (
  user_id,
  linked_wallet_id,
  title,
  target_amount,
  saved_amount,
  target_date,
  priority,
  source_asset_label,
  icon_key,
  tag_color_hex,
  tag_text_color_hex
) VALUES (
  $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
)
RETURNING id, user_id, linked_wallet_id, title, target_amount, saved_amount, target_date, priority, source_asset_label, icon_key, tag_color_hex, tag_text_color_hex, status, created_at, updated_at;

-- name: GetGoalByID :one
SELECT
  id, user_id, linked_wallet_id, title, target_amount, saved_amount,
  target_date, priority, source_asset_label, icon_key,
  tag_color_hex, tag_text_color_hex, status, created_at, updated_at
FROM goals
WHERE user_id = $1
  AND id = $2;

-- name: UpdateGoal :one
UPDATE goals
SET
  linked_wallet_id = COALESCE(sqlc.narg('linked_wallet_id')::uuid, linked_wallet_id),
  title = COALESCE(sqlc.narg('title')::text, title),
  target_amount = COALESCE(sqlc.narg('target_amount')::bigint, target_amount),
  saved_amount = COALESCE(sqlc.narg('saved_amount')::bigint, saved_amount),
  target_date = COALESCE(sqlc.narg('target_date')::date, target_date),
  priority = COALESCE(sqlc.narg('priority')::text, priority),
  status = COALESCE(sqlc.narg('status')::text, status),
  updated_at = NOW()
WHERE user_id = sqlc.arg('user_id')
  AND id = sqlc.arg('id')
RETURNING id, user_id, linked_wallet_id, title, target_amount, saved_amount, target_date, priority, source_asset_label, icon_key, tag_color_hex, tag_text_color_hex, status, created_at, updated_at;

-- name: UpsertGoalContribution :one
INSERT INTO goal_contributions (goal_id, wallet_id, contributed_amount)
SELECT g.id, w.id, sqlc.arg('contributed_amount')::bigint
FROM goals g
JOIN wallets w ON w.id = sqlc.arg('wallet_id') AND w.user_id = sqlc.arg('user_id')
WHERE g.id = sqlc.arg('goal_id')
  AND g.user_id = sqlc.arg('user_id')
ON CONFLICT (goal_id, wallet_id) DO UPDATE SET
  contributed_amount = goal_contributions.contributed_amount + EXCLUDED.contributed_amount,
  updated_at = NOW()
RETURNING id, goal_id, wallet_id, contributed_amount, updated_at;

-- name: AddGoalSavedAmount :one
UPDATE goals
SET
  saved_amount = saved_amount + sqlc.arg('delta')::bigint,
  status = CASE WHEN saved_amount + sqlc.arg('delta')::bigint >= target_amount THEN 'completed' ELSE status END,
  updated_at = NOW()
WHERE user_id = sqlc.arg('user_id')
  AND id = sqlc.arg('id')
RETURNING id, user_id, linked_wallet_id, title, target_amount, saved_amount, target_date, priority, source_asset_label, icon_key, tag_color_hex, tag_text_color_hex, status, created_at, updated_at;

-- name: CreateBill :one
INSERT INTO bills (
  user_id,
  title,
  category,
  amount,
  due_date,
  frequency,
  auto_pay,
  icon_key,
  icon_color_hex,
  icon_bg_color_hex
) VALUES (
  $1, $2, $3, $4, $5, $6, $7, $8, $9, $10
)
RETURNING id, user_id, title, category, amount, due_date, frequency, is_paid, auto_pay, icon_key, icon_color_hex, icon_bg_color_hex, paid_at, created_at, updated_at;

-- name: MarkBillPaid :one
UPDATE bills
SET
  is_paid = $3,
  paid_at = CASE WHEN $3 THEN NOW() ELSE NULL END,
  updated_at = NOW()
WHERE user_id = $1
  AND id = $2
RETURNING id, user_id, title, category, amount, due_date, frequency, is_paid, auto_pay, icon_key, icon_color_hex, icon_bg_color_hex, paid_at, created_at, updated_at;

-- name: DeleteBill :execrows
DELETE FROM bills
WHERE user_id = $1
  AND id = $2;

-- name: ListNotificationsByUser :many
SELECT id, user_id, category, title, body, action_route, action_label, is_read, created_at
FROM notifications
WHERE user_id = $1
ORDER BY created_at DESC
LIMIT $2;

-- name: MarkAllNotificationsRead :execrows
UPDATE notifications
SET is_read = TRUE
WHERE user_id = $1
  AND is_read = FALSE;
