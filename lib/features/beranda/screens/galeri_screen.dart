// lib/features/beranda/screens/galeri_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';

class GaleriScreen extends ConsumerWidget {
  const GaleriScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tahunAsync = ref.watch(galeriTahunProvider);
    final galeriAsync = ref.watch(galeriProvider);
    final selectedTahun = ref.watch(selectedTahunProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Galeri')),
      body: Column(
        children: [
          // Year filter
          tahunAsync.when(
            loading: () => const SizedBox(height: 60),
            error: (_, __) => const SizedBox(),
            data: (years) => SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                children: [
                  _YearChip(
                    label: 'Semua',
                    selected: selectedTahun == null,
                    onTap: () => ref.read(selectedTahunProvider.notifier).state = null,
                  ),
                  ...years.map((y) => _YearChip(
                    label: '$y',
                    selected: selectedTahun == y,
                    onTap: () => ref.read(selectedTahunProvider.notifier).state = y,
                  )),
                ],
              ),
            ),
          ),
          Expanded(
            child: galeriAsync.when(
              loading: () => Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  padding: const EdgeInsets.all(4),
                  children: List.generate(
                    9,
                    (_) => Container(color: Colors.white),
                  ),
                ),
              ),
              error: (e, _) => const Center(child: Text('Gagal memuat galeri')),
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
                      padding: const EdgeInsets.all(4),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return GestureDetector(
                          onTap: () => _showDetail(context, item.imageUrl, item.judul),
                          child: Hero(
                            tag: item.id,
                            child: CachedNetworkImage(
                              imageUrl: item.imageUrl,
                              fit: BoxFit.cover,
                              memCacheWidth: 300,
                              placeholder: (_, __) => Container(color: Colors.grey.shade200),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, String url, String title) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                width: double.infinity,
                memCacheWidth: 900,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _YearChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
