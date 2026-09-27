// lib/core/config/api_config.dart

/// Alamat backend diambil saat build lewat --dart-define-from-file:
///   flutter run --dart-define-from-file=config/dev.json
///   flutter build apk --dart-define-from-file=config/prod.json
class ApiConfig {
  ApiConfig._();

  /// Default: emulator Android → laptop (http://10.0.2.2:8080).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const String apiUrl = '$baseUrl/api/v1';

  /// Prefix URL file yang disimpan di server kita (hasil upload admin).
  static const String filesUrl = '$baseUrl/files/';
}
