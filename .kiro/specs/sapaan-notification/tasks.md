# Implementation Tasks

## Task Overview

Implementasi fitur **Sapaan Notifikasi** — notifikasi lokal terjadwal harian berisi ayat Alkitab untuk jemaat GKJW Karangpilang, lengkap dengan panel admin untuk mengatur jadwal dan konten ayat (manual atau via AI Groq).

---

## Task 1: Setup Dependencies & Platform Configuration

**Requirements:** Req 8 (inisialisasi), Req 1 (shared_preferences)

- [x] 1.1 Tambahkan `shared_preferences: ^2.3.3` ke `pubspec.yaml` di bagian `dependencies`
- [x] 1.2 Tambahkan `timezone: ^0.9.4` ke `pubspec.yaml` (diperlukan `flutter_local_notifications` untuk scheduled notifications)
- [x] 1.3 Konfigurasi Android: tambahkan permission `SCHEDULE_EXACT_ALARM` dan `RECEIVE_BOOT_COMPLETED` di `android/app/src/main/AndroidManifest.xml`
- [x] 1.4 Konfigurasi Android: tambahkan `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` di `AndroidManifest.xml`
- [x] 1.5 Konfigurasi iOS: tambahkan key `NSUserNotificationUsageDescription` di `ios/Runner/Info.plist`
- [x] 1.6 Jalankan `flutter pub get` untuk mengunduh dependencies baru

---

## Task 2: Buat Tabel `sapaan_config` di Supabase

**Requirements:** Req 4 (skema data), Req 5 (jadwal), Req 6 (ayat manual)

- [ ] 2.1 Buat tabel `sapaan_config` di Supabase dengan kolom:
  - `id` (uuid, primary key, default `gen_random_uuid()`)
  - `jam_pagi` (integer, not null, default `7`)
  - `menit_pagi` (integer, not null, default `0`)
  - `jam_malam` (integer, not null, default `19`)
  - `menit_malam` (integer, not null, default `0`)
  - `ayat_pagi` (text, not null, default `'Kasih karunia dan damai sejahtera dari Allah, Bapa kita, dan dari Tuhan Yesus Kristus menyertai kamu. (Roma 1:7)'`)
  - `ayat_malam` (text, not null, default `'Aku mau tidur dan langsung tertidur; sebab hanya Engkaulah, ya TUHAN, yang membiarkan aku diam dengan aman. (Mazmur 4:9)'`)
  - `updated_at` (timestamptz, default `now()`)
- [x] 2.2 Insert satu baris data default ke tabel `sapaan_config`
- [x] 2.3 Set Row Level Security (RLS): enable RLS, buat policy `SELECT` untuk semua user (anon + authenticated), buat policy `UPDATE` hanya untuk authenticated user

---

## Task 3: Buat Model & Service untuk `sapaan_config`

**Requirements:** Req 4, Req 5, Req 6

- [ ] 3.1 Tambahkan class `SapaanConfigModel` di `lib/data/models/supabase_models.dart`:
  ```dart
  class SapaanConfigModel {
    final String id;
    final int jamPagi;
    final int menitPagi;
    final int jamMalam;
    final int menitMalam;
    final String ayatPagi;
    final String ayatMalam;
    final DateTime updatedAt;
    // fromJson, toJson, copyWith
  }
  ```
- [x] 3.2 Tambahkan method `getSapaanConfig()` di `lib/data/services/supabase_service.dart` — fetch single record dari tabel `sapaan_config`
- [x] 3.3 Tambahkan method `updateSapaanConfig(SapaanConfigModel item)` di `supabase_service.dart` — update record berdasarkan `id`
- [x] 3.4 Tambahkan `sapaanConfigProvider` di `lib/providers/providers.dart` sebagai `FutureProvider<SapaanConfigModel?>`

---

## Task 4: Buat `NotificationService`

**Requirements:** Req 2, Req 3, Req 8

- [x] 4.1 Buat file `lib/data/services/notification_service.dart`
- [ ] 4.2 Implementasikan method `initialize()`:
  - Inisialisasi `FlutterLocalNotificationsPlugin`
  - Setup `AndroidInitializationSettings` dengan icon `@mipmap/ic_launcher`
  - Setup `DarwinInitializationSettings` dengan request permission `alert`, `badge`, `sound`
  - Buat Android notification channel `sapaan_channel` dengan importance `high` dan nama "Sapaan Harian"
  - Inisialisasi timezone dengan `tz.initializeTimeZones()` dan set local timezone ke `Asia/Jakarta`
