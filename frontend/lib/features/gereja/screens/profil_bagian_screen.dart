// lib/features/gereja/screens/profil_bagian_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../models/profil_bagian.dart';
import '../widgets/profil_bagian_card.dart';

/// Halaman detail satu bagian profil gereja: foto besar di atas, lalu teksnya.
class ProfilBagianScreen extends ConsumerWidget {
  final ProfilBagian bagian;
  const ProfilBagianScreen({super.key, required this.bagian});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info =
        ref.watch(informasiGerejaProvider).value ?? const <String, dynamic>{};
    final judul = bagian.judul;
    final isi = bagian.isi(info);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: MediaQuery.sizeOf(context).width * 9 / 16,
            backgroundColor: AppColors.navy900,
            foregroundColor: Colors.white,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            // Judul cukup di bawah foto; di atas foto hanya tombol kembali berlatar
            // gelap agar tetap terlihat di foto yang terang.
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child: BackButton(color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'profil-${bagian.slug}',
                    child: ProfilFoto(url: bagian.foto(info)),
                  ),
                  // Bayangan atas agar tombol kembali & judul tetap terbaca di foto terang.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 120),
            sliver: SliverList.list(
              children: [
                Text(
                  judul,
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.heading,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 40,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.gold600,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (isi.isEmpty)
                  Text(
                    'Informasi belum tersedia.',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                for (final bagianIsi in isi) ...[
                  if (bagianIsi.judul != null) _SubJudul(bagianIsi.judul!),
                  if (bagian == ProfilBagian.visiMisi &&
                      bagianIsi.judul == 'Misi')
                    _DaftarPoin(bagianIsi.isi)
                  else
                    _Paragraf(bagianIsi.isi),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubJudul extends StatelessWidget {
  final String text;
  const _SubJudul(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.heading,
        ),
      ),
    );
  }
}

TextStyle get _bodyStyle => TextStyle(
  fontFamily: 'PlusJakartaSans',
  fontSize: 15,
  height: 1.75,
  color: AppColors.textPrimary,
);

/// Teks dengan paragraf dipisah baris kosong.
class _Paragraf extends StatelessWidget {
  final String text;
  const _Paragraf(this.text);

  @override
  Widget build(BuildContext context) {
    final paragraf = text.split(RegExp(r'\n\s*\n'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < paragraf.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == paragraf.length - 1 ? 0 : 14),
            child: Text(paragraf[i].trim(), style: _bodyStyle),
          ),
      ],
    );
  }
}

/// Satu poin per baris (misi), diberi nomor.
class _DaftarPoin extends StatelessWidget {
  final String text;
  const _DaftarPoin(this.text);

  @override
  Widget build(BuildContext context) {
    final poin = [
      for (final l in text.split('\n'))
        if (l.trim().isNotEmpty)
          l.trim().replaceFirst(RegExp(r'^(\d+[.)]|[-•*])\s*'), ''),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < poin.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 2, right: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.gold600.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold600,
                    ),
                  ),
                ),
                Expanded(child: Text(poin[i], style: _bodyStyle)),
              ],
            ),
          ),
      ],
    );
  }
}
