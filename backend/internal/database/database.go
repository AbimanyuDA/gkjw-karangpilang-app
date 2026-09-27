// Package database mengelola koneksi PostgreSQL dan migrasi skema.
package database

import (
	"context"
	"embed"
	"fmt"
	"io/fs"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jackc/pgx/v5/stdlib"
	"github.com/pressly/goose/v3"
)

//go:embed migrations/*.sql
var migrations embed.FS

// Connect membuka connection pool dan memastikan database dapat dijangkau.
func Connect(ctx context.Context, url string) (*pgxpool.Pool, error) {
	cfg, err := pgxpool.ParseConfig(url)
	if err != nil {
		return nil, fmt.Errorf("parse DATABASE_URL: %w", err)
	}
	cfg.MaxConns = 20
	cfg.MaxConnIdleTime = 5 * time.Minute

	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		return nil, fmt.Errorf("buat connection pool: %w", err)
	}

	pingCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	if err := pool.Ping(pingCtx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("ping database: %w", err)
	}
	return pool, nil
}

// Migrate menjalankan semua migrasi yang belum diterapkan.
func Migrate(ctx context.Context, pool *pgxpool.Pool) error {
	dir, err := fs.Sub(migrations, "migrations")
	if err != nil {
		return fmt.Errorf("baca folder migrasi: %w", err)
	}
	db := stdlib.OpenDBFromPool(pool)
	defer db.Close()

	provider, err := goose.NewProvider(goose.DialectPostgres, db, dir)
	if err != nil {
		return fmt.Errorf("siapkan migrasi: %w", err)
	}
	if _, err := provider.Up(ctx); err != nil {
		return fmt.Errorf("jalankan migrasi: %w", err)
	}
	return nil
}
