package resource

import (
	"reflect"
	"testing"
)

var qRes = Resource{
	Table: "banner_slide",
	Fields: []Field{
		{Name: "image_url", Type: Text},
		{Name: "urutan", Type: Int},
		{Name: "is_active", Type: Bool},
	},
	OrderBy:     "urutan ASC",
	Filters:     []string{"urutan", "is_active"},
	PublicWhere: "is_active",
}

const cols = "id::text AS id, image_url, urutan, is_active, created_at, updated_at"

func TestBuildList(t *testing.T) {
	sql, args := qRes.buildList(ListQuery{
		Filters: map[string]any{"is_active": true, "urutan": int64(2)},
		Public:  true, Limit: 10, Offset: 20,
	})
	want := "SELECT " + cols + " FROM banner_slide WHERE is_active AND urutan = $1 AND is_active = $2 ORDER BY urutan ASC LIMIT $3 OFFSET $4"
	if sql != want {
		t.Errorf("sql =\n%s\nwant\n%s", sql, want)
	}
	if !reflect.DeepEqual(args, []any{int64(2), true, 10, 20}) {
		t.Errorf("args = %v", args)
	}
}

func TestBuildList_NoFiltersDefaultOrder(t *testing.T) {
	r := qRes
	r.OrderBy = ""
	sql, _ := r.buildList(ListQuery{Limit: 5})
	want := "SELECT " + cols + " FROM banner_slide ORDER BY created_at DESC LIMIT $1 OFFSET $2"
	if sql != want {
		t.Errorf("sql = %s", sql)
	}
}

func TestBuildCount(t *testing.T) {
	sql, args := qRes.buildCount(ListQuery{Public: true})
	if sql != "SELECT count(*) FROM banner_slide WHERE is_active" || len(args) != 0 {
		t.Errorf("sql = %s args = %v", sql, args)
	}
}

func TestBuildGet(t *testing.T) {
	sql, _ := qRes.buildGet("abc", true)
	if sql != "SELECT "+cols+" FROM banner_slide WHERE id = $1 AND is_active" {
		t.Errorf("sql = %s", sql)
	}
}

func TestBuildInsert(t *testing.T) {
	sql, args := qRes.buildInsert(map[string]any{"is_active": false, "image_url": "https://x"})
	want := "INSERT INTO banner_slide (image_url, is_active) VALUES ($1, $2) RETURNING " + cols
	if sql != want {
		t.Errorf("sql =\n%s\nwant\n%s", sql, want)
	}
	if !reflect.DeepEqual(args, []any{"https://x", false}) {
		t.Errorf("args = %v", args)
	}
}

func TestBuildInsert_Upsert(t *testing.T) {
	r := Resource{Table: "gereja_covers", UpsertKey: "key", Fields: []Field{{Name: "key"}, {Name: "image_url"}}}
	sql, _ := r.buildInsert(map[string]any{"key": "bpm", "image_url": "https://x"})
	want := "INSERT INTO gereja_covers (key, image_url) VALUES ($1, $2) ON CONFLICT (key) DO UPDATE SET image_url = EXCLUDED.image_url, updated_at = now() RETURNING id::text AS id, key, image_url, created_at, updated_at"
	if sql != want {
		t.Errorf("sql =\n%s\nwant\n%s", sql, want)
	}
}

func TestBuildUpdate(t *testing.T) {
	sql, args := qRes.buildUpdate("id-1", map[string]any{"urutan": int64(4)})
	want := "UPDATE banner_slide SET urutan = $2, updated_at = now() WHERE id = $1 RETURNING " + cols
	if sql != want {
		t.Errorf("sql = %s", sql)
	}
	if !reflect.DeepEqual(args, []any{"id-1", int64(4)}) {
		t.Errorf("args = %v", args)
	}
}

func TestBuildUpsertSingleton(t *testing.T) {
	r := Resource{Table: "tentang_aplikasi", Singleton: true, Fields: []Field{{Name: "versi"}, {Name: "deskripsi"}}}
	sql, args := r.buildUpsertSingleton(map[string]any{"versi": "1.0"})
	want := "INSERT INTO tentang_aplikasi (id, versi) VALUES (1, $1) ON CONFLICT (id) DO UPDATE SET versi = EXCLUDED.versi, updated_at = now() RETURNING id::text AS id, versi, deskripsi, created_at, updated_at"
	if sql != want {
		t.Errorf("sql =\n%s\nwant\n%s", sql, want)
	}
	if len(args) != 1 {
		t.Errorf("args = %v", args)
	}
}
