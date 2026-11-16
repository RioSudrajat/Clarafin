package handler

import (
	"context"
	"errors"
	"net/http"

	"github.com/google/uuid"

	"github.com/clarafin/api/internal/domain"
	"github.com/clarafin/api/internal/middleware"
	"github.com/clarafin/api/internal/service"
)

// QuotaProvider abstracts quota status reads for HTTP handlers and unit tests.
type QuotaProvider interface {
	GetQuotaStatus(ctx context.Context, userID uuid.UUID) (*service.QuotaStatus, error)
}

// QuotaHandler serves authenticated AI quota status endpoints.
type QuotaHandler struct {
	service QuotaProvider
}

// NewQuotaHandler constructs a QuotaHandler backed by the provided QuotaProvider.
func NewQuotaHandler(svc QuotaProvider) *QuotaHandler {
	return &QuotaHandler{service: svc}
}

// GetQuota handles GET /v1/ai/quota and returns the caller's plan and remaining AI action quota.
func (h *QuotaHandler) GetQuota(w http.ResponseWriter, r *http.Request) {
	reqID := middleware.RequestIDFromContext(r.Context())

	userID, ok := middleware.UserIDFromContext(r.Context())
	if !ok {
		domain.WriteError(w, http.StatusUnauthorized, domain.ErrCodeUnauthorized, "Authentication required.", reqID)
		return
	}
	if h == nil || h.service == nil {
		domain.WriteError(w, http.StatusInternalServerError, domain.ErrCodeInternalError, "Quota service is not initialized.", reqID)
		return
	}

	status, err := h.service.GetQuotaStatus(r.Context(), userID)
	if err != nil {
		switch {
		case errors.Is(err, service.ErrUserNotFound):
			domain.WriteError(w, http.StatusNotFound, domain.ErrCodeNotFound, "User account not found.", reqID)
		case errors.Is(err, service.ErrInvalidQuotaRequest):
			domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Invalid quota request.", reqID)
		default:
			domain.WriteError(w, http.StatusInternalServerError, domain.ErrCodeInternalError, "Failed to retrieve AI quota status.", reqID)
		}
		return
	}

	domain.WriteJSON(w, http.StatusOK, status, reqID)
}
