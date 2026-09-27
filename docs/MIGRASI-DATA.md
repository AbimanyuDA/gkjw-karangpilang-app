# Migrasi data dari Supabase & Firestore

> **Status per 27 September 2026:** project Supabase lama (`roocpiqogsnqqnfdokiv`) **sudah tidak ada** (DNS NXDOMAIN).
> Data yang hanya tersimpan di Supabase (agenda, galeri, banner, profil, FAQ, dll.) serta file di Supabase Storage tidak bisa diambil lagi.
> Yang masih bisa dimigrasi hanya data **Firestore**. Hasil uji: 1 warta (link Google Drive) + 4 video siaran.
> 2 warta, 1 tata ibadah, dan 5 cover Gereja **dilewati** karena file PDF/gambarnya ada di Supabase Storage.
> Unggah ulang lewat menu Admin setelah server baru berjalan.

Perintah `api migrate-legacy` membaca data lama lewat API publik yang dulu dipakai aplikasi, lalu menyimpannya ke PostgreSQL baru.

- **Supabase**: semua tabel (agenda, galeri, banner, profil, FAQ, dll). File di Supabase Storage (banner, foto, PDF) **diunduh dan disimpan ulang** di server baru, dan URL-nya diganti otomatis.
- **Firestore**: `warta_jemaat`, `tata_ibadah`, `renungan` (digabung ke tabel `dokumen`), `siaran`, `gereja_covers`.
- Link luar (Google Drive, YouTube, CDN) dibiarkan apa adanya.
- **Aman dijalankan ulang**: tabel yang sudah berisi data dilewati, jadi tidak ada data ganda.

## Nilai yang dibutuhkan

Ambil dari commit lama (sebelum branch `refactor/go-backend`):

| Env | Sumber lama |
|---|---|
| `LEGACY_SUPABASE_URL` | `lib/core/constants/app_constants.dart` → `supabaseUrl` |
| `LEGACY_SUPABASE_ANON_KEY` | `lib/core/constants/app_constants.dart` → `supabaseAnonKey` |
| `LEGACY_FIREBASE_PROJECT_ID` | `lib/firebase_options.dart` → `projectId` |
| `LEGACY_FIREBASE_API_KEY` | `lib/firebase_options.dart` → `apiKey` (Android) |

```bash
git show main:lib/core/constants/app_constants.dart
```

## Langkah

Jalankan di VPS dari folder `deploy/`, setelah stack berjalan:

```bash
# 1. Uji dulu tanpa menulis apa pun
docker compose exec \
  -e LEGACY_SUPABASE_URL=https://xxxx.supabase.co \
  -e LEGACY_SUPABASE_ANON_KEY=eyJ... \
  -e LEGACY_FIREBASE_PROJECT_ID=gkjw-xxxx \
  -e LEGACY_FIREBASE_API_KEY=AIza... \
  api /app/api migrate-legacy -dry-run

# 2. Jika laporannya sudah benar, jalankan tanpa -dry-run
```

Contoh laporan:

```
banners   supabase:banner_slide   dibaca=3  diimpor=3  dilewati=0
agenda    supabase:agenda         dibaca=12 diimpor=11 dilewati=1
    - baris 7: judul tidak boleh kosong
dokumen   firestore:warta_jemaat  dibaca=40 diimpor=40 dilewati=0
```

Baris yang dilewati biasanya data lama yang tidak lengkap. Perbaiki lewat aplikasi admin setelah migrasi.

Jika kolom "Note" berisi `gagal membaca sumber`, tabel itu tidak ada di Supabase atau tidak bisa dibaca dengan anon key (RLS). Tabel lain tetap dimigrasi.

## Setelah migrasi

1. Buka aplikasi versi baru dan cek setiap menu.
2. Biarkan Supabase & Firebase tetap hidup ±1 bulan, sampai semua jemaat sudah update aplikasi.
3. Setelah itu matikan project Supabase & Firebase, lalu **rotasi/hapus** API key lama. Key itu tertanam di APK lama dan ada di riwayat git.
