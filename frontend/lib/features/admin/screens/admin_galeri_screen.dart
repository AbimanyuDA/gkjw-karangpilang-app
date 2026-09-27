// lib/features/admin/screens/admin_galeri_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../data/models/content_models.dart';
import '../../../data/services/content_service.dart';
import '../../../providers/providers.dart';

class AdminGaleriScreen extends ConsumerStatefulWidget {
  const AdminGaleriScreen({super.key});
  @override
  ConsumerState<AdminGaleriScreen> createState() => _AdminGaleriScreenState();
}

class _AdminGaleriScreenState extends ConsumerState<AdminGaleriScreen> {
  ContentService get _service => ref.read(contentServiceProvider);

  final _picker = ImagePicker();

  void _showAddDialog() {
    final judulCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final komisiCtrl = TextEditingController();
    int selectedYear = DateTime.now().year;
    File? pickedFile;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> pickPhoto() async {
            final picked = await _picker.pickImage(source: ImageSource.gallery);
            if (picked == null) return;
            setDialogState(() => pickedFile = File(picked.path));
          }

          Future<void> save() async {
            if (judulCtrl.text.trim().isEmpty || (pickedFile == null && urlCtrl.text.trim().isEmpty)) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Isi judul dan pilih foto (atau tempel URL gambar)')),
              );
              return;
            }
            setDialogState(() => isSaving = true);
            File? compressed;
            try {
              var imageUrl = urlCtrl.text.trim();
              final file = pickedFile;
              if (file != null) {
                // Foto galeri: sisi terpanjang 1600 px, ±300 KB — tajam tapi hemat kuota jemaat.
                compressed = await ImageCompressor.compressImage(
                  file,
                  targetSizeBytes: 300 * 1024,
                  maxDimension: 1600,
                );
                imageUrl = (await ref.read(apiClientProvider).upload('galeri', compressed)).url;
              }
              await _service.addGaleri(GaleriModel(
                id: '',
                judul: judulCtrl.text.trim(),
                imageUrl: imageUrl,
                tahun: selectedYear,
                komisi: komisiCtrl.text.trim(),
                createdAt: DateTime.now(),
              ));
              ref.invalidate(galeriProvider);
              ref.invalidate(galeriTahunProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            } on Exception catch (e) {
              setDialogState(() => isSaving = false);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
              }
            } finally {
              try {
                await compressed?.delete();
              } on FileSystemException {
                // file sementara sudah hilang — abaikan
              }
            }
          }

          final file = pickedFile;
          return AlertDialog(
            title: const Text('Tambah Foto Galeri'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: isSaving ? null : pickPhoto,
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.gold500.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: file != null
                            ? Image.file(file, fit: BoxFit.cover)
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.primary),
                                  SizedBox(height: 8),
                                  Text('Pilih foto dari galeri HP',
                                      style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12)),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: judulCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Judul Foto *',
                      prefixIcon: Icon(Icons.photo),
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
                      const Text('Tahun: ', style: TextStyle(fontFamily: 'PlusJakartaSans')),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: selectedYear,
                        items: List.generate(6, (i) => DateTime.now().year - i)
                            .map((y) => DropdownMenuItem(
                                  value: y,
                                  child: Text('$y', style: const TextStyle(fontFamily: 'PlusJakartaSans')),
                                ))
                            .toList(),
                        onChanged: isSaving ? null : (v) => setDialogState(() => selectedYear = v!),
                      ),
                    ],
                  ),
                  if (file == null) ...[
                    const SizedBox(height: 4),
                    TextField(
                      controller: urlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'atau URL Gambar',
                        prefixIcon: Icon(Icons.link),
                        helperText: 'Opsional, bila foto sudah ada di internet',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: isSaving ? null : save,
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Simpan'),
              ),
            ],
          );
        },
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
                    Text('Belum ada foto', style: TextStyle(fontFamily: 'PlusJakartaSans')),
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
                          memCacheWidth: 300,
                          placeholder: (_, __) => Container(
                            color: AppColors.gold500.withValues(alpha: 0.16),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.gold500.withValues(alpha: 0.16),
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
                              fontFamily: 'PlusJakartaSans',
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
                            if (ok != true) return;
                            try {
                              await _service.deleteGaleri(item.id);
                              await _service.deleteFile(item.imageUrl);
                              ref.invalidate(galeriProvider);
                              ref.invalidate(galeriTahunProvider);
                            } on Exception catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal menghapus: $e')),
                                );
                              }
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
