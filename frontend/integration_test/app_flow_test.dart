// E2E: menjalankan aplikasi sungguhan terhadap backend lokal.
//
//   make dev
//   make app-e2e DEVICE=<id> [CONFIG=config/dev-ios.json]
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gkjw_karangpilang/main.dart' as app;

/// pumpAndSettle tidak bisa dipakai: beranda punya animasi/timer yang terus berjalan.
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
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

  testWidgets('jemaat membuka warta & siaran dari API', (tester) async {
    app.main();
    await pumpUntil(tester, find.text('Menu Utama'));
    await settle(tester); // transisi dari animasi pembuka

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

    // ── Gereja → Informasi Gereja: tiga kartu, masing-masing bisa dibuka ──
    await tester.tap(find.text('Gereja').last);
    await settle(tester, 1500);
    await tester.tap(find.text('Informasi Gereja').first);
    await pumpUntil(tester, find.text('Visi dan Misi'));
    expect(find.textContaining('Sejarah GKJW'), findsOneWidget);
    expect(find.text('Potret Diri'), findsOneWidget);
    await settle(tester, 2500); // waktu untuk tangkapan layar
    await tester.tap(find.text('Visi dan Misi'));
    await settle(tester, 2500);
    expect(find.text('Visi dan Misi'), findsWidgets);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    await tester.tap(find.text('Beranda').last);
    await pumpUntil(tester, find.text('Menu Utama'));

    // ── Aplikasi jemaat tidak lagi punya pintu masuk admin ──
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });
}
