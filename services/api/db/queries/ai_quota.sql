-- name: LockUserForQuota :one
SELECT id
FROM users
WHERE id = $1
  AND deleted_at IS NULL
FOR UPDATE;

-- name: ReserveAIUsage :one
INSERT INTO ai_usage_ledger (
  user_id,
  request_id,
  month_year,
  action_type,
  surface_mode,
  bucket,
  status
) VALUES (
  $1, $2, $3, $4, $5, $6, 'reserved'
)
ON CONFLICT (request_id) DO NOTHING
RETURNING id, user_id, request_id, month_year, action_type, surface_mode, bucket, status, created_at;

-- name: GetAIUsageByRequestID :one
SELECT id, user_id, request_id, month_year, action_type, surface_mode, bucket, status, created_at
FROM ai_usage_ledger
WHERE user_id = $1
  AND request_id = $2;

-- name: MarkAIUsageSuccess :one
UPDATE ai_usage_ledger
SET status = 'success'
WHERE user_id = $1
  AND request_id = $2
  AND status = 'reserved'
RETURNING id, user_id, request_id, month_year, action_type, surface_mode, bucket, status, created_at;

-- name: MarkAIUsageFailed :one
UPDATE ai_usage_ledger
SET status = 'failed'
WHERE user_id = $1
  AND request_id = $2
  AND status = 'reserved'
RETURNING id, user_id, request_id, month_year, action_type, surface_mode, bucket, status, created_at;

-- name: GetMonthlyFreeUsageCount :one
SELECT COUNT(*)::bigint AS used_count
FROM ai_usage_ledger
WHERE user_id = $1
  AND month_year = $2
  AND bucket = 'free'
  AND status IN ('reserved', 'success');

-- name: GetActiveProSubscription :one
SELECT id, user_id, order_id, plan_type, source_session_id, price_paid, quota_total, quota_used, xendit_invoice_id, status, starts_at, expires_at, created_at
FROM pro_subscriptions
WHERE user_id = $1
  AND status = 'active'
  AND (starts_at IS NULL OR starts_at <= NOW())
  AND (expires_at IS NULL OR expires_at > NOW())
ORDER BY
  CASE
    WHEN quota_total = -1 THEN 0
    WHEN quota_used < quota_total THEN 1
    ELSE 2
  END ASC,
  expires_at DESC NULLS LAST,
  created_at DESC
LIMIT 1;

-- name: ListActiveProSubscriptions :many
SELECT id, user_id, order_id, plan_type, source_session_id, price_paid, quota_total, quota_used, xendit_invoice_id, status, starts_at, expires_at, created_at
FROM pro_subscriptions
WHERE user_id = $1
  AND status = 'active'
  AND (starts_at IS NULL OR starts_at <= NOW())
  AND (expires_at IS NULL OR expires_at > NOW())
ORDER BY
  CASE
    WHEN quota_total = -1 THEN 0
    WHEN quota_used < quota_total THEN 1
    ELSE 2
  END ASC,
  expires_at DESC NULLS LAST,
  created_at DESC;

-- name: IncrementProSubscriptionUsage :one
UPDATE pro_subscriptions
SET quota_used = quota_used + 1
WHERE user_id = $1
  AND id = $2
  AND status = 'active'
  AND (starts_at IS NULL OR starts_at <= NOW())
  AND (expires_at IS NULL OR expires_at > NOW())
  AND (quota_total = -1 OR quota_used < quota_total)
RETURNING id, user_id, order_id, plan_type, source_session_id, price_paid, quota_total, quota_used, xendit_invoice_id, status, starts_at, expires_at, created_at;

-- name: DecrementProSubscriptionUsage :one
UPDATE pro_subscriptions
SET quota_used = GREATEST(quota_used - 1, 0)
WHERE user_id = $1
  AND id = $2
  AND quota_used > 0
RETURNING id, user_id, order_id, plan_type, source_session_id, price_paid, quota_total, quota_used, xendit_invoice_id, status, starts_at, expires_at, created_at;

-- name: GetAIUsageByRequestIDOnly :one
SELECT id, user_id, request_id, month_year, action_type, surface_mode, bucket, status, created_at
FROM ai_usage_ledger
WHERE request_id = $1;

-- name: MarkAIUsageSuccessByRequestID :one
UPDATE ai_usage_ledger
SET status = 'success'
WHERE request_id = $1
  AND status = 'reserved'
RETURNING id, user_id, request_id, month_year, action_type, surface_mode, bucket, status, created_at;

-- name: MarkAIUsageFailedByRequestID :one
UPDATE ai_usage_ledger
SET status = 'failed'
WHERE request_id = $1
  AND status = 'reserved'
RETURNING id, user_id, request_id, month_year, action_type, surface_mode, bucket, status, created_at;

-- name: GetMonthlyUsageCountByBucket :one
SELECT COUNT(*)::bigint AS used_count
FROM ai_usage_ledger
WHERE user_id = $1
  AND month_year = $2
  AND bucket = $3
  AND status IN ('reserved', 'success');

-- name: ListActiveProSubscriptionsAt :many
SELECT id, user_id, order_id, plan_type, source_session_id, price_paid, quota_total, quota_used, xendit_invoice_id, status, starts_at, expires_at, created_at
FROM pro_subscriptions
WHERE user_id = sqlc.arg('user_id')
  AND status = 'active'
  AND (starts_at IS NULL OR starts_at <= sqlc.arg('at_time')::timestamptz)
  AND (expires_at IS NULL OR expires_at > sqlc.arg('at_time')::timestamptz)
ORDER BY
  CASE
    WHEN quota_total = -1 THEN 0
    WHEN quota_used < quota_total THEN 1
    ELSE 2
  END ASC,
  CASE
    WHEN plan_type = 'pro_monthly' THEN 0
    ELSE 1
  END ASC,
  expires_at DESC NULLS LAST,
  created_at DESC;

-- name: IncrementProSubscriptionUsageAt :one
UPDATE pro_subscriptions
SET quota_used = quota_used + 1
WHERE user_id = sqlc.arg('user_id')
  AND id = sqlc.arg('id')
  AND status = 'active'
  AND (starts_at IS NULL OR starts_at <= sqlc.arg('at_time')::timestamptz)
  AND (expires_at IS NULL OR expires_at > sqlc.arg('at_time')::timestamptz)
  AND (quota_total = -1 OR quota_used < quota_total)
RETURNING id, user_id, order_id, plan_type, source_session_id, price_paid, quota_total, quota_used, xendit_invoice_id, status, starts_at, expires_at, created_at;

-- name: FindProSubscriptionForCompensation :one
SELECT id, user_id, order_id, plan_type, source_session_id, price_paid, quota_total, quota_used, xendit_invoice_id, status, starts_at, expires_at, created_at
FROM pro_subscriptions
WHERE user_id = $1
  AND quota_used > 0
  AND plan_type = $2
ORDER BY
  CASE WHEN status = 'active' THEN 0 ELSE 1 END ASC,
  expires_at DESC NULLS LAST,
  created_at DESC
LIMIT 1;
