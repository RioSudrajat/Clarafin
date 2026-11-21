package config

import "time"

// Backend-managed Gemini model routing & resilience policy.
// Keeping model selection in backend code ensures .env only stores secrets (GEMINI_API_KEY).
const (
	DefaultGeminiModel               = "gemini-3.1-flash-lite-preview"
	DefaultGeminiContextCacheEnabled = false
	DefaultGeminiAttemptTimeout      = 15 * time.Second
	DefaultGeminiCooldownDuration    = 30 * time.Second
)

const defaultFallbackModels = "gemini-3.1-flash-lite,gemini-3.5-flash,gemini-3.6-flash,gemini-3-flash-preview,gemini-2.5-flash,gemini-2.5-flash-lite"
