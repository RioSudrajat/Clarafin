package config

import (
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
)

// DefaultGeminiModel is the primary Gemini model used when GEMINI_MODEL is unset.
const DefaultGeminiModel = "gemini-3.5-flash"

const defaultFallbackModels = "gemini-3.1-flash-lite-preview,gemini-3.1-flash-lite,gemini-flash-lite-latest,gemini-3-flash-preview,gemini-3.8-flash"

// Config holds validated runtime configuration loaded from environment variables.
type Config struct {
	AppEnv                    string
	HTTPPort                  string
	LogLevel                  string
	DatabaseURL               string
	RedisURL                  string
	SupabaseJWTSecret         string
	SupabaseJWKSURL           string
	GeminiAPIKey              string
	GeminiModel               string
	GeminiFallbackModels      []string
	GeminiContextCacheEnabled bool
	AIRateLimitPerMin         int
	EnableDevAuth             bool
	DevJWTSecret              string
	AllowedOrigins            []string
}

// Load reads environment variables, applies safe defaults, and fails fast when required secrets are missing.
func Load() (*Config, error) {
	appEnv := strings.ToLower(getEnvOrDefault("APP_ENV", "development"))

	httpPort := getEnvOrDefault("HTTP_PORT", "8080")
	portNum, err := strconv.Atoi(httpPort)
	if err != nil || portNum < 1 || portNum > 65535 {
		return nil, fmt.Errorf("invalid HTTP_PORT %q: must be between 1 and 65535", httpPort)
	}

	defaultLogLevel := "info"
	if appEnv == "development" {
		defaultLogLevel = "debug"
	}
	logLevel := strings.ToLower(getEnvOrDefault("LOG_LEVEL", defaultLogLevel))
	switch logLevel {
	case "debug", "info", "warn", "error":
	default:
		return nil, fmt.Errorf("invalid LOG_LEVEL %q: must be debug, info, warn, or error", logLevel)
	}

	databaseURL := getTrimmedEnv("DATABASE_URL")
	if databaseURL == "" {
		return nil, errors.New("DATABASE_URL is required")
	}

	redisURL := getTrimmedEnv("REDIS_URL")
	if redisURL == "" {
		return nil, errors.New("REDIS_URL is required")
	}

	geminiCacheEnabled, err := getBoolEnvOrDefault("GEMINI_CONTEXT_CACHE_ENABLED", true)
	if err != nil {
		return nil, err
	}

	aiRateLimit, err := getIntEnvOrDefault("AI_RATE_LIMIT_PER_MIN", 10)
	if err != nil {
		return nil, err
	}
	if aiRateLimit <= 0 {
		return nil, fmt.Errorf("invalid AI_RATE_LIMIT_PER_MIN %d: must be positive", aiRateLimit)
	}

	enableDevAuth, err := getBoolEnvOrDefault("ENABLE_DEV_AUTH", false)
	if err != nil {
		return nil, err
	}

	geminiModel := getEnvOrDefault("GEMINI_MODEL", DefaultGeminiModel)
	rawFallbackModels, hasFallbackEnv := os.LookupEnv("GEMINI_FALLBACK_MODELS")

	cfg := &Config{
		AppEnv:                    appEnv,
		HTTPPort:                  httpPort,
		LogLevel:                  logLevel,
		DatabaseURL:               databaseURL,
		RedisURL:                  redisURL,
		SupabaseJWTSecret:         getTrimmedEnv("SUPABASE_JWT_SECRET"),
		SupabaseJWKSURL:           getTrimmedEnv("SUPABASE_JWKS_URL"),
		GeminiAPIKey:              getTrimmedEnv("GEMINI_API_KEY"),
		GeminiModel:               geminiModel,
		GeminiFallbackModels:      ParseGeminiFallbackModels(rawFallbackModels, hasFallbackEnv, geminiModel),
		GeminiContextCacheEnabled: geminiCacheEnabled,
		AIRateLimitPerMin:         aiRateLimit,
		EnableDevAuth:             enableDevAuth,
		DevJWTSecret:              getTrimmedEnv("DEV_JWT_SECRET"),
		AllowedOrigins:            parseAllowedOrigins(getTrimmedEnv("ALLOWED_ORIGINS"), appEnv),
	}

	if err := validateEnvironmentRules(cfg); err != nil {
		return nil, err
	}

	return cfg, nil
}

