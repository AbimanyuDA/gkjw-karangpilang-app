// lib/features/gereja/widgets/profil_bagian_card.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Foto bagian profil gereja; bila admin belum mengunggah foto, tampil latar navy
/// dengan logo samar agar kartu tetap rapi.
class ProfilFoto extends StatelessWidget {
  final String? url;
  const ProfilFoto({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final placeholder = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy700, AppColors.navy900],
        ),
      ),
      child: Align(
        alignment: const Alignment(0, -0.35),
        child: Opacity(
          opacity: 0.35,
          child: Image.asset(
            'assets/images/logo.png',
            width: 72,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
    if (url == null) return placeholder;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      memCacheWidth: 1280,
      placeholder: (context, _) => placeholder,
      errorWidget: (context, _, _) => placeholder,
    );
  }
}

/// Kartu besar bergambar (16:9) dengan judul di kiri bawah, seperti kartu menu Gereja.
class ProfilBagianCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final Object heroTag;
  final VoidCallback onTap;

  const ProfilBagianCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.heroTag,
    required this.onTap,
  });

  static final _radius = BorderRadius.circular(22);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: _radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.navy900.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: _radius,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: heroTag,
                  child: ProfilFoto(url: imageUrl),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 40,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.gold600,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(onTap: onTap, splashColor: Colors.white24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
