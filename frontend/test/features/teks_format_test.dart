import 'package:flutter_test/flutter_test.dart';
import 'package:gkjw_karangpilang/features/gereja/models/teks_format.dart';

void main() {
  test('paragraf dipisah baris kosong, baris tunggal tetap satu paragraf', () {
    expect(parseTeks('Nama: GKJW\nBerdiri: 1996\n\nParagraf kedua.'), const [
      Paragraf('Nama: GKJW\nBerdiri: 1996'),
      Paragraf('Paragraf kedua.'),
    ]);
  });

  test('baris diawali "- " menjadi poin, juga • dan *', () {
    expect(parseTeks('Wilayah:\n- Karangpilang\n• Wiyung\n* Gresik'), const [
      Paragraf('Wilayah:'),
      Daftar(['Karangpilang', 'Wiyung', 'Gresik']),
    ]);
  });

  test(
    'baris diawali nomor menjadi daftar bernomor mulai dari nomor pertama',
    () {
      expect(parseTeks('3. Tiga\n4) Empat'), const [
        Daftar(['Tiga', 'Empat'], mulai: 3),
      ]);
    },
  );

  test('tanda hubung di tengah kalimat atau tanpa spasi bukan poin', () {
    expect(parseTeks('Surabaya - Gresik\n-tanpa spasi\n1990.'), const [
      Paragraf('Surabaya - Gresik\n-tanpa spasi\n1990.'),
    ]);
  });

  test('ganti jenis daftar dan teks setelah daftar membuat blok baru', () {
    expect(parseTeks('- a\n1. b\nlanjut'), const [
      Daftar(['a']),
      Daftar(['b'], mulai: 1),
      Paragraf('lanjut'),
    ]);
  });

  test('teks kosong', () {
    expect(parseTeks('  \n\n'), isEmpty);
  });
}
