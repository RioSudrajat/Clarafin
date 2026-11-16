package middleware

import (
	"context"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rsa"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"math/big"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"

	"github.com/clarafin/api/internal/config"
	"github.com/clarafin/api/internal/domain"
)

// ContextWithUserID stores a non-nil authenticated user UUID in ctx.
func ContextWithUserID(ctx context.Context, userID uuid.UUID) context.Context {
	if ctx == nil {
		ctx = context.Background()
	}
	return context.WithValue(ctx, userIDContextKey, userID)
}

// UserIDFromContext extracts the authenticated user UUID injected by RequireAuth.
func UserIDFromContext(ctx context.Context) (uuid.UUID, bool) {
	if ctx == nil {
		return uuid.Nil, false
	}
	id, ok := ctx.Value(userIDContextKey).(uuid.UUID)
	if !ok || id == uuid.Nil {
		return uuid.Nil, false
	}
	return id, true
}

// RequireAuth validates Bearer JWTs (HS256 via SupabaseJWTSecret/DevJWTSecret and/or RS*/ES* via JWKS)
// and injects the authenticated UUID `sub` claim into request context.
func RequireAuth(cfg *config.Config) func(http.Handler) http.Handler {
	verifier := newJWTVerifier(cfg)

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			reqID := RequestIDFromContext(r.Context())

			tokenStr, ok := extractBearerToken(r.Header.Get("Authorization"))
			if !ok {
				domain.WriteError(w, http.StatusUnauthorized, domain.ErrCodeUnauthorized, "Missing or invalid authorization token.", reqID)
				return
			}

			userID, err := verifier.verify(r.Context(), tokenStr)
			if err != nil {
				domain.WriteError(w, http.StatusUnauthorized, domain.ErrCodeUnauthorized, "Invalid or expired authorization token.", reqID)
				return
			}

			next.ServeHTTP(w, r.WithContext(ContextWithUserID(r.Context(), userID)))
		})
	}
}

func extractBearerToken(header string) (string, bool) {
	if header == "" {
		return "", false
	}
	parts := strings.SplitN(strings.TrimSpace(header), " ", 2)
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
		return "", false
	}
	token := strings.TrimSpace(parts[1])
	if token == "" || strings.ContainsAny(token, " \t\r\n") {
		return "", false
	}
	return token, true
}

type jwtVerifier struct {
	supabaseSecret []byte
	devSecret      []byte
	jwks           *jwksCache
	validMethods   []string
}

func newJWTVerifier(cfg *config.Config) *jwtVerifier {
	v := &jwtVerifier{}
	if cfg == nil {
		return v
	}

	hasHMAC := false
	if cfg.SupabaseJWTSecret != "" {
		v.supabaseSecret = []byte(cfg.SupabaseJWTSecret)
		hasHMAC = true
	}
	// Dev secret is accepted strictly in development mode when explicitly enabled.
	if cfg.EnableDevAuth && cfg.AppEnv == "development" && cfg.DevJWTSecret != "" {
		v.devSecret = []byte(cfg.DevJWTSecret)
		hasHMAC = true
	}
	if hasHMAC {
		v.validMethods = append(v.validMethods, jwt.SigningMethodHS256.Alg())
	}

	if cfg.SupabaseJWKSURL != "" {
		v.jwks = newJWKSCache(cfg.SupabaseJWKSURL)
		v.validMethods = append(
			v.validMethods,
			jwt.SigningMethodES256.Alg(),
			jwt.SigningMethodES384.Alg(),
			jwt.SigningMethodES512.Alg(),
			jwt.SigningMethodRS256.Alg(),
			jwt.SigningMethodRS384.Alg(),
			jwt.SigningMethodRS512.Alg(),
		)
	}

	return v
}

func (v *jwtVerifier) verify(ctx context.Context, tokenStr string) (uuid.UUID, error) {
	if len(v.validMethods) == 0 {
		return uuid.Nil, errors.New("no JWT verifier configured")
	}

	// Fast path tries Supabase secret or JWKS; dev secret is retried only on signature mismatch when enabled.
	claims, err := v.parseWithKeyfunc(tokenStr, func(tok *jwt.Token) (any, error) {
		return v.resolveKey(ctx, tok, false)
	})
	if err != nil && len(v.devSecret) > 0 && errors.Is(err, jwt.ErrTokenSignatureInvalid) {
		claims, err = v.parseWithKeyfunc(tokenStr, func(tok *jwt.Token) (any, error) {
			return v.resolveKey(ctx, tok, true)
		})
	}
	if err != nil {
		return uuid.Nil, err
	}

	sub, err := claims.GetSubject()
	if err != nil || sub == "" {
		return uuid.Nil, errors.New("missing subject claim")
	}
	userID, err := uuid.Parse(sub)
	if err != nil || userID == uuid.Nil {
		return uuid.Nil, errors.New("invalid subject uuid")
	}
	return userID, nil
}

