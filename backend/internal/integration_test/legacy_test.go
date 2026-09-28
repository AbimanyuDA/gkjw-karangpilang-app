package integration_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/legacy"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/resource"
)

// fakeFirestore meniru REST API Firestore aplikasi versi lama.
func fakeFirestore(t *testing.T) *httptest.Server {
	t.Helper()
	collections := map[string]string{
		"warta_jemaat": `{"documents":[
			{"name":"projects/p/databases/(default)/documents/warta_jemaat/w1","fields":{
				"judul":{"stringValue":"Warta 1"},
				"file_url":{"stringValue":"https://drive.google.com/file/d/abc/view"},
				"tanggal":{"timestampValue":"2026-09-20T00:00:00Z"},
				"created_at":{"timestampValue":"2026-09-19T10:00:00Z"}}},
			{"name":"projects/p/databases/(default)/documents/warta_jemaat/w2","fields":{
				"judul":{"stringValue":"Warta lama"},
				"url":{"stringValue":"https://lama.supabase.co/storage/v1/object/public/pdf_documents/a.pdf"},
				"tanggal":{"timestampValue":"2026-09-13T00:00:00Z"}}}]}`,
		"siaran": `{"documents":[{"name":"projects/p/databases/(default)/documents/siaran/s1","fields":{
			"judul":{"stringValue":"Ibadah Minggu"},"youtube_id":{"stringValue":"dQw4w9WgXcQ"},
			"kategori":{"stringValue":"umum"},"tanggal":{"timestampValue":"2026-09-21T00:00:00.123456Z"}}}]}`,
		"gereja_covers": `{"documents":[
			{"name":"projects/p/databases/(default)/documents/gereja_covers/bpm","fields":{"imageUrl":{"stringValue":"https://cdn.example.org/bpm.jpg"}}},
			{"name":"projects/p/databases/(default)/documents/gereja_covers/kemajelisan","fields":{"imageUrl":{"stringValue":""}}}]}`,
	}
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Query().Get("key") != "k" {
			http.Error(w, "no key", http.StatusForbidden)
			return
		}
		col := r.URL.Path[strings.LastIndex(r.URL.Path, "/")+1:]
		body, ok := collections[col]
		if !ok {
			body = `{}`
		}
		w.Write([]byte(body))
	}))
	t.Cleanup(srv.Close)
	return srv
}

func newLegacyMigrator(t *testing.T, dryRun bool) (*legacy.Migrator, *resource.PgStore) {
	pool, store := setup(t)
	src := fakeFirestore(t)
	return &legacy.Migrator{
		Pool:      pool,
		Firestore: legacy.FirestoreSource{ProjectID: "p", APIKey: "k", BaseURL: src.URL},
		DryRun:    dryRun,
	}, store
}

func TestMigrateLegacy(t *testing.T) {
	m, store := newLegacyMigrator(t, false)
	ctx := context.Background()

	reports, err := m.Run(ctx)
	if err != nil {
		t.Fatal(err)
	}
	bySource := map[string]legacy.TableReport{}
	for _, r := range reports {
		bySource[r.Source] = r
	}

	// Warta: field lama file_url → url; link Google Drive dibiarkan; file di penyimpanan lama dilewati.
	warta := bySource["firestore:warta_jemaat"]
	if warta.Imported != 1 || len(warta.Skipped) != 1 || !strings.Contains(warta.Skipped[0], "unggah ulang") {
		t.Errorf("warta report = %+v", warta)
	}
	docs, _, _ := store.List(ctx, find(t, "dokumen"), resource.ListQuery{Filters: map[string]any{"kategori": "warta"}, Limit: 10})
	if len(docs) != 1 || docs[0]["url"] != "https://drive.google.com/file/d/abc/view" {
		t.Errorf("dokumen = %v", docs)
	}

	if r := bySource["firestore:siaran"]; r.Imported != 1 {
		t.Errorf("siaran report = %+v", r)
	}
	covers, _, _ := store.List(ctx, find(t, "gereja-covers"), resource.ListQuery{Limit: 10})
	if len(covers) != 1 || covers[0]["key"] != "bpm" {
		t.Errorf("covers = %v (cover kosong harus diabaikan)", covers)
	}
	if r := bySource["firestore:renungan"]; r.Read != 0 {
		t.Errorf("renungan report = %+v", r)
	}

	// Idempoten: dijalankan ulang tidak menggandakan data.
	if _, err := m.Run(ctx); err != nil {
		t.Fatal(err)
	}
	if _, total, _ := store.List(ctx, find(t, "dokumen"), resource.ListQuery{Limit: 10}); total != 1 {
		t.Errorf("rerun duplicated dokumen: %d", total)
	}
	if _, total, _ := store.List(ctx, find(t, "siaran"), resource.ListQuery{Limit: 10}); total != 1 {
		t.Errorf("rerun duplicated siaran: %d", total)
	}
}

func TestMigrateLegacyDryRunWritesNothing(t *testing.T) {
	m, store := newLegacyMigrator(t, true)
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
	if _, total, _ := store.List(context.Background(), find(t, "siaran"), resource.ListQuery{Limit: 10}); total != 0 {
		t.Errorf("dry run wrote %d siaran", total)
	}
}
