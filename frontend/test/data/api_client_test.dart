import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gkjw_karangpilang/data/api/api_client.dart';
import 'package:gkjw_karangpilang/data/models/pdf_item_model.dart';
import 'package:gkjw_karangpilang/data/services/content_service.dart';

import '../helpers/fake_http.dart';

void main() {
  late FakeHttpAdapter http;
  late String? token;
  late int unauthorizedCalls;
  late ApiClient api;

  setUp(() {
    http = FakeHttpAdapter();
    token = null;
    unauthorizedCalls = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))..httpClientAdapter = http;
    api = ApiClient(
      baseUrl: 'unused',
      tokenReader: () => token,
      onUnauthorized: () => unauthorizedCalls++,
      dio: dio,
    );
  });

  group('ApiClient', () {
    test('unwraps envelope data for lists', () async {
      http.reply(200, ok([
        {'id': '1'},
      ], meta: {'total': 1, 'limit': 50, 'offset': 0}));

      final rows = await api.getList('/agenda', query: {'limit': 5});

      expect(rows, [
        {'id': '1'},
      ]);
      expect(http.requests.single.uri.toString(), 'https://api.test/api/v1/agenda?limit=5');
    });

    test('getObject returns null for an empty singleton', () async {
      http.reply(200, ok(null));
      expect(await api.getObject('/tentang-aplikasi'), isNull);
    });

    test('sends bearer token only to admin endpoints', () async {
      token = 'abc';
      http
        ..reply(200, ok([]))
        ..reply(200, ok({'id': 'x'}));

      await api.getList('/agenda');
      await api.post('/admin/agenda', {'judul': 'x'});

      expect(http.requests[0].headers['Authorization'], isNull);
      expect(http.requests[1].headers['Authorization'], 'Bearer abc');
    });

    test('maps server validation errors to ApiException with fields', () async {
      http.reply(400, err('validation_error', 'Data tidak valid', fields: {'judul': 'wajib diisi'}));

      await expectLater(
        api.post('/admin/agenda', {}),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'validation_error')
            .having((e) => e.fields['judul'], 'field', 'wajib diisi')
            .having((e) => e.toString(), 'message', contains('judul: wajib diisi'))),
      );
    });

    test('calls onUnauthorized on 401 so the admin session is cleared', () async {
      http.reply(401, err('unauthorized', 'Silakan login terlebih dahulu'));

      await expectLater(api.delete('/admin/faq/1'), throwsA(isA<ApiException>()));
      expect(unauthorizedCalls, 1);
    });

    test('network failure becomes a friendly offline error', () async {
      http.fail(DioExceptionType.connectionError);

      await expectLater(
        api.getList('/agenda'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'offline')),
      );
      expect(unauthorizedCalls, 0);
    });

    test('login parses the session', () async {
      http.reply(200, ok({
        'token': 'jwt',
        'email': 'admin@gkjw.org',
        'expires_at': '2099-01-01T00:00:00Z',
      }));

      final session = await api.login('admin@gkjw.org', 'secret');

      expect(session.token, 'jwt');
      expect(session.isExpired, isFalse);
    });

    test('deleteFileByUrl only deletes files hosted on our server', () async {
      http.reply(200, ok({}));

      await api.deleteFileByUrl('https://drive.google.com/file/d/x/view',
          filesUrlPrefix: 'https://api.test/files/');
      await api.deleteFileByUrl('https://api.test/files/banners/abc.jpg',
          filesUrlPrefix: 'https://api.test/files/');

      expect(http.requests, hasLength(1));
      expect(http.requests.single.method, 'DELETE');
      expect(http.requests.single.path, '/admin/uploads/banners/abc.jpg');
    });
  });

  group('ContentService', () {
    test('getDokumen filters by kategori and parses items', () async {
      http.reply(200, ok([
        {
          'id': 'd1',
          'judul': 'Warta',
          'url': 'https://api.test/files/dokumen/a.pdf',
          'tanggal': '2026-09-27T00:00:00Z',
          'thumbnail': null,
        },
      ]));

      final items = await ContentService(api).getDokumen(DokumenKategori.tataIbadah);

      expect(http.requests.single.uri.queryParameters['kategori'], 'tata_ibadah');
      expect(items.single.judul, 'Warta');
    });

    test('getGaleri omits tahun when not filtering', () async {
      http
        ..reply(200, ok([]))
        ..reply(200, ok([]));
      final service = ContentService(api);

      await service.getGaleri();
      await service.getGaleri(tahun: 2025);

      expect(http.requests[0].uri.queryParameters.containsKey('tahun'), isFalse);
      expect(http.requests[1].uri.queryParameters['tahun'], '2025');
    });

    test('getGaleriTahun returns ints', () async {
      http.reply(200, ok([2026, 2024]));
      expect(await ContentService(api).getGaleriTahun(), [2026, 2024]);
    });
  });
}