func (v *jwtVerifier) parseWithKeyfunc(tokenStr string, kf jwt.Keyfunc) (*jwt.RegisteredClaims, error) {
	claims := &jwt.RegisteredClaims{}
	tok, err := jwt.ParseWithClaims(
		tokenStr,
		claims,
		kf,
		jwt.WithValidMethods(v.validMethods),
		jwt.WithExpirationRequired(),
	)
	if err != nil || tok == nil || !tok.Valid {
		return nil, fmt.Errorf("jwt validation failed: %w", err)
	}
	return claims, nil
}

func (v *jwtVerifier) resolveKey(ctx context.Context, tok *jwt.Token, tryDevSecret bool) (any, error) {
	if tok.Method == nil || tok.Method.Alg() == "" || strings.EqualFold(tok.Method.Alg(), "none") {
		return nil, errors.New("disallowed signing algorithm")
	}

	switch tok.Method.(type) {
	case *jwt.SigningMethodHMAC:
		if tok.Method.Alg() != jwt.SigningMethodHS256.Alg() {
			return nil, errors.New("unexpected HMAC algorithm")
		}
		if tryDevSecret && len(v.devSecret) > 0 {
			return v.devSecret, nil
		}
		if len(v.supabaseSecret) > 0 {
			return v.supabaseSecret, nil
		}
		if len(v.devSecret) > 0 {
			return v.devSecret, nil
		}
		return nil, errors.New("HMAC secret not configured")

	case *jwt.SigningMethodECDSA, *jwt.SigningMethodRSA:
		if v.jwks == nil {
			return nil, errors.New("JWKS verifier not configured")
		}
		kid, _ := tok.Header["kid"].(string)
		return v.jwks.lookupKey(ctx, kid, tok.Method)

	default:
		return nil, errors.New("unsupported signing method")
	}
}

type jwkEntry struct {
	kid string
	alg string
	key any
}

type jwksCache struct {
	url                string
	client             *http.Client
	ttl                time.Duration
	unknownRefreshWait time.Duration

	mu                 sync.RWMutex
	keys               map[string]jwkEntry
	ordered            []jwkEntry
	expiresAt          time.Time
	lastUnknownRefresh time.Time
}

func newJWKSCache(jwksURL string) *jwksCache {
	return &jwksCache{
		url:                jwksURL,
		client:             &http.Client{Timeout: 5 * time.Second},
		ttl:                10 * time.Minute,
		unknownRefreshWait: 5 * time.Second,
		keys:               make(map[string]jwkEntry),
	}
}

func (c *jwksCache) lookupKey(ctx context.Context, kid string, method jwt.SigningMethod) (any, error) {
	now := time.Now()
	c.mu.RLock()
	valid := now.Before(c.expiresAt)
	entry, found := c.findLocked(kid)
	c.mu.RUnlock()

	if !valid || !found {
		if err := c.refresh(ctx, !found && valid); err != nil && !valid {
			return nil, err
		}
		c.mu.RLock()
		entry, found = c.findLocked(kid)
		c.mu.RUnlock()
	}

	if !found {
		return nil, errors.New("matching JWKS key not found")
	}
	if entry.alg != "" && entry.alg != method.Alg() {
		return nil, errors.New("JWK algorithm mismatch")
	}

	switch m := method.(type) {
	case *jwt.SigningMethodECDSA:
		ecKey, ok := entry.key.(*ecdsa.PublicKey)
		if !ok {
			return nil, errors.New("JWK key is not ECDSA")
		}
		if !ecdsaCurveMatchesAlg(ecKey.Curve, m.Alg()) {
			return nil, errors.New("ECDSA curve mismatch")
		}
		return ecKey, nil
	case *jwt.SigningMethodRSA:
		rsaKey, ok := entry.key.(*rsa.PublicKey)
		if !ok {
			return nil, errors.New("JWK key is not RSA")
		}
		return rsaKey, nil
	default:
		return nil, errors.New("unsupported asymmetric signing method")
	}
}

