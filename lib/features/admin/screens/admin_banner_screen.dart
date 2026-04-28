// lib/features/admin/screens/admin_banner_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/supabase_models.dart';
import '../../../data/services/supabase_service.dart';

class AdminBannerScreen extends StatefulWidget {
  const AdminBannerScreen({super.key});
  @override
  State<AdminBannerScreen> createState() => _AdminBannerScreenState();
}

class _AdminBannerScreenState extends State<AdminBannerScreen> {
  final _service = SupabaseService();
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  List<BannerSlideModel> _banners = [];
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getAllBannerSlides();
      setState(() { _banners = data; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Gagal memuat data: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Upload dari device ────────────────────────────────────────
  Future<void> _pickAndUpload() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);
    final ext = picked.path.split('.').last.toLowerCase();
    final fileName = 'banner_${DateTime.now().millisecondsSinceEpoch}.$ext';

    setState(() => _isUploading = true);
    try {
      // Upload ke Supabase Storage bucket "banners"
      await _supabase.storage.from('banners').upload(
        fileName,
        file,
        fileOptions: FileOptions(contentType: 'image/$ext', upsert: false),
      );

      // Ambil public URL
      final publicUrl =
          _supabase.storage.from('banners').getPublicUrl(fileName);

      // Simpan ke tabel banner_slide
      final urutan = _banners.isEmpty ? 1 : (_banners.last.urutan + 1);
      await _service.addBannerSlide(BannerSlideModel(
        id: '',
        imageUrl: publicUrl,
        judul: null,
        urutan: urutan,
        isActive: true,
        createdAt: DateTime.now(),
      ));

      _showSnack('Banner berhasil ditambahkan!');
      _loadBanners();
    } catch (e) {
      _showSnack('Gagal upload: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ── Toggle aktif/nonaktif ─────────────────────────────────────
  Future<void> _toggleActive(BannerSlideModel banner) async {
    try {
      await _service.updateBannerSlide(BannerSlideModel(
        id: banner.id,
        imageUrl: banner.imageUrl,
        judul: banner.judul,
        urutan: banner.urutan,
        isActive: !banner.isActive,
        createdAt: banner.createdAt,
      ));
      _loadBanners();
    } catch (e) {
      _showSnack('Gagal update: $e', isError: true);
    }
  }

  // ── Delete banner + file dari storage ────────────────────────
  Future<void> _deleteBanner(BannerSlideModel banner) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Banner?',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: const Text(
          'Banner ini akan dihapus permanen dari beranda dan storage.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _isUploading = true);
    try {
      // Ekstrak path file dari URL untuk hapus dari storage
      final uri = Uri.parse(banner.imageUrl);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf('banners');
      if (bucketIndex != -1 && bucketIndex + 1 < segments.length) {
        final filePath = segments.sublist(bucketIndex + 1).join('/');
        await _supabase.storage.from('banners').remove([filePath]);
      }

      // Hapus dari tabel
      await _service.deleteBannerSlide(banner.id);
      _showSnack('Banner berhasil dihapus');
      _loadBanners();
    } catch (e) {
      _showSnack('Gagal hapus: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Banner Beranda'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBanners),
        ],
      ),
      floatingActionButton: _isUploading
          ? FloatingActionButton.extended(
              onPressed: null,
              backgroundColor: AppColors.primary.withValues(alpha: 0.7),
              icon: const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
              label: const Text('Mengunggah...'),
            )
          : FloatingActionButton.extended(
              onPressed: _pickAndUpload,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Upload Gambar'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
      body: Column(
        children: [
          // ── INFO RASIO ──
          _RatioInfoCard(),

          // ── LIST / EMPTY ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _banners.isEmpty
                    ? _EmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: _banners.length,
                        separatorBuilder: (_, p) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _BannerCard(
                          banner: _banners[i],
                          onToggle: () => _toggleActive(_banners[i]),
                          onDelete: () => _deleteBanner(_banners[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── RATIO INFO CARD ───────────────────────────────────────────
class _RatioInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.primary.withValues(alpha: 0.06),
          AppColors.secondary.withValues(alpha: 0.08),
        ]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          // Contoh rasio visual
          Container(
            width: 80, height: 35,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: const Center(
              child: Text('16 : 7',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                      fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Panduan Ukuran Gambar',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                        fontWeight: FontWeight.w700, color: AppColors.primary)),
                SizedBox(height: 4),
                _InfoRow(icon: Icons.photo_size_select_actual,
                    label: 'Resolusi', value: '1600 × 700 px'),
                _InfoRow(icon: Icons.straighten, label: 'Minimal', value: '800 × 350 px'),
                _InfoRow(icon: Icons.storage, label: 'Format', value: 'JPG / PNG / WebP'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── EMPTY STATE ───────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 72,
              color: AppColors.textLight.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text('Belum ada banner',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          const Text('Tekan tombol Upload untuk menambah',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                  color: AppColors.textLight)),
        ],
      ),
    );
  }
}

// ── BANNER CARD ───────────────────────────────────────────────
class _BannerCard extends StatelessWidget {
  final BannerSlideModel banner;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _BannerCard({
    required this.banner,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.07),
              blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // Preview gambar rasio 16:7
          AspectRatio(
            aspectRatio: 16 / 7,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: banner.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (ctx2, url) => Container(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      child: const Center(child: CircularProgressIndicator(
                          color: AppColors.secondary, strokeWidth: 2)),
                    ),
                    errorWidget: (ctx2, url, err) => Container(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      child: const Center(child: Icon(Icons.broken_image_outlined,
                          color: AppColors.textLight, size: 36)),
                    ),
                  ),
                  // Badge status
                  Positioned(
                    top: 8, left: 8,
                    child: _StatusBadge(isActive: banner.isActive),
                  ),
                  // Badge urutan
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('#${banner.urutan}',
                          style: const TextStyle(fontFamily: 'Poppins',
                              color: Colors.white, fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Actions row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    banner.judul ?? 'Banner #${banner.urutan}',
                    style: const TextStyle(fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600, fontSize: 13,
                        color: AppColors.textPrimary),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Toggle aktif
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: banner.isActive,
                    onChanged: (_) => onToggle(),
                    activeThumbColor: AppColors.primary,
                  ),
                ),
                // Hapus
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error, size: 22),
                  onPressed: onDelete,
                  tooltip: 'Hapus banner',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── STATUS BADGE ──────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF2ECC71).withValues(alpha: 0.92)
            : Colors.grey.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? '● Aktif' : '● Nonaktif',
        style: const TextStyle(fontFamily: 'Poppins', color: Colors.white,
            fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── INFO ROW ──────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 11, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text('$label: ', style: const TextStyle(fontFamily: 'Poppins',
              fontSize: 11, color: AppColors.textSecondary,
              fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontFamily: 'Poppins',
              fontSize: 11, color: AppColors.textPrimary,
              fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
