// lib/data/models/pdf_item_model.dart

/// Kategori dokumen PDF (dulu tiga koleksi Firestore terpisah).
enum DokumenKategori {
  warta('warta'),
  tataIbadah('tata_ibadah'),
  renungan('renungan');

  const DokumenKategori(this.apiValue);
  final String apiValue;
}

class PdfItem {
  final String id;
  final String judul;
  final String url;
  final DateTime tanggal;
  final String? thumbnail;

  const PdfItem({
    required this.id,
    required this.judul,
    required this.url,
    required this.tanggal,
    this.thumbnail,
  });

  factory PdfItem.fromJson(Map<String, dynamic> json) => PdfItem(
        id: json['id'],
        judul: json['judul'] ?? '',
        url: json['url'] ?? '',
        tanggal: DateTime.parse(json['tanggal']).toLocal(),
        thumbnail: json['thumbnail'],
      );

  Map<String, dynamic> toJson(DokumenKategori kategori) => {
        'kategori': kategori.apiValue,
        'judul': judul,
        'url': url,
        'tanggal': tanggal.toUtc().toIso8601String(),
        if (thumbnail != null) 'thumbnail': thumbnail,
      };
}

class VideoSiaran {
  final String id;
  final String judul;
  final String youtubeId;
  final String kategori; // umum, anak, remaja, sekolah_minggu
  final DateTime tanggal;
  final String? thumbnail;
  final String? deskripsi;

  const VideoSiaran({
    required this.id,
    required this.judul,
    required this.youtubeId,
    required this.kategori,
    required this.tanggal,
    this.thumbnail,
    this.deskripsi,
  });

  factory VideoSiaran.fromJson(Map<String, dynamic> json) => VideoSiaran(
        id: json['id'],
        judul: json['judul'] ?? '',
        youtubeId: json['youtube_id'] ?? '',
        kategori: json['kategori'] ?? 'umum',
        tanggal: DateTime.parse(json['tanggal']).toLocal(),
        thumbnail: json['thumbnail'],
        deskripsi: json['deskripsi'],
      );

  Map<String, dynamic> toJson() => {
        'judul': judul,
        'youtube_id': youtubeId,
        'kategori': kategori,
        'tanggal': tanggal.toUtc().toIso8601String(),
        if (thumbnail != null) 'thumbnail': thumbnail,
        if (deskripsi != null && deskripsi!.isNotEmpty) 'deskripsi': deskripsi,
      };
}
