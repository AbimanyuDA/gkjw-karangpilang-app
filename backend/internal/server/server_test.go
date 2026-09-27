package server

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/auth"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/resource"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/upload"
)

type pinger struct{ err error }

func (p pinger) Ping(context.Context) error { return p.err }

type noAdmins struct{}

func (noAdmins) FindByEmail(context.Context, string) (auth.Admin, error) {
	return auth.Admin{}, auth.ErrAdminNotFound
}

type emptyRepo struct{ resource.Repository }

func (emptyRepo) List(context.Context, resource.Resource, resource.ListQuery) ([]resource.Row, int, error) {
	return nil, 0, nil
}

func newTestRouter(t *testing.T, db Pinger, trustProxy bool) (http.Handler, *auth.Tokens) {
	t.Helper()
	st, err := upload.NewStorage(t.TempDir(), "http://localhost")
	if err != nil {
		t.Fatal(err)
	}
	tokens := auth.NewTokens([]byte(strings.Repeat("k", 32)), time.Hour)
	return NewRouter(Deps{
		DB:         db,
		Repo:       emptyRepo{},
		Auth:       auth.NewHandler(noAdmins{}, tokens),
		Uploads:    upload.NewHandler(st),
		TrustProxy: trustProxy,
	}), tokens
}

func serve(h http.Handler, req *http.Request) *httptest.ResponseRecorder {
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	return rec
}

func TestHealthz(t *testing.T) {
	ok, _ := newTestRouter(t, pinger{}, false)
	if rec := serve(ok, httptest.NewRequest("GET", "/healthz", nil)); rec.Code != http.StatusOK {
		t.Errorf("healthy: status = %d", rec.Code)
	}
	down, _ := newTestRouter(t, pinger{err: errors.New("db down")}, false)
	if rec := serve(down, httptest.NewRequest("GET", "/healthz", nil)); rec.Code != http.StatusInternalServerError {
		t.Errorf("unhealthy: status = %d", rec.Code)
	}
}

func TestPublicRoutesAreCacheableAndOpen(t *testing.T) {
	h, _ := newTestRouter(t, pinger{}, false)
	rec := serve(h, httptest.NewRequest("GET", "/api/v1/agenda", nil))
	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d", rec.Code)
	}
	if rec.Header().Get("Cache-Control") != publicCache {
		t.Errorf("Cache-Control = %q", rec.Header().Get("Cache-Control"))
	}
	if rec.Header().Get("X-Content-Type-Options") != "nosniff" {
		t.Error("missing security header")
	}
}

func TestAdminRoutesRequireToken(t *testing.T) {
	h, tokens := newTestRouter(t, pinger{}, false)
	for _, tc := range []struct{ method, path string }{
		{"GET", "/api/v1/admin/agenda"},
		{"POST", "/api/v1/admin/agenda"},
		{"DELETE", "/api/v1/admin/agenda/6f1c1f4e-6a8e-4c43-9a57-2b1f4f7d9a10"},
		{"PUT", "/api/v1/admin/sapaan-config"},
		{"POST", "/api/v1/admin/uploads?bucket=banners"},
		{"GET", "/api/v1/auth/me"},
	} {
		rec := serve(h, httptest.NewRequest(tc.method, tc.path, nil))
		if rec.Code != http.StatusUnauthorized {
			t.Errorf("%s %s without token: status = %d", tc.method, tc.path, rec.Code)
		}
	}

	token, _, _ := tokens.Issue("a1", "admin@gkjw.org")
	req := httptest.NewRequest("GET", "/api/v1/admin/agenda", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rec := serve(h, req)
	if rec.Code != http.StatusOK {
		t.Errorf("with token: status = %d", rec.Code)
	}
	if rec.Header().Get("Cache-Control") != "no-store" {
		t.Errorf("admin responses must not be cached, got %q", rec.Header().Get("Cache-Control"))
	}
}

func TestLoginRateLimitedPerIP(t *testing.T) {
	h, _ := newTestRouter(t, pinger{}, true)
	attempt := func(ip string) int {
		req := httptest.NewRequest("POST", "/api/v1/auth/login", strings.NewReader(`{"email":"a@b.c","password":"x"}`))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("X-Real-IP", ip)
		return serve(h, req).Code
	}
	for i := 0; i < 10; i++ {
		if code := attempt("10.0.0.1"); code != http.StatusUnauthorized {
			t.Fatalf("attempt %d: status = %d", i, code)
		}
	}
	if code := attempt("10.0.0.1"); code != http.StatusTooManyRequests {
		t.Errorf("11th attempt: status = %d, want 429", code)
	}
	if code := attempt("10.0.0.2"); code != http.StatusUnauthorized {
		t.Errorf("other IP must not be limited: status = %d", code)
	}
}

func TestClientIPIgnoresHeaderWhenProxyUntrusted(t *testing.T) {
	var seen string
	h := clientIP(false)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { seen = r.RemoteAddr }))
	req := httptest.NewRequest("GET", "/", nil)
	req.RemoteAddr = "1.2.3.4:5555"
	req.Header.Set("X-Real-IP", "9.9.9.9")
	h.ServeHTTP(httptest.NewRecorder(), req)
	if seen != "1.2.3.4:5555" {
		t.Errorf("RemoteAddr = %q, spoofed header must be ignored", seen)
	}
}

func TestUnknownRouteIsJSON404(t *testing.T) {
	h, _ := newTestRouter(t, pinger{}, false)
	rec := serve(h, httptest.NewRequest("GET", "/nope", nil))
	if rec.Code != http.StatusNotFound || !strings.Contains(rec.Body.String(), `"not_found"`) {
		t.Errorf("status = %d body = %s", rec.Code, rec.Body)
	}
}
