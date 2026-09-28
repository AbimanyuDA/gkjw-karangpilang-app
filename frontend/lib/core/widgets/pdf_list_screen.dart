// lib/core/widgets/pdf_list_screen.dart
// Generic reusable screen untuk Warta, Tata Ibadah, Renungan
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';
import '../utils/pdf_cache.dart';
import '../../data/models/pdf_item_model.dart';
import 'pdf_viewer_screen.dart';

class PdfListScreen extends ConsumerStatefulWidget {
  final String title;
  final AsyncValue<List<PdfItem>> asyncItems;
  final IconData icon;
  final Future<void> Function()? onRefresh;

  const PdfListScreen({
    super.key,
    required this.title,
    required this.asyncItems,
    required this.icon,
    this.onRefresh,
  });

  @override
  ConsumerState<PdfListScreen> createState() => _PdfListScreenState();
}

class _PdfListScreenState extends ConsumerState<PdfListScreen> {
  final Map<String, double> _downloadProgress = {};

  final _cache = PdfCache();

  Future<void> _openPdf(PdfItem item) async {
    setState(() => _downloadProgress[item.id] = 0.0);

    try {
      final filePath = await _cache.obtain(
        cacheKey: item.id,
        url: item.url,
        onProgress: (p) {
          if (mounted) setState(() => _downloadProgress[item.id] = p);
        },
      );
      if (!mounted) return;
      setState(() => _downloadProgress.remove(item.id));
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
              title: item.judul,
              pdfPath: filePath,
            ),
          ),
        );
      }
    } on Exception {
      if (!mounted) return;
      setState(() => _downloadProgress.remove(item.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka file PDF')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: widget.asyncItems.when(
        loading: () => _buildShimmer(),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Gagal memuat data', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
        data: (items) => items.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, size: 64, color: AppColors.textLight),
                    const SizedBox(height: 12),
                    Text('Belum ada konten', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: widget.onRefresh ?? () async {},
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildCard(items[index]),
                ),
              ),
      ),
    );
  }

  Widget _buildCard(PdfItem item) {
    final progress = _downloadProgress[item.id];
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(item.tanggal);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: progress != null ? null : () => _openPdf(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.tint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.judul,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              if (progress == null)
                Icon(Icons.picture_as_pdf, color: AppColors.error, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceAlt,
      highlightColor: AppColors.cardBg,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 84,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
