// lib/core/utils/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/beranda/screens/beranda_screen.dart';
import '../../features/beranda/screens/warta_screen.dart';
import '../../features/beranda/screens/tata_ibadah_screen.dart';
import '../../features/beranda/screens/renungan_screen.dart';
import '../../features/beranda/screens/agenda_screen.dart';
import '../../features/beranda/screens/galeri_screen.dart';
import '../../features/beranda/screens/persembahan_screen.dart';
import '../../features/beranda/screens/eperpus_screen.dart';
import '../../features/beranda/screens/inspirasi_screen.dart';
import '../../features/siaran/screens/siaran_screen.dart';
import '../../features/gereja/screens/gereja_screen.dart';
import '../../features/gereja/screens/informasi_gereja_screen.dart';
import '../../features/gereja/screens/kependetaan_screen.dart';
import '../../features/gereja/screens/kemajelisan_screen.dart';
import '../../features/gereja/screens/bpm_screen.dart';
import '../../features/gereja/screens/perwilayahan_screen.dart';
import '../../features/gereja/screens/profil_ruangan_screen.dart';
import '../../features/informasi/screens/informasi_screen.dart';
import '../../features/informasi/screens/notifikasi_screen.dart';
import '../../features/informasi/screens/hubungi_kami_screen.dart';
import '../../features/informasi/screens/tentang_screen.dart';
import '../../features/informasi/screens/faq_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_gereja_cover_screen.dart';
import '../widgets/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isAuth = user != null;
    final loc = state.matchedLocation;

    // Splash selalu diizinkan
    if (loc == '/splash') return null;

    // Admin route hanya untuk yang login
    if (loc.startsWith('/admin') && !isAuth) return '/login';

    // Jika sudah login lalu ke login → redirect ke beranda
    if (isAuth && loc == '/login') return '/beranda';

    // Jemaat (belum login) boleh akses semua KECUALI /admin
    // → Login hanya pintu masuk admin, bukan jemaat biasa
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/beranda',
          pageBuilder: (context, state) => const NoTransitionPage(child: BerandaScreen()),
          routes: [
            GoRoute(path: 'warta', builder: (c, s) => const WartaScreen()),
            GoRoute(path: 'tata-ibadah', builder: (c, s) => const TataIbadahScreen()),
            GoRoute(path: 'renungan', builder: (c, s) => const RenunganScreen()),
            GoRoute(path: 'agenda', builder: (c, s) => const AgendaScreen()),
            GoRoute(path: 'galeri', builder: (c, s) => const GaleriScreen()),
            GoRoute(path: 'persembahan', builder: (c, s) => const PersembahanScreen()),
            GoRoute(path: 'eperpus', builder: (c, s) => const EperpusScreen()),
            GoRoute(path: 'inspirasi', builder: (c, s) => const InspirasiScreen()),
          ],
        ),
        GoRoute(
          path: '/siaran',
          pageBuilder: (context, state) => const NoTransitionPage(child: SiaranScreen()),
        ),
        GoRoute(
          path: '/gereja',
          pageBuilder: (context, state) => const NoTransitionPage(child: GerejaScreen()),
          routes: [
            GoRoute(path: 'informasi', builder: (c, s) => const InformasiGerejaScreen()),
            GoRoute(path: 'kependetaan', builder: (c, s) => const KependetaanScreen()),
            GoRoute(path: 'kemajelisan', builder: (c, s) => const KemajelisanScreen()),
            GoRoute(path: 'bpm', builder: (c, s) => const BpmScreen()),
            GoRoute(path: 'perwilayahan', builder: (c, s) => const PerwilayahanScreen()),
            GoRoute(path: 'profil-ruangan', builder: (c, s) => const ProfilRuanganScreen()),
          ],
        ),
        GoRoute(
          path: '/informasi',
          pageBuilder: (context, state) => const NoTransitionPage(child: InformasiScreen()),
          routes: [
            GoRoute(path: 'notifikasi', builder: (c, s) => const NotifikasiScreen()),
            GoRoute(path: 'hubungi', builder: (c, s) => const HubungiKamiScreen()),
            GoRoute(path: 'tentang', builder: (c, s) => const TentangScreen()),
            GoRoute(path: 'faq', builder: (c, s) => const FaqScreen()),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
      routes: [
        GoRoute(
          path: 'gereja-cover',
          builder: (c, s) => const AdminGerejaCoverScreen(),
        ),
      ],
    ),
  ],
);
