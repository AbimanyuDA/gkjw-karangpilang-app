-- +goose Up
-- Halaman Informasi Gereja dibagi tiga kartu (Visi dan Misi, Sejarah, Potret Diri),
-- masing-masing dengan foto sendiri.
ALTER TABLE informasi_gereja RENAME COLUMN deskripsi TO sejarah;
ALTER TABLE informasi_gereja
    ADD COLUMN visi_misi_foto text,
    ADD COLUMN sejarah_foto   text,
    ADD COLUMN potret_foto    text,
    ADD COLUMN potret_diri    text;

-- +goose Down
ALTER TABLE informasi_gereja
    DROP COLUMN potret_diri,
    DROP COLUMN potret_foto,
    DROP COLUMN sejarah_foto,
    DROP COLUMN visi_misi_foto;
ALTER TABLE informasi_gereja RENAME COLUMN sejarah TO deskripsi;
