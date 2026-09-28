# Migrasi data lama (Firestore)

Aplikasi versi lama menyimpan data di **Firestore** dan **Supabase**. Project Supabase sudah dihapus
(per 27 September 2026), jadi datanya — agenda, galeri, banner, profil, FAQ, dll. — tidak bisa
diambil lagi dan perlu diisi ulang lewat website admin.

Perintah `api migrate-legacy` menyalin yang masih ada di Firestore:

- `warta_jemaat`, `tata_ibadah`, `renungan` → tabel `dokumen`
- `siaran` → video siaran
- `gereja_covers` → cover menu Gereja

Link luar (Google Drive, YouTube) dibiarkan apa adanya. Data yang file-nya dulu disimpan di
Supabase Storage **dilewati** dengan keterangan "unggah ulang lewat website admin".
Perintah ini **aman dijalankan ulang**: data yang sudah ada tidak digandakan.

Hasil uji terhadap Firestore asli: 1 warta + 4 video siaran bisa dipindahkan; 2 warta,
1 tata ibadah, dan 5 cover perlu diunggah ulang.

## Nilai yang dibutuhkan

Ambil dari commit lama (branch `main`, sebelum refactor):

```bash
git show main:lib/firebase_options.dart   # projectId & apiKey (Android)
```

| Env | Sumber |
|---|---|
| `LEGACY_FIREBASE_PROJECT_ID` | `projectId` |
| `LEGACY_FIREBASE_API_KEY` | `apiKey` |

## Langkah

Jalankan di VPS dari folder `deploy/`, setelah stack berjalan:

```bash
# 1. Uji dulu tanpa menulis apa pun
docker compose exec \
  -e LEGACY_FIREBASE_PROJECT_ID=gkjw-karangpilang-app \
  -e LEGACY_FIREBASE_API_KEY=AIza... \
  api /app/api migrate-legacy -dry-run

# 2. Jika laporannya sudah benar, jalankan tanpa -dry-run
```

Contoh laporan:

```
dokumen   firestore:warta_jemaat  dibaca=3 diimpor=1 dilewati=2
    - baris 2: file url ada di penyimpanan lama yang sudah dihapus — unggah ulang lewat website admin
siaran    firestore:siaran        dibaca=4 diimpor=4 dilewati=0
```

## Setelah migrasi

1. Isi ulang konten yang hilang lewat website admin (`https://{DOMAIN}/admin/`).
2. Setelah semua jemaat memakai aplikasi versi baru, hapus project Firebase lama dan
   **rotasi/hapus** API key-nya (key itu tertanam di APK lama dan ada di riwayat git).
