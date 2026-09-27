-- +goose Up
-- Skema awal: menggabungkan tabel Supabase lama dan koleksi Firestore
-- (warta_jemaat, tata_ibadah, renungan → tabel `dokumen`; siaran; gereja_covers).

CREATE TABLE admins (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email         text NOT NULL UNIQUE,
    password_hash text NOT NULL,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE banner_slide (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    image_url  text NOT NULL,
    judul      text,
    link_url   text,
    urutan     integer NOT NULL DEFAULT 0,
    is_active  boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX banner_slide_active_urutan_idx ON banner_slide (is_active, urutan);

CREATE TABLE galeri (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    judul      text NOT NULL,
    deskripsi  text,
    tahun      integer NOT NULL,
    komisi     text,
    foto_url   text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX galeri_tahun_idx ON galeri (tahun DESC, created_at DESC);

CREATE TABLE agenda (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    judul      text NOT NULL,
    deskripsi  text,
    tanggal    timestamptz NOT NULL,
    tempat     text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX agenda_tanggal_idx ON agenda (tanggal);

CREATE TABLE kependetaan (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    nama       text NOT NULL,
    jabatan    text NOT NULL,
    foto_url   text,
    bio        text,
    komisi     text,
    urutan     integer NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE kemajelisan (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    nama       text NOT NULL,
    jabatan    text NOT NULL,
    foto_url   text,
    bio        text,
    komisi     text,
    urutan     integer NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE bpm (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    nama       text NOT NULL,
    ketua      text,
    deskripsi  text,
    foto_url   text,
    urutan     integer NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE perwilayahan (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    nama       text NOT NULL,
    ketua      text,
    deskripsi  text,
    foto_url   text,
    urutan     integer NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE profil_ruangan (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    nama       text NOT NULL,
    kapasitas  integer,
    deskripsi  text,
    foto_url   text,
    urutan     integer NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE eperpus (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    judul      text NOT NULL,
    penulis    text,
    deskripsi  text,
    cover_url  text,
    file_url   text NOT NULL,
    tahun      integer,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE inspirasi (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    kategori   text NOT NULL,
    teks      text NOT NULL,
    warna      text NOT NULL DEFAULT '#3B82F6',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX inspirasi_kategori_idx ON inspirasi (kategori);

CREATE TABLE notifikasi (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    judul      text NOT NULL,
    pesan      text NOT NULL,
    is_active  boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX notifikasi_active_idx ON notifikasi (is_active, created_at DESC);

CREATE TABLE faq (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    pertanyaan text NOT NULL,
    jawaban    text NOT NULL,
    urutan     integer NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE hubungi_kami (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    nama       text NOT NULL,
    jenis      text NOT NULL,
    nilai      text NOT NULL,
    ikon       text,
    urutan     integer NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Dulu tiga koleksi Firestore terpisah: warta_jemaat, tata_ibadah, renungan.
CREATE TABLE dokumen (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    kategori   text NOT NULL CHECK (kategori IN ('warta', 'tata_ibadah', 'renungan')),
    judul      text NOT NULL,
    url        text NOT NULL,
    tanggal    timestamptz NOT NULL,
    thumbnail  text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX dokumen_kategori_tanggal_idx ON dokumen (kategori, tanggal DESC);

CREATE TABLE siaran (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    judul      text NOT NULL,
    youtube_id text NOT NULL,
    kategori   text NOT NULL,
    tanggal    timestamptz NOT NULL,
    thumbnail  text,
    deskripsi  text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX siaran_kategori_tanggal_idx ON siaran (kategori, tanggal DESC);

-- Satu cover per menu halaman Gereja; `key` = nama menu.
CREATE TABLE gereja_covers (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    key        text NOT NULL UNIQUE,
    image_url  text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Tabel konfigurasi satu baris (id selalu 1).
CREATE TABLE informasi_gereja (
    id         smallint PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    nama       text,
    alamat     text,
    deskripsi  text,
    visi       text,
    misi       text,
    telepon    text,
    email      text,
    maps_url   text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE tentang_aplikasi (
    id             smallint PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    versi          text,
    deskripsi      text,
    tim_pengembang text,
    created_at     timestamptz NOT NULL DEFAULT now(),
    updated_at     timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE sapaan_config (
    id          smallint PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    jam_pagi    integer NOT NULL DEFAULT 7 CHECK (jam_pagi BETWEEN 0 AND 23),
    menit_pagi  integer NOT NULL DEFAULT 0 CHECK (menit_pagi BETWEEN 0 AND 59),
    jam_malam   integer NOT NULL DEFAULT 19 CHECK (jam_malam BETWEEN 0 AND 23),
    menit_malam integer NOT NULL DEFAULT 0 CHECK (menit_malam BETWEEN 0 AND 59),
    ayat_pagi   text NOT NULL DEFAULT '',
    ayat_malam  text NOT NULL DEFAULT '',
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now()
);

-- +goose Down
DROP TABLE sapaan_config;
DROP TABLE tentang_aplikasi;
DROP TABLE informasi_gereja;
DROP TABLE gereja_covers;
DROP TABLE siaran;
DROP TABLE dokumen;
DROP TABLE hubungi_kami;
DROP TABLE faq;
DROP TABLE notifikasi;
DROP TABLE inspirasi;
DROP TABLE eperpus;
DROP TABLE profil_ruangan;
DROP TABLE perwilayahan;
DROP TABLE bpm;
DROP TABLE kemajelisan;
DROP TABLE kependetaan;
DROP TABLE agenda;
DROP TABLE galeri;
DROP TABLE banner_slide;
DROP TABLE admins;
