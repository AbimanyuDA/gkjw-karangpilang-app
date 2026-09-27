// lib/features/admin/screens/admin_gereja_cover_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../core/widgets/image_crop_screen.dart';
import '../../../data/models/content_models.dart';
import '../../../providers/providers.dart';

class AdminGerejaCoverScreen extends ConsumerStatefulWidget {
  const AdminGerejaCoverScreen({super.key});

  @override
  ConsumerState<AdminGerejaCoverScreen> createState() => _AdminGerejaCoverScreenState();
}

class _AdminGerejaCoverScreenState extends ConsumerState<AdminGerejaCoverScreen> {
  final _picker = ImagePicker();

  // Track uploading state per menu key
  final Map<String, bool> _uploading = {};

  static const _menuItems = [
    _MenuItem('informasi_gereja', 'Informasi Gereja', Icons.info_outline, Color(0xFF1C3A63)),
    _MenuItem('kependetaan', 'Kependetaan', Icons.person_outline, Color(0xFF0B1F3A)),
    _MenuItem('kemajelisan', 'Kemajelisan', Icons.people_outline, Color(0xFF8A6420)),
    _MenuItem('bpm', 'Badan Pembantu Majelis', Icons.groups_outlined, Color(0xFFB5842A)),
    _MenuItem('perwilayahan', 'Perwilayahan', Icons.map_outlined, Color(0xFF122B4D)),
    _MenuItem('profil_ruangan', 'Profil Ruangan', Icons.meeting_room_outlined, Color(0xFF1C3A63)),
  ];

