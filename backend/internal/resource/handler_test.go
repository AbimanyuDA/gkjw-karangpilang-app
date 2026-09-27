package resource

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"

	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/httpx"
)

const validID = "6f1c1f4e-6a8e-4c43-9a57-2b1f4f7d9a10"

// fakeRepo merekam panggilan terakhir dan mengembalikan nilai yang sudah disiapkan.
type fakeRepo struct {
	lastQuery  ListQuery
	lastValues Row
	lastPublic bool
	rows       []Row
	err        error
	singleton  Row
}

func (f *fakeRepo) List(_ context.Context, _ Resource, q ListQuery) ([]Row, int, error) {
	f.lastQuery = q
	return f.rows, len(f.rows), f.err
}
func (f *fakeRepo) Get(_ context.Context, _ Resource, id string, public bool) (Row, error) {
	f.lastPublic = public
	if f.err != nil {
		return nil, f.err
	}
	return Row{"id": id}, nil
}
func (f *fakeRepo) Create(_ context.Context, _ Resource, v Row) (Row, error) {
	f.lastValues = v
	return v, f.err
}
func (f *fakeRepo) Update(_ context.Context, _ Resource, _ string, v Row) (Row, error) {
	f.lastValues = v
	return v, f.err
}
func (f *fakeRepo) Delete(context.Context, Resource, string) error { return f.err }
func (f *fakeRepo) GetSingleton(context.Context, Resource) (Row, error) {
	return f.singleton, f.err
}
func (f *fakeRepo) PutSingleton(_ context.Context, _ Resource, v Row) (Row, error) {
	f.lastValues = v
	return v, f.err
}
func (f *fakeRepo) DistinctInts(context.Context, Resource, string) ([]int64, error) {
	return nil, f.err
}

func newRouter(repo Repository) http.Handler {
	r := chi.NewRouter()
	r.Route("/public", func(r chi.Router) { MountPublic(r, repo, All) })
	r.Route("/admin", func(r chi.Router) { MountAdmin(r, repo, All) })
	return r
}

func do(t *testing.T, h http.Handler, method, path, body string) (*httptest.ResponseRecorder, httpx.Envelope) {
	t.Helper()
	req := httptest.NewRequest(method, path, strings.NewReader(body))
	if body != "" {
		req.Header.Set("Content-Type", "application/json")
	}
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	var env httpx.Envelope
	if err := json.Unmarshal(rec.Body.Bytes(), &env); err != nil {
		t.Fatalf("invalid JSON response %q: %v", rec.Body.String(), err)
	}
	return rec, env
}

func TestList_PublicAppliesFiltersAndPagination(t *testing.T) {
	repo := &fakeRepo{rows: []Row{{"id": "1"}}}
	rec, env := do(t, newRouter(repo), "GET", "/public/dokumen?kategori=warta&limit=20&offset=40", "")

	if rec.Code != http.StatusOK || !env.Success {
		t.Fatalf("status = %d body = %s", rec.Code, rec.Body)
	}
	if !repo.lastQuery.Public || repo.lastQuery.Limit != 20 || repo.lastQuery.Offset != 40 {
		t.Errorf("query = %+v", repo.lastQuery)
	}
	if repo.lastQuery.Filters["kategori"] != "warta" {
		t.Errorf("filters = %v", repo.lastQuery.Filters)
	}
	if env.Meta == nil || env.Meta.Total != 1 {
		t.Errorf("meta = %+v", env.Meta)
	}
}

func TestList_EmptyReturnsArrayNotNull(t *testing.T) {
	rec, _ := do(t, newRouter(&fakeRepo{}), "GET", "/public/agenda", "")
	if !strings.Contains(rec.Body.String(), `"data":[]`) {
		t.Errorf("body = %s", rec.Body)
	}
}

func TestList_AdminIsNotPublic(t *testing.T) {
	repo := &fakeRepo{}
	do(t, newRouter(repo), "GET", "/admin/banners", "")
	if repo.lastQuery.Public {
		t.Error("admin list must not apply public filter")
	}
}

func TestList_InvalidParams(t *testing.T) {
	for _, path := range []string{
		"/public/agenda?limit=0",
		"/public/agenda?limit=999",
		"/public/agenda?offset=-1",
		"/public/dokumen?kategori=hack",
		"/public/galeri?tahun=abc",
	} {
		t.Run(path, func(t *testing.T) {
			rec, env := do(t, newRouter(&fakeRepo{}), "GET", path, "")
			if rec.Code != http.StatusBadRequest || env.Error.Code != "validation_error" {
				t.Errorf("status = %d body = %s", rec.Code, rec.Body)
			}
		})
	}
}

func TestGet_InvalidIDIs404(t *testing.T) {
	rec, _ := do(t, newRouter(&fakeRepo{}), "GET", "/public/agenda/not-a-uuid", "")
	if rec.Code != http.StatusNotFound {
		t.Errorf("status = %d", rec.Code)
	}
}

