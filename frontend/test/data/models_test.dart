import 'package:flutter_test/flutter_test.dart';
import 'package:gkjw_karangpilang/data/models/content_models.dart';
import 'package:gkjw_karangpilang/data/models/pdf_item_model.dart';

void main() {
  test('PdfItem round-trips and sends UTC dates with kategori', () {
    final item = PdfItem.fromJson({
      'id': 'd1',
      'judul': 'Warta',
      'url': 'https://x/a.pdf',
      'tanggal': '2026-09-26T17:00:00Z',
      'thumbnail': null,
    });

    final json = item.toJson(DokumenKategori.renungan);

    expect(json['kategori'], 'renungan');
    expect(json['tanggal'], '2026-09-26T17:00:00.000Z');
    expect(json.containsKey('thumbnail'), isFalse);
    expect(json.containsKey('id'), isFalse);
  });

  test('VideoSiaran omits empty deskripsi', () {
    final video = VideoSiaran(
      id: '',
      judul: 'Ibadah',
      youtubeId: 'abcdefghijk',
      kategori: 'umum',
      tanggal: DateTime.utc(2026, 9, 27),
      deskripsi: '',
    );
    expect(video.toJson().containsKey('deskripsi'), isFalse);
  });

  test('AgendaModel maps tempat and sends UTC', () {
    final agenda = AgendaModel.fromJson({
      'id': 'a1',
      'judul': 'Rapat',
      'deskripsi': null,
      'tanggal': '2026-10-01T03:00:00Z',
      'tempat': 'Aula',
    });
    expect(agenda.lokasi, 'Aula');
    expect(agenda.toJson()['tanggal'], '2026-10-01T03:00:00.000Z');
    expect(agenda.toJson()['tempat'], 'Aula');
  });

  test('GerejaCoverModel parses API shape', () {
    final cover = GerejaCoverModel.fromJson({'id': 'c1', 'key': 'bpm', 'image_url': 'https://x/c.jpg'});
    expect(cover.key, 'bpm');
    expect(cover.imageUrl, 'https://x/c.jpg');
  });
}
