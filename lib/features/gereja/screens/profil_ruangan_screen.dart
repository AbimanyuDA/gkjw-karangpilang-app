// lib/features/gereja/screens/profil_ruangan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';

class ProfilRuanganScreen extends ConsumerWidget {
  const ProfilRuanganScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(profilRuanganProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Ruangan')),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Gagal memuat data')),
        data: (items) => items.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.meeting_room_outlined, size: 64, color: AppColors.textLight),
                    SizedBox(height: 12),
                    Text('Belum ada data ruangan', style: TextStyle(fontFamily: 'Poppins')),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item['foto_url'] != null)
                          CachedNetworkImage(
                            imageUrl: item['foto_url'],
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        else
                          Container(
                            height: 120,
                            color: AppColors.primary.withValues(alpha: 0.08),
                            child: const Center(
                              child: Icon(Icons.meeting_room_outlined,
                                  size: 48, color: AppColors.primary),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['nama'] ?? '',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (item['kapasitas'] != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.people_outline,
                                        size: 15, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Kapasitas: ${item['kapasitas']} orang',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (item['deskripsi'] != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  item['deskripsi'],
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
