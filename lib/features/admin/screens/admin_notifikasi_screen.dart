// lib/features/admin/screens/admin_notifikasi_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/supabase_models.dart';
import '../../../data/services/supabase_service.dart';
import '../../../providers/providers.dart';

class AdminNotifikasiScreen extends ConsumerStatefulWidget {
  const AdminNotifikasiScreen({super.key});
  @override
  ConsumerState<AdminNotifikasiScreen> createState() => _AdminNotifikasiScreenState();
}

class _AdminNotifikasiScreenState extends ConsumerState<AdminNotifikasiScreen> {
  final _service = SupabaseService();

  void _showAddDialog() {
    final judulCtrl = TextEditingController();
    final pesanCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kirim Notifikasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: judulCtrl,
              decoration: const InputDecoration(
                labelText: 'Judul *',
                prefixIcon: Icon(Icons.notifications_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pesanCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Pesan *',
                prefixIcon: Icon(Icons.message_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (judulCtrl.text.isEmpty || pesanCtrl.text.isEmpty) return;
              await _service.addNotifikasi(NotifikasiModel(
                id: '',
                judul: judulCtrl.text.trim(),
                pesan: pesanCtrl.text.trim(),
                isActive: true,
                createdAt: DateTime.now(),
              ));
              ref.invalidate(notifikasiProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(notifikasiProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Notifikasi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add_alert),
        label: const Text('Kirim Notifikasi'),
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Gagal memuat')),
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications, color: AppColors.error, size: 22),
                      ),
                      title: Text(item.judul,
                          style: const TextStyle(
                              fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                      subtitle: Text(item.pesan,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () async {
                          await _service.deleteNotifikasi(item.id);
                          ref.invalidate(notifikasiProvider);
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
