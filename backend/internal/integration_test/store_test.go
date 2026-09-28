// Package integration_test menguji query SQL terhadap PostgreSQL sungguhan.
//
// Jalankan dengan: make test-integration
// (atau set TEST_DATABASE_URL ke database kosong khusus test — isinya akan dihapus).
package integration_test

import (
	"context"
	"errors"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/auth"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/database"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/httpx"
	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/resource"
)

func setup(t *testing.T) (*pgxpool.Pool, *resource.PgStore) {
	t.Helper()
	url := os.Getenv("TEST_DATABASE_URL")
	if url == "" {
		t.Skip("TEST_DATABASE_URL tidak di-set; lewati integration test")
	}
	ctx := context.Background()
	pool, err := database.Connect(ctx, url)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	if _, err := pool.Exec(ctx, "DROP SCHEMA public CASCADE; CREATE SCHEMA public"); err != nil {
		t.Fatal(err)
	}
	if err := database.Migrate(ctx, pool); err != nil {
		t.Fatal(err)
	}
	return pool, resource.NewPgStore(pool)
}

func find(t *testing.T, path string) resource.Resource {
	t.Helper()
	for _, r := range resource.All {
		if r.Path == path {
			return r
		}
	}
	t.Fatalf("resource %q tidak ada", path)
	return resource.Resource{}
}

func mustValidate(t *testing.T, r resource.Resource, in map[string]any, mode resource.Mode) resource.Row {
	t.Helper()
	v, errs := r.Validate(in, mode)
	if errs != nil {
		t.Fatalf("validate: %v", errs)
	}
	return v
}

// TestEveryResourceMatchesSchema memastikan setiap spec di registry cocok dengan tabel hasil migrasi.
func TestEveryResourceMatchesSchema(t *testing.T) {
	_, store := setup(t)
	ctx := context.Background()
	for _, r := range resource.All {
		t.Run(r.Path, func(t *testing.T) {
			var err error
			if r.Singleton {
				_, err = store.GetSingleton(ctx, r)
			} else {
				_, _, err = store.List(ctx, r, resource.ListQuery{Limit: 1, Public: true})
			}
			if err != nil {
				t.Errorf("spec tidak cocok dengan skema: %v", err)
			}
		})
	}
}

func TestDokumenCRUDAndFilter(t *testing.T) {
	_, store := setup(t)
	ctx := context.Background()
	res := find(t, "dokumen")

	for i, kat := range []string{"warta", "warta", "renungan"} {
		_, err := store.Create(ctx, res, mustValidate(t, res, map[string]any{
			"kategori": kat, "judul": "Doc", "url": "https://x/a.pdf",
			"tanggal": time.Date(2026, 9, 20+i, 0, 0, 0, 0, time.UTC).Format(time.RFC3339),
		}, resource.Create))
		if err != nil {
			t.Fatal(err)
		}
	}

	items, total, err := store.List(ctx, res, resource.ListQuery{Filters: map[string]any{"kategori": "warta"}, Limit: 1})
	if err != nil {
		t.Fatal(err)
	}
	if total != 2 || len(items) != 1 {
		t.Fatalf("total = %d len = %d", total, len(items))
	}
	newest := items[0]
	if newest["tanggal"].(time.Time).Day() != 21 {
		t.Errorf("expected newest first, got %v", newest["tanggal"])
	}
	id, ok := newest["id"].(string)
	if !ok || len(id) != 36 {
		t.Fatalf("id must be uuid string, got %#v", newest["id"])
	}

	updated, err := store.Update(ctx, res, id, mustValidate(t, res, map[string]any{"judul": "Baru"}, resource.Update))
	if err != nil || updated["judul"] != "Baru" || updated["kategori"] != "warta" {
		t.Fatalf("update: %v %v", err, updated)
	}
	if !updated["updated_at"].(time.Time).After(updated["created_at"].(time.Time)) &&
		!updated["updated_at"].(time.Time).Equal(updated["created_at"].(time.Time)) {
		t.Error("updated_at must not be before created_at")
	}

	if err := store.Delete(ctx, res, id); err != nil {
		t.Fatal(err)
	}
	if err := store.Delete(ctx, res, id); !errors.Is(err, httpx.ErrNotFound) {
		t.Errorf("second delete: %v", err)
	}
	if _, err := store.Get(ctx, res, id, true); !errors.Is(err, httpx.ErrNotFound) {
		t.Errorf("get deleted: %v", err)
	}
}

func TestPublicWhereHidesInactive(t *testing.T) {
	_, store := setup(t)
	ctx := context.Background()
	res := find(t, "banners")
	row, err := store.Create(ctx, res, mustValidate(t, res, map[string]any{
		"image_url": "https://x/b.jpg", "is_active": false,
	}, resource.Create))
	if err != nil {
		t.Fatal(err)
	}
	if _, total, _ := store.List(ctx, res, resource.ListQuery{Public: true, Limit: 10}); total != 0 {
		t.Errorf("public list shows inactive banner")
	}
	if _, total, _ := store.List(ctx, res, resource.ListQuery{Limit: 10}); total != 1 {
		t.Errorf("admin list must show inactive banner")
	}
	if _, err := store.Get(ctx, res, row["id"].(string), true); !errors.Is(err, httpx.ErrNotFound) {
		t.Errorf("public get must hide inactive banner: %v", err)
	}
}

