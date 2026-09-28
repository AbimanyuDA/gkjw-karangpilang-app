// lib/core/theme/app_theme.dart
// Palet & tipografi mengikuti website GKJW Karangpilang (GKJW-LandingPage/src/styles/tokens.css).
//
//   Tema TERANG  → cream/ivory dominan, teks navy, aksen emas.
//   Tema GELAP   → navy dominan (seperti mode gelap website), teks ivory, aksen emas.
//
// Tema mengikuti pengaturan HP. Seluruh layar membaca warna lewat `AppColors.*`,
// yang menunjuk ke palet aktif (diatur di main.dart saat tema HP berubah).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppFonts {
  AppFonts._();

  /// Teks isi — Plus Jakarta Sans (sama dengan website).
  static const String body = 'PlusJakartaSans';

  /// Judul — Source Serif 4 (sama dengan website).
  static const String display = 'SourceSerif4';
}

/// Kumpulan warna untuk satu tema.
@immutable
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.secondary,
    required this.accentText,
    required this.heading,
    required this.background,
    required this.surface,
    required this.cardBg,
    required this.surfaceAlt,
    required this.tint,
    required this.line,
    required this.textPrimary,
    required this.textSecondary,
    required this.textLight,
    required this.success,
    required this.error,
  });

  final Brightness brightness;

  /// Warna utama untuk ikon, penekanan, dan latar tombol/kartu penting.
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;

  /// Aksen emas (tombol utama, penanda aktif).
  final Color secondary;

  /// Teks beraksen emas yang tetap terbaca di atas latar.
  final Color accentText;

  /// Warna judul.
  final Color heading;

  final Color background;
  final Color surface;
  final Color cardBg;
  final Color surfaceAlt;

  /// Latar lembut untuk ikon/chip (emas tipis di terang, biru di gelap).
  final Color tint;
  final Color line;

  final Color textPrimary;
  final Color textSecondary;
  final Color textLight;

  final Color success;
  final Color error;

  bool get isDark => brightness == Brightness.dark;

  /// TERANG — cream, putih, emas.
  static const light = AppPalette(
    brightness: Brightness.light,
    primary: AppColors.navy900,
    primaryDark: AppColors.navy950,
    primaryLight: AppColors.navy700,
    secondary: AppColors.gold500,
    accentText: AppColors.gold700,
    heading: AppColors.navy900,
    background: AppColors.ivory100,
    surface: AppColors.ivory50,
    cardBg: AppColors.ivory50,
    surfaceAlt: AppColors.ivory200,
    tint: Color(0x29D9A23A), // gold-500 @ 16%
    line: Color(0x1716202E), // ink-900 @ 9%
    textPrimary: Color(0xFF16202E),
    textSecondary: Color(0xFF3A4658),
    textLight: Color(0xFF677285),
    success: Color(0xFF2E7D4F),
    error: Color(0xFFB3261E),
  );

  /// GELAP — navy (nilai dari tema gelap website).
  static const dark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF6F9BDC), // biru terang: terbaca di atas navy
    primaryDark: AppColors.navy700,
    primaryLight: Color(0xFF9DBCEA),
    secondary: Color(0xFFE9BD55), // gold-400
    accentText: Color(0xFFE9BD55),
    heading: AppColors.ivory50,
    background: Color(0xFF0A1422),
    surface: Color(0xFF0E1A2C),
    cardBg: Color(0xFF15233A),
    surfaceAlt: Color(0xFF1A2C49),
    tint: Color(0xFF1C3A63),
    line: Color(0x1FF3D58A), // gold-300 @ 12%
    textPrimary: Color(0xFFECE6D8),
    textSecondary: Color(0xFFC2BDB0),
    textLight: Color(0xFF9AA2B1),
    success: Color(0xFF81C995),
    error: Color(0xFFF2B8B5),
  );
}

class AppColors {
  AppColors._();

  // ── Palet dasar website (tetap, tidak ikut tema) ──
  static const Color navy950 = Color(0xFF06142A);
  static const Color navy900 = Color(0xFF0B1F3A);
  static const Color navy800 = Color(0xFF122B4D);
  static const Color navy700 = Color(0xFF1C3A63);
  static const Color gold300 = Color(0xFFF3D58A);
  static const Color gold500 = Color(0xFFD9A23A);
  static const Color gold600 = Color(0xFFB5842A);
  static const Color gold700 = Color(0xFF8A6420);
  static const Color ivory50 = Color(0xFFFDFAF3);
  static const Color ivory100 = Color(0xFFF8F2E4);
  static const Color ivory200 = Color(0xFFEFE5CF);

  // ── Palet aktif (berganti mengikuti tema HP) ──
  static AppPalette _palette = AppPalette.light;
  static AppPalette get palette => _palette;
  static bool get isDark => _palette.isDark;

