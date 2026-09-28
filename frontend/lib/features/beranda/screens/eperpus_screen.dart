// lib/features/beranda/screens/eperpus_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/utils/pdf_cache.dart';
import 'package:open_filex/open_filex.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/content_models.dart';
import '../../../providers/providers.dart';

class EperpusScreen extends ConsumerWidget {
  const EperpusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(eperpusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('E-Perpustakaan')),
      body: booksAsync.when(
        loading: () => Shimmer.fromColors(
          baseColor: AppColors.surfaceAlt,
          highlightColor: AppColors.cardBg,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, __) => Container(
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        error: (e, _) => const Center(child: Text('Gagal memuat perpustakaan')),
        data: (books) => books.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.library_books_outlined, size: 64, color: AppColors.textLight),
                    SizedBox(height: 12),
                    Text('Belum ada buku', style: TextStyle(fontFamily: 'PlusJakartaSans')),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: books.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _BookCard(book: books[index]),
              ),
      ),
    );
  }
}

class _BookCard extends StatefulWidget {
  final EperpusModel book;
  const _BookCard({required this.book});

  @override
  State<_BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<_BookCard> {
  double? _progress;

  static final _cache = PdfCache();

  Future<void> _openBook() async {
    setState(() => _progress = 0.0);

    try {
      final filePath = await _cache.obtain(
        cacheKey: 'eperpus_${widget.book.id}',
        url: widget.book.fileUrl,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (mounted) setState(() => _progress = null);
      await OpenFilex.open(filePath);
    } on Exception {
      if (!mounted) return;
      setState(() => _progress = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka buku')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: widget.book.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: widget.book.coverUrl!,
                      width: 68,
                      height: 90,
                      fit: BoxFit.cover,
                      memCacheWidth: 150,
                    )
                  : Container(
                      width: 68,
                      height: 90,
                      color: AppColors.tint,
                      child: Icon(Icons.book, color: AppColors.primary, size: 32),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.book.judul,
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.book.penulis != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.book.penulis!,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (widget.book.tahun != null)
                    Text(
                      '${widget.book.tahun}',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (_progress != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: _progress,
                          borderRadius: BorderRadius.circular(4),
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mengunduh ${(_progress! * 100).toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _openBook,
                      icon: const Icon(Icons.menu_book, size: 16),
                      label: const Text('Baca'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        textStyle: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
