// lib/features/gereja/models/profil_bagian.dart
//
// Tiga bagian halaman Informasi Gereja. Isinya diatur admin di menu
// "Informasi Gereja" (kolom foto & teks per bagian).

enum ProfilBagian {
  visiMisi(slug: 'visi-misi', fotoKey: 'visi_misi_foto'),
  sejarah(slug: 'sejarah', fotoKey: 'sejarah_foto'),
  potretDiri(slug: 'potret-diri', fotoKey: 'potret_foto');

  const ProfilBagian({required this.slug, required this.fotoKey});

  /// Segmen URL: /gereja/informasi/{slug}
  final String slug;

  /// Nama kolom foto di data informasi gereja.
  final String fotoKey;

  static ProfilBagian? fromSlug(String? slug) {
    for (final b in values) {
      if (b.slug == slug) return b;
    }
    return null;
  }

  String get judul => switch (this) {
    ProfilBagian.visiMisi => 'Visi dan Misi',
    ProfilBagian.sejarah => 'Sejarah GKJW Karangpilang',
    ProfilBagian.potretDiri => 'Potret Diri',
  };

  String? foto(Map<String, dynamic> info) => _teks(info[fotoKey]);

  /// Bagian-bagian teks yang ditampilkan di halaman detail (judul sub-bagian → isi).
  /// Judul null berarti isi langsung tanpa sub-judul.
  List<({String? judul, String isi})> isi(Map<String, dynamic> info) {
    final entries = switch (this) {
      ProfilBagian.visiMisi => [
        (judul: 'Visi' as String?, isi: _teks(info['visi'])),
        (judul: 'Misi' as String?, isi: _teks(info['misi'])),
      ],
      ProfilBagian.sejarah => [
        (judul: null as String?, isi: _teks(info['sejarah'])),
      ],
      ProfilBagian.potretDiri => [
        (judul: null as String?, isi: _teks(info['potret_diri'])),
      ],
    };
    return [
      for (final e in entries)
        if (e.isi != null) (judul: e.judul, isi: e.isi!),
    ];
  }
}

String? _teks(Object? v) {
  if (v is! String) return null;
  final t = v.trim();
  return t.isEmpty ? null : t;
}
