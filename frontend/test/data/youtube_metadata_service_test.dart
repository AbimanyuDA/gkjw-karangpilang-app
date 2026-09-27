import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gkjw_karangpilang/data/services/youtube_metadata_service.dart';

import '../helpers/fake_http.dart';

void main() {
  group('extractVideoId', () {
    const id = 'dQw4w9WgXcQ';
    for (final input in [
      'https://www.youtube.com/watch?v=$id',
      'https://www.youtube.com/watch?feature=share&v=$id&t=10',
      'https://youtu.be/$id?si=abc',
      'https://www.youtube.com/live/$id',
      'https://youtube.com/shorts/$id',
      'https://www.youtube.com/embed/$id',
      '  $id  ',
    ]) {
      test(input.trim(), () => expect(YoutubeMetadataService.extractVideoId(input), id));
    }
    test('rejects non-youtube text', () {
      expect(YoutubeMetadataService.extractVideoId('https://example.com/video'), isNull);
      expect(YoutubeMetadataService.extractVideoId(''), isNull);
    });
  });

  group('parseDateFromTitle', () {
    test('Indonesian month names', () {
      expect(YoutubeMetadataService.parseDateFromTitle('Ibadah Minggu 27 April 2025'), DateTime(2025, 4, 27));
      expect(YoutubeMetadataService.parseDateFromTitle('Ibadah 5 Sept 2026 | GKJW'), DateTime(2026, 9, 5));
      expect(YoutubeMetadataService.parseDateFromTitle('IBADAH 1 DESEMBER 2024'), DateTime(2024, 12, 1));
    });
    test('numeric dates', () {
      expect(YoutubeMetadataService.parseDateFromTitle('Ibadah 20/04/2025'), DateTime(2025, 4, 20));
      expect(YoutubeMetadataService.parseDateFromTitle('Ibadah 20-4-2025'), DateTime(2025, 4, 20));
    });
    test('invalid or missing dates', () {
      expect(YoutubeMetadataService.parseDateFromTitle('Ibadah 31 Februari 2025'), isNull);
      expect(YoutubeMetadataService.parseDateFromTitle('Ibadah Paskah'), isNull);
    });
  });

  group('fetch', () {
    YoutubeMetadataService service(FakeHttpAdapter http,
            {({String title, String description, DateTime? date})? details, bool throwDetails = false}) =>
        YoutubeMetadataService(
          dio: Dio()..httpClientAdapter = http,
          detailsFetcher: (_) async {
            if (throwDetails) throw Exception('diblokir');
            return details;
          },
        );

    test('combines oEmbed title with details; title date wins', () async {
      final http = FakeHttpAdapter()..reply(200, {'title': 'Ibadah Minggu 27 April 2025'});
      final meta = await service(http,
              details: (title: 'x', description: 'Pelayan firman: Pdt. A', date: DateTime(2025, 4, 28)))
          .fetch('dQw4w9WgXcQ');

      expect(meta!.title, 'Ibadah Minggu 27 April 2025');
      expect(meta.description, 'Pelayan firman: Pdt. A');
      expect(meta.date, DateTime(2025, 4, 27));
      expect(http.requests.single.uri.host, 'www.youtube.com');
      expect(http.requests.single.uri.queryParameters.containsKey('key'), isFalse,
          reason: 'tidak boleh memakai API key');
    });

    test('falls back to details when oEmbed fails', () async {
      final http = FakeHttpAdapter()..reply(404, {});
      final meta = await service(http, details: (title: 'Ibadah Remaja', description: '', date: DateTime(2026, 1, 3)))
          .fetch('dQw4w9WgXcQ');
      expect(meta!.title, 'Ibadah Remaja');
      expect(meta.date, DateTime(2026, 1, 3));
    });

    test('still returns title when details are blocked', () async {
      final http = FakeHttpAdapter()..reply(200, {'title': 'Ibadah Anak'});
      final meta = await service(http, throwDetails: true).fetch('dQw4w9WgXcQ');
      expect(meta!.title, 'Ibadah Anak');
      expect(meta.description, isEmpty);
    });

    test('returns null when nothing works', () async {
      final http = FakeHttpAdapter()..fail(DioExceptionType.connectionError);
      expect(await service(http, throwDetails: true).fetch('dQw4w9WgXcQ'), isNull);
    });
  });
}
