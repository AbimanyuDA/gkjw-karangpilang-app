package integration_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/legacy"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/resource"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/upload"
)

var pngFile = append([]byte("\x89PNG\r\n\x1a\n"), make([]byte, 32)...)

// fakeLegacy meniru REST API Supabase (tabel + storage) dan Firestore.
func fakeLegacy(t *testing.T) *httptest.Server {
	t.Helper()
	var srv *httptest.Server
	tables := map[string]any{
		"banner_slide": []map[string]any{
			{"id": "b1", "image_url": "{{BASE}}/storage/v1/object/public/banners/b1.jpg", "judul": nil, "urutan": 1, "is_active": true, "created_at": "2025-01-01T00:00:00+00:00"},
			{"id": "b2", "image_url": "{{BASE}}/storage/v1/object/public/banners/b1.jpg", "urutan": 2, "is_active": false, "extra_col": "diabaikan"},
		},
		"agenda": []map[string]any{
			{"id": "a1", "judul": "Rapat Majelis", "tanggal": "2026-10-01T19:00:00+07:00", "tempat": "Aula"},
			{"id": "a2", "judul": "", "tanggal": "2026-10-02T19:00:00+07:00"}, // tidak valid → dilewati
		},
		"notifikasi": []map[string]any{
			{"judul": "Lama", "pesan": "x", "is_active": true, "created_at": "2024-05-01T00:00:00+00:00"},
			{"judul": "Baru", "pesan": "y", "is_active": true, "created_at": "2026-05-01T00:00:00+00:00"},
		},
		"tentang_aplikasi": []map[string]any{{"id": "t1", "versi": "1.0.0", "deskripsi": "App"}},
	}
	firestore := map[string]string{
		"warta_jemaat": `{"documents":[{"name":"projects/p/databases/(default)/documents/warta_jemaat/w1","fields":{
			"judul":{"stringValue":"Warta 1"},
			"file_url":{"stringValue":"https://drive.google.com/file/d/abc/view"},
			"tanggal":{"timestampValue":"2026-09-20T00:00:00Z"}}}]}`,
		"siaran": `{"documents":[{"name":"projects/p/databases/(default)/documents/siaran/s1","fields":{
			"judul":{"stringValue":"Ibadah Minggu"},"youtube_id":{"stringValue":"dQw4w9WgXcQ"},
			"kategori":{"stringValue":"umum"},"tanggal":{"timestampValue":"2026-09-21T00:00:00.123456Z"}}}]}`,
		"gereja_covers": `{"documents":[
			{"name":"projects/p/databases/(default)/documents/gereja_covers/bpm","fields":{"imageUrl":{"stringValue":"https://cdn.example.org/bpm.jpg"}}},
			{"name":"projects/p/databases/(default)/documents/gereja_covers/kemajelisan","fields":{"imageUrl":{"stringValue":""}}}]}`,
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/rest/v1/{table}", func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("apikey") != "anon" {
			http.Error(w, "no key", http.StatusUnauthorized)
			return
		}
		rows, ok := tables[r.PathValue("table")]
		if !ok {
			http.Error(w, `{"message":"relation does not exist"}`, http.StatusNotFound)
			return
		}
		b, _ := json.Marshal(rows)
		w.Write([]byte(strings.ReplaceAll(string(b), "{{BASE}}", srv.URL)))
	})
	mux.HandleFunc("/storage/v1/object/public/banners/b1.jpg", func(w http.ResponseWriter, r *http.Request) {
		w.Write(pngFile)
	})
	mux.HandleFunc("/v1/projects/p/databases/(default)/documents/{col}", func(w http.ResponseWriter, r *http.Request) {
		body, ok := firestore[r.PathValue("col")]
		if !ok {
			body = `{}`
		}
		w.Write([]byte(body))
	})
	srv = httptest.NewServer(mux)
	t.Cleanup(srv.Close)
	return srv
}