- [x] 4.3 Implementasikan method `requestPermission()` — minta izin notifikasi di Android 13+ dan iOS, return `bool` apakah izin diberikan
- [ ] 4.4 Implementasikan method `scheduleSapaanPagi(SapaanConfigModel config)`:
  - Cancel notifikasi ID `1` yang ada
  - Jadwalkan notifikasi harian berulang menggunakan `zonedSchedule` dengan `DateTimeComponents.time`
  - Judul: `"Sapaan Pagi 🌅"`, body: `config.ayatPagi`
  - Waktu: `config.jamPagi:config.menitPagi` di timezone `Asia/Jakarta`
  - Notification ID: `1`
- [ ] 4.5 Implementasikan method `scheduleSapaanMalam(SapaanConfigModel config)`:
  - Cancel notifikasi ID `2` yang ada
  - Jadwalkan notifikasi harian berulang
  - Judul: `"Sapaan Malam 🌙"`, body: `config.ayatMalam`
  - Waktu: `config.jamMalam:config.menitMalam` di timezone `Asia/Jakarta`
  - Notification ID: `2`
- [x] 4.6 Implementasikan method `cancelSapaanPagi()` — cancel notifikasi ID `1`
- [x] 4.7 Implementasikan method `cancelSapaanMalam()` — cancel notifikasi ID `2`

---

## Task 5: Buat `SapaanPreferenceService`

**Requirements:** Req 1

- [x] 5.1 Buat file `lib/data/services/sapaan_preference_service.dart`
- [x] 5.2 Implementasikan method `getSapaanPagiEnabled()` — baca `sapaan_pagi_enabled` dari `SharedPreferences`, default `false`
- [x] 5.3 Implementasikan method `getSapaanMalamEnabled()` — baca `sapaan_malam_enabled`, default `false`
- [x] 5.4 Implementasikan method `setSapaanPagiEnabled(bool value)` — simpan ke `SharedPreferences`
- [x] 5.5 Implementasikan method `setSapaanMalamEnabled(bool value)` — simpan ke `SharedPreferences`

---

## Task 6: Inisialisasi Notifikasi di `main.dart`

**Requirements:** Req 8

- [x] 6.1 Di `main()` dalam `lib/main.dart`, setelah inisialisasi Supabase, panggil `NotificationService().initialize()`
- [x] 6.2 Setelah inisialisasi, baca preferensi dari `SapaanPreferenceService`
- [x] 6.3 Jika `sapaan_pagi_enabled == true`, fetch `SapaanConfigModel` dari Supabase lalu panggil `NotificationService().scheduleSapaanPagi(config)`
- [x] 6.4 Jika `sapaan_malam_enabled == true`, fetch `SapaanConfigModel` dari Supabase lalu panggil `NotificationService().scheduleSapaanMalam(config)`
- [x] 6.5 Wrap logika fetch di try-catch — jika gagal, lanjutkan tanpa crash (jadwal lama tetap aktif)

---

## Task 7: Update `InformasiScreen` — Toggle Fungsional

**Requirements:** Req 1, Req 2, Req 3

- [x] 7.1 Ubah `_InformasiScreenState` menjadi `ConsumerStatefulWidget` (Riverpod) di `lib/features/informasi/screens/informasi_screen.dart`
- [x] 7.2 Di `initState`, muat nilai toggle dari `SapaanPreferenceService` dan set ke state
- [ ] 7.3 Pada `onChanged` toggle Sapaan Pagi:
  - Simpan nilai baru ke `SapaanPreferenceService`
  - Jika `true`: request permission → jika granted, fetch config → schedule pagi; jika denied, tampilkan `SnackBar` "Izin notifikasi diperlukan"
  - Jika `false`: panggil `NotificationService().cancelSapaanPagi()`
- [ ] 7.4 Pada `onChanged` toggle Sapaan Malam:
  - Simpan nilai baru ke `SapaanPreferenceService`
  - Jika `true`: request permission → jika granted, fetch config → schedule malam; jika denied, tampilkan `SnackBar`
  - Jika `false`: panggil `NotificationService().cancelSapaanMalam()`
- [x] 7.5 Tambahkan provider `notificationServiceProvider` dan `sapaanPreferenceServiceProvider` di `lib/providers/providers.dart`

---

## Task 8: Buat `GroqService` untuk Generate Ayat via AI

**Requirements:** Req 7

