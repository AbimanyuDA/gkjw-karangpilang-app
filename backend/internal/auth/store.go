package auth

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// ErrAdminNotFound dikembalikan bila email admin tidak terdaftar.
var ErrAdminNotFound = errors.New("admin tidak ditemukan")

// Admin adalah akun pengurus yang boleh mengelola konten.
type Admin struct {
	ID           string
	Email        string
	PasswordHash string
}

// PgAdminStore menyimpan akun admin di PostgreSQL.
type PgAdminStore struct {
	pool *pgxpool.Pool
}

// NewPgAdminStore membuat store admin.
func NewPgAdminStore(pool *pgxpool.Pool) *PgAdminStore {
	return &PgAdminStore{pool: pool}
}

// FindByEmail mencari admin (email tidak case-sensitive).
func (s *PgAdminStore) FindByEmail(ctx context.Context, email string) (Admin, error) {
	var a Admin
	err := s.pool.QueryRow(ctx,
		"SELECT id::text, email, password_hash FROM admins WHERE email = $1",
		NormalizeEmail(email),
	).Scan(&a.ID, &a.Email, &a.PasswordHash)
	if errors.Is(err, pgx.ErrNoRows) {
		return Admin{}, ErrAdminNotFound
	}
	if err != nil {
		return Admin{}, fmt.Errorf("cari admin: %w", err)
	}
	return a, nil
}

// FindByID mencari admin berdasarkan id (dari token).
func (s *PgAdminStore) FindByID(ctx context.Context, id string) (Admin, error) {
	var a Admin
	err := s.pool.QueryRow(ctx,
		"SELECT id::text, email, password_hash FROM admins WHERE id::text = $1", id,
	).Scan(&a.ID, &a.Email, &a.PasswordHash)
	if errors.Is(err, pgx.ErrNoRows) {
		return Admin{}, ErrAdminNotFound
	}
	if err != nil {
		return Admin{}, fmt.Errorf("cari admin: %w", err)
	}
	return a, nil
}

// SetPassword mengganti hash password admin.
func (s *PgAdminStore) SetPassword(ctx context.Context, id, passwordHash string) error {
	tag, err := s.pool.Exec(ctx,
		"UPDATE admins SET password_hash = $1, updated_at = now() WHERE id::text = $2", passwordHash, id)
	if err != nil {
		return fmt.Errorf("ganti password: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return ErrAdminNotFound
	}
	return nil
}

// Upsert membuat admin baru atau mengganti password admin yang sudah ada.
func (s *PgAdminStore) Upsert(ctx context.Context, email, passwordHash string) error {
	_, err := s.pool.Exec(ctx, `
		INSERT INTO admins (email, password_hash) VALUES ($1, $2)
		ON CONFLICT (email) DO UPDATE SET password_hash = EXCLUDED.password_hash, updated_at = now()`,
		NormalizeEmail(email), passwordHash)
	if err != nil {
		return fmt.Errorf("simpan admin: %w", err)
	}
	return nil
}

// NormalizeEmail merapikan email agar pencarian konsisten.
func NormalizeEmail(email string) string {
	return strings.ToLower(strings.TrimSpace(email))
}
