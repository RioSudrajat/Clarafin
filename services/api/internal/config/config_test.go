package config_test

import (
	"os"
	"reflect"
	"strings"
	"testing"

	"github.com/clarafin/api/internal/config"
)

func clearConfigEnv(t *testing.T) {
	t.Helper()
	keys := []string{
		"APP_ENV",
		"HTTP_PORT",
		"LOG_LEVEL",
		"DATABASE_URL",
		"REDIS_URL",
		"SUPABASE_JWT_SECRET",
		"SUPABASE_JWKS_URL",
		"GEMINI_API_KEY",
		"GEMINI_MODEL",
		"GEMINI_FALLBACK_MODELS",
		"GEMINI_CONTEXT_CACHE_ENABLED",
		"AI_RATE_LIMIT_PER_MIN",
		"ENABLE_DEV_AUTH",
		"DEV_JWT_SECRET",
		"ALLOWED_ORIGINS",
	}
	for _, key := range keys {
		t.Setenv(key, "")
	}
	_ = os.Unsetenv("GEMINI_FALLBACK_MODELS")
}

func TestLoadConfig_FailsWithoutRequiredDatabaseURL(t *testing.T) {
	clearConfigEnv(t)
	t.Setenv("REDIS_URL", "redis://localhost:6379/0")

	_, err := config.Load()
	if err == nil {
		t.Fatal("expected error when DATABASE_URL is missing, got nil")
	}
	if !strings.Contains(err.Error(), "DATABASE_URL") {
		t.Fatalf("expected error to mention DATABASE_URL, got: %v", err)
	}
}

func TestLoadConfig_FailsWithoutRequiredRedisURL(t *testing.T) {
	clearConfigEnv(t)
	t.Setenv("DATABASE_URL", "postgresql://clarafin:clarafin_dev_password@localhost:5432/clarafin?sslmode=disable")

	_, err := config.Load()
	if err == nil {
		t.Fatal("expected error when REDIS_URL is missing, got nil")
	}
	if !strings.Contains(err.Error(), "REDIS_URL") {
		t.Fatalf("expected error to mention REDIS_URL, got: %v", err)
	}
}

func TestLoadConfig_DefaultsGeminiModelAndRateLimit(t *testing.T) {
	clearConfigEnv(t)
	t.Setenv("DATABASE_URL", "postgresql://clarafin:clarafin_dev_password@localhost:5432/clarafin?sslmode=disable")
	t.Setenv("REDIS_URL", "redis://localhost:6379/0")

	cfg, err := config.Load()
	if err != nil {
		t.Fatalf("expected Load() to succeed with development defaults, got: %v", err)
	}

	if cfg.AppEnv != "development" {
		t.Errorf("expected AppEnv 'development', got %q", cfg.AppEnv)
	}
	if cfg.HTTPPort != "8080" {
		t.Errorf("expected HTTPPort '8080', got %q", cfg.HTTPPort)
	}
	if cfg.GeminiModel != "gemini-3.1-flash-lite-preview" {
		t.Errorf("expected GeminiModel 'gemini-3.1-flash-lite-preview', got %q", cfg.GeminiModel)
	}
	wantFallbacks := []string{
		"gemini-3.1-flash-lite",
		"gemini-3.5-flash",
		"gemini-3.6-flash",
		"gemini-3-flash-preview",
		"gemini-2.5-flash",
		"gemini-2.5-flash-lite",
	}
	if !reflect.DeepEqual(cfg.GeminiFallbackModels, wantFallbacks) {
		t.Errorf("expected GeminiFallbackModels %v, got %v", wantFallbacks, cfg.GeminiFallbackModels)
	}
	if cfg.GeminiContextCacheEnabled {
		t.Errorf("expected GeminiContextCacheEnabled false by default")
	}
	if cfg.AIRateLimitPerMin != 10 {
		t.Errorf("expected AIRateLimitPerMin 10, got %d", cfg.AIRateLimitPerMin)
	}
	if cfg.EnableDevAuth {
		t.Errorf("expected EnableDevAuth false by default")
	}
	wantOrigins := []string{"http://localhost:3000", "http://localhost:8080"}
	if !reflect.DeepEqual(cfg.AllowedOrigins, wantOrigins) {
		t.Errorf("expected AllowedOrigins %v, got %v", wantOrigins, cfg.AllowedOrigins)
	}
}

