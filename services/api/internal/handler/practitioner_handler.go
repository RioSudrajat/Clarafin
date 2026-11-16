package handler

import (
	"context"
	"errors"
	"net/http"
	"strings"

	"github.com/go-chi/chi/v5"

	"github.com/clarafin/api/internal/ai"
	"github.com/clarafin/api/internal/domain"
	"github.com/clarafin/api/internal/middleware"
)

// PractitionerProvider defines public practitioner discovery and catalog package read methods.
type PractitionerProvider interface {
	ListPublicPractitioners(ctx context.Context, filter ai.PublicPractitionerFilter) ([]ai.PublicPractitionerDTO, error)
	GetPublicPractitioner(ctx context.Context, idOrCode string) (*ai.PublicPractitionerDetailDTO, error)
	ListCatalogPackages(ctx context.Context, serviceCategory string) ([]ai.CatalogPackageDTO, error)
}

// PractitionerHandler serves public practitioner discovery and catalog package endpoints.
type PractitionerHandler struct {
	provider PractitionerProvider
}

// NewPractitionerHandler constructs a PractitionerHandler backed by provider.
func NewPractitionerHandler(provider PractitionerProvider) *PractitionerHandler {
	return &PractitionerHandler{provider: provider}
}

// RegisterRoutes mounts /practitioners, /practitioners/{id}, and /catalog-packages on r (expected under /v1).
func (h *PractitionerHandler) RegisterRoutes(r chi.Router) {
	r.Get("/practitioners", h.ListPractitioners)
	r.Get("/practitioners/{id}", h.GetPractitioner)
	r.Get("/catalog-packages", h.ListCatalogPackages)
}

// ListPractitioners handles GET /v1/practitioners with optional ?tier=, ?method=, ?tag=, and ?city= filters.
func (h *PractitionerHandler) ListPractitioners(w http.ResponseWriter, r *http.Request) {
	reqID := middleware.RequestIDFromContext(r.Context())
	if h == nil || h.provider == nil {
		domain.WriteError(w, http.StatusInternalServerError, domain.ErrCodeInternalError, "Practitioner service is not initialized.", reqID)
		return
	}

	q := r.URL.Query()
	filter := ai.PublicPractitionerFilter{
		Tier:   strings.TrimSpace(q.Get("tier")),
		Method: strings.TrimSpace(q.Get("method")),
		Tag:    strings.TrimSpace(q.Get("tag")),
		City:   strings.TrimSpace(q.Get("city")),
	}

	items, err := h.provider.ListPublicPractitioners(r.Context(), filter)
	if err != nil {
		writePractitionerError(w, reqID, err)
		return
	}

	domain.WriteJSON(w, http.StatusOK, map[string]any{"practitioners": items}, reqID)
}

// GetPractitioner handles GET /v1/practitioners/{id}, accepting canonical codes ("c1".."c6") or UUIDs.
func (h *PractitionerHandler) GetPractitioner(w http.ResponseWriter, r *http.Request) {
	reqID := middleware.RequestIDFromContext(r.Context())
	if h == nil || h.provider == nil {
		domain.WriteError(w, http.StatusInternalServerError, domain.ErrCodeInternalError, "Practitioner service is not initialized.", reqID)
		return
	}

	idOrCode := strings.TrimSpace(chi.URLParam(r, "id"))
	detail, err := h.provider.GetPublicPractitioner(r.Context(), idOrCode)
	if err != nil {
		writePractitionerError(w, reqID, err)
		return
	}

	domain.WriteJSON(w, http.StatusOK, detail, reqID)
}

// ListCatalogPackages handles GET /v1/catalog-packages with optional ?service_category= filter.
func (h *PractitionerHandler) ListCatalogPackages(w http.ResponseWriter, r *http.Request) {
	reqID := middleware.RequestIDFromContext(r.Context())
	if h == nil || h.provider == nil {
		domain.WriteError(w, http.StatusInternalServerError, domain.ErrCodeInternalError, "Catalog service is not initialized.", reqID)
		return
	}

	serviceCategory := strings.TrimSpace(r.URL.Query().Get("service_category"))
	items, err := h.provider.ListCatalogPackages(r.Context(), serviceCategory)
	if err != nil {
		writePractitionerError(w, reqID, err)
		return
	}

	domain.WriteJSON(w, http.StatusOK, map[string]any{"catalog_packages": items}, reqID)
}

func writePractitionerError(w http.ResponseWriter, reqID string, err error) {
	switch {
	case errors.Is(err, ai.ErrInvalidMatchingInput):
		domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Invalid practitioner or catalog query parameters.", reqID)
	case errors.Is(err, ai.ErrPractitionerNotFound):
		domain.WriteError(w, http.StatusNotFound, domain.ErrCodeNotFound, "Practitioner not found.", reqID)
	default:
		domain.WriteError(w, http.StatusInternalServerError, domain.ErrCodeInternalError, "Failed to load practitioner or catalog data.", reqID)
	}
}
