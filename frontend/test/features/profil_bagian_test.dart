import 'package:flutter_test/flutter_test.dart';
import 'package:gkjw_karangpilang/features/gereja/models/profil_bagian.dart';

void main() {
  const info = <String, dynamic>{
    'visi': ' Menjadi gereja yang melayani ',
    'misi': '',
    'sejarah': 'Berdiri tahun 1930.',
    'sejarah_foto': 'https://x/sejarah.jpg',
    'visi_misi_foto': '  ',
  };

  test('slug ↔ bagian', () {
    for (final b in ProfilBagian.values) {
      expect(ProfilBagian.fromSlug(b.slug), b);
    }
    expect(ProfilBagian.fromSlug('lain'), isNull);
    expect(ProfilBagian.fromSlug(null), isNull);
  });

  test('judul tiap bagian', () {
    expect(ProfilBagian.values.map((b) => b.judul), [
      'Visi dan Misi',
      'Sejarah GKJW Karangpilang',
      'Potret Diri',
    ]);
  });

  test('foto kosong dianggap tidak ada', () {
    expect(ProfilBagian.sejarah.foto(info), 'https://x/sejarah.jpg');
    expect(ProfilBagian.visiMisi.foto(info), isNull);
    expect(ProfilBagian.potretDiri.foto(info), isNull);
  });

  test('isi melewati teks kosong dan merapikan spasi', () {
    final visiMisi = ProfilBagian.visiMisi.isi(info);
    expect(visiMisi, hasLength(1));
    expect(visiMisi.single.judul, 'Visi');
    expect(visiMisi.single.isi, 'Menjadi gereja yang melayani');
    expect(ProfilBagian.sejarah.isi(info).single.judul, isNull);
    expect(ProfilBagian.potretDiri.isi(info), isEmpty);
  });
}
