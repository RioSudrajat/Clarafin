package main

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
	_ "time/tzdata"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"

	"github.com/clarafin/api/internal/adapter/gemini"
	"github.com/clarafin/api/internal/ai"
	"github.com/clarafin/api/internal/config"
	"github.com/clarafin/api/internal/repository"
	"github.com/clarafin/api/internal/server"
	"github.com/clarafin/api/internal/service"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to load configuration: %v\n", err)
		os.Exit(1)
	}

	logger, err := newLogger(cfg.AppEnv, cfg.LogLevel)
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to initialize logger: %v\n", err)
		os.Exit(1)
	}
	defer func() {
		_ = logger.Sync()
	}()

	jakartaLoc, err := time.LoadLocation("Asia/Jakarta")
	if err != nil {
		logger.Fatal("failed to load Asia/Jakarta timezone", zap.Error(err))
	}

	startupCtx, startupCancel := context.WithTimeout(context.Background(), 10*time.Second)
	pool, err := pgxpool.New(startupCtx, cfg.DatabaseURL)
	if err != nil {
		startupCancel()
		logger.Fatal("failed to initialize postgres pool", zap.Error(err))
	}
	defer pool.Close()

	if err := pool.Ping(startupCtx); err != nil {
		startupCancel()
		logger.Fatal("failed to ping postgres", zap.Error(err))
	}

	redisOpts, err := redis.ParseURL(cfg.RedisURL)
	if err != nil {
		startupCancel()
		logger.Fatal("failed to parse redis url", zap.Error(err))
	}
	rdb := redis.NewClient(redisOpts)
	defer func() {
		_ = rdb.Close()
	}()

	if err := rdb.Ping(startupCtx).Err(); err != nil {
		startupCancel()
		logger.Fatal("failed to ping redis", zap.Error(err))
	}
	startupCancel()

	store := repository.NewStore(pool)
	quotaService := service.NewQuotaService(store, service.WithJakartaLocation(jakartaLoc))
	trackerService := service.NewTrackerService(
		store,
		service.WithTrackerJakartaLocation(jakartaLoc),
		service.WithTrackerQuotaProvider(quotaService),
	)
	financialTools := ai.NewFinancialTools(store, ai.WithFinancialJakartaLocation(jakartaLoc))
	actionTools := ai.NewActionTools(
		store,
		ai.WithActionJakartaLocation(jakartaLoc),
		ai.WithActionFinancialTools(financialTools),
	)
	matchingTool := ai.NewMatchingTool(store, ai.WithMatchingJakartaLocation(jakartaLoc))

	geminiCtx, geminiCancel := context.WithTimeout(context.Background(), 10*time.Second)
	geminiClient, err := gemini.NewClient(geminiCtx, gemini.Config{
		APIKey:              cfg.GeminiAPIKey,
		DefaultModel:        cfg.GeminiModel,
		FallbackModels:      cfg.GeminiFallbackModels,
		ContextCacheEnabled: cfg.GeminiContextCacheEnabled,
		AttemptTimeout:      config.DefaultGeminiAttemptTimeout,
		CooldownDuration:    config.DefaultGeminiCooldownDuration,
		Logger:              logger,
	})
	geminiCancel()
	if err != nil {
		logger.Fatal("failed to initialize gemini client", zap.Error(err))
	}
	if !geminiClient.IsConfigured() {
		logger.Warn("GEMINI_API_KEY is empty; non-greeting AI endpoints will return unavailable until configured")
	}

	orchestrator := ai.NewOrchestrator(ai.OrchestratorConfig{
		Model:      cfg.GeminiModel,
		LLM:        geminiClient,
		Quota:      quotaService,
		Financial:  financialTools,
		Actions:    actionTools,
		Matching:   matchingTool,
		DraftRepo:  store,
		Logger:     logger,
		JakartaLoc: jakartaLoc,
	})

	router := server.NewRouter(server.Dependencies{
		Config:              cfg,
		Logger:              logger,
		Store:               store,
		QuotaService:        quotaService,
		TrackerService:      trackerService,
		PractitionerCatalog: matchingTool,
		AIService:           orchestrator,
		Redis:               rdb,
		JakartaLoc:          jakartaLoc,
	})

	srv := &http.Server{
		Addr:              ":" + cfg.HTTPPort,
		Handler:           router,
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       30 * time.Second,
		WriteTimeout:      60 * time.Second,
		IdleTimeout:       120 * time.Second,
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	errCh := make(chan error, 1)
	go func() {
		logger.Info(
			"starting clarafin api server",
			zap.String("addr", srv.Addr),
			zap.String("env", cfg.AppEnv),
			zap.String("gemini_model", cfg.GeminiModel),
			zap.Strings("gemini_fallback_models", cfg.GeminiFallbackModels),
			zap.Bool("dev_auth_enabled", cfg.EnableDevAuth && cfg.AppEnv == "development"),
		)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			errCh <- err
		}
		close(errCh)
	}()

	select {
	case <-ctx.Done():
		logger.Info("shutdown signal received")
	case err := <-errCh:
		if err != nil {
			logger.Fatal("http server exited unexpectedly", zap.Error(err))
		}
		return
	}

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		logger.Error("graceful shutdown failed", zap.Error(err))
		os.Exit(1)
	}
	logger.Info("server stopped cleanly")
}

func newLogger(appEnv, level string) (*zap.Logger, error) {
	var zapCfg zap.Config
	if appEnv == "development" {
		zapCfg = zap.NewDevelopmentConfig()
	} else {
		zapCfg = zap.NewProductionConfig()
	}

	parsedLevel, err := zapcore.ParseLevel(level)
	if err != nil {
		return nil, fmt.Errorf("parse log level %q: %w", level, err)
	}
	zapCfg.Level = zap.NewAtomicLevelAt(parsedLevel)
	return zapCfg.Build()
}
