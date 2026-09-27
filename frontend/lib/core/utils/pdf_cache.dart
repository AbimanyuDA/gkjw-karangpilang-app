// lib/core/utils/pdf_cache.dart
// Cache PDF di HP: file yang sudah pernah diunduh langsung dibuka tanpa unduh ulang.
// Ini yang paling menghemat bandwidth server saat ramai (mis. Minggu pagi).
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

typedef PdfDownloader = Future<void> Function(
  String url,
  String savePath,
  void Function(int received, int total) onProgress,
);

class PdfCache {
  PdfCache({PdfDownloader? downloader, Future<Directory> Function()? cacheRoot})
      : _download = downloader ?? _dioDownload,
        _cacheRoot = cacheRoot ?? getApplicationCacheDirectory;

  final PdfDownloader _download;
  final Future<Directory> Function() _cacheRoot;

  /// Kembalikan path file lokal untuk [cacheKey]; unduh dari [url] bila belum ada.
  Future<String> obtain({
    required String cacheKey,
    required String url,
    void Function(double progress)? onProgress,
  }) async {
    final dir = Directory('${(await _cacheRoot()).path}/pdf');
    await dir.create(recursive: true);

    final file = File('${dir.path}/${safeFileName(cacheKey)}.pdf');
    if (await file.exists() && await file.length() > 0) return file.path;

    // Unduh ke .part dulu agar unduhan yang terputus tidak dianggap cache valid.
    final part = File('${file.path}.part');
    try {
      await _download(normalizeUrl(url), part.path, (received, total) {
        if (total > 0) onProgress?.call(received / total);
      });
      await part.rename(file.path);
    } on Exception {
      if (await part.exists()) await part.delete();
      rethrow;
    }
    return file.path;
  }

  /// Link Google Drive "view" diubah menjadi link unduh langsung (data lama).
  static String normalizeUrl(String url) {
    final match = RegExp(r'drive\.google\.com/file/d/([a-zA-Z0-9_-]+)').firstMatch(url);
    final fileId = match?.group(1);
    if (fileId == null) return url;
    return 'https://drive.google.com/uc?export=download&id=$fileId';
  }

  /// Hanya huruf, angka, '-' dan '_' agar aman sebagai nama file.
  static String safeFileName(String key) => key.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  static Future<void> _dioDownload(
    String url,
    String savePath,
    void Function(int, int) onProgress,
  ) =>
      Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(minutes: 2),
      )).download(url, savePath, onReceiveProgress: onProgress);
}
