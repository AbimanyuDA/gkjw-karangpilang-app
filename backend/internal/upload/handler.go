package upload

import (
	"errors"
	"fmt"
	"net/http"

	"github.com/go-chi/chi/v5"

	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/httpx"
)

// multipartOverhead memberi ruang untuk header multipart di atas ukuran file.
const multipartOverhead = 64 << 10

// Handler melayani upload, hapus, dan unduh file.
type Handler struct {
	storage *Storage
}

// NewHandler membuat handler upload.
func NewHandler(storage *Storage) *Handler {
	return &Handler{storage: storage}
}

// Upload menerima multipart/form-data dengan field "file" dan query ?bucket=.
func (h *Handler) Upload(w http.ResponseWriter, r *http.Request) {
	bucket := r.URL.Query().Get("bucket")
	if _, ok := Buckets[bucket]; !ok {
		httpx.Fail(w, r, httpx.BadRequest("bucket tidak dikenal"))
		return
	}
	r.Body = http.MaxBytesReader(w, r.Body, MaxBytes(bucket)+multipartOverhead)

	reader, err := r.MultipartReader()
	if err != nil {
		httpx.Fail(w, r, httpx.BadRequest("body harus multipart/form-data"))
		return
	}
	for {
		part, err := reader.NextPart()
		if err != nil {
			httpx.Fail(w, r, uploadError(err, "field \"file\" tidak ditemukan"))
			return
		}
		if part.FormName() != "file" {
			part.Close()
			continue
		}
		stored, err := h.storage.Save(bucket, part)
		part.Close()
		if err != nil {
			httpx.Fail(w, r, uploadError(err, ""))
			return
		}
		httpx.OK(w, http.StatusCreated, stored, nil)
		return
	}
}

// Delete menghapus file: DELETE /admin/uploads/{bucket}/{name}.
func (h *Handler) Delete(w http.ResponseWriter, r *http.Request) {
	bucket, name := chi.URLParam(r, "bucket"), chi.URLParam(r, "name")
	if err := h.storage.Delete(bucket, name); err != nil {
		httpx.Fail(w, r, err)
		return
	}
	httpx.OK(w, http.StatusOK, map[string]string{"bucket": bucket, "name": name}, nil)
}

// Serve menyajikan file: GET /files/{bucket}/{name}. Nama file unik dan tidak
// pernah berubah, sehingga aman di-cache lama oleh browser & CDN.
func (h *Handler) Serve(w http.ResponseWriter, r *http.Request) {
	bucket, name := chi.URLParam(r, "bucket"), chi.URLParam(r, "name")
	f, err := h.storage.Open(bucket, name)
	if err != nil {
		http.NotFound(w, r)
		return
	}
	defer f.Close()

	info, err := f.Stat()
	if err != nil {
		httpx.Fail(w, r, fmt.Errorf("stat file: %w", err))
		return
	}
	w.Header().Set("Cache-Control", "public, max-age=31536000, immutable")
	w.Header().Set("X-Content-Type-Options", "nosniff")
	http.ServeContent(w, r, name, info.ModTime(), f)
}

func uploadError(err error, fallback string) error {
	var tooLarge *http.MaxBytesError
	if errors.As(err, &tooLarge) {
		return &httpx.Error{Code: "payload_too_large", Message: "Ukuran file terlalu besar"}
	}
	var apiErr *httpx.Error
	if errors.As(err, &apiErr) || fallback == "" {
		return err
	}
	return httpx.BadRequest(fallback)
}
