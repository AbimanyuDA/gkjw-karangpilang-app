package legacy

import (
	"context"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"sort"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/resource"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/upload"
)

// FileSaver menyimpan file hasil unduhan ke storage baru.
type FileSaver interface {
	Save(bucket string, src io.Reader) (upload.Stored, error)
}

// Migrator memindahkan data lama ke database baru.
type Migrator struct {
	Pool      *pgxpool.Pool
	Supabase  SupabaseSource
	Firestore FirestoreSource
	Files     FileSaver
	HTTP      *http.Client
	DryRun    bool

	store  *resource.PgStore
	copied map[string]string // URL lama → URL baru (hindari unduh file yang sama dua kali)
}

// TableReport merangkum hasil migrasi satu tabel.
type TableReport struct {
	Target   string
	Source   string
	Read     int
	Imported int
	Skipped  []string // alasan baris dilewati
	Note     string
}

// job mendeskripsikan satu sumber data lama → satu resource baru.
type job struct {
	target string // Resource.Path
	source string // nama tabel/koleksi lama (untuk laporan)
	fetch  func(context.Context) ([]map[string]any, error)
	files  map[string]string // field URL → bucket tujuan
}

// Run menjalankan seluruh migrasi dan mengembalikan laporan per tabel.
func (m *Migrator) Run(ctx context.Context) ([]TableReport, error) {
	m.store = resource.NewPgStore(m.Pool)
	m.copied = map[string]string{}

	var reports []TableReport
	for _, j := range m.jobs() {
		rep, err := m.runJob(ctx, j)
		if err != nil {
			return reports, err
		}
		reports = append(reports, rep)
	}
	return reports, nil
}

func (m *Migrator) jobs() []job {
	profil := map[string]string{"foto_url": "profil"}
	jobs := []job{
		m.supabaseJob("banners", "banner_slide", map[string]string{"image_url": "banners"}),
		m.supabaseJob("galeri", "galeri", map[string]string{"foto_url": "galeri"}),
		m.supabaseJob("agenda", "agenda", nil),
		m.supabaseJob("kependetaan", "kependetaan", profil),
		m.supabaseJob("kemajelisan", "kemajelisan", profil),
		m.supabaseJob("bpm", "bpm", profil),
		m.supabaseJob("perwilayahan", "perwilayahan", profil),
		m.supabaseJob("profil-ruangan", "profil_ruangan", profil),
		m.supabaseJob("eperpus", "eperpus", map[string]string{"cover_url": "eperpus-cover", "file_url": "eperpus"}),
		m.supabaseJob("inspirasi", "inspirasi", nil),
		m.supabaseJob("notifikasi", "notifikasi", nil),
		m.supabaseJob("faq", "faq", nil),
		m.supabaseJob("hubungi-kami", "hubungi_kami", nil),
		m.supabaseJob("informasi-gereja", "informasi_gereja", nil),
		m.supabaseJob("tentang-aplikasi", "tentang_aplikasi", nil),
		m.supabaseJob("sapaan-config", "sapaan_config", nil),
	}
	for _, c := range []struct{ collection, kategori string }{
		{"warta_jemaat", "warta"}, {"tata_ibadah", "tata_ibadah"}, {"renungan", "renungan"},
	} {
		c := c
		jobs = append(jobs, job{
			target: "dokumen", source: "firestore:" + c.collection,
			files: map[string]string{"url": "dokumen"},
			fetch: func(ctx context.Context) ([]map[string]any, error) {
				docs, err := m.Firestore.Fetch(ctx, c.collection)
				if err != nil {
					return nil, err
				}
				rows := make([]map[string]any, 0, len(docs))
				for _, d := range docs {
					row := d.Fields
					if row["url"] == nil || row["url"] == "" {
						row["url"] = row["file_url"] // nama field lama
					}
					delete(row, "file_url")
					row["kategori"] = c.kategori
					rows = append(rows, row)
				}
				return rows, nil
			},
		})
	}
	jobs = append(jobs,
		job{
			target: "siaran", source: "firestore:siaran",
			fetch: func(ctx context.Context) ([]map[string]any, error) {
				docs, err := m.Firestore.Fetch(ctx, "siaran")
				if err != nil {
					return nil, err
				}
				rows := make([]map[string]any, 0, len(docs))
				for _, d := range docs {
					rows = append(rows, d.Fields)
				}
				return rows, nil
			},
		},
		job{
			target: "gereja-covers", source: "firestore:gereja_covers",
			files: map[string]string{"image_url": "gereja-covers"},
			fetch: func(ctx context.Context) ([]map[string]any, error) {
				docs, err := m.Firestore.Fetch(ctx, "gereja_covers")
				if err != nil {
					return nil, err
				}
				var rows []map[string]any
				for _, d := range docs {
					if u, _ := d.Fields["imageUrl"].(string); u != "" {
						rows = append(rows, map[string]any{"key": d.ID, "image_url": u})
					}
				}
				return rows, nil
			},
		},
	)
	return jobs
}

