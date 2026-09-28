import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gkjw_karangpilang/data/api/api_client.dart';
import 'package:gkjw_karangpilang/data/models/pdf_item_model.dart';
import 'package:gkjw_karangpilang/data/services/content_service.dart';

import '../helpers/fake_http.dart';

void main() {
  late FakeHttpAdapter http;
  late ApiClient api;

  setUp(() {
    http = FakeHttpAdapter();
    api = ApiClient(
      baseUrl: 'unused',
      dio: Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))..httpClientAdapter = http,
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
      expect(http.requests.single.headers['Authorization'], isNull, reason: 'aplikasi tidak pernah login');
    });

    test('getObject returns null for an empty singleton', () async {
      http.reply(200, ok(null));
      expect(await api.getObject('/tentang-aplikasi'), isNull);
    });

    test('maps server errors to ApiException with fields', () async {
      http.reply(400, err('validation_error', 'Data tidak valid', fields: {'kategori': 'tidak dikenal'}));

      await expectLater(
        api.getList('/dokumen'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'validation_error')
            .having((e) => e.toString(), 'message', contains('kategori: tidak dikenal'))),
      );
    });

    test('network failure becomes a friendly offline error', () async {
      http.fail(DioExceptionType.connectionError);

      await expectLater(
        api.getList('/agenda'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'offline')),
      );
    });

    test('timeout becomes a friendly timeout error', () async {
      http.fail(DioExceptionType.receiveTimeout);

      await expectLater(
        api.getList('/agenda'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'timeout')),
      );
    });

    test('rejects a response without the success envelope', () async {
      http.reply(200, {'unexpected': true});
      await expectLater(api.getList('/agenda'), throwsA(isA<ApiException>()));
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

    test('getSiaran passes kategori only when set', () async {
      http
        ..reply(200, ok([]))
        ..reply(200, ok([]));
      final service = ContentService(api);

      await service.getSiaran();
      await service.getSiaran(kategori: 'anak');

      expect(http.requests[0].uri.queryParameters.containsKey('kategori'), isFalse);
      expect(http.requests[1].uri.queryParameters['kategori'], 'anak');
    });
  });
}
