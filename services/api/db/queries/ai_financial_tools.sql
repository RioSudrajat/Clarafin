-- name: ListActiveWalletsByUser :many
SELECT
  id, user_id, name, type, institution_code, account_number_masked,
  balance, is_auto_sync, custom_color_hex, return_percentage,
  dividend_drop_date, is_volatile, has_claimed_dividend, is_archived,
  created_at, updated_at
FROM wallets
WHERE user_id = $1
  AND is_archived = FALSE
ORDER BY created_at ASC, id ASC;

-- name: GetCashflowPeriodTotals :one
SELECT
  COALESCE(SUM(amount) FILTER (WHERE type = 'income'), 0)::bigint AS total_income,
  COALESCE(SUM(amount) FILTER (WHERE type = 'expense'), 0)::bigint AS total_expense,
  COALESCE(SUM(amount) FILTER (WHERE type = 'transfer'), 0)::bigint AS total_transfer,
  (COALESCE(SUM(amount) FILTER (WHERE type = 'income'), 0) - COALESCE(SUM(amount) FILTER (WHERE type = 'expense'), 0))::bigint AS net_cashflow,
  COUNT(*) FILTER (WHERE type = 'income')::bigint AS income_count,
  COUNT(*) FILTER (WHERE type = 'expense')::bigint AS expense_count,
  COUNT(*) FILTER (WHERE type = 'transfer')::bigint AS transfer_count,
  COUNT(*)::bigint AS total_count
FROM transactions
WHERE user_id = sqlc.arg('user_id')
  AND occurred_at >= sqlc.arg('start_at')::timestamptz
  AND occurred_at < sqlc.arg('end_at')::timestamptz;

-- name: GetCashflowFlowEdges :many
WITH income_nodes AS (
  SELECT
    ti.category::text AS source_category,
    SUM(ti.amount)::bigint AS source_total
  FROM transactions ti
  WHERE ti.user_id = sqlc.arg('user_id')
    AND ti.type = 'income'
    AND ti.occurred_at >= sqlc.arg('start_at')::timestamptz
    AND ti.occurred_at < sqlc.arg('end_at')::timestamptz
  GROUP BY ti.category
),
expense_nodes AS (
  SELECT
    te.category::text AS target_category,
    SUM(te.amount)::bigint AS target_total,
    COUNT(*)::bigint AS expense_tx_count
  FROM transactions te
  WHERE te.user_id = sqlc.arg('user_id')
    AND te.type = 'expense'
    AND te.occurred_at >= sqlc.arg('start_at')::timestamptz
    AND te.occurred_at < sqlc.arg('end_at')::timestamptz
  GROUP BY te.category
),
income_sum AS (
  SELECT COALESCE(SUM(source_total), 0)::bigint AS total_income
  FROM income_nodes
),
bipartite_raw AS (
  SELECT
    i.source_category,
    i.source_total,
    e.target_category,
    e.target_total,
    e.expense_tx_count,
    FLOOR((i.source_total::numeric * e.target_total::numeric) / s.total_income::numeric)::bigint AS base_flow,
    ROW_NUMBER() OVER (PARTITION BY e.target_category ORDER BY i.source_total DESC, i.source_category ASC) AS rn
  FROM income_nodes i
  CROSS JOIN expense_nodes e
  CROSS JOIN income_sum s
  WHERE s.total_income > 0
),
bipartite_exact AS (
  SELECT
    source_category::text AS source_category,
    source_total::bigint AS source_total,
    target_category::text AS target_category,
    target_total::bigint AS target_total,
    (
      base_flow + CASE
        WHEN rn = 1 THEN target_total - SUM(base_flow) OVER (PARTITION BY target_category)
        ELSE 0
      END
    )::bigint AS flow_amount,
    expense_tx_count::bigint AS expense_tx_count
  FROM bipartite_raw
),
expense_only_fallback AS (
  SELECT
    'Existing Balance'::text AS source_category,
    0::bigint AS source_total,
    e.target_category::text AS target_category,
    e.target_total::bigint AS target_total,
    e.target_total::bigint AS flow_amount,
    e.expense_tx_count::bigint AS expense_tx_count
  FROM expense_nodes e
  CROSS JOIN income_sum s
  WHERE s.total_income = 0
)
SELECT source_category, source_total, target_category, target_total, flow_amount, expense_tx_count
FROM bipartite_exact
UNION ALL
SELECT source_category, source_total, target_category, target_total, flow_amount, expense_tx_count
FROM expense_only_fallback
ORDER BY target_total DESC, flow_amount DESC, source_category ASC, target_category ASC;

