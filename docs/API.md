# API v1

Base URL: `https://{DOMAIN}/api/v1`. Semua respons memakai format:

```json
{ "success": true, "data": ..., "error": null, "meta": { "total": 12, "limit": 50, "offset": 0 } }
```

Jika gagal: `"success": false` dan `"error": { "code": "validation_error", "message": "...", "fields": { "judul": "wajib diisi" } }`.

## Publik (tanpa login)

| Endpoint | Keterangan |
|---|---|
| `GET /{konten}` | Daftar. Query: `limit` (1–200, default 50), `offset`, dan filter (lihat tabel konten) |
| `GET /{konten}/{id}` | Satu item |
| `GET /galeri/tahun` | Daftar tahun yang punya foto |
| `GET /informasi-gereja`, `/tentang-aplikasi`, `/sapaan-config` | Konfigurasi satu baris (`data` bisa `null`) |
| `GET /files/{bucket}/{nama}` | File hasil upload (di luar `/api/v1`) |
| `GET /healthz` | Status server & database (di luar `/api/v1`) |

`banners` dan `notifikasi` di endpoint publik hanya menampilkan data `is_active = true`.

## Auth

| Endpoint | Body / Header |
|---|---|
| `POST /auth/login` | `{"email","password"}` → `{token, expires_at, email}`. Dibatasi 10×/menit per IP |
| `GET /auth/me` | `Authorization: Bearer <token>` |

## Admin (`Authorization: Bearer <token>`)

| Endpoint | Keterangan |
|---|---|
| `GET /admin/{konten}` | Seperti publik, tapi termasuk data nonaktif |
| `POST /admin/{konten}` | Tambah (field wajib harus ada) |
| `PUT /admin/{konten}/{id}` | Ubah. **Hanya field yang dikirim yang diubah** |
| `DELETE /admin/{konten}/{id}` | Hapus |
| `PUT /admin/informasi-gereja` (dan singleton lain) | Buat/ubah konfigurasi |
| `POST /admin/uploads?bucket=X` | `multipart/form-data` field `file` → `{url, bucket, name}` |
| `DELETE /admin/uploads/{bucket}/{nama}` | Hapus file |

Bucket: `banners`, `gereja-covers`, `galeri`, `profil`, `eperpus-cover` (JPG/PNG/WebP, maks. 5 MB), `dokumen`, `eperpus` (PDF, maks. 30 MB). Jenis file diperiksa dari isinya, bukan dari nama file.

## Daftar konten

| `{konten}` | Filter | Catatan |
|---|---|---|
| `dokumen` | `kategori` = `warta` / `tata_ibadah` / `renungan` | Terbaru dulu |
| `siaran` | `kategori` = `umum` / `anak` / `remaja` / `sekolah_minggu` | |
| `agenda` | | Urut tanggal |
| `galeri` | `tahun` | |
| `banners` | | `is_active` |
| `notifikasi` | | `is_active` |
| `inspirasi` | `kategori` | |
| `kependetaan`, `kemajelisan`, `bpm`, `perwilayahan`, `profil-ruangan`, `faq`, `hubungi-kami`, `eperpus` | | Urut `urutan` |
| `gereja-covers` | | `POST` dengan `key` yang sama akan mengganti cover lama |

Definisi field lengkap (tipe, wajib/tidak, panjang maksimal) ada di [backend/internal/resource/registry.go](../backend/internal/resource/registry.go).
