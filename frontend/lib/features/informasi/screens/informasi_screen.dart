// lib/features/informasi/screens/informasi_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';

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
        title: Text(
          'Pengaturan',
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.heading,
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
                      // Logo polos, tanpa latar
                      Image.asset(
                        'assets/images/logo.png',
                        width: 96,
                        semanticLabel: 'Logo GKJW Karangpilang',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'GKJW Karangpilang+',
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.heading,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Versi 1.0',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _ThemePicker(),
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
                  color: AppColors.cardBg,
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
                          color: const Color(0xFFB5842A),
                        ),
                        const Divider(height: 24),
                        _NotificationToggle(
                          icon: Icons.nights_stay,
                          title: 'Sapaan Malam',
                          value: notificationEvening,
                          onChanged: (value) {
                            setState(() => notificationEvening = value);
                          },
                          color: AppColors.primary,
                        ),
                        const Divider(height: 24),
                        _NotificationToggle(
                          icon: Icons.location_on,
                          title: 'Area Gereja',
                          value: notificationChurch,
                          onChanged: (value) {
                            setState(() => notificationChurch = value);
                          },
                          color: AppColors.accentText,
                        ),
                        Divider(height: 24),
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
                SizedBox(height: 24),

                // HUBUNGI KAMI Section
                _SectionHeader(title: 'HUBUNGI KAMI'),
                SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: AppColors.cardBg,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _ContactItem(
                          icon: Icons.phone,
                          title: 'WhatsApp Admin',
                          onTap: () {},
                          color: Color(0xFF25D366),
                        ),
                        Divider(height: 20),
                        _ContactItem(
                          icon: Icons.email,
                          title: 'Email Sekretariat',
                          subtitle: 'info.gkisalatiga@gmail.com',
                          onTap: () {},
                          color: Color(0xFFEA4335),
                        ),
                        Divider(height: 20),
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
                SizedBox(height: 24),

                // TENTANG APLIKASI Section
                _SectionHeader(title: 'TENTANG APLIKASI'),
                SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: AppColors.cardBg,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _AboutItem(
                          icon: Icons.description,
                          title: 'Catatan Perubahan',
                          onTap: () {},
                          color: AppColors.primary,
                        ),
                        Divider(height: 20),
                        _AboutItem(
                          icon: Icons.code,
                          title: 'Kode Sumber (GitHub)',
                          onTap: () {},
                          color: AppColors.primary,
                        ),
                        Divider(height: 20),
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
                SizedBox(height: 16),
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
      style: TextStyle(
        fontFamily: 'PlusJakartaSans',
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

  _NotificationToggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.hasArrow = false,
    this.onTap,
    Color? color,
  }) : color = color ?? AppColors.secondary; // warna aksen tema aktif

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
        SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (hasArrow)
          Icon(Icons.chevron_right, color: AppColors.textLight, size: 20)
        else
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceAlt,
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

  _ContactItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    Color? color,
  }) : color = color ?? AppColors.secondary; // warna aksen tema aktif

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
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
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

  _AboutItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    Color? color,
  }) : color = color ?? AppColors.secondary; // warna aksen tema aktif

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
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
        ],
      ),
    );
  }
}

/// Pemilih tampilan: Ikuti HP · Terang · Gelap. Pilihan disimpan di perangkat.
class _ThemePicker extends ConsumerWidget {
  const _ThemePicker();

  static const _options = [
    (ThemeMode.system, Icons.brightness_auto_rounded, 'Ikuti HP'),
    (ThemeMode.light, Icons.light_mode_rounded, 'Terang'),
    (ThemeMode.dark, Icons.dark_mode_rounded, 'Gelap'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(themeControllerProvider);
    // Dengar langsung agar pilihan tertanda walau warna tidak berubah
    // (mis. memilih "Ikuti HP" saat HP sedang terang).
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Semantics(
          label: 'Tampilan aplikasi',
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (mode, icon, label) in _options)
                  _ThemeOption(
                    icon: icon,
                    label: label,
                    selected: controller.mode == mode,
                    onTap: () => controller.setMode(mode),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.navy900 : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.secondary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
