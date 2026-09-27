package resource

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/AbimanyuDA/gkjw-karangpilang-app/backend/internal/httpx"
)

// Row adalah satu baris hasil query dalam bentuk map kolom → nilai.
type Row = map[string]any

// PgStore mengimplementasikan Repository di atas PostgreSQL.
type PgStore struct {
	pool *pgxpool.Pool
}

// NewPgStore membuat store baru.
func NewPgStore(pool *pgxpool.Pool) *PgStore {
	return &PgStore{pool: pool}
}

// List mengembalikan satu halaman data dan jumlah total yang cocok dengan filter.
func (s *PgStore) List(ctx context.Context, r Resource, q ListQuery) ([]Row, int, error) {
	countSQL, countArgs := r.buildCount(q)
	var total int
	if err := s.pool.QueryRow(ctx, countSQL, countArgs...).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("hitung %s: %w", r.Table, err)
	}

	sql, args := r.buildList(q)
	rows, err := s.pool.Query(ctx, sql, args...)
	if err != nil {
		return nil, 0, fmt.Errorf("list %s: %w", r.Table, err)
	}
	items, err := pgx.CollectRows(rows, pgx.RowToMap)
	if err != nil {
		return nil, 0, fmt.Errorf("baca %s: %w", r.Table, err)
	}
	return items, total, nil
}

// Get mengambil satu baris berdasarkan id.
func (s *PgStore) Get(ctx context.Context, r Resource, id string, public bool) (Row, error) {
	sql, args := r.buildGet(id, public)
	return s.one(ctx, r, sql, args)
}

// Create menyisipkan baris baru (atau upsert bila Resource.UpsertKey diisi).
func (s *PgStore) Create(ctx context.Context, r Resource, values Row) (Row, error) {
	sql, args := r.buildInsert(values)
	return s.one(ctx, r, sql, args)
}

// Update mengubah field yang dikirim pada baris dengan id tertentu.
func (s *PgStore) Update(ctx context.Context, r Resource, id string, values Row) (Row, error) {
	sql, args := r.buildUpdate(id, values)
	return s.one(ctx, r, sql, args)
}

// Delete menghapus baris; mengembalikan httpx.ErrNotFound bila tidak ada.
func (s *PgStore) Delete(ctx context.Context, r Resource, id string) error {
	sql, args := r.buildDelete(id)
	tag, err := s.pool.Exec(ctx, sql, args...)
	if err != nil {
		return mapPgError(fmt.Errorf("hapus %s: %w", r.Table, err))
	}
	if tag.RowsAffected() == 0 {
		return httpx.ErrNotFound
	}
	return nil
}

// GetSingleton mengambil baris konfigurasi; nil bila belum pernah diisi.
func (s *PgStore) GetSingleton(ctx context.Context, r Resource) (Row, error) {
	row, err := s.one(ctx, r, r.buildGetSingleton(), nil)
	if errors.Is(err, httpx.ErrNotFound) {
		return nil, nil
	}
	return row, err
}

// PutSingleton membuat atau memperbarui baris konfigurasi.
func (s *PgStore) PutSingleton(ctx context.Context, r Resource, values Row) (Row, error) {
	sql, args := r.buildUpsertSingleton(values)
	return s.one(ctx, r, sql, args)
}

// DistinctInts mengembalikan nilai unik sebuah kolom integer, terurut menurun.
func (s *PgStore) DistinctInts(ctx context.Context, r Resource, column string) ([]int64, error) {
	if _, ok := r.field(column); !ok {
		return nil, fmt.Errorf("kolom %q tidak ada di %s", column, r.Table)
	}
	sql := fmt.Sprintf("SELECT DISTINCT %s FROM %s WHERE %s IS NOT NULL ORDER BY %s DESC", column, r.Table, column, column)
	rows, err := s.pool.Query(ctx, sql)
	if err != nil {
		return nil, fmt.Errorf("distinct %s.%s: %w", r.Table, column, err)
	}
	vals, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (int64, error) {
		var v int64
		err := row.Scan(&v)
		return v, err
	})
	if err != nil {
		return nil, fmt.Errorf("baca distinct %s.%s: %w", r.Table, column, err)
	}
	return vals, nil
}

func (s *PgStore) one(ctx context.Context, r Resource, sql string, args []any) (Row, error) {
	rows, err := s.pool.Query(ctx, sql, args...)
	if err != nil {
		return nil, mapPgError(fmt.Errorf("query %s: %w", r.Table, err))
	}
	row, err := pgx.CollectExactlyOneRow(rows, pgx.RowToMap)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, httpx.ErrNotFound
	}
	if err != nil {
		return nil, mapPgError(fmt.Errorf("baca %s: %w", r.Table, err))
	}
	return row, nil
}

// mapPgError mengubah pelanggaran constraint menjadi error yang aman untuk klien.
func mapPgError(err error) error {
	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) {
		return err
	}
	switch pgErr.Code {
	case "23505": // unique_violation
		return &httpx.Error{Code: "conflict", Message: "Data dengan nilai tersebut sudah ada"}
	case "23502", "23514": // not_null_violation, check_violation
		return httpx.Validation(map[string]string{pgErr.ColumnName: "nilai tidak diizinkan"})
	case "22P02": // invalid_text_representation (mis. uuid tidak valid)
		return httpx.ErrNotFound
	}
	return err
}
