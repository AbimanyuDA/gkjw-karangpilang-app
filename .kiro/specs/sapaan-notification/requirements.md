# Requirements Document

## Introduction

Fitur **Sapaan Notifikasi** adalah sistem notifikasi lokal terjadwal untuk aplikasi Flutter GKJW Karangpilang. Fitur ini memungkinkan jemaat menerima notifikasi berisi ayat Alkitab setiap pagi (jam 07.00) dan/atau setiap malam (jam 19.00) sesuai preferensi masing-masing. Admin gereja dapat mengatur jadwal, menginput ayat secara manual, atau men-generate ayat otomatis menggunakan AI (Groq API). Konten dan jadwal sapaan disimpan di Supabase, sedangkan preferensi toggle jemaat disimpan secara lokal menggunakan `shared_preferences`.

---

## Glossary

- **Sapaan_Pagi**: Notifikasi lokal terjadwal yang dikirim setiap hari pada jam yang dikonfigurasi admin (default 07.00) berisi ayat Alkitab bertema pagi hari.
- **Sapaan_Malam**: Notifikasi lokal terjadwal yang dikirim setiap hari pada jam yang dikonfigurasi admin (default 19.00) berisi ayat Alkitab bertema malam hari.
- **Notification_Scheduler**: Komponen Flutter yang bertanggung jawab menjadwalkan dan membatalkan notifikasi lokal menggunakan `flutter_local_notifications`.
- **Preference_Store**: Penyimpanan lokal berbasis `shared_preferences` yang menyimpan status toggle Sapaan_Pagi dan Sapaan_Malam milik jemaat.
- **Sapaan_Config**: Record di tabel Supabase `sapaan_config` yang menyimpan jadwal (jam dan menit) serta konten ayat Alkitab untuk Sapaan_Pagi dan Sapaan_Malam.
- **Groq_API**: Layanan AI eksternal di `https://api.groq.com/openai/v1/chat/completions` yang digunakan admin untuk men-generate ayat Alkitab secara otomatis berdasarkan tema/deskripsi.
- **Admin_Panel**: Layar admin di `admin_notifikasi_screen.dart` yang diperluas untuk mengelola Sapaan_Config.
- **Informasi_Screen**: Layar pengaturan jemaat di `informasi_screen.dart` yang menampilkan toggle Sapaan_Pagi dan Sapaan_Malam.
- **Jemaat**: Pengguna akhir aplikasi GKJW Karangpilang.
- **Admin**: Pengelola gereja yang memiliki akses ke Admin_Panel.

---

## Requirements

### Requirement 1: Penyimpanan Preferensi Toggle Jemaat

**User Story:** Sebagai Jemaat, saya ingin preferensi Sapaan_Pagi dan Sapaan_Malam saya tersimpan secara persisten, sehingga pengaturan tidak hilang ketika aplikasi ditutup dan dibuka kembali.

#### Acceptance Criteria

1. WHEN Jemaat mengaktifkan toggle Sapaan_Pagi, THE Preference_Store SHALL menyimpan nilai `true` untuk kunci `sapaan_pagi_enabled` menggunakan `shared_preferences`.
2. WHEN Jemaat menonaktifkan toggle Sapaan_Pagi, THE Preference_Store SHALL menyimpan nilai `false` untuk kunci `sapaan_pagi_enabled`.
3. WHEN Jemaat mengaktifkan toggle Sapaan_Malam, THE Preference_Store SHALL menyimpan nilai `true` untuk kunci `sapaan_malam_enabled`.
4. WHEN Jemaat menonaktifkan toggle Sapaan_Malam, THE Preference_Store SHALL menyimpan nilai `false` untuk kunci `sapaan_malam_enabled`.
5. WHEN Informasi_Screen dibuka, THE Preference_Store SHALL memuat nilai tersimpan untuk `sapaan_pagi_enabled` dan `sapaan_malam_enabled` dan menampilkannya pada toggle yang sesuai.
6. IF nilai tersimpan tidak ditemukan di Preference_Store, THEN THE Informasi_Screen SHALL menampilkan toggle dalam kondisi nonaktif (nilai default `false`).

---

### Requirement 2: Penjadwalan Notifikasi Lokal Sapaan Pagi

**User Story:** Sebagai Jemaat, saya ingin menerima notifikasi berisi ayat Alkitab setiap pagi pada jam yang ditentukan admin, sehingga saya mendapat sapaan rohani di awal hari.

#### Acceptance Criteria