func TestGet_PublicFlag(t *testing.T) {
	repo := &fakeRepo{}
	do(t, newRouter(repo), "GET", "/public/banners/"+validID, "")
	if !repo.lastPublic {
		t.Error("public get must set public flag")
	}
}

func TestCreate(t *testing.T) {
	repo := &fakeRepo{}
	body := `{"kategori":"warta","judul":"Warta 1","url":"https://x/a.pdf","tanggal":"2026-09-27T00:00:00Z"}`
	rec, env := do(t, newRouter(repo), "POST", "/admin/dokumen", body)
	if rec.Code != http.StatusCreated || !env.Success {
		t.Fatalf("status = %d body = %s", rec.Code, rec.Body)
	}
	if repo.lastValues["judul"] != "Warta 1" {
		t.Errorf("values = %v", repo.lastValues)
	}
}

func TestCreate_ValidationError(t *testing.T) {
	rec, env := do(t, newRouter(&fakeRepo{}), "POST", "/admin/dokumen", `{"judul":"x"}`)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d", rec.Code)
	}
	for _, f := range []string{"kategori", "url", "tanggal"} {
		if _, ok := env.Error.Fields[f]; !ok {
			t.Errorf("missing field error for %s: %v", f, env.Error.Fields)
		}
	}
}

func TestCreate_BadJSON(t *testing.T) {
	for _, body := range []string{`{`, `[]`, `{"a":1}{"b":2}`} {
		rec, _ := do(t, newRouter(&fakeRepo{}), "POST", "/admin/agenda", body)
		if rec.Code != http.StatusBadRequest {
			t.Errorf("body %q: status = %d", body, rec.Code)
		}
	}
}

func TestUpdate_Partial(t *testing.T) {
	repo := &fakeRepo{}
	rec, _ := do(t, newRouter(repo), "PUT", "/admin/banners/"+validID, `{"is_active":false}`)
	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d body = %s", rec.Code, rec.Body)
	}
	if len(repo.lastValues) != 1 || repo.lastValues["is_active"] != false {
		t.Errorf("values = %v", repo.lastValues)
	}
}

func TestDelete_NotFound(t *testing.T) {
	rec, _ := do(t, newRouter(&fakeRepo{err: httpx.ErrNotFound}), "DELETE", "/admin/faq/"+validID, "")
	if rec.Code != http.StatusNotFound {
		t.Errorf("status = %d", rec.Code)
	}
}

func TestRepoErrorIsGeneric500(t *testing.T) {
	rec, env := do(t, newRouter(&fakeRepo{err: context.DeadlineExceeded}), "GET", "/public/faq", "")
	if rec.Code != http.StatusInternalServerError || env.Error.Code != "internal_error" {
		t.Errorf("status = %d body = %s", rec.Code, rec.Body)
	}
	if strings.Contains(rec.Body.String(), "deadline") {
		t.Error("internal error details must not leak")
	}
}

func TestSingleton(t *testing.T) {
	repo := &fakeRepo{}
	rec, _ := do(t, newRouter(repo), "GET", "/public/tentang-aplikasi", "")
	if rec.Code != http.StatusOK || !strings.Contains(rec.Body.String(), `"data":null`) {
		t.Errorf("empty singleton: status = %d body = %s", rec.Code, rec.Body)
	}

	rec, _ = do(t, newRouter(repo), "PUT", "/admin/sapaan-config", `{"jam_pagi":6,"ayat_pagi":"Mzm 23:1"}`)
	if rec.Code != http.StatusOK || repo.lastValues["jam_pagi"] != int64(6) {
		t.Errorf("status = %d values = %v", rec.Code, repo.lastValues)
	}

	rec, _ = do(t, newRouter(repo), "PUT", "/admin/sapaan-config", `{"jam_pagi":24}`)
	if rec.Code != http.StatusBadRequest {
		t.Errorf("out of range hour: status = %d", rec.Code)
	}
}

func TestSingleton_NoWriteOnPublic(t *testing.T) {
	req := httptest.NewRequest("PUT", "/public/sapaan-config", strings.NewReader(`{}`))
	rec := httptest.NewRecorder()
	newRouter(&fakeRepo{}).ServeHTTP(rec, req)
	if rec.Code != http.StatusMethodNotAllowed {
		t.Errorf("status = %d", rec.Code)
	}
}

func TestDistinctRoute(t *testing.T) {
	rec, _ := do(t, newRouter(&fakeRepo{}), "GET", "/public/galeri/tahun", "")
	if rec.Code != http.StatusOK || !strings.Contains(rec.Body.String(), `"data":[]`) {
		t.Errorf("status = %d body = %s", rec.Code, rec.Body)
	}
}
