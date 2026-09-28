import 'package:flutter_test/flutter_test.dart';
import 'package:gkjw_karangpilang/features/gereja/models/profil_bagian.dart';

void main() {
  const info = <String, dynamic>{
    'nama': 'GKJW Karangpilang',
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

  test('judul sejarah memakai nama gereja, dengan cadangan', () {
    expect(
      ProfilBagian.sejarah.judul(namaGereja(info)),
      'Sejarah GKJW Karangpilang',
    );
    expect(namaGereja(null), 'GKJW Karangpilang');
    expect(namaGereja({'nama': 'GKJW X'}), 'GKJW X');
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
