// lib/features/beranda/screens/beranda_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/content_models.dart';
import '../../../providers/providers.dart';

// Provider autoDispose → re-fetch setiap kali beranda dibuka
final bannerSlidesProvider = FutureProvider.autoDispose<List<BannerSlideModel>>(
  (ref) => ref.watch(contentServiceProvider).getBannerSlides(),
);

class BerandaScreen extends ConsumerStatefulWidget {
  const BerandaScreen({super.key});

  @override
  ConsumerState<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends ConsumerState<BerandaScreen> {
  final PageController _pageController = PageController();
  int _currentBannerIndex = 0;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      final banners = ref.read(bannerSlidesProvider).value;
      if (banners == null || banners.isEmpty) return;
      final next = (_currentBannerIndex + 1) % banners.length;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 3) return 'Selamat Malam';
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final bannerAsync = ref.watch(bannerSlidesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── HEADER GREETING ──
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo + sapaan (seperti header website)
                    Image.asset(
                      'assets/images/logo.png',
                      width: 52,
                      semanticLabel: 'Logo GKJW Karangpilang',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: TextStyle(
                              fontFamily: AppFonts.display,
                              color: AppColors.heading,
                              fontSize: 22,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Selamat Datang di GKJW Karangpilang',
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              color: AppColors.accentText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── BANNER CAROUSEL ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 0, bottom: 0),
              child: bannerAsync.when(
                data: (banners) {
                  if (banners.isEmpty) return const SizedBox.shrink();
                  return _BannerCarousel(
                    banners: banners,
                    pageController: _pageController,
                    currentIndex: _currentBannerIndex,
                    onPageChanged: (i) =>
                        setState(() => _currentBannerIndex = i),
                  );
                },
                loading: () => _BannerPlaceholder(),
                error: (_, p) => const SizedBox.shrink(),
              ),
            ),
          ),

          // ── MENU UTAMA ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Menu Utama',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.heading,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Card container menu
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.07),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _MenuItem(
                              icon: Icons.newspaper,
                              label: 'Warta\nJemaat',
                              accent: AppColors.navy900,
                              onTap: () => context.go('/beranda/warta'),
                            ),
                            _MenuItem(
                              icon: Icons.book,
                              label: 'Tata\nIbadah',
                              accent: AppColors.navy900,
                              onTap: () => context.go('/beranda/tata-ibadah'),
                            ),
                            _MenuItem(
                              icon: Icons.auto_stories,
                              label: 'Renungan\nYKB',
                              accent: AppColors.navy900,
                              onTap: () => context.go('/beranda/renungan'),
                            ),
                            _MenuItem(
                              icon: Icons.calendar_month,
                              label: 'Agenda\nGereja',
                              accent: AppColors.navy900,
                              onTap: () => context.go('/beranda/agenda'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _MenuItem(
                              icon: Icons.photo_library,
                              label: 'Galeri',
                              accent: AppColors.navy900,
                              onTap: () => context.go('/beranda/galeri'),
                            ),
                            _MenuItem(
                              icon: Icons.qr_code,
                              label: 'Persembahan',
                              accent: AppColors.navy900,
                              onTap: () => context.go('/beranda/persembahan'),
                            ),
                            _MenuItem(
                              icon: Icons.library_books,
                              label: 'E-Perpus',
                              accent: AppColors.navy900,
                              onTap: () => context.go('/beranda/eperpus'),
                            ),
                            _MenuItem(
                              icon: Icons.lightbulb,
                              label: 'Inspirasi',
                              accent: AppColors.navy900,
                              onTap: () => context.go('/beranda/inspirasi'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── FIRMAN HARI INI ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Firman Hari Ini',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    // Terang: kartu cream-emas. Gelap: kartu navy.
                    decoration: AppColors.isDark
                        ? BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.navy700, AppColors.navy900],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.line),
                          )
                        : BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.gold500.withValues(alpha: 0.16),
                                AppColors.gold500.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.gold500.withValues(alpha: 0.3)),
                          ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.gold500.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.format_quote,
                                color: AppColors.secondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Firman Hari Ini',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontWeight: FontWeight.w600,
                                color: AppColors.heading,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '"Sebab Aku ini mengetahui rancangan-rancangan apa yang ada pada-Ku mengenai kamu, demikianlah firman TUHAN, yaitu rancangan damai sejahtera dan bukan rancangan kecelakaan, untuk memberikan kepadamu hari depan yang penuh harapan."',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.6,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '— Yeremia 29:11',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 12,
                              color: AppColors.accentText,
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
          ),

          SliverPadding(
            padding: const EdgeInsets.only(bottom: 100),
            sliver: SliverToBoxAdapter(child: const SizedBox(height: 28)),
          ),
        ],
      ),
    );
  }
}

// ── BANNER CAROUSEL ──────────────────────────────────────────────
class _BannerCarousel extends StatelessWidget {
  final List<BannerSlideModel> banners;
  final PageController pageController;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const _BannerCarousel({
    required this.banners,
    required this.pageController,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Slide image area — ratio 16:9 (landscape banner)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: PageView.builder(
              controller: pageController,
              onPageChanged: onPageChanged,
              itemCount: banners.length,
              itemBuilder: (context, index) {
                final banner = banners[index];
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: banner.imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 800,
                      placeholder: (context, url) => Container(
                        color: AppColors.tint,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.secondary,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.tint,
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.textLight,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Dot indicator + counter
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...List.generate(banners.length, (i) {
              final isActive = i == currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
            const SizedBox(width: 8),
            Text(
              '${currentIndex + 1}/${banners.length}',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 11,
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── BANNER PLACEHOLDER (saat loading) ──
class _BannerPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: AppColors.tint,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.secondary,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── MENU ITEM ──
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent; // warna ikon di tema terang
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            // Terang: tile cream + ikon navy/emas. Gelap: tile biru navy + ikon cream.
            decoration: AppColors.isDark
                ? BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.navy700, AppColors.navy800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                  )
                : BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accent.withValues(alpha: 0.28)),
                  ),
            child: Icon(icon, color: AppColors.isDark ? AppColors.ivory50 : accent, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
