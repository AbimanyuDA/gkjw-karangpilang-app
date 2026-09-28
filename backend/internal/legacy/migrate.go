package legacy

import (
	"context"
	"fmt"
	"log/slog"
	"sort"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/resource"
)

// Penyimpanan file lama yang sudah tidak ada: baris yang masih menunjuk ke sini
// dilewati (lebih baik diunggah ulang daripada tampil sebagai link rusak).
var deadFileHosts = []string{".supabase.co/"}

// Migrator memindahkan data lama dari Firestore ke database baru.
type Migrator struct {
	Pool      *pgxpool.Pool
	Firestore FirestoreSource
	DryRun    bool

	store *resource.PgStore
}

// TableReport merangkum hasil migrasi satu koleksi.
type TableReport struct {
	Target   string
	Source   string
	Read     int
	Imported int
	Skipped  []string // alasan baris dilewati
	Note     string
}

// job mendeskripsikan satu koleksi Firestore → satu resource baru.
type job struct {
	target     string // Resource.Path
	collection string
	transform  func(Doc) (map[string]any, bool) // false = abaikan dokumen
}

// Run menjalankan seluruh migrasi dan mengembalikan laporan per koleksi.
func (m *Migrator) Run(ctx context.Context) ([]TableReport, error) {
	m.store = resource.NewPgStore(m.Pool)
	var reports []TableReport
	for _, j := range jobs() {
		rep, err := m.runJob(ctx, j)
		if err != nil {
			return reports, err
		}
		reports = append(reports, rep)
	}
	return reports, nil
}

func jobs() []job {
	dokumen := func(kategori string) func(Doc) (map[string]any, bool) {
		return func(d Doc) (map[string]any, bool) {
			row := d.Fields
			if row["url"] == nil || row["url"] == "" {
				row["url"] = row["file_url"] // nama field lama
			}
			delete(row, "file_url")
			row["kategori"] = kategori
			return row, true
		}
	}
	return []job{
		{target: "dokumen", collection: "warta_jemaat", transform: dokumen("warta")},
		{target: "dokumen", collection: "tata_ibadah", transform: dokumen("tata_ibadah")},
		{target: "dokumen", collection: "renungan", transform: dokumen("renungan")},
		{target: "siaran", collection: "siaran", transform: func(d Doc) (map[string]any, bool) { return d.Fields, true }},
		{target: "gereja-covers", collection: "gereja_covers", transform: func(d Doc) (map[string]any, bool) {
			u, _ := d.Fields["imageUrl"].(string)
			return map[string]any{"key": d.ID, "image_url": u}, u != ""
		}},
	}
}

func (m *Migrator) runJob(ctx context.Context, j job) (TableReport, error) {
	res, ok := findResource(j.target)
	if !ok {
		return TableReport{}, fmt.Errorf("resource %q tidak ada di registry", j.target)
	}
	rep := TableReport{Target: j.target, Source: "firestore:" + j.collection}

	docs, err := m.Firestore.Fetch(ctx, j.collection)
	if err != nil {
		// Koleksi yang tidak ada / tidak bisa dibaca tidak menghentikan migrasi.
		rep.Note = "gagal membaca sumber: " + err.Error()
		slog.Warn("legacy fetch gagal", "collection", j.collection, "err", err)
		return rep, nil
	}
	var rows []map[string]any
	for _, d := range docs {
		if row, keep := j.transform(d); keep {
			rows = append(rows, row)
		}
	}
	rep.Read = len(rows)

	// Idempoten: jangan menimpa data yang sudah ada (dokumen dicek per kategori).
	kategori := ""
	if j.target == "dokumen" && len(rows) > 0 {
		kategori, _ = rows[0]["kategori"].(string)
	}
	if n, err := m.count(ctx, res.Table, kategori); err != nil {
		return rep, err
	} else if n > 0 {
		rep.Note = fmt.Sprintf("dilewati: %s sudah berisi %d data", strings.TrimSpace(res.Table+" "+kategori), n)
		return rep, nil
	}

	for i, row := range rows {
		label := fmt.Sprintf("baris %d", i+1)
		input := pickFields(res, row)
		if field, dead := deadFileField(input); dead {
			rep.Skipped = append(rep.Skipped, label+": file "+field+" ada di penyimpanan lama yang sudah dihapus — unggah ulang lewat website admin")
			continue
		}
		values, errs := res.Validate(input, resource.Create)
		if errs != nil {
			rep.Skipped = append(rep.Skipped, label+": "+formatErrs(errs))
			continue
		}
		if m.DryRun {
			rep.Imported++
			continue
		}
		if err := m.insert(ctx, res, values, row["created_at"]); err != nil {
			rep.Skipped = append(rep.Skipped, label+": "+err.Error())
			continue
		}
		rep.Imported++
	}
	return rep, nil
}

func (m *Migrator) insert(ctx context.Context, res resource.Resource, values resource.Row, createdAt any) error {
	row, err := m.store.Create(ctx, res, values)
	if err != nil {
		return err
	}
	// Pertahankan waktu dibuat asli agar urutan tetap sama.
	if ts, ok := createdAt.(string); ok && ts != "" {
		_, err = m.Pool.Exec(ctx,
			fmt.Sprintf("UPDATE %s SET created_at = $1::timestamptz, updated_at = $1::timestamptz WHERE id = $2", res.Table),
			ts, row["id"])
	}
	return err
}

func (m *Migrator) count(ctx context.Context, table, kategori string) (int, error) {
	sql := "SELECT count(*) FROM " + table
	args := []any{}
	if kategori != "" {
		sql += " WHERE kategori = $1"
		args = append(args, kategori)
	}
	var n int
	if err := m.Pool.QueryRow(ctx, sql, args...).Scan(&n); err != nil {
		return 0, fmt.Errorf("hitung %s: %w", table, err)
	}
	return n, nil
}

// deadFileField mengembalikan nama field yang menunjuk ke penyimpanan lama yang sudah hilang.
func deadFileField(row map[string]any) (string, bool) {
	for k, v := range row {
		s, _ := v.(string)
		for _, host := range deadFileHosts {
			if strings.Contains(s, host) {
				return k, true
			}
		}
	}
	return "", false
}

// pickFields hanya mengambil kolom yang dikenal spec (kolom lama lain diabaikan).
func pickFields(res resource.Resource, row map[string]any) map[string]any {
	out := map[string]any{}
	for _, f := range res.Fields {
		if v, ok := row[f.Name]; ok {
			out[f.Name] = v
		}
	}
	return out
}

func findResource(path string) (resource.Resource, bool) {
	for _, r := range resource.All {
		if r.Path == path {
			return r, true
		}
	}
	return resource.Resource{}, false
}

func formatErrs(errs map[string]string) string {
	parts := make([]string, 0, len(errs))
	for k, v := range errs {
		parts = append(parts, k+" "+v)
	}
	sort.Strings(parts)
	return strings.Join(parts, "; ")
}