  Future<void> _pickAndUpload(_MenuItem item) async {
    // Show ratio info dialog first
    final confirmed = await _showRatioDialog(item);
    if (!confirmed) return;

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (picked == null) return;

    final imageBytes = await picked.readAsBytes();
    if (!mounted) return;

    // Buka screen untuk crop/preview dengan rasio 16:9
    final Uint8List? croppedBytes = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageCropScreen(
          imageBytes: imageBytes,
          aspectRatio: 16 / 9,
          title: 'Sesuaikan Cover (16:9)',
        ),
      ),
    );

    if (croppedBytes == null) return;

    setState(() => _uploading[item.key] = true);

    File? tempFile;
    File? compressedFile;
    try {
      // Simpan hasil crop sementara
      final tempDir = Directory.systemTemp;
      tempFile = File('${tempDir.path}/cropped_cover_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(croppedBytes);

      // Kompres gambar otomatis under 100kb
      compressedFile = await ImageCompressor.compressImage(tempFile);
      // Upload gambar baru, simpan sebagai cover, lalu hapus file cover lama
      final service = ref.read(contentServiceProvider);
      final oldUrl = _coverFor(item.key)?.imageUrl;
      final uploaded = await ref.read(apiClientProvider).upload('gereja-covers', compressedFile);
      await service.setGerejaCover(item.key, uploaded.url);
      if (oldUrl != null) await service.deleteFile(oldUrl);
      ref.invalidate(gerejaCoversProvider);

      if (mounted) _showSnack('Cover "${item.label}" berhasil diunggah ✓');
    } on Exception catch (e) {
      if (mounted) _showSnack('Gagal upload: $e', isError: true);
    } finally {
      if (tempFile != null) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      if (compressedFile != null) {
        try {
          await compressedFile.delete();
        } catch (_) {}
      }
      if (mounted) setState(() => _uploading[item.key] = false);
    }
  }

  Future<bool> _showRatioDialog(_MenuItem item) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.aspect_ratio_rounded, color: item.color),
            const SizedBox(width: 8),
            const Text(
              'Panduan Ukuran',
              style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cover untuk: ${item.label}',
              style: const TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            // Ratio info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: item.color.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(Icons.crop_landscape_rounded, 'Rasio Gambar', '16 : 9', item.color),
                  const SizedBox(height: 6),
                  _infoRow(Icons.photo_size_select_large_outlined, 'Resolusi Min.', '800 × 450 px', item.color),
                  const SizedBox(height: 6),
                  _infoRow(Icons.hd_rounded, 'Resolusi Ideal', '1280 × 720 px', item.color),
                  const SizedBox(height: 6),
                  _infoRow(Icons.data_usage_rounded, 'Ukuran File Max.', '5 MB', item.color),
                  const SizedBox(height: 6),
                  _infoRow(Icons.image_rounded, 'Format', 'JPG / PNG / WEBP', item.color),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '💡 Tips: Gunakan foto landscape (horizontal) gereja atau kegiatan untuk hasil terbaik.',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.photo_library_outlined, size: 16),
            label: const Text('Pilih Gambar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Future<void> _deleteCover(_MenuItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Hapus Cover?', style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w700)),
        content: Text('Cover "${item.label}" akan dihapus.', style: const TextStyle(fontFamily: 'PlusJakartaSans')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final cover = _coverFor(item.key);
      if (cover != null) {
        final service = ref.read(contentServiceProvider);
        await service.deleteGerejaCover(cover.id);
        await service.deleteFile(cover.imageUrl);
        ref.invalidate(gerejaCoversProvider);
      }
      if (mounted) _showSnack('Cover dihapus');
    } on Exception catch (e) {
      if (mounted) _showSnack('Gagal hapus: $e', isError: true);
    }
  }

  GerejaCoverModel? _coverFor(String key) {
    final covers = ref.read(gerejaCoversProvider).value ?? const [];
    for (final c in covers) {
      if (c.key == key) return c;
    }
    return null;
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'PlusJakartaSans')),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade700 : AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2E4),
      appBar: AppBar(
        title: const Text(
          'Cover Menu Gereja',
          style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header info strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.gold500.withValues(alpha: 0.16),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Rasio yang direkomendasikan: 16:9 (landscape). Tap menu untuk ganti cover.',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 11,
                      color: AppColors.primary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Builder(
              builder: (context) {
                final covers = {
                  for (final c in ref.watch(gerejaCoversProvider).value ?? const <GerejaCoverModel>[])
                    c.key: c.imageUrl,
                };

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _menuItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _menuItems[index];
                    final imageUrl = covers[item.key] ?? '';
                    final isUploading = _uploading[item.key] ?? false;

                    return Card(
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        children: [
                          // Cover preview — 16:9 ratio
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Image or placeholder
                                if (imageUrl.isNotEmpty)
                                  CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 600,
                                    placeholder: (_, __) => Container(color: Colors.grey.shade200),
                                    errorWidget: (_, __, ___) => _buildPlaceholder(item),
                                  )
                                else
                                  _buildPlaceholder(item),

                                // Upload progress overlay
                                if (isUploading)
                                  Container(
                                    color: Colors.black54,
                                    child: const Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(color: Colors.white),
                                          SizedBox(height: 8),
                                          Text(
                                            'Mengunggah...',
                                            style: TextStyle(
                                              fontFamily: 'PlusJakartaSans',
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // Ratio badge top-right
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '16:9',
                                      style: TextStyle(
                                        fontFamily: 'PlusJakartaSans',
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                // Label overlay bottom
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                                      ),
                                    ),
                                    child: Text(
                                      item.label,
                                      style: const TextStyle(
                                        fontFamily: 'PlusJakartaSans',
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Action row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                            child: Row(
                              children: [
                                Icon(item.icon, color: item.color, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        imageUrl.isNotEmpty ? 'Cover tersedia' : 'Belum ada cover',
                                        style: TextStyle(
                                          fontFamily: 'PlusJakartaSans',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: imageUrl.isNotEmpty ? Colors.green.shade700 : AppColors.textSecondary,
                                        ),
                                      ),
                                      const Text(
                                        'Rekomendasi: 16:9 · Min. 800×450px',
                                        style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 10, color: AppColors.textLight),
                                      ),
                                    ],
                                  ),
                                ),
                                if (imageUrl.isNotEmpty)
                                  IconButton(
                                    onPressed: isUploading ? null : () => _deleteCover(item),
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                    tooltip: 'Hapus cover',
                                  ),
                                TextButton.icon(
                                  onPressed: isUploading ? null : () => _pickAndUpload(item),
                                  icon: Icon(
                                    imageUrl.isNotEmpty ? Icons.edit_outlined : Icons.upload_rounded,
                                    size: 16,
                                  ),
                                  label: Text(imageUrl.isNotEmpty ? 'Ganti' : 'Upload'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: item.color,
                                    textStyle: const TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(_MenuItem item) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [item.color.withValues(alpha: 0.4), item.color.withValues(alpha: 0.75)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: Colors.white.withValues(alpha: 0.8), size: 36),
          const SizedBox(height: 6),
          const Text(
            'Belum ada cover\nKetuk "Upload" untuk menambah',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              color: Colors.white,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const _MenuItem(this.key, this.label, this.icon, this.color);
}
