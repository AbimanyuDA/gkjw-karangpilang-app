package resource

import (
	"regexp"
	"testing"
)

// TestRegistryConsistent menjaga agar spec di registry.go tidak saling bertentangan.
func TestRegistryConsistent(t *testing.T) {
	paths := map[string]bool{}
	for _, r := range All {
		t.Run(r.Path, func(t *testing.T) {
			if r.Path == "" || r.Table == "" || len(r.Fields) == 0 {
				t.Fatal("Path, Table, dan Fields wajib diisi")
			}
			if paths[r.Path] {
				t.Errorf("path %q duplikat", r.Path)
			}
			paths[r.Path] = true

			seen := map[string]bool{}
			for _, f := range r.Fields {
				if seen[f.Name] {
					t.Errorf("field %q duplikat", f.Name)
				}
				seen[f.Name] = true
				if serverManaged[f.Name] {
					t.Errorf("field %q dikelola server, tidak boleh di spec", f.Name)
				}
			}
			for _, name := range r.Filters {
				if !seen[name] {
					t.Errorf("filter %q bukan field", name)
				}
			}
			for _, name := range r.Distinct {
				if f, ok := r.field(name); !ok || f.Type != Int {
					t.Errorf("distinct %q harus field Int", name)
				}
			}
			if r.UpsertKey != "" && !seen[r.UpsertKey] {
				t.Errorf("UpsertKey %q bukan field", r.UpsertKey)
			}
			if r.Label == "" || r.Group == "" {
				t.Error("Label dan Group wajib diisi (dipakai website admin)")
			}
			for _, f := range r.Fields {
				if f.Label == "" {
					t.Errorf("field %q tanpa Label", f.Name)
				}
				if (f.Input == InputImage || f.Input == InputPDF) && f.Upload == "" {
					t.Errorf("field %q butuh Upload bucket", f.Name)
				}
				if f.Pattern != "" {
					if _, err := regexp.Compile(f.Pattern); err != nil {
						t.Errorf("Pattern %q tidak valid: %v", f.Name, err)
					}
				}
			}
			for _, c := range append(append([]string{}, r.Columns...), r.TitleField) {
				if c != "" && !seen[c] {
					t.Errorf("kolom/judul %q bukan field", c)
				}
			}
			if r.Singleton && (len(r.Filters) > 0 || r.UpsertKey != "") {
				t.Error("singleton tidak mendukung filter/upsert")
			}
		})
	}
}