1. WHEN Jemaat mengaktifkan toggle Sapaan_Pagi, THE Notification_Scheduler SHALL menjadwalkan notifikasi lokal harian berulang pada jam dan menit yang tersimpan di Sapaan_Config (default 07:00).
2. WHEN Notification_Scheduler menjadwalkan Sapaan_Pagi, THE Notification_Scheduler SHALL menggunakan judul "Sapaan Pagi 🌅" dan isi pesan berupa ayat Alkitab dari field `ayat_pagi` di Sapaan_Config.
3. WHEN Jemaat menonaktifkan toggle Sapaan_Pagi, THE Notification_Scheduler SHALL membatalkan jadwal notifikasi Sapaan_Pagi yang aktif.
4. WHILE Sapaan_Pagi aktif dan Sapaan_Config diperbarui oleh Admin, THE Notification_Scheduler SHALL menjadwalkan ulang notifikasi Sapaan_Pagi dengan jadwal dan konten terbaru pada saat aplikasi dibuka berikutnya.
5. IF izin notifikasi belum diberikan oleh Jemaat, THEN THE Notification_Scheduler SHALL meminta izin notifikasi kepada sistem operasi sebelum menjadwalkan notifikasi.
6. IF izin notifikasi ditolak oleh Jemaat, THEN THE Informasi_Screen SHALL menampilkan pesan informasi bahwa notifikasi tidak dapat dijadwalkan tanpa izin.

---

### Requirement 3: Penjadwalan Notifikasi Lokal Sapaan Malam

**User Story:** Sebagai Jemaat, saya ingin menerima notifikasi berisi ayat Alkitab setiap malam pada jam yang ditentukan admin, sehingga saya mendapat sapaan rohani di penghujung hari.

#### Acceptance Criteria

1. WHEN Jemaat mengaktifkan toggle Sapaan_Malam, THE Notification_Scheduler SHALL menjadwalkan notifikasi lokal harian berulang pada jam dan menit yang tersimpan di Sapaan_Config (default 19:00).
2. WHEN Notification_Scheduler menjadwalkan Sapaan_Malam, THE Notification_Scheduler SHALL menggunakan judul "Sapaan Malam 🌙" dan isi pesan berupa ayat Alkitab dari field `ayat_malam` di Sapaan_Config.
3. WHEN Jemaat menonaktifkan toggle Sapaan_Malam, THE Notification_Scheduler SHALL membatalkan jadwal notifikasi Sapaan_Malam yang aktif.
4. WHILE Sapaan_Malam aktif dan Sapaan_Config diperbarui oleh Admin, THE Notification_Scheduler SHALL menjadwalkan ulang notifikasi Sapaan_Malam dengan jadwal dan konten terbaru pada saat aplikasi dibuka berikutnya.
5. IF izin notifikasi belum diberikan oleh Jemaat, THEN THE Notification_Scheduler SHALL meminta izin notifikasi kepada sistem operasi sebelum menjadwalkan notifikasi.

---

### Requirement 4: Pengambilan Konfigurasi Sapaan dari Supabase

**User Story:** Sebagai Jemaat, saya ingin notifikasi yang saya terima selalu berisi konten terbaru yang ditetapkan admin, sehingga ayat Alkitab yang saya terima relevan dan terkini.

#### Acceptance Criteria

1. WHEN aplikasi dibuka, THE Notification_Scheduler SHALL mengambil data Sapaan_Config terbaru dari tabel `sapaan_config` di Supabase.
2. WHEN data Sapaan_Config berhasil diambil dan toggle Sapaan_Pagi aktif, THE Notification_Scheduler SHALL menjadwalkan ulang notifikasi Sapaan_Pagi dengan data terbaru.
3. WHEN data Sapaan_Config berhasil diambil dan toggle Sapaan_Malam aktif, THE Notification_Scheduler SHALL menjadwalkan ulang notifikasi Sapaan_Malam dengan data terbaru.
4. IF pengambilan data Sapaan_Config dari Supabase gagal, THEN THE Notification_Scheduler SHALL mempertahankan jadwal notifikasi yang sudah ada tanpa perubahan.
5. THE Sapaan_Config SHALL menyimpan field: `id`, `jam_pagi` (integer, 0–23), `menit_pagi` (integer, 0–59), `jam_malam` (integer, 0–23), `menit_malam` (integer, 0–59), `ayat_pagi` (text), `ayat_malam` (text), `updated_at` (timestamp).

---

### Requirement 5: Manajemen Jadwal Sapaan oleh Admin

**User Story:** Sebagai Admin, saya ingin mengatur jam pengiriman Sapaan_Pagi dan Sapaan_Malam, sehingga notifikasi dikirim pada waktu yang paling tepat bagi jemaat.

#### Acceptance Criteria

1. THE Admin_Panel SHALL menampilkan form pengaturan jadwal Sapaan_Pagi dengan input jam (0–23) dan menit (0–59), dengan nilai default 07:00.
2. THE Admin_Panel SHALL menampilkan form pengaturan jadwal Sapaan_Malam dengan input jam (0–23) dan menit (0–59), dengan nilai default 19:00.
3. WHEN Admin menyimpan jadwal baru, THE Admin_Panel SHALL memperbarui field `jam_pagi`, `menit_pagi`, `jam_malam`, dan `menit_malam` di record Sapaan_Config di Supabase.
4. WHEN Admin menyimpan jadwal baru, THE Admin_Panel SHALL menampilkan konfirmasi bahwa perubahan berhasil disimpan.
5. IF input jam berada di luar rentang 0–23 atau input menit berada di luar rentang 0–59, THEN THE Admin_Panel SHALL menampilkan pesan validasi dan tidak menyimpan data.

