// lib/features/gereja/screens/informasi_gereja_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../models/profil_bagian.dart';
import '../widgets/profil_bagian_card.dart';

/// Tiga kartu profil gereja (Visi dan Misi, Sejarah, Potret Diri) + kontak.
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
          final nama = namaGereja(info);
          return RefreshIndicator(
            onRefresh: () => ref.refresh(informasiGerejaProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                for (final bagian in ProfilBagian.values) ...[
                  ProfilBagianCard(
                    title: bagian.judul(nama),
                    imageUrl: bagian.foto(data),
                    heroTag: 'profil-${bagian.slug}',
                    onTap: () => context.go('/gereja/informasi/${bagian.slug}'),
                  ),
                  const SizedBox(height: 20),
                ],
                _KontakCard(info: data),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KontakCard extends StatelessWidget {
  final Map<String, dynamic> info;
  const _KontakCard({required this.info});

  String? _v(String key) {
    final v = info[key];
    return v is String && v.trim().isNotEmpty ? v.trim() : null;
  }

  @override
  Widget build(BuildContext context) {
    final alamat = _v('alamat');
    final telepon = _v('telepon');
    final email = _v('email');
    final maps = _v('maps_url');
    if (alamat == null && telepon == null && email == null && maps == null) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kontak',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            if (alamat != null)
              _ContactRow(
                icon: Icons.place_outlined,
                label: alamat,
                onTap: maps == null ? null : () => launchUrl(Uri.parse(maps)),
              ),
            if (telepon != null)
              _ContactRow(
                icon: Icons.phone_outlined,
                label: telepon,
                onTap: () => launchUrl(Uri.parse('tel:$telepon')),
              ),
            if (email != null)
              _ContactRow(
                icon: Icons.email_outlined,
                label: email,
                onTap: () => launchUrl(Uri.parse('mailto:$email')),
              ),
            if (maps != null && alamat == null)
              _ContactRow(
                icon: Icons.map_outlined,
                label: 'Lihat di Google Maps',
                onTap: () => launchUrl(Uri.parse(maps)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ContactRow({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
          ],
        ),
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
