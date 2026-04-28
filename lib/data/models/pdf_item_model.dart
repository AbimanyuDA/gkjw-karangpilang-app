// lib/data/models/pdf_item_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PdfItem {
  final String id;
  final String judul;
  final String url; // file_url di Firestore
  final DateTime tanggal;
  final String? thumbnail;

  const PdfItem({
    required this.id,
    required this.judul,
    required this.url,
    required this.tanggal,
    this.thumbnail,
  });

  factory PdfItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PdfItem(
      id: doc.id,
      judul: data['judul'] ?? '',
      url: data['url'] ?? data['file_url'] ?? '',
      tanggal: data['tanggal'] is Timestamp
          ? (data['tanggal'] as Timestamp).toDate()
          : DateTime.now(),
      thumbnail: data['thumbnail'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'judul': judul,
        'url': url,
        'tanggal': Timestamp.fromDate(tanggal),
        if (thumbnail != null) 'thumbnail': thumbnail,
        'created_at': FieldValue.serverTimestamp(),
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

  factory VideoSiaran.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoSiaran(
      id: doc.id,
      judul: data['judul'] ?? '',
      youtubeId: data['youtube_id'] ?? '',
      kategori: data['kategori'] ?? 'umum',
      tanggal: data['tanggal'] is Timestamp
          ? (data['tanggal'] as Timestamp).toDate()
          : DateTime.now(),
      thumbnail: data['thumbnail'],
      deskripsi: data['deskripsi'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'judul': judul,
        'youtube_id': youtubeId,
        'kategori': kategori,
        'tanggal': Timestamp.fromDate(tanggal),
        if (thumbnail != null) 'thumbnail': thumbnail,
        if (deskripsi != null && deskripsi!.isNotEmpty) 'deskripsi': deskripsi,
        'created_at': FieldValue.serverTimestamp(),
      };
}