func TestMigrateLegacy(t *testing.T) {
	pool, store := setup(t)
	ctx := context.Background()
	src := fakeLegacy(t)
	storage, err := upload.NewStorage(t.TempDir(), "https://api.new")
	if err != nil {
		t.Fatal(err)
	}

	newMigrator := func() *legacy.Migrator {
		return &legacy.Migrator{
			Pool:      pool,
			Supabase:  legacy.SupabaseSource{BaseURL: src.URL, AnonKey: "anon"},
			Firestore: legacy.FirestoreSource{ProjectID: "p", APIKey: "k", BaseURL: src.URL},
			Files:     storage,
		}
	}

	reports, err := newMigrator().Run(ctx)
	if err != nil {
		t.Fatal(err)
	}
	byTarget := map[string]legacy.TableReport{}
	for _, r := range reports {
		if r.Target == "dokumen" && r.Read == 0 {
			continue
		}
		byTarget[r.Target] = r
	}

	// Banner: file Supabase disalin ke server baru, satu file dipakai dua baris → diunduh sekali.
	banners, _, _ := store.List(ctx, find(t, "banners"), resource.ListQuery{Limit: 10})
	if len(banners) != 2 {
		t.Fatalf("banners = %d", len(banners))
	}
	u0, u1 := banners[0]["image_url"].(string), banners[1]["image_url"].(string)
	if !strings.HasPrefix(u0, "https://api.new/files/banners/") || u0 != u1 {
		t.Errorf("banner urls not rewritten/deduplicated: %s %s", u0, u1)
	}

	// Agenda: baris tidak valid dilewati dan dilaporkan.
	if r := byTarget["agenda"]; r.Imported != 1 || len(r.Skipped) != 1 {
		t.Errorf("agenda report = %+v", r)
	}

	// Notifikasi: created_at asli dipertahankan sehingga urutan terbaru tetap benar.
	notif, _, _ := store.List(ctx, find(t, "notifikasi"), resource.ListQuery{Public: true, Limit: 10})
	if len(notif) != 2 || notif[0]["judul"] != "Baru" {
		t.Errorf("notifikasi order = %v", notif)
	}

	// Firestore: warta (field lama file_url) → dokumen; link Google Drive dibiarkan.
	docs, _, _ := store.List(ctx, find(t, "dokumen"), resource.ListQuery{Filters: map[string]any{"kategori": "warta"}, Limit: 10})
	if len(docs) != 1 || docs[0]["url"] != "https://drive.google.com/file/d/abc/view" {
		t.Errorf("dokumen = %v", docs)
	}
	if r := byTarget["siaran"]; r.Imported != 1 {
		t.Errorf("siaran report = %+v", r)
	}
	covers, _, _ := store.List(ctx, find(t, "gereja-covers"), resource.ListQuery{Limit: 10})
	if len(covers) != 1 || covers[0]["key"] != "bpm" {
		t.Errorf("covers = %v (cover kosong harus dilewati)", covers)
	}

	// Singleton & tabel yang tidak ada di sumber lama.
	tentang, _ := store.GetSingleton(ctx, find(t, "tentang-aplikasi"))
	if tentang == nil || tentang["versi"] != "1.0.0" {
		t.Errorf("tentang = %v", tentang)
	}
	if r := byTarget["faq"]; r.Imported != 0 || !strings.Contains(r.Note, "gagal membaca") {
		t.Errorf("missing source table should be reported, got %+v", r)
	}

	// Idempoten: dijalankan ulang tidak menggandakan data.
	if _, err := newMigrator().Run(ctx); err != nil {
		t.Fatal(err)
	}
	if _, total, _ := store.List(ctx, find(t, "banners"), resource.ListQuery{Limit: 10}); total != 2 {
		t.Errorf("rerun duplicated banners: %d", total)
	}
	if _, total, _ := store.List(ctx, find(t, "dokumen"), resource.ListQuery{Limit: 10}); total != 1 {
		t.Errorf("rerun duplicated dokumen: %d", total)
	}
}

func TestMigrateLegacyDryRunWritesNothing(t *testing.T) {
	pool, store := setup(t)
	src := fakeLegacy(t)
	m := &legacy.Migrator{
		Pool:      pool,
		Supabase:  legacy.SupabaseSource{BaseURL: src.URL, AnonKey: "anon"},
		Firestore: legacy.FirestoreSource{ProjectID: "p", APIKey: "k", BaseURL: src.URL},
		Files:     nil, // dry run tidak boleh menyentuh storage
		DryRun:    true,
	}
	reports, err := m.Run(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	imported := 0
	for _, r := range reports {
		imported += r.Imported
	}
	if imported == 0 {
		t.Error("dry run should still report what would be imported")
	}
	if _, total, _ := store.List(context.Background(), find(t, "banners"), resource.ListQuery{Limit: 10}); total != 0 {
		t.Errorf("dry run wrote %d banners", total)
	}
}
