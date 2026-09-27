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
import 'core/utils/app_router.dart';
import 'data/api/api_client.dart';
import 'data/services/auth_controller.dart';
import 'providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize locale for intl (Indonesian date formatting)
  await initializeDateFormatting('id_ID', null);

  // Sesi admin + klien API backend
  final auth = AuthController(storage: const SecureTokenStorage());
  await auth.restore();
  final api = ApiClient(
    baseUrl: ApiConfig.apiUrl,
    tokenReader: () => auth.token,
    onUnauthorized: auth.logout, // token kedaluwarsa/dicabut → kembali ke mode jemaat
  );

  runApp(ProviderScope(
    overrides: [
      authControllerProvider.overrideWithValue(auth),
      apiClientProvider.overrideWithValue(api),
    ],
    child: GkjwApp(router: createAppRouter(auth)),
  ));
}

class GkjwApp extends StatelessWidget {
  const GkjwApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      // ✅ Delegate wajib untuk support locale id_ID
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
