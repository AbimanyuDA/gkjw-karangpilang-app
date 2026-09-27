package server

import (
	"log/slog"
	"net"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5/middleware"
)

// clientIP memakai header X-Real-IP yang di-set oleh Caddy. Hanya aktif bila
// TRUST_PROXY=true, karena header dari klien langsung bisa dipalsukan.
// (Sengaja tidak memakai X-Forwarded-For/True-Client-IP yang bisa dikirim klien.)
func clientIP(trustProxy bool) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if trustProxy {
				if ip := net.ParseIP(r.Header.Get("X-Real-IP")); ip != nil {
					r.RemoteAddr = ip.String()
				}
			}
			next.ServeHTTP(w, r)
		})
	}
}

// remoteIP dipakai sebagai kunci rate limit.
func remoteIP(r *http.Request) (string, error) {
	if host, _, err := net.SplitHostPort(r.RemoteAddr); err == nil {
		return host, nil
	}
	return r.RemoteAddr, nil
}

// requestLogger mencatat setiap request dalam format JSON (slog).
func requestLogger(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		ww := middleware.NewWrapResponseWriter(w, r.ProtoMajor)
		next.ServeHTTP(ww, r)
		slog.InfoContext(r.Context(), "http",
			"method", r.Method,
			"path", r.URL.Path,
			"status", ww.Status(),
			"bytes", ww.BytesWritten(),
			"duration_ms", time.Since(start).Milliseconds(),
			"ip", r.RemoteAddr,
			"request_id", middleware.GetReqID(r.Context()),
		)
	})
}

// cacheControl memasang header Cache-Control tetap.
func cacheControl(value string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Cache-Control", value)
			next.ServeHTTP(w, r)
		})
	}
}

func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		h.Set("X-Content-Type-Options", "nosniff")
		h.Set("X-Frame-Options", "DENY")
		h.Set("Referrer-Policy", "strict-origin-when-cross-origin")
		next.ServeHTTP(w, r)
	})
}
