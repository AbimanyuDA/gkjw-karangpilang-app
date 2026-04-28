// lib/features/admin/screens/admin_galeri_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/supabase_models.dart';
import '../../../data/services/supabase_service.dart';
import '../../../providers/providers.dart';

class AdminGaleriScreen extends ConsumerStatefulWidget {
  const AdminGaleriScreen({super.key});
  @override
  ConsumerState<AdminGaleriScreen> createState() => _AdminGaleriScreenState();
}

class _AdminGaleriScreenState extends ConsumerState<AdminGaleriScreen> {
  final _service = SupabaseService();

  void _showAddDialog() {
    final judulCtrl = TextEditingController();
    final urlCtrl = TextEditingController   ();
    final komisiCtrl = TextEditingController();
    int selectedYear = DateTime.now().year;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tambah Foto Galeri'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: judulCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Judul Foto *',
                    prefixIcon: Icon(Icons.photo),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL Gambar *',
                    prefixIcon: Icon(Icons.link),
                    helperText: 'Link gambar (Google Drive share link / CDN)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: komisiCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Komisi / Kegiatan',
                    prefixIcon: Icon(Icons.group_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Tahun: ', style: TextStyle(fontFamily: 'Poppins')),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: selectedYear,
                      items: List.generate(6, (i) => DateTime.now().year - i)
                          .map((y) => DropdownMenuItem(
                            value: y,
                            child: Text('$y', style: const TextStyle(fontFamily: 'Poppins')),
                          ))
                          .toList(),
                      onChanged: (v) => setDialogState(() => selectedYear = v!),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (judulCtrl.text.isEmpty || urlCtrl.text.isEmpty) return;
                await _service.addGaleri(GaleriModel(
                  id: '',
                  judul: judulCtrl.text.trim(),
                  imageUrl: urlCtrl.text.trim(),
                  tahun: selectedYear,
                  komisi: komisiCtrl.text.trim(),
                  createdAt: DateTime.now(),
                ));
                ref.invalidate(galeriProvider);
                ref.invalidate(galeriTahunProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final galeriAsync = ref.watch(galeriProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Galeri')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add_photo_alternate),
        label: const Text('Tambah Foto'),
      ),
      body: galeriAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Gagal memuat')),
        data: (items) => items.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library_outlined, size: 64, color: AppColors.textLight),
                    SizedBox(height: 12),
                    Text('Belum ada foto', style: TextStyle(fontFamily: 'Poppins')),
                  ],
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            child: const Icon(Icons.image_not_supported_outlined),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.7),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Text(
                            item.judul,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Hapus foto?'),
                                content: Text('Hapus "${item.judul}"?'),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: const Text('Batal')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.error),
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await _service.deleteGaleri(item.id);
                              ref.invalidate(galeriProvider);
                              ref.invalidate(galeriTahunProvider);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.delete_outline,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
