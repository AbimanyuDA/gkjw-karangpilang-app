// lib/features/informasi/screens/informasi_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class InformasiScreen extends StatefulWidget {
  const InformasiScreen({super.key});

  @override
  State<InformasiScreen> createState() => _InformasiScreenState();
}

class _InformasiScreenState extends State<InformasiScreen> {
  bool notificationMorning = false;
  bool notificationEvening = false;
  bool notificationChurch = false;
  bool notificationHistory = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        centerTitle: true,
        title: const Text(
          'Pengaturan',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Logo dan Info Aplikasi
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.church,
                          size: 50,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'GKJW Karangpilang+',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Versi 1.0',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // NOTIFIKASI Section
                const _SectionHeader(title: 'NOTIFIKASI'),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _NotificationToggle(
                          icon: Icons.wb_sunny,
                          title: 'Sapaan Pagi',
                          value: notificationMorning,
                          onChanged: (value) {
                            setState(() => notificationMorning = value);
                          },
                          color: const Color(0xFFFFA500),
                        ),
                        const Divider(height: 24),
                        _NotificationToggle(
                          icon: Icons.nights_stay,
                          title: 'Sapaan Malam',
                          value: notificationEvening,
                          onChanged: (value) {
                            setState(() => notificationEvening = value);
                          },
                          color: const Color(0xFF4A90E2),
                        ),
                        const Divider(height: 24),
                        _NotificationToggle(
                          icon: Icons.location_on,
                          title: 'Area Gereja',
                          value: notificationChurch,
                          onChanged: (value) {
                            setState(() => notificationChurch = value);
                          },
                          color: const Color(0xFF27AE60),
                        ),
                        const Divider(height: 24),
                        _NotificationToggle(
                          icon: Icons.notifications,
                          title: 'Riwayat Notifikasi',
                          value: notificationHistory,
                          onChanged: (value) {
                            setState(() => notificationHistory = value);
                          },
                          hasArrow: true,
                          onTap: () => context.go('/informasi/notifikasi'),
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // HUBUNGI KAMI Section
                const _SectionHeader(title: 'HUBUNGI KAMI'),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _ContactItem(
                          icon: Icons.phone,
                          title: 'WhatsApp Admin',
                          onTap: () {},
                          color: const Color(0xFF25D366),
                        ),
                        const Divider(height: 20),
                        _ContactItem(
                          icon: Icons.email,
                          title: 'Email Sekretariat',
                          subtitle: 'info.gkisalatiga@gmail.com',
                          onTap: () {},
                          color: const Color(0xFFEA4335),
                        ),
                        const Divider(height: 20),
                        _ContactItem(
                          icon: Icons.location_on_outlined,
                          title: 'Lokasi Gereja',
                          subtitle:
                              'Jl. Jend. Sudirman 111B, Salatiga, 50742, J...',
                          onTap: () => context.go('/informasi/hubungi'),
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // TENTANG APLIKASI Section
                const _SectionHeader(title: 'TENTANG APLIKASI'),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _AboutItem(
                          icon: Icons.description,
                          title: 'Catatan Perubahan',
                          onTap: () {},
                          color: const Color(0xFF9C27B0),
                        ),
                        const Divider(height: 20),
                        _AboutItem(
                          icon: Icons.code,
                          title: 'Kode Sumber (GitHub)',
                          onTap: () {},
                          color: const Color(0xFF424242),
                        ),
                        const Divider(height: 20),
                        _AboutItem(
                          icon: Icons.build,
                          title: 'Hubungi Pengembang',
                          subtitle: 'dev.gkisalatiga@gmail.com',
                          onTap: () {},
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// Section Header Widget
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

// Notification Toggle Widget
class _NotificationToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool hasArrow;
  final VoidCallback? onTap;
  final Color color;

  const _NotificationToggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.hasArrow = false,
    this.onTap,
    this.color = AppColors.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        if (hasArrow)
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20)
        else
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              inactiveTrackColor: Colors.grey[300],
            ),
          ),
      ],
    );
  }
}

// Contact Item Widget
class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color color;

  const _ContactItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.color = AppColors.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}

// About Item Widget
class _AboutItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color color;

  const _AboutItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.color = AppColors.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}
