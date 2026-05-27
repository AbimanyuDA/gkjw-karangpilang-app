// lib/core/widgets/profil_list_screen.dart
// Generic reusable screen untuk Kependetaan, Kemajelisan, BPM, Perwilayahan, Ruangan
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

class ProfilListScreen extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final String namaKey;
  final String jabatanKey;
  final String? fotoKey;
  final String? bioKey;

  const ProfilListScreen({
    super.key,
    required this.title,
    required this.items,
    this.namaKey = 'nama',
    this.jabatanKey = 'jabatan',
    this.fotoKey = 'foto_url',
    this.bioKey = 'bio',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 64, color: AppColors.textLight),
                  const SizedBox(height: 12),
                  Text('Belum ada data', style: Theme.of(context).textTheme.titleMedium),
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          backgroundImage: item[fotoKey] != null
                              ? ResizeImage(CachedNetworkImageProvider(item[fotoKey]), width: 150, height: 150)
                              : null,
                          child: item[fotoKey] == null
                              ? Text(
                                  (item[namaKey] as String).isNotEmpty
                                      ? (item[namaKey] as String)[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item[namaKey] ?? '',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item[jabatanKey] ?? '',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (bioKey != null && item[bioKey] != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  item[bioKey],
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