func TestGerejaCoverUpsert(t *testing.T) {
	_, store := setup(t)
	ctx := context.Background()
	res := find(t, "gereja-covers")
	for _, url := range []string{"https://x/1.jpg", "https://x/2.jpg"} {
		if _, err := store.Create(ctx, res, mustValidate(t, res, map[string]any{"key": "bpm", "image_url": url}, resource.Create)); err != nil {
			t.Fatal(err)
		}
	}
	items, total, _ := store.List(ctx, res, resource.ListQuery{Limit: 10})
	if total != 1 || items[0]["image_url"] != "https://x/2.jpg" {
		t.Errorf("upsert failed: %v", items)
	}
}

func TestSingletonAndDistinct(t *testing.T) {
	_, store := setup(t)
	ctx := context.Background()

	cfg := find(t, "sapaan-config")
	if row, err := store.GetSingleton(ctx, cfg); err != nil || row != nil {
		t.Fatalf("empty singleton: %v %v", row, err)
	}
	if _, err := store.PutSingleton(ctx, cfg, mustValidate(t, cfg, map[string]any{"ayat_pagi": "Mzm 23"}, resource.Update)); err != nil {
		t.Fatal(err)
	}
	row, err := store.PutSingleton(ctx, cfg, mustValidate(t, cfg, map[string]any{"ayat_malam": "Mzm 4:9"}, resource.Update))
	if err != nil || row["ayat_pagi"] != "Mzm 23" || row["ayat_malam"] != "Mzm 4:9" || row["jam_pagi"] != int32(7) {
		t.Fatalf("singleton partial update: %v %v", err, row)
	}

	galeri := find(t, "galeri")
	for _, y := range []int{2024, 2026, 2024} {
		if _, err := store.Create(ctx, galeri, resource.Row{"judul": "g", "tahun": int64(y), "foto_url": "https://x/g.jpg"}); err != nil {
			t.Fatal(err)
		}
	}
	years, err := store.DistinctInts(ctx, galeri, "tahun")
	if err != nil || len(years) != 2 || years[0] != 2026 {
		t.Errorf("distinct: %v %v", years, err)
	}
}

func TestConstraintViolationIsValidationError(t *testing.T) {
	_, store := setup(t)
	res := find(t, "dokumen")
	// Lewati validasi Go untuk memastikan CHECK constraint di DB tetap menjaga data.
	_, err := store.Create(context.Background(), res, resource.Row{
		"kategori": "bukan", "judul": "x", "url": "https://x", "tanggal": time.Now(),
	})
	var apiErr *httpx.Error
	if !errors.As(err, &apiErr) || apiErr.Code != "validation_error" {
		t.Errorf("err = %v", err)
	}
}

func TestAdminStore(t *testing.T) {
	pool, _ := setup(t)
	ctx := context.Background()
	admins := auth.NewPgAdminStore(pool)

	hash, _ := auth.HashPassword("password-lama-123")
	if err := admins.Upsert(ctx, " Admin@GKJW.org", hash); err != nil {
		t.Fatal(err)
	}
	newHash, _ := auth.HashPassword("password-baru-456")
	if err := admins.Upsert(ctx, "admin@gkjw.org", newHash); err != nil {
		t.Fatal(err)
	}
	a, err := admins.FindByEmail(ctx, "ADMIN@gkjw.org")
	if err != nil || !auth.CheckPassword(a.PasswordHash, "password-baru-456") {
		t.Fatalf("find: %v", err)
	}
	if _, err := admins.FindByEmail(ctx, "x@y.z"); !errors.Is(err, auth.ErrAdminNotFound) {
		t.Errorf("unknown email: %v", err)
	}
}

func TestReorder(t *testing.T) {
	_, store := setup(t)
	ctx := context.Background()
	res := find(t, "faq")
	var ids []string
	for _, q := range []string{"A", "B", "C"} {
		row, err := store.Create(ctx, res, resource.Row{"pertanyaan": q, "jawaban": "x"})
		if err != nil {
			t.Fatal(err)
		}
		ids = append(ids, row["id"].(string))
	}
	// Data baru tanpa urutan otomatis ditaruh paling akhir.
	first, _ := store.Get(ctx, res, ids[0], false)
	last, _ := store.Get(ctx, res, ids[2], false)
	if first["urutan"] != int32(0) || last["urutan"] != int32(2) {
		t.Fatalf("auto urutan = %v, %v", first["urutan"], last["urutan"])
	}

	// Balik urutan: C, A, B
	if err := store.Reorder(ctx, res, []string{ids[2], ids[0], ids[1]}); err != nil {
		t.Fatal(err)
	}
	rows, _, _ := store.List(ctx, res, resource.ListQuery{Limit: 10})
	var got []string
	for _, r := range rows {
		got = append(got, r["pertanyaan"].(string))
	}
	if strings.Join(got, "") != "CAB" {
		t.Errorf("order = %v, want C A B", got)
	}

	// Id tak dikenal → seluruh perubahan dibatalkan (transaksi).
	err := store.Reorder(ctx, res, []string{ids[0], "6f1c1f4e-6a8e-4c43-9a57-2b1f4f7d9a10"})
	if !errors.Is(err, httpx.ErrNotFound) {
		t.Fatalf("err = %v", err)
	}
	rows, _, _ = store.List(ctx, res, resource.ListQuery{Limit: 10})
	if rows[0]["pertanyaan"] != "C" {
		t.Error("failed reorder must roll back")
	}
}
