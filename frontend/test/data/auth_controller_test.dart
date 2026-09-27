import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gkjw_karangpilang/data/api/api_client.dart';
import 'package:gkjw_karangpilang/data/services/auth_controller.dart';

import '../helpers/fake_http.dart';

class MemoryTokenStorage implements TokenStorage {
  final Map<String, String> values = {};
  bool throwOnRead = false;

  @override
  Future<String?> read(String key) async {
    if (throwOnRead) throw Exception('keystore rusak');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

ApiClient _api(FakeHttpAdapter http) => ApiClient(
      baseUrl: 'unused',
      tokenReader: () => null,
      dio: Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))..httpClientAdapter = http,
    );

void main() {
  test('login stores the session and notifies listeners', () async {
    final storage = MemoryTokenStorage();
    final auth = AuthController(storage: storage);
    final http = FakeHttpAdapter()
      ..reply(200, ok({
        'token': 'jwt',
        'email': 'admin@gkjw.org',
        'expires_at': '2099-01-01T00:00:00Z',
      }));
    var notified = 0;
    auth.addListener(() => notified++);

    await auth.login(_api(http), ' admin@gkjw.org ', 'secret');

    expect(auth.isLoggedIn, isTrue);
    expect(auth.token, 'jwt');
    expect(storage.values['admin_token'], 'jwt');
    expect(notified, 1);
    expect(http.requests.single.data, {'email': 'admin@gkjw.org', 'password': 'secret'});
  });

  test('failed login leaves the user logged out', () async {
    final auth = AuthController(storage: MemoryTokenStorage());
    final http = FakeHttpAdapter()..reply(401, err('unauthorized', 'Email atau password salah'));

    await expectLater(auth.login(_api(http), 'a@b.c', 'x'), throwsA(isA<ApiException>()));
    expect(auth.isLoggedIn, isFalse);
  });

  test('restore brings back a valid session', () async {
    final storage = MemoryTokenStorage()
      ..values.addAll({
        'admin_token': 'jwt',
        'admin_email': 'admin@gkjw.org',
        'admin_expires_at': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      });
    final auth = AuthController(storage: storage);

    await auth.restore();

    expect(auth.isLoggedIn, isTrue);
    expect(auth.email, 'admin@gkjw.org');
  });

  test('restore discards an expired session', () async {
    final storage = MemoryTokenStorage()
      ..values.addAll({
        'admin_token': 'jwt',
        'admin_email': 'admin@gkjw.org',
        'admin_expires_at': DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String(),
      });
    final auth = AuthController(storage: storage);

    await auth.restore();

    expect(auth.isLoggedIn, isFalse);
    expect(storage.values, isEmpty);
  });

  test('restore survives a broken keystore', () async {
    final auth = AuthController(storage: MemoryTokenStorage()..throwOnRead = true);
    await auth.restore();
    expect(auth.isLoggedIn, isFalse);
  });

  test('logout clears storage and notifies once', () async {
    final storage = MemoryTokenStorage()
      ..values.addAll({
        'admin_token': 'jwt',
        'admin_email': 'admin@gkjw.org',
        'admin_expires_at': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      });
    final auth = AuthController(storage: storage);
    await auth.restore();
    var notified = 0;
    auth.addListener(() => notified++);

    await auth.logout();
    await auth.logout(); // kedua kali tidak melakukan apa-apa

    expect(auth.isLoggedIn, isFalse);
    expect(storage.values, isEmpty);
    expect(notified, 1);
  });
}
