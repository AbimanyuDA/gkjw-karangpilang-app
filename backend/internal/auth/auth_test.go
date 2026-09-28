package auth

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

var secret = []byte(strings.Repeat("s", 32))

type fakeAdmins map[string]Admin

func (f fakeAdmins) FindByEmail(_ context.Context, email string) (Admin, error) {
	a, ok := f[NormalizeEmail(email)]
	if !ok {
		return Admin{}, ErrAdminNotFound
	}
	return a, nil
}

func (f fakeAdmins) FindByID(_ context.Context, id string) (Admin, error) {
	for _, a := range f {
		if a.ID == id {
			return a, nil
		}
	}
	return Admin{}, ErrAdminNotFound
}

func (f fakeAdmins) SetPassword(_ context.Context, id, hash string) error {
	for k, a := range f {
		if a.ID == id {
			a.PasswordHash = hash
			f[k] = a
			return nil
		}
	}
	return ErrAdminNotFound
}

func newTestHandler(t *testing.T) *Handler {
	t.Helper()
	hash, err := HashPassword("rahasia-gereja")
	if err != nil {
		t.Fatal(err)
	}
	admins := fakeAdmins{"admin@gkjw.org": {ID: "a1", Email: "admin@gkjw.org", PasswordHash: hash}}
	return NewHandler(admins, NewTokens(secret, time.Hour))
}

func TestHashPassword_Rules(t *testing.T) {
	if _, err := HashPassword("pendek"); err == nil {
		t.Error("short password must be rejected")
	}
	if _, err := HashPassword(strings.Repeat("a", 73)); err == nil {
		t.Error(">72 byte password must be rejected")
	}
	hash, err := HashPassword("cukup-panjang-123")
	if err != nil || !CheckPassword(hash, "cukup-panjang-123") || CheckPassword(hash, "salah") {
		t.Errorf("hash/check roundtrip failed: %v", err)
	}
}

func TestTokens_RoundTripAndExpiry(t *testing.T) {
	tok := NewTokens(secret, time.Hour)
	raw, exp, err := tok.Issue("a1", "admin@gkjw.org")
	if err != nil {
		t.Fatal(err)
	}
	claims, err := tok.Verify(raw)
	if err != nil || claims.Subject != "a1" || claims.Email != "admin@gkjw.org" {
		t.Fatalf("verify: %v %+v", err, claims)
	}

	tok.now = func() time.Time { return exp.Add(time.Second) }
	if _, err := tok.Verify(raw); err == nil {
		t.Error("expired token must be rejected")
	}
}

func TestTokens_RejectsForgedAndNoneAlg(t *testing.T) {
	tok := NewTokens(secret, time.Hour)
	other := NewTokens([]byte(strings.Repeat("x", 32)), time.Hour)
	forged, _, _ := other.Issue("a1", "admin@gkjw.org")
	if _, err := tok.Verify(forged); err == nil {
		t.Error("token signed with another secret must be rejected")
	}

	none := jwt.NewWithClaims(jwt.SigningMethodNone, Claims{RegisteredClaims: jwt.RegisteredClaims{
		Subject: "a1", Issuer: issuer, ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour)),
	}})
	raw, _ := none.SignedString(jwt.UnsafeAllowNoneSignatureType)
	if _, err := tok.Verify(raw); err == nil {
		t.Error("alg=none must be rejected")
	}
}

func login(t *testing.T, h *Handler, body string) *httptest.ResponseRecorder {
	t.Helper()
	req := httptest.NewRequest("POST", "/auth/login", strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	h.Login(rec, req)
	return rec
}

func TestLogin(t *testing.T) {
	h := newTestHandler(t)
	tests := []struct {
		name string
		body string
		want int
	}{
		{"success (case-insensitive email)", `{"email":" Admin@GKJW.org ","password":"rahasia-gereja"}`, http.StatusOK},
		{"wrong password", `{"email":"admin@gkjw.org","password":"salah-sekali"}`, http.StatusUnauthorized},
		{"unknown email", `{"email":"x@y.z","password":"rahasia-gereja"}`, http.StatusUnauthorized},
		{"empty", `{"email":"","password":""}`, http.StatusBadRequest},
		{"bad json", `{`, http.StatusBadRequest},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rec := login(t, h, tt.body)
			if rec.Code != tt.want {
				t.Errorf("status = %d, want %d (%s)", rec.Code, tt.want, rec.Body)
			}
		})
	}
}

func TestLogin_SameMessageForUnknownEmailAndWrongPassword(t *testing.T) {
	h := newTestHandler(t)
	a := login(t, h, `{"email":"admin@gkjw.org","password":"salah-sekali"}`).Body.String()
	b := login(t, h, `{"email":"x@y.z","password":"salah-sekali"}`).Body.String()
	if a != b {
		t.Errorf("responses differ, enables email enumeration:\n%s\n%s", a, b)
	}
}

func TestRequireAndMe(t *testing.T) {
	h := newTestHandler(t)
	var resp struct {
		Data loginResponse `json:"data"`
	}
	if err := json.Unmarshal(login(t, h, `{"email":"admin@gkjw.org","password":"rahasia-gereja"}`).Body.Bytes(), &resp); err != nil {
		t.Fatal(err)
	}

	protected := h.Require(http.HandlerFunc(h.Me))
	for name, header := range map[string]string{
		"no header":    "",
		"wrong scheme": "Basic abc",
		"garbage":      "Bearer abc.def.ghi",
	} {
		t.Run(name, func(t *testing.T) {
			req := httptest.NewRequest("GET", "/auth/me", nil)
			if header != "" {
				req.Header.Set("Authorization", header)
			}
			rec := httptest.NewRecorder()
			protected.ServeHTTP(rec, req)
			if rec.Code != http.StatusUnauthorized {
				t.Errorf("status = %d", rec.Code)
			}
		})
	}

	req := httptest.NewRequest("GET", "/auth/me", nil)
	req.Header.Set("Authorization", "Bearer "+resp.Data.Token)
	rec := httptest.NewRecorder()
	protected.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK || !strings.Contains(rec.Body.String(), "admin@gkjw.org") {
		t.Errorf("status = %d body = %s", rec.Code, rec.Body)
	}
}

func TestChangePassword(t *testing.T) {
	h := newTestHandler(t)
	token, _, _ := h.tokens.Issue("a1", "admin@gkjw.org")
	change := func(body string) *httptest.ResponseRecorder {
		req := httptest.NewRequest("PUT", "/auth/password", strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		rec := httptest.NewRecorder()
		h.Require(http.HandlerFunc(h.ChangePassword)).ServeHTTP(rec, req)
		return rec
	}

	if rec := change(`{"current_password":"salah-sekali-123","new_password":"password-baru-456"}`); rec.Code != http.StatusBadRequest {
		t.Errorf("wrong current password: status = %d", rec.Code)
	}
	if rec := change(`{"current_password":"rahasia-gereja","new_password":"pendek"}`); rec.Code != http.StatusBadRequest {
		t.Errorf("weak new password: status = %d", rec.Code)
	}
	if rec := change(`{"current_password":"rahasia-gereja","new_password":"password-baru-456"}`); rec.Code != http.StatusOK {
		t.Fatalf("status = %d body = %s", rec.Code, rec.Body)
	}
	if login(t, h, `{"email":"admin@gkjw.org","password":"password-baru-456"}`).Code != http.StatusOK {
		t.Error("login with new password failed")
	}
	if login(t, h, `{"email":"admin@gkjw.org","password":"rahasia-gereja"}`).Code != http.StatusUnauthorized {
		t.Error("old password must stop working")
	}
}
