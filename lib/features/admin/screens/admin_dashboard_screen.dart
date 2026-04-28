// lib/features/admin/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import 'admin_pdf_screen.dart';
import 'admin_agenda_screen.dart';
import 'admin_siaran_screen.dart';
import 'admin_galeri_screen.dart';
import 'admin_notifikasi_screen.dart';
import 'admin_banner_screen.dart';
import 'admin_gereja_cover_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Panel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/beranda'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Konfirmasi Logout'),
                  content: const Text('Yakin ingin keluar dari admin panel?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) context.go('/beranda');
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card admin
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: const Icon(Icons.admin_panel_settings,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Admin Panel',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          user.email ?? '',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'GKJW Karangpilang',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── KONTEN FIRESTORE ──
            _SectionHeader(title: 'Konten Ibadah', icon: Icons.church),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _AdminCard(
                  icon: Icons.newspaper,
                  title: 'Warta Jemaat',
                  color: const Color(0xFF8B1A2F),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminPdfScreen(
                          koleksi: PdfKoleksi.warta),
                    ),
                  ),
                ),
                _AdminCard(
                  icon: Icons.book,
                  title: 'Tata Ibadah',
                  color: const Color(0xFF1565C0),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminPdfScreen(
                          koleksi: PdfKoleksi.tataIbadah),
                    ),
                  ),
                ),
                _AdminCard(
                  icon: Icons.auto_stories,
                  title: 'Renungan',
                  color: const Color(0xFF2E7D32),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminPdfScreen(
                          koleksi: PdfKoleksi.renungan),
                    ),
                  ),
                ),
                _AdminCard(
                  icon: Icons.live_tv,
                  title: 'Video Siaran',
                  color: const Color(0xFFE53935),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminSiaranScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── KONTEN SUPABASE ──
            _SectionHeader(title: 'Konten Jemaat', icon: Icons.people),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _AdminCard(
                  icon: Icons.view_carousel,
                  title: 'Banner Slide',
                  subtitle: 'Foto carousel beranda',
                  color: const Color(0xFF8B1A2F),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminBannerScreen()),
                  ),
                ),
                _AdminCard(
                  icon: Icons.calendar_month,
                  title: 'Agenda',
                  color: const Color(0xFFF57C00),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminAgendaScreen()),
                  ),
                ),
                _AdminCard(
                  icon: Icons.photo_library,
                  title: 'Galeri',
                  color: const Color(0xFF6A1B9A),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminGaleriScreen()),
                  ),
                ),
                _AdminCard(
                  icon: Icons.notifications,
                  title: 'Notifikasi',
                  color: const Color(0xFFE74C3C),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminNotifikasiScreen()),
                  ),
                ),
                _AdminCard(
                  icon: Icons.library_books,
                  title: 'E-Perpus',
                  color: const Color(0xFF00796B),
                  onTap: () => _showComingSoon(context, 'E-Perpus'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── PROFIL GEREJA ──
            _SectionHeader(title: 'Profil Gereja', icon: Icons.account_balance),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _AdminCard(
                  icon: Icons.church_outlined,
                  title: 'Cover',
                  color: const Color(0xFF8B1A2F),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminGerejaCoverScreen()),
                  ),
                ),
                _AdminCard(
                  icon: Icons.people,
                  title: 'Kependetaan',
                  color: const Color(0xFF00695C),
                  onTap: () => _showComingSoon(context, 'Kependetaan'),
                ),
                _AdminCard(
                  icon: Icons.groups,
                  title: 'Kemajelisan',
                  color: const Color(0xFF37474F),
                  onTap: () => _showComingSoon(context, 'Kemajelisan'),
                ),
                _AdminCard(
                  icon: Icons.help_outline,
                  title: 'FAQ',
                  color: const Color(0xFF0288D1),
                  onTap: () => _showComingSoon(context, 'FAQ'),
                ),
                _AdminCard(
                  icon: Icons.info_outline,
                  title: 'Info Gereja',
                  color: const Color(0xFF5C6BC0),
                  onTap: () => _showComingSoon(context, 'Info Gereja'),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String fitur) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fitur "$fitur" segera hadir'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
              if (subtitle != null) ...
                [
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      color: AppColors.textLight,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