---

### Requirement 6: Input Manual Ayat Alkitab oleh Admin

**User Story:** Sebagai Admin, saya ingin menginput ayat Alkitab secara manual untuk Sapaan_Pagi dan Sapaan_Malam, sehingga saya dapat memilih ayat yang sesuai dengan tema ibadah atau momen tertentu.

#### Acceptance Criteria

1. THE Admin_Panel SHALL menampilkan text field untuk input ayat Alkitab Sapaan_Pagi dengan label "Ayat Sapaan Pagi".
2. THE Admin_Panel SHALL menampilkan text field untuk input ayat Alkitab Sapaan_Malam dengan label "Ayat Sapaan Malam".
3. WHEN Admin menyimpan ayat manual, THE Admin_Panel SHALL memperbarui field `ayat_pagi` atau `ayat_malam` di record Sapaan_Config di Supabase.
4. WHEN Admin menyimpan ayat manual, THE Admin_Panel SHALL menampilkan konfirmasi bahwa ayat berhasil disimpan.
5. IF field ayat dikosongkan saat menyimpan, THEN THE Admin_Panel SHALL menampilkan pesan validasi dan tidak menyimpan data kosong.

---

### Requirement 7: Generate Ayat Alkitab Otomatis via AI (Groq)

**User Story:** Sebagai Admin, saya ingin men-generate ayat Alkitab secara otomatis berdasarkan tema yang saya tentukan, sehingga saya tidak perlu mencari ayat secara manual setiap hari.

#### Acceptance Criteria

1. THE Admin_Panel SHALL menampilkan text field untuk input tema/deskripsi ayat yang diinginkan, dengan label "Tema Ayat (untuk AI)".
2. THE Admin_Panel SHALL menampilkan tombol "Generate Pagi" dan "Generate Malam" untuk memicu pembuatan ayat via Groq_API.
3. WHEN Admin menekan tombol "Generate Pagi" atau "Generate Malam", THE Admin_Panel SHALL menampilkan indikator loading selama proses berlangsung.
4. WHEN Admin menekan tombol "Generate Pagi" atau "Generate Malam", THE Admin_Panel SHALL mengirim HTTP POST request ke `https://api.groq.com/openai/v1/chat/completions` dengan model `llama3-8b-8192`, menggunakan tema yang diinput Admin sebagai konteks prompt, dan meminta satu ayat Alkitab yang relevan beserta referensinya.
5. WHEN Groq_API mengembalikan respons berhasil, THE Admin_Panel SHALL mengisi text field ayat yang sesuai (pagi atau malam) dengan teks ayat yang di-generate.
6. IF Groq_API mengembalikan error atau koneksi gagal, THEN THE Admin_Panel SHALL menampilkan pesan error "Gagal generate ayat. Silakan coba lagi." dan mempertahankan isi text field sebelumnya.
7. WHEN ayat berhasil di-generate, THE Admin_Panel SHALL memungkinkan Admin mengedit teks hasil generate sebelum menyimpan ke Supabase.

---

### Requirement 8: Inisialisasi Notifikasi saat Aplikasi Dimulai

**User Story:** Sebagai Jemaat, saya ingin notifikasi terjadwal tetap aktif setelah aplikasi di-restart, sehingga saya tidak perlu mengatur ulang preferensi setiap kali membuka aplikasi.

#### Acceptance Criteria

1. WHEN aplikasi dimulai, THE Notification_Scheduler SHALL menginisialisasi plugin `flutter_local_notifications` dengan channel ID `sapaan_channel` dan nama channel "Sapaan Harian".
2. WHEN aplikasi dimulai dan `sapaan_pagi_enabled` bernilai `true` di Preference_Store, THE Notification_Scheduler SHALL menjadwalkan ulang notifikasi Sapaan_Pagi menggunakan data Sapaan_Config terbaru dari Supabase.
3. WHEN aplikasi dimulai dan `sapaan_malam_enabled` bernilai `true` di Preference_Store, THE Notification_Scheduler SHALL menjadwalkan ulang notifikasi Sapaan_Malam menggunakan data Sapaan_Config terbaru dari Supabase.
4. THE Notification_Scheduler SHALL menggunakan notification ID `1` untuk Sapaan_Pagi dan notification ID `2` untuk Sapaan_Malam agar jadwal lama dapat dibatalkan dan diganti dengan benar.
5. WHERE platform Android, THE Notification_Scheduler SHALL membuat notification channel dengan importance `high` dan mengaktifkan `SCHEDULE_EXACT_ALARM` permission.
6. WHERE platform iOS, THE Notification_Scheduler SHALL meminta izin `alert`, `badge`, dan `sound` saat inisialisasi pertama kali.
