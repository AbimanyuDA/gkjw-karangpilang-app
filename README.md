# Aplikasi GKJW Jemaat Karangpilang

Aplikasi resmi jemaat (Flutter) dengan backend sendiri (Go + PostgreSQL) yang dijalankan dengan Docker.

```
.
├── frontend/   Aplikasi Flutter (Android & iOS)
├── backend/    REST API Go + migrasi database PostgreSQL
├── deploy/     Docker Compose produksi & dev, Caddy (HTTPS), backup harian
├── docs/       Panduan deploy & migrasi data
└── Makefile    Perintah sehari-hari (`make help`)
```

## Arsitektur

```
HP jemaat ─┐
Website ───┼─► Cloudflare (CDN) ─► VPS IDCloudHost
           │                       ├─ Caddy      HTTPS otomatis, reverse proxy
           │                       ├─ API (Go)   /api/v1/*, /files/*
           │                       ├─ PostgreSQL data (tidak terbuka ke internet)
           │                       └─ backup     pg_dump + arsip file, tiap hari
```

- **Jemaat** tidak perlu login dan hanya membaca data (`GET /api/v1/...`). Respons boleh di-cache 30 detik oleh Cloudflare.
- **Admin** login lewat `POST /api/v1/auth/login` dan mendapat token JWT. Semua perubahan data lewat `/api/v1/admin/...`.
- **File** (PDF, gambar) di-upload ke server dan disajikan di `/files/{bucket}/{nama}`. Nama file unik, jadi file bisa di-cache selamanya oleh HP dan Cloudflare. Aplikasi juga menyimpan PDF yang sudah diunduh, sehingga tidak perlu unduh ulang.

## Mulai development

Kebutuhan: Docker, Go 1.26+, Flutter 3.41+.

```bash
make dev                              # PostgreSQL + API di http://localhost:8080
make dev-admin EMAIL=admin@gkjw.local # buat akun admin (password diminta)
make app-run                          # jalankan app di emulator Android
```

- **Simulator iOS**: `cd frontend && flutter run --dart-define-from-file=config/dev-ios.json`
- **HP Android fisik**: jalankan `adb reverse tcp:8080 tcp:8080`, lalu ubah `frontend/config/dev.json` menjadi `http://localhost:8080`.

## Test

```bash
make backend-test      # unit test Go
make test-integration  # + test ke PostgreSQL sungguhan (Docker)
make app-test          # flutter analyze + flutter test
make app-e2e DEVICE=<id> ADMIN_PASSWORD=...   # E2E di emulator/simulator (butuh `make dev`)
```

## Menambah jenis konten baru

1. Buat migrasi baru di `backend/internal/database/migrations/0000N_nama.sql` (file lama jangan diubah).
2. Tambahkan satu entri `Resource` di [backend/internal/resource/registry.go](backend/internal/resource/registry.go). Validasi, endpoint publik, dan endpoint admin terbentuk otomatis.
3. Tambahkan model + method di `frontend/lib/data/` dan provider di `frontend/lib/providers/providers.dart`.

## Tampilan & logo

Warna dan font aplikasi mengikuti website: cream `#F8F2E4` dominan, navy `#0B1F3A`, aksen emas `#D9A23A`, dengan Source Serif 4 untuk judul dan Plus Jakarta Sans untuk teks. Semuanya diatur di [frontend/lib/core/theme/app_theme.dart](frontend/lib/core/theme/app_theme.dart).

Mengganti logo: timpa file di `frontend/assets/branding/` dan `frontend/assets/images/logo.png`, lalu jalankan:

```bash
cd frontend && dart run flutter_launcher_icons && dart run flutter_native_splash:create
```

## Siaran YouTube

Judul, deskripsi, dan tanggal video diambil **tanpa API key Google**, gratis dan tanpa kuota: judul dari oEmbed YouTube, deskripsi dan tanggal dari `youtube_explode_dart`. Admin cukup menempel link video.

## Dokumentasi

- [docs/DEPLOY.md](docs/DEPLOY.md): memasang di VPS IDCloudHost dari nol
- [docs/MIGRASI-DATA.md](docs/MIGRASI-DATA.md): memindahkan data lama dari Supabase & Firestore
- [docs/API.md](docs/API.md): daftar endpoint
