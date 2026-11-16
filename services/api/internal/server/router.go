package server

import (
	"net/http"
	"slices"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/redis/go-redis/v9"
	"go.uber.org/zap"

	"github.com/clarafin/api/internal/config"
	"github.com/clarafin/api/internal/domain"
	"github.com/clarafin/api/internal/handler"
	"github.com/clarafin/api/internal/middleware"
	"github.com/clarafin/api/internal/repository"
	"github.com/clarafin/api/internal/service"
)

// Dependencies bundles runtime dependencies required to build the HTTP router.
type Dependencies struct {
	Config                  *config.Config
	Logger                  *zap.Logger
	Store                   *repository.Store
	DevUserProvisioner      handler.DevUserProvisioner
	QuotaService            handler.QuotaProvider
	Redis                   *redis.Client
	JakartaLoc              *time.Location
	RegisterProtectedRoutes func(r chi.Router)
	RegisterAIRoutes        func(r chi.Router)
}

// NewRouter constructs the Clarafin HTTP router with standard middleware, /healthz, and /v1 route groups.
func NewRouter(deps Dependencies) http.Handler {
	cfg := deps.Config
	if cfg == nil {
		cfg = &config.Config{AppEnv: "production", AIRateLimitPerMin: 10}
	}

	logger := deps.Logger
	if logger == nil {
		logger = zap.NewNop()
	}

	jakartaLoc := deps.JakartaLoc
	if jakartaLoc == nil {
		jakartaLoc = time.FixedZone("WIB", 7*3600)
	}

	devProvisioner := deps.DevUserProvisioner
	if devProvisioner == nil && deps.Store != nil {
		devProvisioner = deps.Store
	}

	quotaService := deps.QuotaService
	if quotaService == nil && deps.Store != nil {
		quotaService = service.NewQuotaService(deps.Store, service.WithJakartaLocation(jakartaLoc))
	}

	r := chi.NewRouter()
	r.Use(middleware.RequestID)
	r.Use(middleware.RequestLogger(logger))
	r.Use(middleware.Recoverer(logger))
	r.Use(corsMiddleware(cfg.AllowedOrigins))

	r.NotFound(func(w http.ResponseWriter, r *http.Request) {
		domain.WriteError(w, http.StatusNotFound, domain.ErrCodeNotFound, "Endpoint not found.", middleware.RequestIDFromContext(r.Context()))
	})
	r.MethodNotAllowed(func(w http.ResponseWriter, r *http.Request) {
		domain.WriteError(w, http.StatusMethodNotAllowed, domain.ErrCodeInvalidRequest, "Method not allowed.", middleware.RequestIDFromContext(r.Context()))
	})

	r.Get("/healthz", func(w http.ResponseWriter, r *http.Request) {
		domain.WriteJSON(w, http.StatusOK, map[string]string{
			"status":    "ok",
			"service":   "clarafin-api",
			"env":       cfg.AppEnv,
			"timestamp": time.Now().In(jakartaLoc).Format(time.RFC3339),
		}, middleware.RequestIDFromContext(r.Context()))
	})

	r.Route("/v1", func(v1 chi.Router) {
		if cfg.EnableDevAuth && cfg.AppEnv == "development" {
			devAuthHandler := handler.NewDevAuthHandler(cfg, devProvisioner)
			v1.Post("/dev/token", devAuthHandler.IssueToken)
		}

		v1.Group(func(authed chi.Router) {
			authed.Use(middleware.RequireAuth(cfg))

			authed.Route("/ai", func(ai chi.Router) {
				if quotaService != nil {
					quotaHandler := handler.NewQuotaHandler(quotaService)
					ai.Get("/quota", quotaHandler.GetQuota)
				}

				// Quota polling stays outside the 10rpm chat rate limiter so UI badge refreshes never starve AI calls.
				ai.Group(func(aiLimited chi.Router) {
					aiLimited.Use(middleware.RateLimitAI(deps.Redis, cfg.AIRateLimitPerMin, time.Minute))
					if deps.RegisterAIRoutes != nil {
						deps.RegisterAIRoutes(aiLimited)
					}
				})
			})

			if deps.RegisterProtectedRoutes != nil {
				deps.RegisterProtectedRoutes(authed)
			}
		})
	})

	return r
}

func corsMiddleware(allowedOrigins []string) func(http.Handler) http.Handler {
	allowWildcard := slices.Contains(allowedOrigins, "*")

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			origin := strings.TrimSpace(r.Header.Get("Origin"))
			if origin != "" {
				w.Header().Add("Vary", "Origin")
				if allowWildcard {
					w.Header().Set("Access-Control-Allow-Origin", "*")
				} else if slices.Contains(allowedOrigins, origin) {
					w.Header().Set("Access-Control-Allow-Origin", origin)
				}

				if allowWildcard || slices.Contains(allowedOrigins, origin) {
					w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
					w.Header().Set("Access-Control-Allow-Headers", "Accept, Authorization, Content-Type, X-Request-Id")
					w.Header().Set("Access-Control-Expose-Headers", "X-Request-Id, X-RateLimit-Limit, X-RateLimit-Remaining, Retry-After")
					w.Header().Set("Access-Control-Max-Age", "3600")
				}
			}

			if r.Method == http.MethodOptions {
				w.WriteHeader(http.StatusNoContent)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}
