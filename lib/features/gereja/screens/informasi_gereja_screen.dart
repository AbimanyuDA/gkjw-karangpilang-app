// lib/features/gereja/screens/informasi_gereja_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';

class InformasiGerejaScreen extends ConsumerWidget {
  const InformasiGerejaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(informasiGerejaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Informasi Gereja')),
      body: infoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Gagal memuat informasi')),
        data: (info) {
          if (info == null) return const Center(child: Text('Data tidak tersedia'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.church, color: Colors.white, size: 56),
                      const SizedBox(height: 12),
                      Text(
                        info['nama'] ?? 'GKJW Karangpilang',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (info['alamat'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          info['alamat'],
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (info['deskripsi'] != null)
                  _InfoSection(
                    icon: Icons.info_outline,
                    title: 'Tentang Gereja',
                    content: info['deskripsi'],
                  ),

                if (info['visi'] != null)
                  _InfoSection(
                    icon: Icons.visibility_outlined,
                    title: 'Visi',
                    content: info['visi'],
                  ),

                if (info['misi'] != null)
                  _InfoSection(
                    icon: Icons.flag_outlined,
                    title: 'Misi',
                    content: info['misi'],
                  ),

                // Contact info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kontak',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (info['telepon'] != null)
                          _ContactRow(
                            icon: Icons.phone_outlined,
                            label: info['telepon'],
                            onTap: () => launchUrl(Uri.parse('tel:${info['telepon']}')),
                          ),
                        if (info['email'] != null)
                          _ContactRow(
                            icon: Icons.email_outlined,
                            label: info['email'],
                            onTap: () => launchUrl(Uri.parse('mailto:${info['email']}')),
                          ),
                        if (info['maps_url'] != null)
                          _ContactRow(
                            icon: Icons.location_on_outlined,
                            label: 'Lihat di Google Maps',
                            onTap: () => launchUrl(Uri.parse(info['maps_url'])),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  const _InfoSection({required this.icon, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                content,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ContactRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
