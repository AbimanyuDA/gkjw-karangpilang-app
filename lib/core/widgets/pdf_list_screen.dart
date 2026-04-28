// lib/core/widgets/pdf_list_screen.dart
// Generic reusable screen untuk Warta, Tata Ibadah, Renungan
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';
import '../../data/models/pdf_item_model.dart';
import 'pdf_viewer_screen.dart';

class PdfListScreen extends ConsumerStatefulWidget {
  final String title;
  final AsyncValue<List<PdfItem>> asyncItems;
  final IconData icon;

  const PdfListScreen({
    super.key,
    required this.title,
    required this.asyncItems,
    required this.icon,
  });

  @override
  ConsumerState<PdfListScreen> createState() => _PdfListScreenState();
}

class _PdfListScreenState extends ConsumerState<PdfListScreen> {
  final Map<String, double> _downloadProgress = {};

  Future<void> _openPdf(PdfItem item) async {
    final dir = await getTemporaryDirectory();
    final filename = '${item.judul.replaceAll(' ', '_')}.pdf';
    final filePath = '${dir.path}/$filename';

    // Konversi otomatis link Google Drive (view) menjadi Direct Download
    String downloadUrl = item.url;
    if (downloadUrl.contains('drive.google.com/file/d/')) {
      final match = RegExp(r'file/d/([a-zA-Z0-9_-]+)').firstMatch(downloadUrl);
      if (match != null && match.groupCount >= 1) {
        final fileId = match.group(1);
        downloadUrl = 'https://drive.google.com/uc?export=download&id=$fileId';
      }
    }

    setState(() => _downloadProgress[item.id] = 0.0);

    try {
      await Dio().download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            setState(() => _downloadProgress[item.id] = received / total);
          }
        },
      );
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
    } catch (e) {
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
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
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
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildCard(items[index]),
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
                  color: AppColors.primary.withValues(alpha: 0.1),
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
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
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
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              if (progress == null)
                const Icon(Icons.picture_as_pdf, color: AppColors.error, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 84,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
