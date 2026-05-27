// lib/features/siaran/screens/siaran_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/pdf_item_model.dart';
import '../../../providers/providers.dart';
import 'siaran_detail_screen.dart';

const _kategoriList = [
  {'key': null, 'label': 'Semua'},
  {'key': 'umum', 'label': 'Ibadah Umum'},
  {'key': 'anak', 'label': 'Ibadah Anak'},
  {'key': 'remaja', 'label': 'Ibadah Remaja'},
  {'key': 'sekolah_minggu', 'label': 'Sekolah Minggu'},
];

class SiaranScreen extends ConsumerStatefulWidget {
  const SiaranScreen({super.key});

  @override
  ConsumerState<SiaranScreen> createState() => _SiaranScreenState();
}

class _SiaranScreenState extends ConsumerState<SiaranScreen> {
  bool _isCategoryExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedKat = ref.watch(siaranKategoriProvider);
    final siaranAsync = ref.watch(siaranProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Row 1: Title + Lihat Semua/Tutup Arsip ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Ibadah GKJW Karangpilang',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isCategoryExpanded = !_isCategoryExpanded;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _isCategoryExpanded
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isCategoryExpanded ? 'Tutup Arsip' : 'Lihat Semua',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _isCategoryExpanded
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Row 2: Search bar (always visible) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Cari khotbah, judul, tanggal...',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: AppColors.textLight,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: AppColors.textLight,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),

            // ── Row 3: Inline Category Chips (animated) ──
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isCategoryExpanded
                  ? SizedBox(
                      height: 48,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 8,
                          bottom: 8,
                        ),
                        itemCount: _kategoriList.length,
                        itemBuilder: (context, index) {
                          final k = _kategoriList[index];
                          final isSelected = k['key'] == selectedKat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                ref
                                        .read(siaranKategoriProvider.notifier)
                                        .state =
                                    k['key'];
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  k['label'] as String,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            Expanded(
              child: siaranAsync.when(
                loading: () => Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: 4,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) => Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                error: (e, stack) =>
                    const Center(child: Text('Gagal memuat siaran')),
                data: (videos) {
                  final filteredVideos = _searchQuery.isEmpty
                      ? videos
                      : videos
                            .where(
                              (v) => v.judul.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ),
                            )
                            .toList();

                  return filteredVideos.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.live_tv_outlined,
                                size: 64,
                                color: AppColors.textLight,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Belum ada siaran',
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: filteredVideos.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) =>
                              _VideoCard(video: filteredVideos[index]),
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final VideoSiaran video;
  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMMM yyyy', 'id_ID').format(video.tanggal);
    final thumbUrl =
        'https://img.youtube.com/vi/${video.youtubeId}/mqdefault.jpg';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video thumbnail area
          GestureDetector(
            onTap: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (context) => SiaranDetailScreen(video: video),
                ),
              );
            },
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: thumbUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  memCacheWidth: 320,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: 200,
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.video_library,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.25),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatKategori(video.kategori),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  video.judul,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatKategori(String k) {
    return switch (k) {
      'umum' => 'Ibadah Umum',
      'anak' => 'Ibadah Anak',
      'remaja' => 'Ibadah Remaja',
      'sekolah_minggu' => 'Sekolah Minggu',
      _ => k,
    };
  }
}
