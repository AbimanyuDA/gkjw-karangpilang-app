package server

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/auth"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/resource"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/upload"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/youtube"
)

type pinger struct{ err error }

func (p pinger) Ping(context.Context) error { return p.err }

type noAdmins struct{}

func (noAdmins) FindByEmail(context.Context, string) (auth.Admin, error) {
	return auth.Admin{}, auth.ErrAdminNotFound
}
func (noAdmins) FindByID(context.Context, string) (auth.Admin, error) {
	return auth.Admin{}, auth.ErrAdminNotFound
}
func (noAdmins) SetPassword(context.Context, string, string) error { return auth.ErrAdminNotFound }

type fakeYT struct{}

func (fakeYT) Fetch(_ context.Context, id string) (youtube.Metadata, error) {
	return youtube.Metadata{VideoID: id, Title: "Ibadah"}, nil
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
		YouTube:    fakeYT{},
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
		{"GET", "/api/v1/admin/schema"},
		{"GET", "/api/v1/admin/youtube?url=dQw4w9WgXcQ"},
		{"PUT", "/api/v1/auth/password"},
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

func adminGet(t *testing.T, h http.Handler, tokens *auth.Tokens, path string) *httptest.ResponseRecorder {
	t.Helper()
	token, _, _ := tokens.Issue("a1", "admin@gkjw.org")
	req := httptest.NewRequest("GET", path, nil)
	req.Header.Set("Authorization", "Bearer "+token)
	return serve(h, req)
}

func TestAdminSchema(t *testing.T) {
	h, tokens := newTestRouter(t, pinger{}, false)
	rec := adminGet(t, h, tokens, "/api/v1/admin/schema")
	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d", rec.Code)
	}
	var body struct {
		Data adminSchema `json:"data"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatal(err)
	}
	if len(body.Data.Resources) != len(resource.All) {
		t.Errorf("resources = %d, want %d", len(body.Data.Resources), len(resource.All))
	}
	// Setiap field upload harus menunjuk bucket yang benar-benar ada.
	for _, r := range body.Data.Resources {
		for _, f := range r.Fields {
			if f.Upload == "" {
				continue
			}
			b, ok := body.Data.Buckets[f.Upload]
			if !ok {
				t.Errorf("%s.%s: bucket %q tidak ada", r.Path, f.Name, f.Upload)
				continue
			}
			if (f.Input == resource.InputPDF) != (b.Kind == "pdf") {
				t.Errorf("%s.%s: input %s tidak cocok dengan bucket %s", r.Path, f.Name, f.Input, b.Kind)
			}
		}
	}
}

func TestAdminYouTube(t *testing.T) {
	h, tokens := newTestRouter(t, pinger{}, false)
	if rec := adminGet(t, h, tokens, "/api/v1/admin/youtube?url=https://youtu.be/dQw4w9WgXcQ"); rec.Code != http.StatusOK ||
		!strings.Contains(rec.Body.String(), `"youtube_id":"dQw4w9WgXcQ"`) {
		t.Errorf("status = %d body = %s", rec.Code, rec.Body)
	}
	if rec := adminGet(t, h, tokens, "/api/v1/admin/youtube?url=bukan-link"); rec.Code != http.StatusBadRequest {
		t.Errorf("invalid link: status = %d", rec.Code)
	}
}
