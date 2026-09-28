// lib/features/gereja/screens/informasi_gereja_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../models/profil_bagian.dart';
import '../widgets/profil_bagian_card.dart';

/// Tiga kartu profil gereja: Visi dan Misi, Sejarah, Potret Diri.
class InformasiGerejaScreen extends ConsumerWidget {
  const InformasiGerejaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(informasiGerejaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Informasi Gereja')),
      body: infoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Pesan(
          'Gagal memuat informasi',
          onRetry: () => ref.invalidate(informasiGerejaProvider),
        ),
        data: (info) {
          final data = info ?? const <String, dynamic>{};
          return RefreshIndicator(
            onRefresh: () => ref.refresh(informasiGerejaProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                for (final bagian in ProfilBagian.values) ...[
                  ProfilBagianCard(
                    title: bagian.judul,
                    imageUrl: bagian.foto(data),
                    heroTag: 'profil-${bagian.slug}',
                    onTap: () => context.go('/gereja/informasi/${bagian.slug}'),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Pesan extends StatelessWidget {
  final String text;
  final VoidCallback onRetry;
  const _Pesan(this.text, {required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: TextStyle(color: AppColors.textSecondary)),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
