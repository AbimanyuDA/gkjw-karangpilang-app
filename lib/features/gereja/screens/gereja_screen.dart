// lib/features/gereja/screens/gereja_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GerejaScreen extends StatelessWidget {
  const GerejaScreen({super.key});

  static const _menuItems = [
    _GerejaMenuItem(
      key: 'informasi_gereja',
      title: 'Informasi Gereja',
      subtitle: 'Profil, visi, dan misi gereja',
      route: '/gereja/informasi',
      accentColor: Color(0xFF1565C0),
    ),
    _GerejaMenuItem(
      key: 'kependetaan',
      title: 'Kependetaan',
      subtitle: 'Profil gembala sidang',
      route: '/gereja/kependetaan',
      accentColor: Color(0xFF8B1A2F),
    ),
    _GerejaMenuItem(
      key: 'kemajelisan',
      title: 'Kemajelisan',
      subtitle: 'Profil majelis jemaat',
      route: '/gereja/kemajelisan',
      accentColor: Color(0xFF2E7D32),
    ),
    _GerejaMenuItem(
      key: 'bpm',
      title: 'Badan Pembantu Majelis',
      subtitle: 'Komisi-komisi di gereja',
      route: '/gereja/bpm',
      accentColor: Color(0xFFF57C00),
    ),
    _GerejaMenuItem(
      key: 'perwilayahan',
      title: 'Perwilayahan',
      subtitle: 'Data wilayah jemaat',
      route: '/gereja/perwilayahan',
      accentColor: Color(0xFF6A1B9A),
    ),
    _GerejaMenuItem(
      key: 'profil_ruangan',
      title: 'Profil Ruangan',
      subtitle: 'Fasilitas ruangan gereja',
      route: '/gereja/profil-ruangan',
      accentColor: Color(0xFF00695C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('gereja_covers').snapshots(),
        builder: (context, snapshot) {
          // Build a map of key → imageUrl from Firestore
          final covers = <String, String>{};
          if (snapshot.hasData) {
            for (final doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              covers[doc.id] = data['imageUrl'] as String? ?? '';
            }
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GKJW Karangpilang',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Profil & Sejarah Gereja',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _menuItems[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _GerejaCoverCard(
                          item: item,
                          imageUrl: covers[item.key] ?? '',
                          onTap: () => context.go(item.route),
                        ),
                      );
                    },
                    childCount: _menuItems.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Data model ───────────────────────────────────────────────
class _GerejaMenuItem {
  final String key;
  final String title;
  final String subtitle;
  final String route;
  final Color accentColor;
  const _GerejaMenuItem({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.accentColor,
  });
}

// ─── Card Widget ──────────────────────────────────────────────
class _GerejaCoverCard extends StatelessWidget {
  final _GerejaMenuItem item;
  final String imageUrl;
  final VoidCallback onTap;

  const _GerejaCoverCard({
    required this.item,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Background image or placeholder ──
              _buildImage(),

              // ── Dark gradient overlay at bottom ──
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.20),
                        Colors.black.withValues(alpha: 0.72),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),

              // ── Text overlay ──
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Colored accent underline
                    Container(
                      width: 36,
                      height: 3,
                      decoration: BoxDecoration(
                        color: item.accentColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Arrow indicator top-right ──
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        memCacheWidth: 640,
        placeholder: (_, __) => _buildPlaceholder(),
        errorWidget: (_, __, ___) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            item.accentColor.withValues(alpha: 0.6),
            item.accentColor.withValues(alpha: 0.9),
          ],
        ),
      ),
    );
  }
}