-- name: GetCashflowMerchantBreakdown :many
SELECT
  TRIM(t.title)::text AS merchant,
  COUNT(*)::bigint AS tx_count,
  SUM(t.amount)::bigint AS total_amount,
  ARRAY_AGG(DISTINCT w.name ORDER BY w.name)::text[] AS wallet_names,
  ARRAY_AGG(DISTINCT t.category ORDER BY t.category)::text[] AS categories
FROM transactions t
JOIN wallets w ON w.id = t.wallet_id AND w.user_id = sqlc.arg('user_id')
WHERE t.user_id = sqlc.arg('user_id')
  AND t.type = 'expense'
  AND t.occurred_at >= sqlc.arg('start_at')::timestamptz
  AND t.occurred_at < sqlc.arg('end_at')::timestamptz
  AND (
    sqlc.arg('keyword_filter')::text = ''
    OR POSITION(LOWER(sqlc.arg('keyword_filter')::text) IN LOWER(t.title)) > 0
    OR POSITION(LOWER(sqlc.arg('keyword_filter')::text) IN LOWER(COALESCE(t.note, ''))) > 0
    OR POSITION(LOWER(sqlc.arg('keyword_filter')::text) IN LOWER(t.category)) > 0
  )
GROUP BY TRIM(t.title)
ORDER BY total_amount DESC, tx_count DESC, merchant ASC;

-- name: GetCashflowCategoryBreakdown :many
SELECT
  t.type::text AS tx_type,
  t.category::text AS category,
  t.category_id,
  COUNT(*)::bigint AS tx_count,
  SUM(t.amount)::bigint AS total_amount
FROM transactions t
WHERE t.user_id = sqlc.arg('user_id')
  AND t.occurred_at >= sqlc.arg('start_at')::timestamptz
  AND t.occurred_at < sqlc.arg('end_at')::timestamptz
  AND (sqlc.arg('tx_type')::text = '' OR t.type = sqlc.arg('tx_type')::text)
GROUP BY t.type, t.category, t.category_id
ORDER BY total_amount DESC, t.category ASC;

-- name: ListBudgetsWithSpent :many
SELECT
  b.id,
  b.user_id,
  b.category_id,
  b.category,
  b.month_year,
  b.limit_amount,
  b.icon_key,
  b.color_hex,
  b.bg_color_hex,
  b.alert_80_sent,
  b.alert_100_sent,
  b.created_at,
  b.updated_at,
  COALESCE(SUM(tx.amount), 0)::bigint AS spent_amount,
  (b.limit_amount - COALESCE(SUM(tx.amount), 0))::bigint AS remaining_amount,
  COUNT(tx.id)::bigint AS tx_count
FROM budgets b
LEFT JOIN (
  SELECT
    t.id,
    t.user_id,
    t.category_id,
    t.category,
    t.amount,
    t.occurred_at,
    c.parent_id AS category_parent_id
  FROM transactions t
  LEFT JOIN categories c ON c.id = t.category_id
  WHERE t.user_id = $1
    AND t.type = 'expense'
) tx
  ON tx.user_id = b.user_id
 AND tx.occurred_at >= ((b.month_year || '-01')::date::timestamp AT TIME ZONE 'Asia/Jakarta')
 AND tx.occurred_at < (((b.month_year || '-01')::date + INTERVAL '1 month')::timestamp AT TIME ZONE 'Asia/Jakarta')
 AND (
   (b.category_id IS NOT NULL AND (tx.category_id = b.category_id OR tx.category_parent_id = b.category_id))
   OR LOWER(tx.category) = LOWER(b.category)
   OR LOWER(tx.category) LIKE LOWER(b.category) || ' • %'
 )
WHERE b.user_id = $1
  AND b.month_year = $2
GROUP BY b.id
ORDER BY b.created_at ASC, b.id ASC;

-- name: ListGoalsByUser :many
SELECT
  id, user_id, linked_wallet_id, title, target_amount, saved_amount,
  target_date, priority, source_asset_label, icon_key,
  tag_color_hex, tag_text_color_hex, status, created_at, updated_at
FROM goals
WHERE user_id = $1
  AND status <> 'archived'
ORDER BY
  CASE priority
    WHEN 'urgent' THEN 1
    WHEN 'needs' THEN 2
    ELSE 3
  END ASC,
  target_date ASC NULLS LAST,
  created_at ASC;

-- name: ListUpcomingBillsByUser :many
SELECT
  id, user_id, title, category, amount, due_date, frequency,
  is_paid, auto_pay, icon_key, icon_color_hex, icon_bg_color_hex,
  paid_at, created_at, updated_at
FROM bills
WHERE user_id = $1
  AND is_paid = FALSE
ORDER BY due_date ASC NULLS LAST, created_at ASC;

-- name: GetLatestMatchExpertSubmission :one
SELECT id, user_id, answers_json, top_practitioner_ids, created_at
FROM match_expert_submissions
WHERE user_id = $1
ORDER BY created_at DESC
LIMIT 1;
