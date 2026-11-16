package middleware

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/redis/go-redis/v9"

	"github.com/clarafin/api/internal/domain"
)

// Atomic fixed-window counter with a self-healing PTTL check so a key without expiry cannot lock out a user.
var aiRateLimitScript = redis.NewScript(`
local current = redis.call("INCR", KEYS[1])
if current == 1 then
	redis.call("PEXPIRE", KEYS[1], ARGV[1])
end
local ttl = redis.call("PTTL", KEYS[1])
if ttl < 0 then
	redis.call("PEXPIRE", KEYS[1], ARGV[1])
	ttl = tonumber(ARGV[1])
end
return {current, ttl}
`)

// RateLimitAI enforces an atomic per-user_id Redis rate limit on /v1/ai/* endpoints.
func RateLimitAI(rdb *redis.Client, limit int, window time.Duration) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			reqID := RequestIDFromContext(r.Context())

			userID, ok := UserIDFromContext(r.Context())
			if !ok {
				domain.WriteError(w, http.StatusUnauthorized, domain.ErrCodeUnauthorized, "Authentication required.", reqID)
				return
			}

			if rdb == nil || limit <= 0 || window <= 0 {
				domain.WriteError(w, http.StatusInternalServerError, domain.ErrCodeInternalError, "Rate limiter is not configured.", reqID)
				return
			}

			windowMs := window.Milliseconds()
			if windowMs < 1 {
				windowMs = 1
			}

			key := fmt.Sprintf("ratelimit:ai:%s", userID.String())
			res, err := aiRateLimitScript.Run(r.Context(), rdb, []string{key}, windowMs).Slice()
			if err != nil || len(res) != 2 {
				domain.WriteError(w, http.StatusInternalServerError, domain.ErrCodeInternalError, "Failed to evaluate rate limit.", reqID)
				return
			}

			count, okCount := res[0].(int64)
			ttlMs, okTTL := res[1].(int64)
			if !okCount || !okTTL {
				domain.WriteError(w, http.StatusInternalServerError, domain.ErrCodeInternalError, "Invalid rate limiter response.", reqID)
				return
			}

			remaining := max(limit-int(count), 0)
			w.Header().Set("X-RateLimit-Limit", strconv.Itoa(limit))
			w.Header().Set("X-RateLimit-Remaining", strconv.Itoa(remaining))

			if count > int64(limit) {
				retryAfter := max((ttlMs+999)/1000, int64(1))
				w.Header().Set("Retry-After", strconv.FormatInt(retryAfter, 10))
				domain.WriteError(
					w,
					http.StatusTooManyRequests,
					domain.ErrCodeRateLimited,
					"AI rate limit exceeded. Please wait before sending more requests.",
					reqID,
				)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}
