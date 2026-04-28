import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/pdf_item_model.dart';

class SiaranDetailScreen extends StatefulWidget {
  final VideoSiaran video;

  const SiaranDetailScreen({super.key, required this.video});

  @override
  State<SiaranDetailScreen> createState() => _SiaranDetailScreenState();
}

class _SiaranDetailScreenState extends State<SiaranDetailScreen> {
  late YoutubePlayerController _ytController;

  @override
  void initState() {
    super.initState();
    _ytController = YoutubePlayerController(
      initialVideoId: widget.video.youtubeId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
      ),
    );
  }

  @override
  void dispose() {
    _ytController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMMM yyyy', 'id_ID').format(widget.video.tanggal);
    final deskripsi = widget.video.deskripsi ?? '';

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _ytController,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.primary,
        topActions: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _ytController.metadata.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18.0,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Siaran'),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                player,
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kategori badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatKategori(widget.video.kategori),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Judul
                      Text(
                        widget.video.judul,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tanggal
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Deskripsi
                      const Text(
                        'Deskripsi',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (deskripsi.isNotEmpty)
                        SelectableText(
                          deskripsi,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            height: 1.6,
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        const Text(
                          'Tidak ada deskripsi tersedia.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontStyle: FontStyle.italic,
                            color: AppColors.textLight,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatKategori(String k) {
    return switch (k) {
      'umum' => 'Ibadah Umum',
      'anak' => 'Ibadah Anak',
      'remaja' => 'Ibadah Remaja',
      'sekolah_minggu' => 'Sekolah Minggu',
      _ => k,
    };
  }
}
