# Deploy ke VPS IDCloudHost

Target: satu VPS Ubuntu 24.04. **Spesifikasi minimal 2 vCPU dan RAM 2 GB** sudah cukup untuk 1000–2000 pengguna bersamaan, karena file dan respons publik di-cache oleh Cloudflare.

## 1. Siapkan VPS

```bash
# Login sebagai root, buat user deploy
adduser deploy && usermod -aG sudo deploy

# Firewall: hanya SSH, HTTP, HTTPS
ufw allow OpenSSH && ufw allow 80,443/tcp && ufw allow 443/udp && ufw enable

# Docker
curl -fsSL https://get.docker.com | sh
usermod -aG docker deploy
```

Nonaktifkan login SSH dengan password (pakai SSH key): set `PasswordAuthentication no` di `/etc/ssh/sshd_config`.

## 2. Domain & Cloudflare

1. Tambahkan domain ke Cloudflare (paket Free cukup).
2. Buat DNS record `A`: `api` → IP VPS, dengan **Proxy aktif (awan oranye)**.
3. SSL/TLS → mode **Full (strict)**.
4. Caching → Cache Rules → buat aturan untuk `api.domain-anda/files/*` dengan status *Eligible for cache*. PDF & gambar lalu disajikan dari server Cloudflare di Indonesia, sehingga bandwidth VPS nyaris tidak terpakai saat Minggu pagi.

## 3. Jalankan stack

```bash
git clone https://github.com/AbimanyuDA/gkjw-karangpilang-app.git
cd gkjw-karangpilang-app/deploy
cp .env.example .env
nano .env        # isi DOMAIN, POSTGRES_PASSWORD, JWT_SECRET (lihat petunjuk di file)

docker compose up -d --build
docker compose ps                 # semua harus "healthy"/"running"
curl https://api.domain-anda/healthz
```

## 4. Buat akun admin

```bash
docker compose exec api /app/api create-admin -email admin@gkjwkarangpilang.org
```

Perintah yang sama juga dipakai untuk mengganti password admin.

## 5. Pindahkan data lama

Ikuti [MIGRASI-DATA.md](MIGRASI-DATA.md).

## 6. Build aplikasi

Isi `frontend/config/prod.json` dengan domain API, lalu dari root repo jalankan:

```bash
make app-build-apk
```

## Operasional

| Kebutuhan | Perintah (dari folder `deploy/`) |
|---|---|
| Lihat log | `docker compose logs -f api` |
| Update ke versi terbaru | `git pull && docker compose up -d --build` |
| Restart | `docker compose restart api` |
| Backup manual sekarang | `docker compose restart backup` (backup langsung jalan saat start) |

### Backup

Service `backup` membuat `backups/db-*.sql.gz` dan `backups/uploads-*.tar.gz` setiap hari dan menyimpannya 14 hari.
**Salin ke luar VPS**, misalnya dengan `rclone` ke Google Drive gereja lewat cron harian:

```bash
rclone copy /home/deploy/gkjw-karangpilang-app/deploy/backups gdrive:backup-gkjw
```

### Restore

```bash
# Database
gunzip -c backups/db-YYYYMMDD-HHMMSS.sql.gz | docker compose exec -T db psql -U gkjw -d gkjw
# File upload
docker run --rm -v gkjw_uploads:/data/uploads -v "$PWD/backups:/b" alpine \
  tar -xzf /b/uploads-YYYYMMDD-HHMMSS.tar.gz -C /data/uploads
```

Uji restore setidaknya sekali. Backup yang belum pernah dicoba restore belum bisa dianggap aman.
