package resource

import (
	"encoding/json"
	"strings"
	"testing"
	"time"
)

var testRes = Resource{
	Path:  "test",
	Table: "test",
	Fields: []Field{
		{Name: "judul", Type: Text, Required: true, MaxLen: 10},
		{Name: "link", Type: Text, URL: true},
		{Name: "kategori", Type: Text, OneOf: []string{"a", "b"}},
		{Name: "urutan", Type: Int, NotNull: true, Min: intPtr(0), Max: intPtr(5)},
		{Name: "aktif", Type: Bool, NotNull: true},
		{Name: "tanggal", Type: Timestamp},
	},
}

func TestValidate_CreateValid(t *testing.T) {
	in := map[string]any{
		"id":       "ignored",
		"judul":    "Ibadah",
		"link":     "https://x.org",
		"kategori": "a",
		"urutan":   json.Number("3"),
		"aktif":    true,
		"tanggal":  "2026-09-27T08:00:00Z",
	}
	out, errs := testRes.Validate(in, Create)
	if errs != nil {
		t.Fatalf("unexpected errors: %v", errs)
	}
	if _, has := out["id"]; has {
		t.Error("server-managed field id must be dropped")
	}
	if out["urutan"] != int64(3) {
		t.Errorf("urutan = %#v, want int64(3)", out["urutan"])
	}
	if got := out["tanggal"].(time.Time); !got.Equal(time.Date(2026, 9, 27, 8, 0, 0, 0, time.UTC)) {
		t.Errorf("tanggal = %v", got)
	}
}

func TestValidate_Errors(t *testing.T) {
	tests := []struct {
		name  string
		in    map[string]any
		mode  Mode
		field string
	}{
		{"missing required", map[string]any{"urutan": json.Number("1")}, Create, "judul"},
		{"blank required", map[string]any{"judul": "   "}, Create, "judul"},
		{"too long", map[string]any{"judul": strings.Repeat("x", 11)}, Create, "judul"},
		{"not a url", map[string]any{"judul": "a", "link": "javascript:alert(1)"}, Create, "link"},
		{"not in enum", map[string]any{"judul": "a", "kategori": "z"}, Create, "kategori"},
		{"int below min", map[string]any{"urutan": json.Number("-1")}, Update, "urutan"},
		{"int above max", map[string]any{"urutan": json.Number("6")}, Update, "urutan"},
		{"float for int", map[string]any{"urutan": json.Number("1.5")}, Update, "urutan"},
		{"null not-null", map[string]any{"aktif": nil}, Update, "aktif"},
		{"null required on update", map[string]any{"judul": nil}, Update, "judul"},
		{"wrong bool type", map[string]any{"aktif": "yes"}, Update, "aktif"},
		{"bad date", map[string]any{"tanggal": "kemarin"}, Update, "tanggal"},
		{"unknown field", map[string]any{"hack": "x"}, Update, "hack"},
		{"empty body", map[string]any{}, Update, "_"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, errs := testRes.Validate(tt.in, tt.mode)
			if _, ok := errs[tt.field]; !ok {
				t.Errorf("expected error on %q, got %v", tt.field, errs)
			}
		})
	}
}

func TestValidate_UpdateAllowsPartialAndNullOptional(t *testing.T) {
	out, errs := testRes.Validate(map[string]any{"link": nil}, Update)
	if errs != nil {
		t.Fatalf("unexpected errors: %v", errs)
	}
	if v, ok := out["link"]; !ok || v != nil {
		t.Errorf("link should be explicit nil, got %#v", out)
	}
}

func TestConvertTimestamp_LocalTimeIsJakarta(t *testing.T) {
	v, msg := convertTimestamp("2026-09-27T08:00:00.000")
	if msg != "" {
		t.Fatalf("unexpected error: %s", msg)
	}
	want := time.Date(2026, 9, 27, 1, 0, 0, 0, time.UTC)
	if !v.(time.Time).Equal(want) {
		t.Errorf("got %v, want %v", v, want)
	}
}
