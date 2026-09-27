// lib/data/api/api_client.dart
// Klien HTTP ke backend GKJW. Semua respons berbentuk:
//   { "success": bool, "data": ..., "error": {code, message, fields}, "meta": {...} }
import 'dart:io';
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

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() {
    if (fields.isEmpty) return message;
    final detail = fields.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    return '$message ($detail)';
  }
}

/// Sesi admin hasil login.
class AdminSession {
  final String token;
  final String email;
  final DateTime expiresAt;

  const AdminSession({
    required this.token,
    required this.email,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Hasil upload file ke server.
class UploadedFile {
  final String url;
  final String bucket;
  final String name;

  const UploadedFile({required this.url, required this.bucket, required this.name});
}

class ApiClient {
  ApiClient({
    required String baseUrl,
    required String? Function() tokenReader,
    void Function()? onUnauthorized,
    Dio? dio,
  })  : _tokenReader = tokenReader,
        _onUnauthorized = onUnauthorized,
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
              responseType: ResponseType.json,
            )) {
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      final token = _tokenReader();
      if (token != null && options.path.startsWith('/admin')) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    }));
  }

  final Dio _dio;
  final String? Function() _tokenReader;
  final void Function()? _onUnauthorized;

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

  // ── Tulis (admin) ─────────────────────────────────────────────
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async =>
      await _send(() => _dio.post(path, data: body)) as Map<String, dynamic>;

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async =>
      await _send(() => _dio.put(path, data: body)) as Map<String, dynamic>;

  Future<void> delete(String path) => _send(() => _dio.delete(path));

  // ── Auth ──────────────────────────────────────────────────────
  Future<AdminSession> login(String email, String password) async {
    final data = await _send(() => _dio.post('/auth/login', data: {
          'email': email,
          'password': password,
        })) as Map<String, dynamic>;
    return AdminSession(
      token: data['token'] as String,
      email: data['email'] as String,
      expiresAt: DateTime.parse(data['expires_at'] as String).toLocal(),
    );
  }

  // ── File ──────────────────────────────────────────────────────
  /// Upload file ke bucket (banners, gereja-covers, galeri, profil, eperpus-cover, dokumen, eperpus).
  Future<UploadedFile> upload(
    String bucket,
    File file, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    final data = await _send(() => _dio.post(
          '/admin/uploads',
          queryParameters: {'bucket': bucket},
          data: form,
          onSendProgress: onProgress,
          options: Options(
            sendTimeout: const Duration(minutes: 5),
            receiveTimeout: const Duration(minutes: 1),
          ),
        )) as Map<String, dynamic>;
    return UploadedFile(
      url: data['url'] as String,
      bucket: data['bucket'] as String,
      name: data['name'] as String,
    );
  }

  /// Hapus file yang sebelumnya di-upload. URL dari luar server kita
  /// (mis. link Google Drive / data lama) diabaikan.
  Future<void> deleteFileByUrl(String url, {required String filesUrlPrefix}) async {
    if (!url.startsWith(filesUrlPrefix)) return;
    final parts = url.substring(filesUrlPrefix.length).split('/');
    if (parts.length != 2) return;
    await delete('/admin/uploads/${parts[0]}/${parts[1]}');
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
      final ex = _toApiException(e);
      if (ex.isUnauthorized) _onUnauthorized?.call();
      throw ex;
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
