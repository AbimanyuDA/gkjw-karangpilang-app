-- +goose Up
-- Informasi Gereja kini hanya berisi tiga kartu + foto kartunya di menu Gereja.
-- Kolom umum/kontak tidak ditampilkan aplikasi (kontak ada di menu Hubungi Kami),
-- dan cover kartu Informasi Gereja pindah dari gereja_covers ke sini.
ALTER TABLE informasi_gereja ADD COLUMN cover_foto text;
INSERT INTO informasi_gereja (id, cover_foto)
SELECT 1, image_url FROM gereja_covers WHERE key = 'informasi_gereja'
ON CONFLICT (id) DO UPDATE SET cover_foto = EXCLUDED.cover_foto;
DELETE FROM gereja_covers WHERE key = 'informasi_gereja';

ALTER TABLE informasi_gereja
    DROP COLUMN nama,
    DROP COLUMN alamat,
    DROP COLUMN telepon,
    DROP COLUMN email,
    DROP COLUMN maps_url;

-- +goose Down
ALTER TABLE informasi_gereja
    ADD COLUMN nama     text,
    ADD COLUMN alamat   text,
    ADD COLUMN telepon  text,
    ADD COLUMN email    text,
    ADD COLUMN maps_url text;
INSERT INTO gereja_covers (key, image_url)
SELECT 'informasi_gereja', cover_foto FROM informasi_gereja WHERE cover_foto IS NOT NULL
ON CONFLICT (key) DO NOTHING;
ALTER TABLE informasi_gereja DROP COLUMN cover_foto;
