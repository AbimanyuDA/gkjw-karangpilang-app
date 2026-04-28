// lib/features/informasi/screens/hubungi_kami_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';

class HubungiKamiScreen extends ConsumerWidget {
  const HubungiKamiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(hubungiProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Hubungi Kami')),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Gagal memuat data')),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _open(item.jenis, item.nilai),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _getColor(item.jenis).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(_getIcon(item.jenis),
                            color: _getColor(item.jenis), size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.nama, style: const TextStyle(
                              fontFamily: 'Poppins', fontWeight: FontWeight.w600,
                              fontSize: 14, color: AppColors.textPrimary,
                            )),
                            const SizedBox(height: 2),
                            Text(item.nilai, style: const TextStyle(
                              fontFamily: 'Poppins', fontSize: 12,
                              color: AppColors.textSecondary,
                            )),
                          ],
                        ),
                      ),
                      const Icon(Icons.open_in_new, color: AppColors.textLight, size: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _open(String jenis, String nilai) {
    final uri = switch (jenis) {
      'whatsapp' => Uri.parse('https://wa.me/$nilai'),
      'email' => Uri.parse('mailto:$nilai'),
      'instagram' => Uri.parse('https://instagram.com/${nilai.replaceAll('@', '')}'),
      'facebook' => Uri.parse('https://facebook.com'),
      'youtube' => Uri.parse('https://youtube.com'),
      _ => Uri.parse(nilai),
    };
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  IconData _getIcon(String jenis) => switch (jenis) {
    'whatsapp' => Icons.chat,
    'email' => Icons.email_outlined,
    'instagram' => Icons.camera_alt_outlined,
    'facebook' => Icons.facebook,
    'youtube' => Icons.play_circle_outlined,
    _ => Icons.link,
  };

  Color _getColor(String jenis) => switch (jenis) {
    'whatsapp' => const Color(0xFF25D366),
    'email' => const Color(0xFFEA4335),
    'instagram' => const Color(0xFFE1306C),
    'facebook' => const Color(0xFF1877F2),
    'youtube' => const Color(0xFFFF0000),
    _ => AppColors.primary,
  };
}
