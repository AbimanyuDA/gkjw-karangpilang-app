// Package server merangkai router, middleware, dan seluruh endpoint API.
package server

import (
	"context"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/go-chi/httprate"

	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/auth"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/httpx"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/resource"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/upload"
)

// Konten publik boleh di-cache sebentar oleh Cloudflare/HP: perubahan admin
// terlihat paling lambat ±30 detik, tapi lonjakan Minggu pagi tidak membebani DB.
const publicCache = "public, max-age=30, stale-while-revalidate=60"

// Pinger memeriksa koneksi database untuk health check.
type Pinger interface {
	Ping(ctx context.Context) error
}

// Deps adalah dependensi yang dibutuhkan router.
type Deps struct {
	DB             Pinger
	Repo           resource.Repository
	Auth           *auth.Handler
	Uploads        *upload.Handler
	AllowedOrigins []string
	TrustProxy     bool
}

// NewRouter membangun http.Handler lengkap.
func NewRouter(d Deps) http.Handler {
	r := chi.NewRouter()
	r.Use(clientIP(d.TrustProxy))
	r.Use(middleware.RequestID)
	r.Use(requestLogger)
	r.Use(middleware.Recoverer)
	r.Use(securityHeaders)
	if len(d.AllowedOrigins) > 0 {
		r.Use(cors.Handler(cors.Options{
			AllowedOrigins: d.AllowedOrigins,
			AllowedMethods: []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
			AllowedHeaders: []string{"Authorization", "Content-Type"},
			MaxAge:         300,
		}))
	}

	r.Get("/healthz", healthz(d.DB))
	r.Get("/files/{bucket}/{name}", d.Uploads.Serve)

	r.Route("/api/v1", func(r chi.Router) {
		// Catatan: tidak ada rate limit per-IP untuk endpoint baca publik.
		// Ratusan jemaat di Wi-Fi gereja / jaringan seluler (CGNAT) berbagi satu IP,
		// sehingga limit per-IP justru akan memblokir mereka di hari Minggu.
		r.Group(func(r chi.Router) {
			r.Use(middleware.Timeout(15 * time.Second))
			r.Use(cacheControl(publicCache))
			resource.MountPublic(r, d.Repo, resource.All)
		})

		r.Route("/auth", func(r chi.Router) {
			r.Use(cacheControl("no-store"))
			r.With(httprate.Limit(10, time.Minute, httprate.WithKeyFuncs(remoteIP))).
				Post("/login", d.Auth.Login)
			r.With(d.Auth.Require).Get("/me", d.Auth.Me)
		})

		r.Route("/admin", func(r chi.Router) {
			r.Use(cacheControl("no-store"))
			r.Use(d.Auth.Require)
			r.Use(httprate.Limit(300, time.Minute, httprate.WithKeyFuncs(remoteIP)))

			// Upload tanpa timeout pendek: PDF besar dari HP bisa butuh waktu.
			r.Post("/uploads", d.Uploads.Upload)
			r.Delete("/uploads/{bucket}/{name}", d.Uploads.Delete)

			r.Group(func(r chi.Router) {
				r.Use(middleware.Timeout(15 * time.Second))
				resource.MountAdmin(r, d.Repo, resource.All)
			})
		})
	})

	r.NotFound(func(w http.ResponseWriter, r *http.Request) {
		httpx.Fail(w, r, httpx.ErrNotFound)
	})
	return r
}

func healthz(db Pinger) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
		defer cancel()
		if err := db.Ping(ctx); err != nil {
			httpx.Fail(w, r, err)
			return
		}
		httpx.OK(w, http.StatusOK, map[string]string{"status": "ok"}, nil)
	}
}
