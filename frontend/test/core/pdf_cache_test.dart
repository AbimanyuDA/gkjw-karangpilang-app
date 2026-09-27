import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gkjw_karangpilang/core/utils/pdf_cache.dart';

void main() {
  late Directory root;
  late List<String> downloadedUrls;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('pdf_cache_test');
    downloadedUrls = [];
  });

  tearDown(() => root.delete(recursive: true));

  PdfCache cacheWith({bool fail = false}) => PdfCache(
        cacheRoot: () async => root,
        downloader: (url, savePath, onProgress) async {
          downloadedUrls.add(url);
          await File(savePath).writeAsString('%PDF-1.4 partial');
          onProgress(50, 100);
          if (fail) throw const SocketException('putus');
          onProgress(100, 100);
        },
      );

  test('downloads once, then serves from cache', () async {
    final cache = cacheWith();
    final progress = <double>[];

    final first = await cache.obtain(cacheKey: 'd1', url: 'https://x/a.pdf', onProgress: progress.add);
    final second = await cache.obtain(cacheKey: 'd1', url: 'https://x/a.pdf');

    expect(first, second);
    expect(downloadedUrls, hasLength(1));
    expect(progress, [0.5, 1.0]);
    expect(File(first).existsSync(), isTrue);
  });

  test('interrupted download is not cached', () async {
    await expectLater(
      cacheWith(fail: true).obtain(cacheKey: 'd2', url: 'https://x/b.pdf'),
      throwsA(isA<SocketException>()),
    );
    expect(root.listSync(recursive: true).whereType<File>(), isEmpty);

    await cacheWith().obtain(cacheKey: 'd2', url: 'https://x/b.pdf');
    expect(downloadedUrls, hasLength(2), reason: 'harus diunduh ulang setelah gagal');
  });

  test('google drive view links become direct download links', () {
    expect(
      PdfCache.normalizeUrl('https://drive.google.com/file/d/AbC_123-x/view?usp=sharing'),
      'https://drive.google.com/uc?export=download&id=AbC_123-x',
    );
    expect(PdfCache.normalizeUrl('https://api.test/files/dokumen/a.pdf'), 'https://api.test/files/dokumen/a.pdf');
  });

  test('cache keys cannot escape the cache folder', () {
    expect(PdfCache.safeFileName('../../etc/passwd'), '______etc_passwd');
  });
}