func (c *jwksCache) findLocked(kid string) (jwkEntry, bool) {
	if kid != "" {
		e, ok := c.keys[kid]
		return e, ok
	}
	if len(c.ordered) == 1 {
		return c.ordered[0], true
	}
	return jwkEntry{}, false
}

func (c *jwksCache) refresh(ctx context.Context, onUnknownKID bool) error {
	c.mu.Lock()
	defer c.mu.Unlock()

	now := time.Now()
	if !onUnknownKID && now.Before(c.expiresAt) {
		return nil
	}
	// Rate-limit refreshes triggered by unknown kids so spoofed headers cannot DoS the JWKS endpoint.
	if onUnknownKID && !c.lastUnknownRefresh.IsZero() && now.Sub(c.lastUnknownRefresh) < c.unknownRefreshWait {
		return errors.New("JWKS unknown-kid refresh throttled")
	}

	reqCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	req, err := http.NewRequestWithContext(reqCtx, http.MethodGet, c.url, nil)
	if err != nil {
		return err
	}
	resp, err := c.client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("JWKS endpoint returned HTTP %d", resp.StatusCode)
	}

	var doc struct {
		Keys []rawJWK `json:"keys"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&doc); err != nil {
		return fmt.Errorf("decode JWKS response: %w", err)
	}

	nextKeys := make(map[string]jwkEntry, len(doc.Keys))
	ordered := make([]jwkEntry, 0, len(doc.Keys))
	for _, raw := range doc.Keys {
		if raw.Use != "" && raw.Use != "sig" {
			continue
		}
		pub, err := raw.toPublicKey()
		if err != nil {
			continue
		}
		entry := jwkEntry{kid: raw.Kid, alg: raw.Alg, key: pub}
		if raw.Kid != "" {
			nextKeys[raw.Kid] = entry
		}
		ordered = append(ordered, entry)
	}

	c.keys = nextKeys
	c.ordered = ordered
	c.expiresAt = now.Add(c.ttl)
	if onUnknownKID {
		c.lastUnknownRefresh = now
	}
	return nil
}

type rawJWK struct {
	Kty string `json:"kty"`
	Use string `json:"use"`
	Alg string `json:"alg"`
	Kid string `json:"kid"`
	Crv string `json:"crv"`
	X   string `json:"x"`
	Y   string `json:"y"`
	N   string `json:"n"`
	E   string `json:"e"`
}

func (j rawJWK) toPublicKey() (any, error) {
	switch j.Kty {
	case "EC":
		var curve elliptic.Curve
		switch j.Crv {
		case "P-256":
			curve = elliptic.P256()
		case "P-384":
			curve = elliptic.P384()
		case "P-521":
			curve = elliptic.P521()
		default:
			return nil, errors.New("unsupported EC curve")
		}
		xBytes, err := base64.RawURLEncoding.DecodeString(j.X)
		if err != nil {
			return nil, err
		}
		yBytes, err := base64.RawURLEncoding.DecodeString(j.Y)
		if err != nil {
			return nil, err
		}
		pub := &ecdsa.PublicKey{
			Curve: curve,
			X:     new(big.Int).SetBytes(xBytes),
			Y:     new(big.Int).SetBytes(yBytes),
		}
		if !curve.IsOnCurve(pub.X, pub.Y) {
			return nil, errors.New("EC point not on curve")
		}
		return pub, nil

	case "RSA":
		nBytes, err := base64.RawURLEncoding.DecodeString(j.N)
		if err != nil {
			return nil, err
		}
		eBytes, err := base64.RawURLEncoding.DecodeString(j.E)
		if err != nil {
			return nil, err
		}
		n := new(big.Int).SetBytes(nBytes)
		e := int(new(big.Int).SetBytes(eBytes).Int64())
		if n.Sign() <= 0 || e < 3 {
			return nil, errors.New("invalid RSA public key")
		}
		return &rsa.PublicKey{N: n, E: e}, nil

	default:
		return nil, errors.New("unsupported JWK key type")
	}
}

func ecdsaCurveMatchesAlg(curve elliptic.Curve, alg string) bool {
	switch alg {
	case jwt.SigningMethodES256.Alg():
		return curve == elliptic.P256()
	case jwt.SigningMethodES384.Alg():
		return curve == elliptic.P384()
	case jwt.SigningMethodES512.Alg():
		return curve == elliptic.P521()
	default:
		return false
	}
}
