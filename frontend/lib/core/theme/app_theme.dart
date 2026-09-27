// lib/core/theme/app_theme.dart
// Palet & tipografi mengikuti website GKJW Karangpilang (GKJW-LandingPage/src/styles/tokens.css):
// dominan cream/ivory, navy untuk teks & elemen utama, emas sebagai aksen.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppFonts {
  AppFonts._();

  /// Teks isi — Plus Jakarta Sans (sama dengan website).
  static const String body = 'PlusJakartaSans';

  /// Judul — Source Serif 4 (sama dengan website).
  static const String display = 'SourceSerif4';
}

class AppColors {
  AppColors._();

  // ── Palet dasar (token website) ──
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

  // ── Peran (dipakai di seluruh aplikasi) ──
  /// Warna utama: navy — teks penting, ikon, tombol sekunder, header gelap.
  static const Color primary = navy900;
  static const Color primaryDark = navy950;
  static const Color primaryLight = navy700;

  /// Aksen emas — tombol utama, penanda aktif.
  static const Color secondary = gold500;
  static const Color secondaryLight = gold300;
  static const Color secondaryDark = gold600;

  /// Teks emas di atas cream (kontras cukup untuk dibaca).
  static const Color accentText = gold700;

  // Latar
  static const Color background = ivory100; // cream — warna dominan
  static const Color surface = ivory50;
  static const Color cardBg = ivory50;
  static const Color surfaceAlt = ivory200;
  static const Color line = Color(0x1716202E); // ink-900 @ 9%

  // Teks
  static const Color textPrimary = Color(0xFF16202E);
  static const Color textSecondary = Color(0xFF3A4658);
  static const Color textLight = Color(0xFF677285);

  // Status
  static const Color success = Color(0xFF2E7D4F);
  static const Color error = Color(0xFFB3261E);
  static const Color warning = Color(0xFFB5842A);
  static const Color info = navy700;

  // Gradien (header gelap seperti hero website mode gelap)
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

  static ThemeData get lightTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy900,
      primary: AppColors.navy900,
      onPrimary: AppColors.ivory50,
      secondary: AppColors.gold500,
      onSecondary: AppColors.navy900,
      surface: AppColors.ivory50,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: _sans,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      dividerColor: AppColors.line,

      // Header cream dengan teks navy — seperti header website.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ivory50,
        foregroundColor: AppColors.navy900,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.line,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        shape: Border(bottom: BorderSide(color: AppColors.line)),
        titleTextStyle: TextStyle(
          fontFamily: _serif,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.navy900,
        ),
        iconTheme: IconThemeData(color: AppColors.navy900),
      ),

      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: AppColors.navy900.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.line),
        ),
      ),

      // Tombol utama: emas dengan teks navy (seperti "Jadwal Ibadah" di website).
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold500,
          foregroundColor: AppColors.navy900,
          disabledBackgroundColor: AppColors.ivory200,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontFamily: _sans, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy900,
          side: const BorderSide(color: AppColors.navy900),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontFamily: _sans, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.navy800,
          textStyle: const TextStyle(fontFamily: _sans, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold500,
        foregroundColor: AppColors.navy900,
        elevation: 3,
        extendedTextStyle: TextStyle(fontFamily: _sans, fontWeight: FontWeight.w700),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.ivory200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.ivory200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold600, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(fontFamily: _sans, color: AppColors.textSecondary),
        floatingLabelStyle: const TextStyle(fontFamily: _sans, color: AppColors.accentText),
        prefixIconColor: AppColors.textLight,
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.ivory50,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: _serif,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.navy900,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.navy900,
        contentTextStyle: TextStyle(fontFamily: _sans, color: AppColors.ivory50),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold600,
        linearTrackColor: AppColors.ivory200,
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.ivory50,
        selectedColor: AppColors.navy900,
        side: BorderSide(color: AppColors.ivory200),
        labelStyle: TextStyle(fontFamily: _sans, color: AppColors.navy900),
        secondaryLabelStyle: TextStyle(fontFamily: _sans, color: AppColors.ivory50),
        shape: StadiumBorder(),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.ivory50,
        selectedItemColor: AppColors.navy900,
        unselectedItemColor: AppColors.textLight,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: TextStyle(fontFamily: _sans, fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontFamily: _sans, fontSize: 11),
      ),

      // Judul serif navy, isi sans — pasangan yang sama dengan website.
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: _serif, fontSize: 34, fontWeight: FontWeight.w700, color: AppColors.navy900),
        headlineLarge: TextStyle(fontFamily: _serif, fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.navy900),
        headlineMedium: TextStyle(fontFamily: _serif, fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.navy900),
        titleLarge: TextStyle(fontFamily: _serif, fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.navy900),
        titleMedium: TextStyle(fontFamily: _sans, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        bodyLarge: TextStyle(fontFamily: _sans, fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontFamily: _sans, fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        labelLarge: TextStyle(fontFamily: _sans, fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
    );
  }
}
