-- +goose Up
-- Banner tidak punya aksi saat diketuk di aplikasi; kolom link tidak dipakai.
ALTER TABLE banner_slide DROP COLUMN link_url;

-- +goose Down
ALTER TABLE banner_slide ADD COLUMN link_url text;