func TestLoadConfig_DevelopmentDevAuthValidation(t *testing.T) {
	const dbURL = "postgresql://clarafin:clarafin_dev_password@localhost:5432/clarafin?sslmode=disable"
	const redisURL = "redis://localhost:6379/0"

	t.Run("fails when ENABLE_DEV_AUTH is true and DEV_JWT_SECRET is missing", func(t *testing.T) {
		clearConfigEnv(t)
		t.Setenv("DATABASE_URL", dbURL)
		t.Setenv("REDIS_URL", redisURL)
		t.Setenv("ENABLE_DEV_AUTH", "true")

		_, err := config.Load()
		if err == nil {
			t.Fatal("expected error when ENABLE_DEV_AUTH=true without DEV_JWT_SECRET")
		}
		if !strings.Contains(err.Error(), "DEV_JWT_SECRET") {
			t.Fatalf("expected error to mention DEV_JWT_SECRET, got: %v", err)
		}
	})

	t.Run("fails when ENABLE_DEV_AUTH is true and DEV_JWT_SECRET is shorter than 32 chars", func(t *testing.T) {
		clearConfigEnv(t)
		t.Setenv("DATABASE_URL", dbURL)
		t.Setenv("REDIS_URL", redisURL)
		t.Setenv("ENABLE_DEV_AUTH", "true")
		t.Setenv("DEV_JWT_SECRET", strings.Repeat("a", 31))

		_, err := config.Load()
		if err == nil {
			t.Fatal("expected error when DEV_JWT_SECRET is shorter than 32 chars")
		}
		if !strings.Contains(err.Error(), "DEV_JWT_SECRET") {
			t.Fatalf("expected error to mention DEV_JWT_SECRET, got: %v", err)
		}
	})

	t.Run("succeeds when ENABLE_DEV_AUTH is true and DEV_JWT_SECRET has 32 chars", func(t *testing.T) {
		clearConfigEnv(t)
		t.Setenv("DATABASE_URL", dbURL)
		t.Setenv("REDIS_URL", redisURL)
		t.Setenv("ENABLE_DEV_AUTH", "true")
		t.Setenv("DEV_JWT_SECRET", strings.Repeat("a", 32))

		cfg, err := config.Load()
		if err != nil {
			t.Fatalf("expected Load() to succeed, got: %v", err)
		}
		if !cfg.EnableDevAuth {
			t.Errorf("expected EnableDevAuth true")
		}
	})
}

