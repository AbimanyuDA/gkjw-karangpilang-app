// lib/data/services/youtube_metadata_service.dart
// Mengambil judul, deskripsi, dan tanggal video YouTube TANPA API key Google:
//   1. oEmbed YouTube (publik, gratis)            → judul
//   2. youtube_explode_dart (membaca halaman video) → deskripsi & tanggal upload
//   3. Tanggal di judul ("Ibadah 27 April 2025")  → dipakai bila tersedia
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeMetadata {
  final String videoId;
  final String title;
  final String description;
  final DateTime? date;

  const YoutubeMetadata({
    required this.videoId,
    required this.title,
    this.description = '',
    this.date,
  });
}

/// Sumber detail video (deskripsi & tanggal); dibuat abstrak agar mudah diuji.
typedef VideoDetailsFetcher = Future<({String title, String description, DateTime? date})?>
    Function(String videoId);

class YoutubeMetadataService {
  YoutubeMetadataService({Dio? dio, VideoDetailsFetcher? detailsFetcher})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 10))),
        _fetchDetails = detailsFetcher ?? _explodeDetails;

  final Dio _dio;
  final VideoDetailsFetcher _fetchDetails;

  static final _idPattern = RegExp(
      r'(?:youtu\.be/|/v/|/u/\w/|embed/|live/|shorts/|watch\?v=|&v=)([A-Za-z0-9_-]{11})');
  static final _barePattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

  /// Ambil ID video (11 karakter) dari berbagai format link YouTube, atau ID mentah.
  static String? extractVideoId(String input) {
    final text = input.trim();
    if (_barePattern.hasMatch(text)) return text;
    return _idPattern.firstMatch(text)?.group(1);
  }

  /// Kembalikan metadata; null bila judul tidak bisa diambil sama sekali.
  Future<YoutubeMetadata?> fetch(String videoId) async {
    String title = await _oembedTitle(videoId) ?? '';
    String description = '';
    DateTime? date;

    final details = await _safeDetails(videoId);
    if (details != null) {
      if (title.isEmpty) title = details.title;
      description = details.description;
      date = details.date;
    }
    if (title.isEmpty) return null;

    // Tanggal di judul lebih tepat untuk video ibadah (tanggal ibadah ≠ tanggal upload).
    date = parseDateFromTitle(title) ?? date;
    return YoutubeMetadata(videoId: videoId, title: title, description: description, date: date);
  }

  Future<String?> _oembedTitle(String videoId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        'https://www.youtube.com/oembed',
        queryParameters: {'url': 'https://www.youtube.com/watch?v=$videoId', 'format': 'json'},
      );
      final title = res.data?['title'];
      return title is String && title.isNotEmpty ? title : null;
    } on DioException catch (e) {
      debugPrint('oEmbed gagal: ${e.message}');
      return null;
    }
  }

  Future<({String title, String description, DateTime? date})?> _safeDetails(String videoId) async {
    try {
      return await _fetchDetails(videoId);
    } on Exception catch (e) {
      debugPrint('Detail video gagal diambil: $e');
      return null;
    }
  }

  static Future<({String title, String description, DateTime? date})?> _explodeDetails(
      String videoId) async {
    final yt = YoutubeExplode();
    try {
      final video = await yt.videos.get(videoId);
      return (
        title: video.title,
        description: video.description,
        date: video.uploadDate ?? video.publishDate,
      );
    } finally {
      yt.close();
    }
  }

  static const _months = {
    'januari': 1, 'jan': 1, 'februari': 2, 'feb': 2, 'maret': 3, 'mar': 3,
    'april': 4, 'apr': 4, 'mei': 5, 'juni': 6, 'jun': 6, 'juli': 7, 'jul': 7,
    'agustus': 8, 'agu': 8, 'aug': 8, 'september': 9, 'sep': 9, 'sept': 9,
    'oktober': 10, 'okt': 10, 'oct': 10, 'november': 11, 'nov': 11,
    'desember': 12, 'des': 12, 'dec': 12,
  };

  /// "Ibadah Minggu 27 April 2025" / "Ibadah 27/04/2025" → DateTime; null bila tidak ada.
  static DateTime? parseDateFromTitle(String title) {
    final names = (_months.keys.toList()..sort((a, b) => b.length.compareTo(a.length))).join('|');
    final named = RegExp(r'\b(\d{1,2})\s+(' + names + r')\.?\s+(\d{4})\b', caseSensitive: false)
        .firstMatch(title);
    if (named != null) {
      final month = _months[named.group(2)!.toLowerCase()];
      final date = _validDate(int.parse(named.group(3)!), month, int.parse(named.group(1)!));
      if (date != null) return date;
    }
    final numeric = RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{4})\b').firstMatch(title);
    if (numeric != null) {
      return _validDate(
          int.parse(numeric.group(3)!), int.parse(numeric.group(2)!), int.parse(numeric.group(1)!));
    }
    return null;
  }

  static DateTime? _validDate(int year, int? month, int day) {
    if (month == null || month < 1 || month > 12 || day < 1 || day > 31) return null;
    final d = DateTime(year, month, day);
    return d.month == month ? d : null; // tolak 31 Februari dll.
  }
}
