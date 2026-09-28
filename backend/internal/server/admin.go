package server

import (
	"context"
	"net/http"

	"github.com/go-chi/chi/v5"

	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/httpx"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/resource"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/upload"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/youtube"
)

// YouTubeFetcher mengambil metadata video (tanpa API key).
type YouTubeFetcher interface {
	Fetch(ctx context.Context, videoID string) (youtube.Metadata, error)
}

type bucketSchema struct {
	Kind     string `json:"kind"` // "image" | "pdf"
	MaxBytes int64  `json:"max_bytes"`
}

type adminSchema struct {
	Resources []resource.ResourceSchema `json:"resources"`
	Buckets   map[string]bucketSchema   `json:"buckets"`
}

// schemaHandler: GET /api/v1/admin/schema — dasar form & menu website admin.
func schemaHandler(resources []resource.Resource) http.HandlerFunc {
	schema := adminSchema{Buckets: map[string]bucketSchema{}}
	for _, r := range resources {
		schema.Resources = append(schema.Resources, resource.Describe(r))
	}
	for name, kind := range upload.Buckets {
		k := "image"
		if kind == upload.PDF {
			k = "pdf"
		}
		schema.Buckets[name] = bucketSchema{Kind: k, MaxBytes: upload.MaxBytes(name)}
	}
	return func(w http.ResponseWriter, r *http.Request) {
		httpx.OK(w, http.StatusOK, schema, nil)
	}
}

// youtubeHandler: GET /api/v1/admin/youtube?url=... — isi otomatis form siaran.
func youtubeHandler(yt YouTubeFetcher) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		id, ok := youtube.ExtractID(r.URL.Query().Get("url"))
		if !ok {
			httpx.Fail(w, r, httpx.Validation(map[string]string{"url": "link YouTube tidak valid"}))
			return
		}
		meta, err := yt.Fetch(r.Context(), id)
		if err != nil {
			httpx.Fail(w, r, &httpx.Error{Code: "not_found", Message: "Video tidak ditemukan atau tidak publik"})
			return
		}
		httpx.OK(w, http.StatusOK, meta, nil)
	}
}

func mountAdminExtras(r chi.Router, d Deps) {
	r.Get("/schema", schemaHandler(resource.All))
	if d.YouTube != nil {
		r.Get("/youtube", youtubeHandler(d.YouTube))
	}
}
