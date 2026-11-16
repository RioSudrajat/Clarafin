package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
	_ "time/tzdata"

	"github.com/go-chi/chi/v5"
	chimiddleware "github.com/go-chi/chi/v5/middleware"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"

	"github.com/clarafin/api/internal/config"
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

	srv := &http.Server{
		Addr:              ":" + cfg.HTTPPort,
		Handler:           newRouter(cfg, jakartaLoc),
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

func newRouter(cfg *config.Config, jakartaLoc *time.Location) http.Handler {
	r := chi.NewRouter()
	r.Use(chimiddleware.RequestID)
	r.Use(chimiddleware.RealIP)
	r.Use(chimiddleware.Recoverer)

	r.Get("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status":    "ok",
			"service":   "clarafin-api",
			"env":       cfg.AppEnv,
			"timestamp": time.Now().In(jakartaLoc).Format(time.RFC3339),
		})
	})

	return r
}