func TestLoadConfig_NonDevelopmentRequiresJWTAndGeminiKey(t *testing.T) {
	const dbURL = "postgresql://clarafin:secret@db.example.com:5432/clarafin?sslmode=require"
	const redisURL = "redis://redis.example.com:6379/0"

	t.Run("production fails without JWT verification config", func(t *testing.T) {
		clearConfigEnv(t)
		t.Setenv("APP_ENV", "production")
		t.Setenv("DATABASE_URL", dbURL)
		t.Setenv("REDIS_URL", redisURL)
		t.Setenv("GEMINI_API_KEY", "test-gemini-key")

		_, err := config.Load()
		if err == nil {
			t.Fatal("expected error in production when neither SUPABASE_JWT_SECRET nor SUPABASE_JWKS_URL is set")
		}
	})

	t.Run("production fails without GEMINI_API_KEY", func(t *testing.T) {
		clearConfigEnv(t)
		t.Setenv("APP_ENV", "production")
		t.Setenv("DATABASE_URL", dbURL)
		t.Setenv("REDIS_URL", redisURL)
		t.Setenv("SUPABASE_JWT_SECRET", strings.Repeat("s", 32))

		_, err := config.Load()
		if err == nil {
			t.Fatal("expected error in production when GEMINI_API_KEY is missing")
		}
		if !strings.Contains(err.Error(), "GEMINI_API_KEY") {
			t.Fatalf("expected error to mention GEMINI_API_KEY, got: %v", err)
		}
	})

	t.Run("production fails when ENABLE_DEV_AUTH is enabled", func(t *testing.T) {
		clearConfigEnv(t)
		t.Setenv("APP_ENV", "production")
		t.Setenv("DATABASE_URL", dbURL)
		t.Setenv("REDIS_URL", redisURL)
		t.Setenv("SUPABASE_JWT_SECRET", strings.Repeat("s", 32))
		t.Setenv("GEMINI_API_KEY", "test-gemini-key")
		t.Setenv("ENABLE_DEV_AUTH", "true")
		t.Setenv("DEV_JWT_SECRET", strings.Repeat("d", 32))

		_, err := config.Load()
		if err == nil {
			t.Fatal("expected error when ENABLE_DEV_AUTH is true outside development")
		}
		if !strings.Contains(err.Error(), "ENABLE_DEV_AUTH") {
			t.Fatalf("expected error to mention ENABLE_DEV_AUTH, got: %v", err)
		}
	})

	t.Run("production succeeds with SUPABASE_JWT_SECRET and GEMINI_API_KEY", func(t *testing.T) {
		clearConfigEnv(t)
		t.Setenv("APP_ENV", "production")
		t.Setenv("DATABASE_URL", dbURL)
		t.Setenv("REDIS_URL", redisURL)
		t.Setenv("SUPABASE_JWT_SECRET", strings.Repeat("s", 32))
		t.Setenv("GEMINI_API_KEY", "test-gemini-key")

		cfg, err := config.Load()
		if err != nil {
			t.Fatalf("expected production config with JWT secret and Gemini key to succeed, got: %v", err)
		}
		if len(cfg.AllowedOrigins) != 0 {
			t.Errorf("expected empty default AllowedOrigins in production, got %v", cfg.AllowedOrigins)
		}
	})

	t.Run("staging succeeds with SUPABASE_JWKS_URL and GEMINI_API_KEY", func(t *testing.T) {
		clearConfigEnv(t)
		t.Setenv("APP_ENV", "staging")
		t.Setenv("DATABASE_URL", dbURL)
		t.Setenv("REDIS_URL", redisURL)
		t.Setenv("SUPABASE_JWKS_URL", "https://example.supabase.co/auth/v1/.well-known/jwks.json")
		t.Setenv("GEMINI_API_KEY", "test-gemini-key")

		cfg, err := config.Load()
		if err != nil {
			t.Fatalf("expected staging config with JWKS URL and Gemini key to succeed, got: %v", err)
		}
		if cfg.SupabaseJWKSURL == "" {
			t.Fatal("expected SupabaseJWKSURL to be populated")
		}
	})
}

