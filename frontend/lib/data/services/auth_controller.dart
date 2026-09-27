// lib/data/services/auth_controller.dart
// Menyimpan sesi login admin (token disimpan terenkripsi di Keychain/Keystore).
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';

/// Penyimpanan token; dibuat abstrak agar mudah diganti saat testing.
abstract class TokenStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage([this._storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class AuthController extends ChangeNotifier {
  AuthController({required TokenStorage storage}) : _storage = storage;

  static const _kToken = 'admin_token';
  static const _kEmail = 'admin_email';
  static const _kExpires = 'admin_expires_at';

  final TokenStorage _storage;
  AdminSession? _session;

  bool get isLoggedIn => _session != null && !_session!.isExpired;
  String? get token => isLoggedIn ? _session!.token : null;
  String? get email => _session?.email;

  /// Pulihkan sesi dari penyimpanan saat aplikasi dibuka.
  Future<void> restore() async {
    try {
      final token = await _storage.read(_kToken);
      final email = await _storage.read(_kEmail);
      final expires = DateTime.tryParse(await _storage.read(_kExpires) ?? '');
      if (token == null || email == null || expires == null) return;

      final session = AdminSession(token: token, email: email, expiresAt: expires);
      if (session.isExpired) {
        await _clearStorage();
        return;
      }
      _session = session;
    } catch (e) {
      // Keystore bisa rusak setelah restore backup HP; anggap belum login.
      debugPrint('Gagal memulihkan sesi admin: $e');
      await _clearStorage();
    }
  }

  Future<void> login(ApiClient api, String email, String password) async {
    final session = await api.login(email.trim(), password);
    await _storage.write(_kToken, session.token);
    await _storage.write(_kEmail, session.email);
    await _storage.write(_kExpires, session.expiresAt.toIso8601String());
    _session = session;
    notifyListeners();
  }

  Future<void> logout() async {
    if (_session == null) return;
    _session = null;
    await _clearStorage();
    notifyListeners();
  }

  Future<void> _clearStorage() async {
    try {
      await _storage.delete(_kToken);
      await _storage.delete(_kEmail);
      await _storage.delete(_kExpires);
    } catch (e) {
      debugPrint('Gagal menghapus sesi admin: $e');
    }
  }
}
