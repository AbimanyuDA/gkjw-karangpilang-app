// lib/features/auth/screens/splash_screen.dart
// Animasi pembuka. Dimulai dari tampilan yang sama dengan splash native
// (latar cream + logo 140 dp di tengah), jadi peralihannya tidak terlihat:
//   1. kilau emas menyapu logo
//   2. logo naik, lalu "GKJW / KARANGPILANG" dan semboyan muncul
//   3. masuk ke beranda
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const _logoSize = 140.0; // sama dengan logo di splash native
  static const _total = Duration(milliseconds: 2600);

  /// Jarak pusat logo ke pusat layar saat teks sudah tampil (tinggi kolom / 2 − logo / 2).
  /// Dengan geseran ini logo mulai persis di tengah, seperti splash native.
  static const _startOffset = 88.0;

  late final AnimationController _controller = AnimationController(vsync: this, duration: _total);

  // Tiap tahap memakai potongan waktu (Interval) dari satu controller.
  late final Animation<double> _shine = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.05, 0.45, curve: Curves.easeInOut),
  );
  late final Animation<double> _lift = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.30, 0.62, curve: Cubic(0.16, 1, 0.3, 1)), // ease-out-expo website
  );
  late final Animation<double> _title = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.42, 0.72, curve: Curves.easeOut),
  );
  late final Animation<double> _motto = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.58, 0.85, curve: Curves.easeOut),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    // Hormati pengaturan "kurangi animasi" di HP.
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
      Future.delayed(const Duration(milliseconds: 600), _goHome);
      return;
    }
    _controller.forward().whenComplete(() => Future.delayed(const Duration(milliseconds: 250), _goHome));
  }

  void _goHome() {
    if (mounted) context.go('/beranda');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              // Cahaya emas lembut di belakang logo — atmosfer, bukan dekorasi ramai.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.12),
                      radius: 0.75,
                      colors: [
                        AppColors.gold300.withValues(alpha: 0.28 * _lift.value),
                        AppColors.background.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.translate(
                      offset: Offset(0, _startOffset * (1 - _lift.value)), // mulai tepat di tengah layar
                      child: Transform.scale(
                        scale: 1 + 0.12 * _lift.value,
                        child: _ShiningLogo(size: _logoSize, progress: _shine.value),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _Reveal(
                      progress: _title.value,
                      child: const Column(
                        children: [
                          Text(
                            'GKJW',
                            style: TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 40,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy900,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'KARANGPILANG',
                            style: TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentText,
                              letterSpacing: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _Reveal(
                      progress: _motto.value,
                      child: Column(
                        children: [
                          Container(width: 36, height: 2, color: AppColors.gold500),
                          const SizedBox(height: 14),
                          const Text(
                            '“Patembayan Kang Nyawiji”',
                            style: TextStyle(
                              fontFamily: AppFonts.display,
                              fontStyle: FontStyle.italic,
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Greja Kristen Jawi Wetan',
                            style: TextStyle(
                              fontFamily: AppFonts.body,
                              fontSize: 12,
                              letterSpacing: 1.5,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Logo dengan kilau emas yang menyapu diagonal satu kali.
class _ShiningLogo extends StatelessWidget {
  const _ShiningLogo({required this.size, required this.progress});

  final double size;
  final double progress; // 0 → 1

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/images/logo.png',
      width: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Logo GKJW Karangpilang',
    );
    if (progress <= 0 || progress >= 1) return logo;

    final x = -1.6 + 3.2 * progress; // pita cahaya bergerak dari kiri ke kanan
    return Stack(
      alignment: Alignment.center,
      children: [
        logo,
        ShaderMask(
          blendMode: BlendMode.srcATop, // hanya pada bagian logo yang tidak transparan
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(x - 0.35, -1),
            end: Alignment(x + 0.35, 1),
            colors: [
              Colors.white.withValues(alpha: 0),
              AppColors.gold300.withValues(alpha: 0.75),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(rect),
          child: logo,
        ),
      ],
    );
  }
}

/// Fade + geser naik sedikit — pola "reveal" yang sama dengan website.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress,
      child: Transform.translate(offset: Offset(0, 14 * (1 - progress)), child: child),
    );
  }
}
