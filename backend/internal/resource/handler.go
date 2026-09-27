package resource

import (
	"context"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/httpx"
)

// Batas paginasi.
const (
	DefaultLimit = 50
	MaxLimit     = 200
)

// Repository adalah akses data yang dibutuhkan handler.
type Repository interface {
	List(ctx context.Context, r Resource, q ListQuery) ([]Row, int, error)
	Get(ctx context.Context, r Resource, id string, public bool) (Row, error)
	Create(ctx context.Context, r Resource, values Row) (Row, error)
	Update(ctx context.Context, r Resource, id string, values Row) (Row, error)
	Delete(ctx context.Context, r Resource, id string) error
	GetSingleton(ctx context.Context, r Resource) (Row, error)
	PutSingleton(ctx context.Context, r Resource, values Row) (Row, error)
	DistinctInts(ctx context.Context, r Resource, column string) ([]int64, error)
}

// Handler melayani endpoint HTTP untuk satu Resource.
type Handler struct {
	repo Repository
	res  Resource
}

// MountPublic mendaftarkan endpoint baca untuk jemaat (tanpa login).
func MountPublic(router chi.Router, repo Repository, resources []Resource) {
	for _, res := range resources {
		h := Handler{repo: repo, res: res}
		if res.Singleton {
			router.Get("/"+res.Path, h.getSingleton)
			continue
		}
		router.Get("/"+res.Path, h.list(true))
		for _, col := range res.Distinct {
			router.Get("/"+res.Path+"/"+col, h.distinct(col))
		}
		router.Get("/"+res.Path+"/{id}", h.get(true))
	}
}

// MountAdmin mendaftarkan endpoint kelola data (wajib login).
func MountAdmin(router chi.Router, repo Repository, resources []Resource) {
	for _, res := range resources {
		h := Handler{repo: repo, res: res}
		if res.Singleton {
			router.Get("/"+res.Path, h.getSingleton)
			router.Put("/"+res.Path, h.putSingleton)
			continue
		}
		router.Get("/"+res.Path, h.list(false))
		router.Post("/"+res.Path, h.create)
		router.Get("/"+res.Path+"/{id}", h.get(false))
		router.Put("/"+res.Path+"/{id}", h.update)
		router.Delete("/"+res.Path+"/{id}", h.delete)
	}
}

func (h Handler) list(public bool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		q, err := h.parseListQuery(r)
		if err != nil {
			httpx.Fail(w, r, err)
			return
		}
		q.Public = public

		items, total, err := h.repo.List(r.Context(), h.res, q)
		if err != nil {
			httpx.Fail(w, r, err)
			return
		}
		if items == nil {
			items = []Row{}
		}
		httpx.OK(w, http.StatusOK, items, &httpx.Meta{Total: total, Limit: q.Limit, Offset: q.Offset})
	}
}

func (h Handler) get(public bool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id, ok := parseID(r)
		if !ok {
			httpx.Fail(w, r, httpx.ErrNotFound)
			return
		}
		row, err := h.repo.Get(r.Context(), h.res, id, public)
		if err != nil {
			httpx.Fail(w, r, err)
			return
		}
		httpx.OK(w, http.StatusOK, row, nil)
	}
}

func (h Handler) create(w http.ResponseWriter, r *http.Request) {
	values, err := h.decode(r, Create)
	if err != nil {
		httpx.Fail(w, r, err)
		return
	}
	row, err := h.repo.Create(r.Context(), h.res, values)
	if err != nil {
		httpx.Fail(w, r, err)
		return
	}
	httpx.OK(w, http.StatusCreated, row, nil)
}

func (h Handler) update(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID(r)
	if !ok {
		httpx.Fail(w, r, httpx.ErrNotFound)
		return
	}
	values, err := h.decode(r, Update)
	if err != nil {
		httpx.Fail(w, r, err)
		return
	}
	row, err := h.repo.Update(r.Context(), h.res, id, values)
	if err != nil {
		httpx.Fail(w, r, err)
		return
	}
	httpx.OK(w, http.StatusOK, row, nil)
}

func (h Handler) delete(w http.ResponseWriter, r *http.Request) {
	id, ok := parseID(r)
	if !ok {
		httpx.Fail(w, r, httpx.ErrNotFound)
		return
	}
	if err := h.repo.Delete(r.Context(), h.res, id); err != nil {
		httpx.Fail(w, r, err)
		return
	}
	httpx.OK(w, http.StatusOK, map[string]string{"id": id}, nil)
}

func (h Handler) getSingleton(w http.ResponseWriter, r *http.Request) {
	row, err := h.repo.GetSingleton(r.Context(), h.res)
	if err != nil {
		httpx.Fail(w, r, err)
		return
	}
	httpx.OK(w, http.StatusOK, row, nil)
}

func (h Handler) putSingleton(w http.ResponseWriter, r *http.Request) {
	values, err := h.decode(r, Update)
	if err != nil {
		httpx.Fail(w, r, err)
		return
	}
	row, err := h.repo.PutSingleton(r.Context(), h.res, values)
	if err != nil {
		httpx.Fail(w, r, err)
		return
	}
	httpx.OK(w, http.StatusOK, row, nil)
}

func (h Handler) distinct(column string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		vals, err := h.repo.DistinctInts(r.Context(), h.res, column)
		if err != nil {
			httpx.Fail(w, r, err)
			return
		}
		if vals == nil {
			vals = []int64{}
		}
		httpx.OK(w, http.StatusOK, vals, nil)
	}
}

func (h Handler) decode(r *http.Request, mode Mode) (Row, error) {
	var input map[string]any
	if err := httpx.DecodeJSON(r, &input); err != nil {
		return nil, err
	}
	values, errs := h.res.Validate(input, mode)
	if errs != nil {
		return nil, httpx.Validation(errs)
	}
	return values, nil
}

func (h Handler) parseListQuery(r *http.Request) (ListQuery, error) {
	params := r.URL.Query()
	q := ListQuery{Limit: DefaultLimit, Filters: map[string]any{}}
	errs := map[string]string{}

	if v := params.Get("limit"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil || n < 1 || n > MaxLimit {
			errs["limit"] = "harus antara 1 dan " + strconv.Itoa(MaxLimit)
		}
		q.Limit = n
	}
	if v := params.Get("offset"); v != "" {
		n, err := strconv.Atoi(v)
		if err != nil || n < 0 {
			errs["offset"] = "harus bilangan bulat ≥ 0"
		}
		q.Offset = n
	}
	for _, name := range h.res.Filters {
		raw := params.Get(name)
		if raw == "" {
			continue
		}
		f, _ := h.res.field(name)
		val, msg := f.convertQueryParam(raw)
		if msg != "" {
			errs[name] = msg
			continue
		}
		q.Filters[name] = val
	}
	if len(errs) > 0 {
		return ListQuery{}, httpx.Validation(errs)
	}
	return q, nil
}

// convertQueryParam mengubah query param (selalu string) sesuai tipe field.
func (f Field) convertQueryParam(raw string) (any, string) {
	if f.Type == Bool {
		switch raw {
		case "true":
			return true, ""
		case "false":
			return false, ""
		}
		return nil, "harus true atau false"
	}
	return f.convert(raw)
}

func parseID(r *http.Request) (string, bool) {
	id := chi.URLParam(r, "id")
	if _, err := uuid.Parse(id); err != nil {
		return "", false
	}
	return id, true
}
