-- +goose Up
-- Semua cover kartu menu Gereja (termasuk Informasi Gereja) kembali diatur di satu
-- tempat: menu admin "Cover Menu Gereja" (tabel gereja_covers).
INSERT INTO gereja_covers (key, image_url)
SELECT 'informasi_gereja', cover_foto FROM informasi_gereja WHERE cover_foto IS NOT NULL
ON CONFLICT (key) DO UPDATE SET image_url = EXCLUDED.image_url, updated_at = now();
ALTER TABLE informasi_gereja DROP COLUMN cover_foto;

-- +goose Down
ALTER TABLE informasi_gereja ADD COLUMN cover_foto text;
INSERT INTO informasi_gereja (id, cover_foto)
SELECT 1, image_url FROM gereja_covers WHERE key = 'informasi_gereja'
ON CONFLICT (id) DO UPDATE SET cover_foto = EXCLUDED.cover_foto;
DELETE FROM gereja_covers WHERE key = 'informasi_gereja';