func validateEnvironmentRules(cfg *Config) error {
	if cfg.AppEnv == "development" {
		if cfg.EnableDevAuth && len(cfg.DevJWTSecret) < 32 {
			return errors.New("DEV_JWT_SECRET must be at least 32 characters when ENABLE_DEV_AUTH is enabled")
		}
		return nil
	}

	// Dev JWT bypass must never run outside local development.
	if cfg.EnableDevAuth {
		return errors.New("ENABLE_DEV_AUTH is only permitted when APP_ENV=development")
	}
	if cfg.SupabaseJWTSecret == "" && cfg.SupabaseJWKSURL == "" {
		return errors.New("SUPABASE_JWT_SECRET or SUPABASE_JWKS_URL is required in non-development environments")
	}
	if cfg.GeminiAPIKey == "" {
		return errors.New("GEMINI_API_KEY is required in non-development environments")
	}
	return nil
}

func getTrimmedEnv(key string) string {
	return strings.TrimSpace(os.Getenv(key))
}

func getEnvOrDefault(key, fallback string) string {
	if v := getTrimmedEnv(key); v != "" {
		return v
	}
	return fallback
}

func getBoolEnvOrDefault(key string, fallback bool) (bool, error) {
	raw := getTrimmedEnv(key)
	if raw == "" {
		return fallback, nil
	}
	parsed, err := strconv.ParseBool(raw)
	if err != nil {
		return false, fmt.Errorf("invalid %s %q: %w", key, raw, err)
	}
	return parsed, nil
}

func getIntEnvOrDefault(key string, fallback int) (int, error) {
	raw := getTrimmedEnv(key)
	if raw == "" {
		return fallback, nil
	}
	parsed, err := strconv.Atoi(raw)
	if err != nil {
		return 0, fmt.Errorf("invalid %s %q: %w", key, raw, err)
	}
	return parsed, nil
}

func parseAllowedOrigins(raw, appEnv string) []string {
	if raw == "" {
		if appEnv == "development" {
			return []string{"http://localhost:3000", "http://localhost:8080"}
		}
		return []string{}
	}

	parts := strings.Split(raw, ",")
	origins := make([]string, 0, len(parts))
	for _, part := range parts {
		trimmed := strings.TrimSpace(part)
		if trimmed != "" {
			origins = append(origins, trimmed)
		}
	}
	return origins
}

// ParseGeminiFallbackModels parses the ordered fallback model list from GEMINI_FALLBACK_MODELS.
// When the environment variable is unset, it returns the default fallback chain
// with the primary model excluded. When explicitly set to "" or "none", it returns an empty slice.
func ParseGeminiFallbackModels(raw string, isSet bool, primaryModel string) []string {
	primary := strings.TrimSpace(primaryModel)
	if !isSet {
		raw = defaultFallbackModels
	} else {
		trimmedRaw := strings.TrimSpace(raw)
		if trimmedRaw == "" || strings.EqualFold(trimmedRaw, "none") {
			return []string{}
		}
	}

	parts := strings.Split(raw, ",")
	seen := make(map[string]struct{}, len(parts))
	fallbacks := make([]string, 0, len(parts))
	for _, part := range parts {
		candidate := strings.TrimSpace(part)
		if candidate == "" || strings.EqualFold(candidate, "none") || candidate == primary {
			continue
		}
		if _, dup := seen[candidate]; dup {
			continue
		}
		seen[candidate] = struct{}{}
		fallbacks = append(fallbacks, candidate)
	}
	return fallbacks
}
