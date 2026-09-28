package auth

import (
	"context"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/httpx"
)

type contextKey struct{}

// AdminStore adalah akses data admin yang dibutuhkan handler.
type AdminStore interface {
	FindByEmail(ctx context.Context, email string) (Admin, error)
	FindByID(ctx context.Context, id string) (Admin, error)
	SetPassword(ctx context.Context, id, passwordHash string) error
}

// Handler melayani endpoint login.
type Handler struct {
	admins AdminStore
	tokens *Tokens
}

// NewHandler membuat handler auth.
func NewHandler(admins AdminStore, tokens *Tokens) *Handler {
	return &Handler{admins: admins, tokens: tokens}
}

type loginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type loginResponse struct {
	Token     string    `json:"token"`
	ExpiresAt time.Time `json:"expires_at"`
	Email     string    `json:"email"`
}

var errInvalidCredentials = &httpx.Error{Code: "unauthorized", Message: "Email atau password salah"}

// Login memverifikasi email & password lalu menerbitkan token.
func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var req loginRequest
	if err := httpx.DecodeJSON(r, &req); err != nil {
		httpx.Fail(w, r, err)
		return
	}
	if strings.TrimSpace(req.Email) == "" || req.Password == "" || len(req.Password) > maxPasswordBytes {
		httpx.Fail(w, r, httpx.Validation(map[string]string{"email": "wajib diisi", "password": "wajib diisi"}))
		return
	}

	admin, err := h.admins.FindByEmail(r.Context(), req.Email)
	switch {
	case errors.Is(err, ErrAdminNotFound):
		CheckPassword(string(dummyHash), req.Password) // samakan waktu respons
		httpx.Fail(w, r, errInvalidCredentials)
		return
	case err != nil:
		httpx.Fail(w, r, err)
		return
	}
	if !CheckPassword(admin.PasswordHash, req.Password) {
		httpx.Fail(w, r, errInvalidCredentials)
		return
	}

	token, exp, err := h.tokens.Issue(admin.ID, admin.Email)
	if err != nil {
		httpx.Fail(w, r, err)
		return
	}
	httpx.OK(w, http.StatusOK, loginResponse{Token: token, ExpiresAt: exp, Email: admin.Email}, nil)
}

// Me mengembalikan identitas admin dari token (untuk cek sesi di aplikasi).
func (h *Handler) Me(w http.ResponseWriter, r *http.Request) {
	claims := ClaimsFrom(r.Context())
	httpx.OK(w, http.StatusOK, map[string]any{
		"id":         claims.Subject,
		"email":      claims.Email,
		"expires_at": claims.ExpiresAt.Time,
	}, nil)
}

type changePasswordRequest struct {
	CurrentPassword string `json:"current_password"`
	NewPassword     string `json:"new_password"`
}

// ChangePassword mengganti password admin yang sedang login.
func (h *Handler) ChangePassword(w http.ResponseWriter, r *http.Request) {
	var req changePasswordRequest
	if err := httpx.DecodeJSON(r, &req); err != nil {
		httpx.Fail(w, r, err)
		return
	}
	admin, err := h.admins.FindByID(r.Context(), ClaimsFrom(r.Context()).Subject)
	if errors.Is(err, ErrAdminNotFound) {
		httpx.Fail(w, r, httpx.ErrUnauthorized)
		return
	}
	if err != nil {
		httpx.Fail(w, r, err)
		return
	}
	if !CheckPassword(admin.PasswordHash, req.CurrentPassword) {
		httpx.Fail(w, r, httpx.Validation(map[string]string{"current_password": "password lama salah"}))
		return
	}
	hash, err := HashPassword(req.NewPassword)
	if err != nil {
		httpx.Fail(w, r, httpx.Validation(map[string]string{"new_password": err.Error()}))
		return
	}
	if err := h.admins.SetPassword(r.Context(), admin.ID, hash); err != nil {
		httpx.Fail(w, r, err)
		return
	}
	httpx.OK(w, http.StatusOK, map[string]string{"status": "password diganti"}, nil)
}

// Require adalah middleware yang menolak request tanpa token admin yang valid.
func (h *Handler) Require(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		raw, ok := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer ")
		if !ok || raw == "" {
			httpx.Fail(w, r, httpx.ErrUnauthorized)
			return
		}
		claims, err := h.tokens.Verify(raw)
		if err != nil {
			httpx.Fail(w, r, httpx.ErrUnauthorized)
			return
		}
		next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), contextKey{}, claims)))
	})
}

// ClaimsFrom mengambil claims yang dipasang oleh Require.
func ClaimsFrom(ctx context.Context) *Claims {
	claims, _ := ctx.Value(contextKey{}).(*Claims)
	return claims
}