func (m *Migrator) supabaseJob(target, table string, files map[string]string) job {
	return job{
		target: target, source: "supabase:" + table, files: files,
		fetch: func(ctx context.Context) ([]map[string]any, error) { return m.Supabase.Fetch(ctx, table) },
	}
}

func (m *Migrator) runJob(ctx context.Context, j job) (TableReport, error) {
	res, ok := findResource(j.target)
	if !ok {
		return TableReport{}, fmt.Errorf("resource %q tidak ada di registry", j.target)
	}
	rep := TableReport{Target: j.target, Source: j.source}

	// Idempoten: jangan menimpa tabel yang sudah berisi data (kecuali dokumen,
	// yang diisi dari 3 koleksi — dicek per kategori di bawah).
	if j.target != "dokumen" {
		if n, err := m.count(ctx, res.Table, ""); err != nil {
			return rep, err
		} else if n > 0 {
			rep.Note = fmt.Sprintf("dilewati: tabel %s sudah berisi %d baris", res.Table, n)
			return rep, nil
		}
	}

	rows, err := j.fetch(ctx)
	if err != nil {
		// Tabel lama yang tidak ada / tidak bisa dibaca tidak menghentikan migrasi.
		rep.Note = "gagal membaca sumber: " + err.Error()
		slog.Warn("legacy fetch gagal", "source", j.source, "err", err)
		return rep, nil
	}
	rep.Read = len(rows)

	if j.target == "dokumen" && len(rows) > 0 {
		kategori, _ := rows[0]["kategori"].(string)
		if n, err := m.count(ctx, res.Table, kategori); err != nil {
			return rep, err
		} else if n > 0 {
			rep.Note = fmt.Sprintf("dilewati: kategori %s sudah berisi %d dokumen", kategori, n)
			return rep, nil
		}
	}

	if res.Singleton {
		if len(rows) > 1 {
			rep.Note = fmt.Sprintf("%d baris di sumber; hanya baris pertama yang dipakai", len(rows))
		}
		rows = rows[:min(1, len(rows))]
	}

	for i, row := range rows {
		label := fmt.Sprintf("baris %d", i+1)
		input := pickFields(res, row)
		if err := m.copyFiles(ctx, input, j.files); err != nil {
			rep.Skipped = append(rep.Skipped, label+": "+err.Error())
			continue
		}
		mode := resource.Create
		if res.Singleton {
			mode = resource.Update
		}
		values, errs := res.Validate(input, mode)
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
	if res.Singleton {
		_, err := m.store.PutSingleton(ctx, res, values)
		return err
	}
	row, err := m.store.Create(ctx, res, values)
	if err != nil {
		return err
	}
	// Pertahankan waktu dibuat asli agar urutan (mis. notifikasi terbaru) tetap sama.
	if ts, ok := createdAt.(string); ok && ts != "" {
		_, err = m.Pool.Exec(ctx,
			fmt.Sprintf("UPDATE %s SET created_at = $1::timestamptz, updated_at = $1::timestamptz WHERE id = $2", res.Table),
			ts, row["id"])
	}
	return err
}

// copyFiles mengunduh file yang masih di Supabase Storage lalu menyimpannya di server baru.
// URL lain (Google Drive, YouTube, CDN) dibiarkan apa adanya.
func (m *Migrator) copyFiles(ctx context.Context, row map[string]any, files map[string]string) error {
	prefix := strings.TrimRight(m.Supabase.BaseURL, "/") + "/storage/v1/object/public/"
	for field, bucket := range files {
		oldURL, _ := row[field].(string)
		if oldURL == "" || !strings.HasPrefix(oldURL, prefix) {
			continue
		}
		if newURL, ok := m.copied[oldURL]; ok {
			row[field] = newURL
			continue
		}
		if m.DryRun {
			continue
		}
		newURL, err := m.download(ctx, oldURL, bucket)
		if err != nil {
			return fmt.Errorf("salin file %s: %w", field, err)
		}
		m.copied[oldURL] = newURL
		row[field] = newURL
	}
	return nil
}

func (m *Migrator) download(ctx context.Context, fileURL, bucket string) (string, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, fileURL, nil)
	if err != nil {
		return "", err
	}
	client := m.HTTP
	if client == nil {
		client = http.DefaultClient
	}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("status %d", resp.StatusCode)
	}
	stored, err := m.Files.Save(bucket, resp.Body)
	if err != nil {
		return "", err
	}
	return stored.URL, nil
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
