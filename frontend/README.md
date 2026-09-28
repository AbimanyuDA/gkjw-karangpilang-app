# GKJW Karangpilang App

Aplikasi mobile resmi **Gereja Kristen Jawi Wetan Jemaat Karangpilang** berbasis Flutter.

## Tech Stack

| Layer | Teknologi |
|-------|-----------|
| Framework | Flutter 3.41.3 |
| Backend | REST API Go + PostgreSQL (folder `../backend`) |
| Auth admin | JWT dari backend, disimpan di `flutter_secure_storage` |
| HTTP | Dio (`lib/data/api/api_client.dart`) |
| Cache PDF | `lib/core/utils/pdf_cache.dart` |
| State Management | Riverpod |
| Navigation | Go Router |

## Fitur

### Menu Beranda
1. **Warta Jemaat** – PDF mingguan, download & view
2. **Tata Ibadah** – PDF mingguan, download & view
3. **Renungan** – PDF harian, download & view
4. **Agenda** – Jadwal kegiatan jemaat
5. **Galeri** – Foto per tahun & komisi
6. **Persembahan** – QRIS + Transfer Bank BRI
7. **E-Perpustakaan** – Buku digital karya GKJW
8. **Inspirasi** – Spin wheel tantangan rohani (anak & dewasa)

### Menu Siaran
- Ibadah Umum, Anak, Remaja, Sekolah Minggu (YouTube embed)

### Menu Gereja
- Informasi Gereja, Kependetaan, Kemajelisan, BPM, Perwilayahan, Profil Ruangan

### Menu Informasi
- Notifikasi, Hubungi Kami, FAQ, Tentang Aplikasi

Konten dikelola lewat **website admin** (`../admin-web`), bukan dari aplikasi.

### Tampilan
- Tema terang (cream/emas) & gelap (navy), mengikuti HP atau dipilih di menu Informasi

## Menjalankan

Aplikasi membaca data dari backend Go (`../backend`). Dari root repo:

```bash
make dev        # backend lokal di http://localhost:8080
make app-run    # emulator Android
# simulator iOS:
flutter run --dart-define-from-file=config/dev-ios.json
```

Build rilis: isi `config/prod.json` dengan domain API, lalu `make app-build-apk` dari root repo.

## Struktur Proyek

```
lib/
├── core/
│   ├── config/       # alamat API (dari --dart-define-from-file)
│   ├── theme/        # palet terang/gelap, font, pilihan tema
│   ├── utils/        # router, cache PDF
│   └── widgets/      # shell navigasi, daftar PDF, profil
├── data/
│   ├── api/          # ApiClient (Dio) — hanya membaca
│   ├── models/       # model konten
│   └── services/     # ContentService, notifikasi sapaan
├── features/         # beranda, siaran, gereja, informasi, splash
└── providers/        # provider Riverpod
```

## Test

```bash
flutter analyze && flutter test
make app-e2e DEVICE=<id>   # dari root repo, butuh `make dev`
```
