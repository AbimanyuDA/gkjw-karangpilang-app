// lib/data/api/api_client.dart
// Klien HTTP (hanya baca) ke backend GKJW. Pengelolaan konten dilakukan di website admin.
// Semua respons berbentuk:
//   { "success": bool, "data": ..., "error": {code, message, fields}, "meta": {...} }
import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  final Map<String, String> fields;
  final int? statusCode;

  const ApiException(
    this.message, {
    this.code = 'unknown',
    this.fields = const {},
    this.statusCode,
  });

  @override
  String toString() {
    if (fields.isEmpty) return message;
    final detail = fields.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    return '$message ($detail)';
  }
}

class ApiClient {
  ApiClient({required String baseUrl, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              responseType: ResponseType.json,
            ));

  final Dio _dio;

  // ── Baca ──────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final data = await _send(() => _dio.get(path, queryParameters: query));
    return (data as List).cast<Map<String, dynamic>>();
  }

  /// Untuk endpoint yang mengembalikan satu objek (bisa null, mis. konfigurasi kosong).
  Future<Map<String, dynamic>?> getObject(String path) async {
    final data = await _send(() => _dio.get(path));
    return data as Map<String, dynamic>?;
  }

  Future<List<T>> getValues<T>(String path) async {
    final data = await _send(() => _dio.get(path));
    return (data as List).cast<T>();
  }

  // ── Internal ──────────────────────────────────────────────────
  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final res = await request();
      final body = res.data;
      if (body is Map<String, dynamic> && body['success'] == true) {
        return body['data'];
      }
      throw const ApiException('Respons server tidak valid', code: 'bad_response');
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final body = e.response?.data;
    if (body is Map<String, dynamic> && body['error'] is Map<String, dynamic>) {
      final err = body['error'] as Map<String, dynamic>;
      return ApiException(
        err['message'] as String? ?? 'Terjadi kesalahan',
        code: err['code'] as String? ?? 'unknown',
        fields: (err['fields'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v.toString())),
        statusCode: e.response?.statusCode,
      );
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        const ApiException('Koneksi ke server terlalu lama. Coba lagi.', code: 'timeout'),
      DioExceptionType.connectionError =>
        const ApiException('Tidak dapat terhubung ke server. Periksa koneksi internet.', code: 'offline'),
      _ => ApiException('Terjadi kesalahan (${e.response?.statusCode ?? '-'})',
          statusCode: e.response?.statusCode),
    };
  }
}