func TestLoadConfig_ParsesCustomValuesAndValidatesPrimitives(t *testing.T) {
	const dbURL = "postgresql://clarafin:clarafin_dev_password@localhost:5432/clarafin?sslmode=disable"
	const redisURL = "redis://localhost:6379/0"

	t.Run("parses custom values cleanly", func(t *testing.T) {
		clearConfigEnv(t)
		t.Setenv("APP_ENV", "development")
		t.Setenv("HTTP_PORT", "9090")
		t.Setenv("LOG_LEVEL", "warn")
		t.Setenv("DATABASE_URL", dbURL)
		t.Setenv("REDIS_URL", redisURL)
		t.Setenv("GEMINI_MODEL", "gemini-2.5-pro")
		t.Setenv("GEMINI_CONTEXT_CACHE_ENABLED", "false")
		t.Setenv("AI_RATE_LIMIT_PER_MIN", "25")
		t.Setenv("ALLOWED_ORIGINS", " https://app.clarafin.id , , https://cms.clarafin.id ")

		cfg, err := config.Load()
		if err != nil {
			t.Fatalf("expected valid custom config, got: %v", err)
		}
		if cfg.HTTPPort != "9090" {
			t.Errorf("expected HTTPPort '9090', got %q", cfg.HTTPPort)
		}
		if cfg.LogLevel != "warn" {
			t.Errorf("expected LogLevel 'warn', got %q", cfg.LogLevel)
		}
		if cfg.GeminiModel != "gemini-2.5-pro" {
			t.Errorf("expected GeminiModel 'gemini-2.5-pro', got %q", cfg.GeminiModel)
		}
		if cfg.GeminiContextCacheEnabled {
			t.Errorf("expected GeminiContextCacheEnabled false")
		}
		if cfg.AIRateLimitPerMin != 25 {
			t.Errorf("expected AIRateLimitPerMin 25, got %d", cfg.AIRateLimitPerMin)
		}
		wantOrigins := []string{"https://app.clarafin.id", "https://cms.clarafin.id"}
		if !reflect.DeepEqual(cfg.AllowedOrigins, wantOrigins) {
			t.Errorf("expected AllowedOrigins %v, got %v", wantOrigins, cfg.AllowedOrigins)
		}
	})

	t.Run("rejects invalid AI_RATE_LIMIT_PER_MIN", func(t *testing.T) {
		for _, val := range []string{"0", "-3", "ten"} {
			clearConfigEnv(t)
			t.Setenv("DATABASE_URL", dbURL)
			t.Setenv("REDIS_URL", redisURL)
			t.Setenv("AI_RATE_LIMIT_PER_MIN", val)

			if _, err := config.Load(); err == nil {
				t.Fatalf("expected error for AI_RATE_LIMIT_PER_MIN=%q", val)
			}
		}
	})

	t.Run("rejects invalid HTTP_PORT", func(t *testing.T) {
		for _, val := range []string{"0", "70000", "abc"} {
			clearConfigEnv(t)
			t.Setenv("DATABASE_URL", dbURL)
			t.Setenv("REDIS_URL", redisURL)
			t.Setenv("HTTP_PORT", val)

			if _, err := config.Load(); err == nil {
				t.Fatalf("expected error for HTTP_PORT=%q", val)
			}
		}
	})

	t.Run("rejects invalid boolean flags", func(t *testing.T) {
		clearConfigEnv(t)
		t.Setenv("DATABASE_URL", dbURL)
		t.Setenv("REDIS_URL", redisURL)
		t.Setenv("ENABLE_DEV_AUTH", "not-a-bool")
		if _, err := config.Load(); err == nil {
			t.Fatal("expected error for invalid ENABLE_DEV_AUTH")
		}

		clearConfigEnv(t)
		t.Setenv("DATABASE_URL", dbURL)
		t.Setenv("REDIS_URL", redisURL)
		t.Setenv("GEMINI_CONTEXT_CACHE_ENABLED", "not-a-bool")
		if _, err := config.Load(); err == nil {
			t.Fatal("expected error for invalid GEMINI_CONTEXT_CACHE_ENABLED")
		}
	})

	t.Run("parses GEMINI_FALLBACK_MODELS with trim, dedupe, primary exclusion, and empty/none overrides", func(t *testing.T) {
		clearConfigEnv(t)
		t.Setenv("DATABASE_URL", dbURL)
		t.Setenv("REDIS_URL", redisURL)
		t.Setenv("GEMINI_MODEL", "gemini-3.5-flash")
		t.Setenv("GEMINI_FALLBACK_MODELS", " gemini-3-flash-preview , gemini-3.5-flash , gemini-3.8-flash , gemini-3-flash-preview , ")

		cfg, err := config.Load()
		if err != nil {
			t.Fatalf("expected valid config with custom GEMINI_FALLBACK_MODELS, got: %v", err)
		}
		wantFallbacks := []string{"gemini-3-flash-preview", "gemini-3.8-flash"}
		if !reflect.DeepEqual(cfg.GeminiFallbackModels, wantFallbacks) {
			t.Fatalf("expected GeminiFallbackModels %v, got %v", wantFallbacks, cfg.GeminiFallbackModels)
		}

		for _, disableVal := range []string{"", "   ", "none", "NONE"} {
			clearConfigEnv(t)
			t.Setenv("DATABASE_URL", dbURL)
			t.Setenv("REDIS_URL", redisURL)
			t.Setenv("GEMINI_FALLBACK_MODELS", disableVal)

			disabledCfg, err := config.Load()
			if err != nil {
				t.Fatalf("expected Load() to succeed for GEMINI_FALLBACK_MODELS=%q, got: %v", disableVal, err)
			}
			if len(disabledCfg.GeminiFallbackModels) != 0 {
				t.Fatalf("expected empty GeminiFallbackModels for %q, got %v", disableVal, disabledCfg.GeminiFallbackModels)
			}
		}
	})
}
