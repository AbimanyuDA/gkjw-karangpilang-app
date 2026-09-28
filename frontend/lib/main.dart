// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/config/api_config.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/utils/app_router.dart';
import 'data/api/api_client.dart';
import 'providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize locale for intl (Indonesian date formatting)
  await initializeDateFormatting('id_ID', null);

  // Tema: pilihan pengguna (tombol di bar navigasi) atau mengikuti HP.
  final themeController = await ThemeController.load();
  AppColors.use(_paletteFor(themeController.effectiveBrightness(
      WidgetsBinding.instance.platformDispatcher.platformBrightness)));

  // Klien API backend (hanya baca; konten dikelola di website admin)
  final api = ApiClient(baseUrl: ApiConfig.apiUrl);

  runApp(ProviderScope(
    overrides: [
      apiClientProvider.overrideWithValue(api),
      themeControllerProvider.overrideWithValue(themeController),
    ],
    child: GkjwApp(router: createAppRouter(), themeController: themeController),
  ));
}

AppPalette _paletteFor(Brightness b) =>
    b == Brightness.dark ? AppPalette.dark : AppPalette.light;

/// Tema terang = cream/emas, gelap = navy. Default mengikuti HP;
/// pengguna bisa memilih sendiri lewat tombol kecil di bar navigasi.
class GkjwApp extends StatefulWidget {
  const GkjwApp({super.key, required this.router, required this.themeController});

  final GoRouter router;
  final ThemeController themeController;

  @override
  State<GkjwApp> createState() => _GkjwAppState();
}

class _GkjwAppState extends State<GkjwApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.themeController.addListener(_applyTheme);
  }

  @override
  void dispose() {
    widget.themeController.removeListener(_applyTheme);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Tema HP berubah saat aplikasi terbuka (berpengaruh bila mode = ikuti HP).
  @override
  void didChangePlatformBrightness() => _applyTheme();

  void _applyTheme() {
    final palette = _paletteFor(widget.themeController.effectiveBrightness(
        WidgetsBinding.instance.platformDispatcher.platformBrightness));
    if (palette == AppColors.palette) return;
    AppColors.use(palette);
    setState(() {});
    // Banyak widget membaca AppColors langsung; gambar ulang semua layar
    // agar warna baru langsung terpakai (state/navigasi tetap).
    WidgetsBinding.instance.reassembleApplication();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Ikon status bar: gelap di tema terang, terang di tema gelap.
      value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      child: MaterialApp.router(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: widget.themeController.mode,
        routerConfig: widget.router,
        debugShowCheckedModeBanner: false,
        locale: const Locale('id', 'ID'),
        supportedLocales: const [
          Locale('id', 'ID'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
