// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_router.dart';
import 'firebase_options.dart';
import 'data/services/notification_service.dart';
import 'data/services/sapaan_preference_service.dart';
import 'data/services/supabase_service.dart';

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
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize locale for intl (Indonesian date formatting)
  await initializeDateFormatting('id_ID', null);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Initialize notifications
  await NotificationService().initialize();

  // Re-schedule notifications based on saved preferences
  try {
    final prefService = SapaanPreferenceService();
    final pagiEnabled = await prefService.getSapaanPagiEnabled();
    final malamEnabled = await prefService.getSapaanMalamEnabled();

    if (pagiEnabled || malamEnabled) {
      final config = await SupabaseService().getSapaanConfig();
      if (config != null) {
        if (pagiEnabled) {
          await NotificationService().scheduleSapaanPagi(config);
        }
        if (malamEnabled) {
          await NotificationService().scheduleSapaanMalam(config);
        }
      }
    }
  } catch (e) {
    // If fetch fails, keep existing scheduled notifications unchanged
    debugPrint('Failed to reschedule notifications on startup: $e');
  }

  runApp(const ProviderScope(child: GkjwApp()));
}

class GkjwApp extends StatelessWidget {
  const GkjwApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
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
