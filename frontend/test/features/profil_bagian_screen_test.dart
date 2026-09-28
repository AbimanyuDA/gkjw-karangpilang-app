import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gkjw_karangpilang/features/gereja/models/profil_bagian.dart';
import 'package:gkjw_karangpilang/features/gereja/screens/profil_bagian_screen.dart';
import 'package:gkjw_karangpilang/features/gereja/widgets/profil_bagian_card.dart';
import 'package:gkjw_karangpilang/providers/providers.dart';

void main() {
  testWidgets('foto mengecil saat digulir tapi tetap tampil', (tester) async {
    tester.view
      ..physicalSize = const Size(400, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          informasiGerejaProvider.overrideWith(
            (ref) async => {
              'sejarah': List.filled(40, 'Paragraf sejarah.').join('\n\n'),
            },
          ),
        ],
        child: const MaterialApp(
          home: ProfilBagianScreen(bagian: ProfilBagian.sejarah),
        ),
      ),
    );
    await tester.pumpAndSettle();

    double fotoHeight() => tester.getSize(find.byType(ProfilFoto)).height;
    expect(fotoHeight(), closeTo(400 * 9 / 16, 0.5));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilFoto), findsOneWidget);
    expect(fotoHeight(), closeTo(kToolbarHeight + 44, 0.5));
    expect(find.byType(BackButton), findsOneWidget);
  });
}
