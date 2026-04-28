// lib/features/informasi/screens/notifikasi_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';

class NotifikasiScreen extends ConsumerWidget {
  const NotifikasiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(notifikasiProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Gagal memuat notifikasi')),
        data: (items) => items.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none, size: 64, color: AppColors.textLight),
                    SizedBox(height: 12),
                    Text('Belum ada notifikasi', style: TextStyle(fontFamily: 'Poppins')),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications, color: AppColors.error, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.judul, style: const TextStyle(
                                  fontFamily: 'Poppins', fontWeight: FontWeight.w600,
                                  fontSize: 14, color: AppColors.textPrimary,
                                )),
                                const SizedBox(height: 4),
                                Text(item.pesan, style: const TextStyle(
                                  fontFamily: 'Poppins', fontSize: 12,
                                  color: AppColors.textSecondary, height: 1.5,
                                )),
                                const SizedBox(height: 6),
                                Text(
                                  DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(item.createdAt),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins', fontSize: 11,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