- [x] 8.1 Buat file `lib/data/services/groq_service.dart`
- [ ] 8.2 Implementasikan method `generateAyatAlkitab(String tema, String sesi)`:
  - `sesi` berisi `"pagi"` atau `"malam"` untuk konteks prompt
  - Kirim HTTP POST ke `https://api.groq.com/openai/v1/chat/completions`
  - Header: `Authorization: Bearer YOUR_GROQ_API_KEY`, `Content-Type: application/json`
  - Body: model `llama3-8b-8192`, system prompt meminta satu ayat Alkitab relevan beserta referensinya dalam Bahasa Indonesia, user message berisi tema dari admin
  - Return `String` berisi teks ayat hasil generate
- [x] 8.3 Tangani error HTTP (non-200) dan network error — throw `Exception` dengan pesan yang jelas
- [x] 8.4 Simpan API key di `lib/env.dart` sebagai konstanta `groqApiKey` (sudah ada file ini di proyek)

---

## Task 9: Update `AdminNotifikasiScreen` — Panel Sapaan Config

**Requirements:** Req 5, Req 6, Req 7

- [x] 9.1 Tambahkan `TabBar` di `AdminNotifikasiScreen` dengan dua tab: "Riwayat Notifikasi" dan "Sapaan Harian"
- [x] 9.2 Tab "Riwayat Notifikasi": pindahkan konten existing (list notifikasi + FAB kirim notifikasi) ke tab ini
- [x] 9.3 Tab "Sapaan Harian": buat widget `_SapaanConfigTab` sebagai `ConsumerStatefulWidget`
- [x] 9.4 Di `_SapaanConfigTab`, load data `SapaanConfigModel` dari `sapaanConfigProvider` saat init
- [ ] 9.5 Tampilkan section **Jadwal Sapaan Pagi**:
  - `TextFormField` untuk jam pagi (keyboard number, validasi 0–23)
  - `TextFormField` untuk menit pagi (keyboard number, validasi 0–59)
  - Atau gunakan `TimePickerDialog` Flutter untuk UX yang lebih baik
- [ ] 9.6 Tampilkan section **Jadwal Sapaan Malam**:
  - `TextFormField` untuk jam malam (validasi 0–23)
  - `TextFormField` untuk menit malam (validasi 0–59)
- [ ] 9.7 Tampilkan section **Ayat Sapaan Pagi**:
  - `TextFormField` multiline dengan label "Ayat Sapaan Pagi"
  - Tombol "Generate Pagi" di samping/bawah field
- [ ] 9.8 Tampilkan section **Ayat Sapaan Malam**:
  - `TextFormField` multiline dengan label "Ayat Sapaan Malam"
  - Tombol "Generate Malam"
- [x] 9.9 Tampilkan `TextFormField` untuk input tema AI dengan label "Tema Ayat (untuk AI)" — digunakan bersama untuk generate pagi maupun malam
- [ ] 9.10 Implementasikan logika tombol "Generate Pagi":
  - Validasi tema tidak kosong
  - Tampilkan loading indicator di tombol
  - Panggil `GroqService().generateAyatAlkitab(tema, 'pagi')`
  - Isi controller ayat pagi dengan hasil
  - Jika error, tampilkan `SnackBar` "Gagal generate ayat. Silakan coba lagi."
- [x] 9.11 Implementasikan logika tombol "Generate Malam" (sama seperti 9.10 tapi untuk malam)
- [ ] 9.12 Tombol **"Simpan Semua"** di bagian bawah:
  - Validasi semua field (jam 0–23, menit 0–59, ayat tidak kosong)
  - Panggil `SupabaseService().updateSapaanConfig(...)` 
  - Tampilkan `SnackBar` sukses "Konfigurasi sapaan berhasil disimpan"
  - Invalidate `sapaanConfigProvider`

---

## Task 10: Verifikasi & Testing Manual

**Requirements:** Semua

- [x] 10.1 Jalankan `flutter analyze` dan pastikan tidak ada error
- [x] 10.2 Test toggle Sapaan Pagi di `InformasiScreen`: aktifkan → cek notifikasi terjadwal, nonaktifkan → cek notifikasi dibatalkan
- [x] 10.3 Test persistensi: aktifkan toggle → tutup app → buka lagi → pastikan toggle masih aktif dan notifikasi masih terjadwal
- [x] 10.4 Test admin panel: buka tab "Sapaan Harian" → ubah jam → simpan → pastikan tersimpan di Supabase
- [x] 10.5 Test generate AI: input tema → tekan "Generate Pagi" → pastikan ayat muncul di field
- [x] 10.6 Test error handling: matikan internet → tekan "Generate" → pastikan muncul pesan error yang sesuai
- [ ] 10.7 Jalankan `flutter build apk --debug` untuk memastikan build berhasil tanpa error
