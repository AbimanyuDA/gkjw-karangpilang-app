// Package config memuat konfigurasi aplikasi dari environment variable.
package config

import (
	"errors"
	"fmt"
	"os"
	"strings"
	"time"
)

const minJWTSecretLen = 32

// Config berisi seluruh pengaturan runtime API.
type Config struct {
	Port               string
	DatabaseURL        string
	JWTSecret          []byte
	JWTTTL             time.Duration
	PublicBaseURL      string
	UploadDir          string
	CORSAllowedOrigins []string
	TrustProxy         bool
}

// Load membaca konfigurasi dari environment dan memvalidasinya.
func Load() (Config, error) {
	return FromLookup(os.LookupEnv)
}

// FromLookup memuat konfigurasi dari fungsi lookup (memudahkan pengujian).
func FromLookup(lookup func(string) (string, bool)) (Config, error) {
	get := func(key, fallback string) string {
		if v, ok := lookup(key); ok && strings.TrimSpace(v) != "" {
			return strings.TrimSpace(v)
		}
		return fallback
	}

	ttl, err := time.ParseDuration(get("JWT_TTL", "168h"))
	if err != nil {
		return Config{}, fmt.Errorf("JWT_TTL tidak valid: %w", err)
	}

	cfg := Config{
		Port:               get("PORT", "8080"),
		DatabaseURL:        get("DATABASE_URL", ""),
		JWTSecret:          []byte(get("JWT_SECRET", "")),
		JWTTTL:             ttl,
		PublicBaseURL:      strings.TrimRight(get("PUBLIC_BASE_URL", "http://localhost:8080"), "/"),
		UploadDir:          get("UPLOAD_DIR", "./tmp/uploads"),
		CORSAllowedOrigins: splitList(get("CORS_ALLOWED_ORIGINS", "")),
		TrustProxy:         get("TRUST_PROXY", "false") == "true",
	}
	return cfg, cfg.validate()
}

func (c Config) validate() error {
	var errs []error
	if c.DatabaseURL == "" {
		errs = append(errs, errors.New("DATABASE_URL wajib diisi"))
	}
	if len(c.JWTSecret) < minJWTSecretLen {
		errs = append(errs, fmt.Errorf("JWT_SECRET minimal %d karakter", minJWTSecretLen))
	}
	if c.JWTTTL <= 0 {
		errs = append(errs, errors.New("JWT_TTL harus lebih dari 0"))
	}
	if !strings.HasPrefix(c.PublicBaseURL, "http://") && !strings.HasPrefix(c.PublicBaseURL, "https://") {
		errs = append(errs, errors.New("PUBLIC_BASE_URL harus diawali http:// atau https://"))
	}
	return errors.Join(errs...)
}

func splitList(s string) []string {
	var out []string
	for _, part := range strings.Split(s, ",") {
		if p := strings.TrimSpace(part); p != "" {
			out = append(out, p)
		}
	}
	return out
}
