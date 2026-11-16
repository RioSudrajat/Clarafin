package handler

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgconn"

	"github.com/clarafin/api/internal/config"
	"github.com/clarafin/api/internal/domain"
	"github.com/clarafin/api/internal/middleware"
	"github.com/clarafin/api/internal/repository"
)

const devTokenTTL = 24 * time.Hour

// DevUserProvisioner abstracts user upsert for dev-token issuance and unit testing.
type DevUserProvisioner interface {
	EnsureDevUserAccount(ctx context.Context, arg repository.EnsureDevUserParams) (repository.User, error)
}

// DevAuthHandler issues local development HS256 JWTs backed by Postgres users.
type DevAuthHandler struct {
	cfg   *config.Config
	store DevUserProvisioner
}

// DevTokenRequest configures optional user attributes when requesting a dev token.
type DevTokenRequest struct {
	UserID   string `json:"user_id,omitempty"`
	Email    string `json:"email,omitempty"`
	FullName string `json:"full_name,omitempty"`
}

// DevUserSummary represents the provisioned user returned alongside a dev token.
type DevUserSummary struct {
	ID       uuid.UUID `json:"id"`
	Email    string    `json:"email"`
	FullName string    `json:"full_name"`
}

// DevTokenResponse matches Clarafin's snake_case JSON auth payload inside the standard data envelope.
type DevTokenResponse struct {
	AccessToken string         `json:"access_token"`
	TokenType   string         `json:"token_type"`
	ExpiresIn   int64          `json:"expires_in"`
	ExpiresAt   time.Time      `json:"expires_at"`
	User        DevUserSummary `json:"user"`
}

type devJWTClaims struct {
	Email string `json:"email"`
	Role  string `json:"role"`
	jwt.RegisteredClaims
}

// NewDevAuthHandler constructs a DevAuthHandler.
func NewDevAuthHandler(cfg *config.Config, store DevUserProvisioner) *DevAuthHandler {
	return &DevAuthHandler{
		cfg:   cfg,
		store: store,
	}
}

// IssueToken handles POST /v1/dev/token strictly when dev auth is enabled in development mode.
func (h *DevAuthHandler) IssueToken(w http.ResponseWriter, r *http.Request) {
	reqID := middleware.RequestIDFromContext(r.Context())

	// Defense-in-depth guard in case a caller invokes the handler outside router gating.
	if h.cfg == nil || !h.cfg.EnableDevAuth || h.cfg.AppEnv != "development" || len(h.cfg.DevJWTSecret) < 32 {
		domain.WriteError(w, http.StatusNotFound, domain.ErrCodeNotFound, "Not found.", reqID)
		return
	}
	if h.store == nil {
		domain.WriteError(w, http.StatusInternalServerError, domain.ErrCodeInternalError, "User store is not initialized.", reqID)
		return
	}

	reqBody, errMsg := decodeDevTokenRequest(w, r)
	if errMsg != "" {
		domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, errMsg, reqID)
		return
	}

	email := strings.ToLower(strings.TrimSpace(reqBody.Email))
	if email == "" {
		email = "dev@clarafin.local"
	}
	if !isValidDevEmail(email) {
		domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "Invalid email format.", reqID)
		return
	}

	fullName := strings.TrimSpace(reqBody.FullName)
	if fullName == "" {
		fullName = "Clarafin Dev User"
	}
	if len(fullName) > 120 {
		domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "full_name must be 120 characters or fewer.", reqID)
		return
	}

	var userID uuid.UUID
	rawID := strings.TrimSpace(reqBody.UserID)
	if rawID != "" {
		parsed, err := uuid.Parse(rawID)
		if err != nil || parsed == uuid.Nil {
			domain.WriteError(w, http.StatusBadRequest, domain.ErrCodeInvalidRequest, "user_id must be a valid non-nil UUID.", reqID)
			return
		}
		userID = parsed
	} else {
		// Derive a deterministic UUID per email so repeated requests upsert the same user row cleanly.
		userID = uuid.NewSHA1(uuid.NameSpaceOID, []byte("clarafin-dev:"+email))
	}

	user, err := h.store.EnsureDevUserAccount(r.Context(), repository.EnsureDevUserParams{
		ID:       userID,
		Email:    email,
		FullName: fullName,
	})
	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) && pgErr.Code == "23505" {
			domain.WriteError(w, http.StatusConflict, domain.ErrCodeConflict, "A user with this email already exists with a different ID.", reqID)
			return
		}
		domain.WriteError(w, http.StatusInternalServerError, domain.ErrCodeInternalError, "Failed to provision dev user.", reqID)
		return
	}

	now := time.Now().UTC()
	expiresAt := now.Add(devTokenTTL)
	claims := devJWTClaims{
		Email: user.Email,
		Role:  "authenticated",
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   user.ID.String(),
			Issuer:    "clarafin-dev",
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(expiresAt),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signed, err := token.SignedString([]byte(h.cfg.DevJWTSecret))
	if err != nil {
		domain.WriteError(w, http.StatusInternalServerError, domain.ErrCodeInternalError, "Failed to sign dev token.", reqID)
		return
	}

	domain.WriteJSON(w, http.StatusOK, DevTokenResponse{
		AccessToken: signed,
		TokenType:   "Bearer",
		ExpiresIn:   int64(devTokenTTL.Seconds()),
		ExpiresAt:   expiresAt,
		User: DevUserSummary{
			ID:       user.ID,
			Email:    user.Email,
			FullName: user.FullName,
		},
	}, reqID)
}

func decodeDevTokenRequest(w http.ResponseWriter, r *http.Request) (DevTokenRequest, string) {
	var body DevTokenRequest
	if r.Body == nil {
		return body, ""
	}

	limited := http.MaxBytesReader(w, r.Body, 1<<20)
	dec := json.NewDecoder(limited)
	dec.DisallowUnknownFields()

	if err := dec.Decode(&body); err != nil {
		if errors.Is(err, io.EOF) {
			return body, ""
		}
		return body, "Invalid JSON request body."
	}

	if err := dec.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return body, "Request body must contain a single JSON object."
	}
	return body, ""
}

func isValidDevEmail(email string) bool {
	if len(email) < 3 || len(email) > 254 || strings.ContainsAny(email, " \t\r\n") {
		return false
	}
	at := strings.IndexByte(email, '@')
	if at <= 0 || at != strings.LastIndexByte(email, '@') {
		return false
	}
	domainPart := email[at+1:]
	return len(domainPart) > 0 && !strings.HasPrefix(domainPart, ".") && !strings.HasSuffix(domainPart, ".")
}
