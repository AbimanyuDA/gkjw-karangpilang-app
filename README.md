# GKJW Karangpilang App

Aplikasi mobile resmi **Gereja Kristen Jawi Wetan Jemaat Karangpilang** berbasis Flutter.

## Tech Stack

| Layer | Teknologi |
|-------|-----------|
| Framework | Flutter 3.41.3 |
| Auth | Firebase Authentication (Email/Password) |
| Database (dokumen/PDF) | Firebase Firestore |
| Database (objek/relasional) | Supabase (PostgreSQL) |
| Storage | Firebase Storage |
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

### Admin Panel
- CRUD semua konten (hanya untuk pengguna yang login)

## Setup

### 1. Firebase
- Project: `gkjw-karangpilang-app`
- `google-services.json` sudah ada di `android/app/`
- `GoogleService-Info.plist` sudah ada di `ios/Runner/`

### 2. Supabase
- Project: `GKJW Karangpilang +`
- URL: `https://roocpiqogsnqqnfdokiv.supabase.co`

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run
```bash
flutter run
```

## Struktur Proyek

```
lib/
├── core/
│   ├── constants/    # AppConstants (URL, keys, dsb)
│   ├── theme/        # AppTheme, AppColors
│   ├── utils/        # AppRouter
│   └── widgets/      # Reusable widgets (PdfListScreen, ProfilListScreen)
├── data/
│   ├── models/       # Data models Firestore & Supabase
│   ├── repositories/ # Repository pattern
│   └── services/     # FirestoreService, SupabaseService
├── features/
│   ├── auth/         # Splash, Login
│   ├── beranda/      # Home + 8 menu
│   ├── siaran/       # YouTube player
│   ├── gereja/       # Profil gereja
│   ├── informasi/    # Info & kontak
│   └── admin/        # Admin dashboard
├── providers/        # Riverpod providers
├── firebase_options.dart
└── main.dart
```

## Database Architecture

### Firebase Firestore (dokumen/PDF/video)
- `warta_jemaat` – Warta jemaat PDF
- `tata_ibadah` – Tata ibadah PDF
- `renungan` – Renungan harian PDF
- `siaran` – Video ibadah (YouTube ID)
- `users` – User profile

### Supabase PostgreSQL (objek/relasional)
- `galeri` – Foto galeri
- `agenda` – Agenda kegiatan
- `kependetaan` – Profil gembala
- `kemajelisan` – Profil majelis
- `bpm` – Badan Pembantu Majelis
- `perwilayahan` – Data wilayah
- `profil_ruangan` – Profil ruangan
- `eperpus` – E-perpustakaan
- `inspirasi` – Konten spin wheel
- `informasi_gereja` – Profil gereja
- `notifikasi` – Pengumuman
- `faq` – FAQ
- `hubungi_kami` – Kontak sosial
- `tentang_aplikasi` – Tentang app

## Admin Login

Buat akun admin di Firebase Console:
1. Buka Firebase Console → gkjw-karangpilang-app
2. Authentication → Add User
3. Masukkan email & password admin
