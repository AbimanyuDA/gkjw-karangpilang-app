package config

import (
	"strings"
	"testing"
	"time"
)

func lookupFrom(env map[string]string) func(string) (string, bool) {
	return func(k string) (string, bool) {
		v, ok := env[k]
		return v, ok
	}
}

func validEnv() map[string]string {
	return map[string]string{
		"DATABASE_URL": "postgres://u:p@localhost/db",
		"JWT_SECRET":   strings.Repeat("x", 32),
	}
}

func TestFromLookup_Defaults(t *testing.T) {
	cfg, err := FromLookup(lookupFrom(validEnv()))
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg.Port != "8080" {
		t.Errorf("Port = %q, want 8080", cfg.Port)
	}
	if cfg.JWTTTL != 168*time.Hour {
		t.Errorf("JWTTTL = %v, want 168h", cfg.JWTTTL)
	}
	if cfg.TrustProxy {
		t.Error("TrustProxy should default to false")
	}
}

func TestFromLookup_ParsesListsAndTrimsURL(t *testing.T) {
	env := validEnv()
	env["CORS_ALLOWED_ORIGINS"] = " https://a.org , ,https://b.org"
	env["PUBLIC_BASE_URL"] = "https://api.example.org/"
	env["TRUST_PROXY"] = "true"

	cfg, err := FromLookup(lookupFrom(env))
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(cfg.CORSAllowedOrigins) != 2 || cfg.CORSAllowedOrigins[1] != "https://b.org" {
		t.Errorf("CORSAllowedOrigins = %v", cfg.CORSAllowedOrigins)
	}
	if cfg.PublicBaseURL != "https://api.example.org" {
		t.Errorf("PublicBaseURL = %q", cfg.PublicBaseURL)
	}
	if !cfg.TrustProxy {
		t.Error("TrustProxy should be true")
	}
}

func TestFromLookup_RejectsInvalid(t *testing.T) {
	cases := map[string]map[string]string{
		"missing db":   {"JWT_SECRET": strings.Repeat("x", 32)},
		"short secret": {"DATABASE_URL": "postgres://x", "JWT_SECRET": "short"},
		"bad ttl":      {"DATABASE_URL": "postgres://x", "JWT_SECRET": strings.Repeat("x", 32), "JWT_TTL": "abc"},
		"bad base url": {"DATABASE_URL": "postgres://x", "JWT_SECRET": strings.Repeat("x", 32), "PUBLIC_BASE_URL": "ftp://x"},
		"negative ttl": {"DATABASE_URL": "postgres://x", "JWT_SECRET": strings.Repeat("x", 32), "JWT_TTL": "-1h"},
	}
	for name, env := range cases {
		t.Run(name, func(t *testing.T) {
			if _, err := FromLookup(lookupFrom(env)); err == nil {
				t.Error("expected error, got nil")
			}
		})
	}
}
