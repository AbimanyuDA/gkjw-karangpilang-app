// E2E: menjalankan aplikasi sungguhan terhadap backend lokal.
//
//   make dev && make dev-admin EMAIL=admin@gkjw.local   (password: E2E_ADMIN_PASSWORD)
//   flutter test integration_test -d <device> \
//     --dart-define-from-file=config/dev-ios.json \      (Android: config/dev.json)
//     --dart-define=E2E_ADMIN_EMAIL=admin@gkjw.local --dart-define=E2E_ADMIN_PASSWORD=...
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gkjw_karangpilang/main.dart' as app;

const _adminEmail = String.fromEnvironment('E2E_ADMIN_EMAIL');
const _adminPassword = String.fromEnvironment('E2E_ADMIN_PASSWORD');

/// pumpAndSettle tidak bisa dipakai: beranda punya animasi/timer yang terus berjalan.
Future<void> pumpUntil(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 20)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Tidak muncul dalam ${timeout.inSeconds} detik: $finder');
}

Future<void> pumpUntilAny(WidgetTester tester, List<Finder> finders) async {
  final end = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finders.any((f) => f.evaluate().isNotEmpty)) return;
  }
  throw TestFailure('Tidak ada yang muncul: $finders');
}

Future<void> settle(WidgetTester tester, [int ms = 1500]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('jemaat membuka konten, admin login & logout', (tester) async {
    app.main();
    await pumpUntil(tester, find.text('Menu Utama'));
    await settle(tester); // transisi dari animasi pembuka

    // Sesi admin dari run sebelumnya → logout dulu agar test mulai dari mode jemaat.
    if (find.byIcon(Icons.admin_panel_settings).evaluate().isNotEmpty) {
      await tester.tap(find.byIcon(Icons.admin_panel_settings));
      await pumpUntil(tester, find.byIcon(Icons.logout));
      await settle(tester);
      await tester.tap(find.byIcon(Icons.logout));
      await pumpUntil(tester, find.text('Logout'));
      await tester.tap(find.text('Logout'));
      await pumpUntil(tester, find.byIcon(Icons.lock_outline));
    }

    // ── Jemaat: Warta Jemaat dimuat dari API ──
    await tester.tap(find.textContaining('Warta').first);
    await pumpUntilAny(tester, [
      find.byIcon(Icons.picture_as_pdf),
      find.text('Belum ada konten'),
      find.text('Gagal memuat data'),
    ]);
    expect(find.text('Gagal memuat data'), findsNothing);
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    // ── Jemaat: tab Siaran ──
    await tester.tap(find.text('Siaran').last);
    await settle(tester, 3000);
    expect(find.textContaining('Gagal'), findsNothing);
    await tester.tap(find.text('Beranda').last);
    await pumpUntil(tester, find.byIcon(Icons.lock_outline));

    // ── Admin: password salah ditolak ──
    await tester.tap(find.byIcon(Icons.lock_outline));
    await pumpUntil(tester, find.text('Masuk sebagai Admin'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Email Admin'), _adminEmail);
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password-salah-123');
    await tester.tap(find.text('Masuk sebagai Admin'));
    await pumpUntil(tester, find.text('Email atau password salah.'));

    // ── Admin: login benar → dashboard ──
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), _adminPassword);
    await tester.tap(find.text('Masuk sebagai Admin'));
    await pumpUntil(tester, find.text(_adminEmail));
    expect(find.text('Admin Panel'), findsWidgets);

    // ── Admin: logout → kembali ke mode jemaat ──
    await settle(tester); // tunggu animasi transisi halaman selesai
    await tester.tap(find.byIcon(Icons.logout));
    await pumpUntil(tester, find.text('Logout'));
    await tester.tap(find.text('Logout'));
    await pumpUntil(tester, find.byIcon(Icons.lock_outline));
  }, skip: _adminEmail.isEmpty || _adminPassword.isEmpty);
}
