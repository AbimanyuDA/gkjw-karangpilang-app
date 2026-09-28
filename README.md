# Aplikasi GKJW Jemaat Karangpilang

Aplikasi resmi jemaat (Flutter), website admin untuk pengurus (React), dan backend sendiri (Go + PostgreSQL) yang dijalankan dengan Docker.

```
.
├── frontend/   Aplikasi Flutter untuk jemaat (Android & iOS) — hanya membaca
├── admin-web/  Website admin untuk pengurus (React + Vite) — di https://{DOMAIN}/admin/
├── backend/    REST API Go + migrasi database PostgreSQL
├── deploy/     Docker Compose produksi & dev, Caddy (HTTPS), backup harian
├── docs/       Panduan deploy & migrasi data
└── Makefile    Perintah sehari-hari (`make help`)
```

## Arsitektur

```
HP jemaat ────┐
Admin (web) ──┼─► Cloudflare (CDN) ─► VPS IDCloudHost
Website ──────┘                       ├─ Caddy       HTTPS, reverse proxy + website admin (/admin/)
                                      ├─ API (Go)    /api/v1/*, /files/*
                                      ├─ PostgreSQL  data (tidak terbuka ke internet)
                                      └─ backup      pg_dump + arsip file, tiap hari
```

- **Jemaat** tidak perlu login dan hanya membaca data (`GET /api/v1/...`). Respons boleh di-cache 30 detik oleh Cloudflare.
- **Admin** mengelola konten lewat **website admin** di `https://{DOMAIN}/admin/` (login email & password → token JWT). Aplikasi HP tidak lagi memiliki menu admin.
- **File** (PDF, gambar) di-upload ke server dan disajikan di `/files/{bucket}/{nama}`. Nama file unik, jadi file bisa di-cache selamanya oleh HP dan Cloudflare. Aplikasi juga menyimpan PDF yang sudah diunduh, sehingga tidak perlu unduh ulang.

## Mulai development

Kebutuhan: Docker, Go 1.26+, Flutter 3.41+, Node.js 22+.

```bash
make dev                              # PostgreSQL + API di http://localhost:8080
make dev-admin EMAIL=admin@gkjw.local # buat akun admin (password diminta)
make admin-dev                        # website admin di http://localhost:5174/admin/
make app-run                          # jalankan app di emulator Android
```

- **Simulator iOS**: `cd frontend && flutter run --dart-define-from-file=config/dev-ios.json`
- **HP Android fisik**: jalankan `adb reverse tcp:8080 tcp:8080`, lalu ubah `frontend/config/dev.json` menjadi `http://localhost:8080`.

## Test

```bash
make backend-test      # unit test Go
make test-integration  # + test ke PostgreSQL sungguhan (Docker)
make admin-test        # typecheck + lint + test website admin
make app-test          # flutter analyze + flutter test
make app-e2e DEVICE=<id>   # E2E aplikasi di emulator/simulator (butuh `make dev`)
```

## Menambah jenis konten baru

1. Buat migrasi baru di `backend/internal/database/migrations/0000N_nama.sql` (file lama jangan diubah).
2. Tambahkan satu entri `Resource` di [backend/internal/resource/registry.go](backend/internal/resource/registry.go) (termasuk `Label`, `Group`, dan `Input` tiap field). Validasi, endpoint API, **dan halaman website admin** terbentuk otomatis — frontend admin tidak perlu diubah.
3. Tampilkan di aplikasi: tambahkan model + method di `frontend/lib/data/` dan provider di `frontend/lib/providers/providers.dart`.

## Website admin

Halaman depan **Persiapan Minggu** menampilkan Minggu terdekat dan apakah warta, tata ibadah, dan video ibadah untuk hari itu sudah diunggah. Tombol "Unggah …" membuka form yang sudah terisi kategori & tanggalnya. Menu lain dibangun otomatis dari `GET /api/v1/admin/schema`: tabel, form, upload gambar/PDF (gambar dikecilkan otomatis sebelum diunggah), dan isi otomatis dari link YouTube.

## Tampilan & logo

Aplikasi & website admin memakai palet website gereja: **tema terang** cream `#F8F2E4` + navy `#0B1F3A` + emas `#D9A23A`; **tema gelap** navy `#0A1422`. Judul memakai Source Serif 4, teks Plus Jakarta Sans. Pengguna memilih *Ikuti HP / Terang / Gelap* di menu Informasi (aplikasi) atau di bawah sidebar (admin). Palet aplikasi ada di [frontend/lib/core/theme/app_theme.dart](frontend/lib/core/theme/app_theme.dart), website admin di [admin-web/src/styles/tokens.css](admin-web/src/styles/tokens.css).

Mengganti logo: timpa file di `frontend/assets/branding/` dan `frontend/assets/images/logo.png`, lalu jalankan:

```bash
cd frontend && dart run flutter_launcher_icons && dart run flutter_native_splash:create
```

## Siaran YouTube

Di website admin, cukup tempel link video: judul, deskripsi, dan tanggal terisi otomatis **tanpa API key Google** (gratis, tanpa kuota). Backend mengambil judul dari oEmbed YouTube dan deskripsi + tanggal dari halaman video ([backend/internal/youtube](backend/internal/youtube/youtube.go)). Tanggal yang tertulis di judul (mis. "Ibadah 27 April 2025") diutamakan.

## Dokumentasi

- [docs/DEPLOY.md](docs/DEPLOY.md): memasang di VPS IDCloudHost dari nol
- [docs/MIGRASI-DATA.md](docs/MIGRASI-DATA.md): memindahkan data lama dari Supabase & Firestore
- [docs/API.md](docs/API.md): daftar endpoint