  /// Dipanggil di main.dart saat tema HP berubah.
  static void use(AppPalette palette) => _palette = palette;

  // ── Peran (dipakai di seluruh aplikasi) ──
  static Color get primary => _palette.primary;
  static Color get primaryDark => _palette.primaryDark;
  static Color get primaryLight => _palette.primaryLight;
  static Color get secondary => _palette.secondary;
  static Color get secondaryLight => gold300;
  static Color get accentText => _palette.accentText;
  static Color get heading => _palette.heading;

  static Color get background => _palette.background;
  static Color get surface => _palette.surface;
  static Color get cardBg => _palette.cardBg;
  static Color get surfaceAlt => _palette.surfaceAlt;
  static Color get tint => _palette.tint;
  static Color get line => _palette.line;

  static Color get textPrimary => _palette.textPrimary;
  static Color get textSecondary => _palette.textSecondary;
  static Color get textLight => _palette.textLight;

  static Color get success => _palette.success;
  static Color get error => _palette.error;
  static Color get warning => gold600;
  static Color get info => _palette.primary;

  /// Header/kartu gelap (navy di kedua tema).
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [navy800, navy950],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [navy800, navy900, navy950],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [gold300, gold500],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTheme {
  AppTheme._();

  static const _serif = AppFonts.display;
  static const _sans = AppFonts.body;

  static ThemeData get lightTheme => _build(AppPalette.light);
  static ThemeData get darkTheme => _build(AppPalette.dark);

  static ThemeData _build(AppPalette p) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy900,
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.isDark ? AppColors.navy950 : AppColors.ivory50,
      secondary: p.secondary,
      onSecondary: AppColors.navy900,
      surface: p.surface,
      onSurface: p.textPrimary,
      error: p.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      fontFamily: _sans,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      dividerColor: p.line,
      canvasColor: p.surface,

      // Header polos (cream / navy) dengan judul serif — seperti header website.
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: p.heading,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: p.line,
        centerTitle: true,
        systemOverlayStyle: p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        shape: Border(bottom: BorderSide(color: p.line)),
        titleTextStyle: TextStyle(
          fontFamily: _serif,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: p.heading,
        ),
        iconTheme: IconThemeData(color: p.heading),
      ),

      cardTheme: CardThemeData(
        color: p.cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: p.isDark ? 0 : 1,
        shadowColor: AppColors.navy900.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: p.line),
        ),
      ),

      // Tombol utama: emas dengan teks navy (seperti "Jadwal Ibadah" di website).
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.secondary,
          foregroundColor: AppColors.navy900,
          disabledBackgroundColor: p.surfaceAlt,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontFamily: _sans, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.heading,
          side: BorderSide(color: p.heading),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontFamily: _sans, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: const TextStyle(fontFamily: _sans, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.secondary, width: 2),
        ),
        labelStyle: TextStyle(fontFamily: _sans, color: p.textSecondary),
        prefixIconColor: p.textLight,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: _serif,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: p.heading,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.navy900,
        contentTextStyle: TextStyle(fontFamily: _sans, color: AppColors.ivory50),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.secondary,
        linearTrackColor: p.surfaceAlt,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.navy900 : p.textLight,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.secondary : p.surfaceAlt,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.cardBg,
        selectedColor: p.secondary,
        side: BorderSide(color: p.line),
        labelStyle: TextStyle(fontFamily: _sans, color: p.textPrimary),
        secondaryLabelStyle: const TextStyle(fontFamily: _sans, color: AppColors.navy900),
        shape: const StadiumBorder(),
      ),

      // Judul serif, isi sans — pasangan yang sama dengan website.
      textTheme: TextTheme(
        displayLarge: TextStyle(fontFamily: _serif, fontSize: 34, fontWeight: FontWeight.w700, color: p.heading),
        headlineLarge: TextStyle(fontFamily: _serif, fontSize: 26, fontWeight: FontWeight.w700, color: p.heading),
        headlineMedium: TextStyle(fontFamily: _serif, fontSize: 22, fontWeight: FontWeight.w700, color: p.heading),
        titleLarge: TextStyle(fontFamily: _serif, fontSize: 19, fontWeight: FontWeight.w700, color: p.heading),
        titleMedium: TextStyle(fontFamily: _sans, fontSize: 16, fontWeight: FontWeight.w600, color: p.textPrimary),
        bodyLarge: TextStyle(fontFamily: _sans, fontSize: 15, fontWeight: FontWeight.w400, color: p.textPrimary),
        bodyMedium: TextStyle(fontFamily: _sans, fontSize: 13, fontWeight: FontWeight.w400, color: p.textSecondary),
        labelLarge: TextStyle(fontFamily: _sans, fontSize: 14, fontWeight: FontWeight.w600, color: p.textPrimary),
      ),
    );
  }
}
