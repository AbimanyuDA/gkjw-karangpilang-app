// lib/data/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pdf_item_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // WARTA JEMAAT
  Stream<List<PdfItem>> watchWarta() => _db
      .collection('warta_jemaat')
      .orderBy('tanggal', descending: true)
      .snapshots()
      .map((s) => s.docs.map(PdfItem.fromFirestore).toList());

  Future<void> addWarta(PdfItem item) =>
      _db.collection('warta_jemaat').add(item.toFirestore());

  Future<void> deleteWarta(String id) =>
      _db.collection('warta_jemaat').doc(id).delete();

  // TATA IBADAH
  Stream<List<PdfItem>> watchTataIbadah() => _db
      .collection('tata_ibadah')
      .orderBy('tanggal', descending: true)
      .snapshots()
      .map((s) => s.docs.map(PdfItem.fromFirestore).toList());

  Future<void> addTataIbadah(PdfItem item) =>
      _db.collection('tata_ibadah').add(item.toFirestore());

  Future<void> deleteTataIbadah(String id) =>
      _db.collection('tata_ibadah').doc(id).delete();

  // RENUNGAN
  Stream<List<PdfItem>> watchRenungan() => _db
      .collection('renungan')
      .orderBy('tanggal', descending: true)
      .snapshots()
      .map((s) => s.docs.map(PdfItem.fromFirestore).toList());

  Future<void> addRenungan(PdfItem item) =>
      _db.collection('renungan').add(item.toFirestore());

  Future<void> deleteRenungan(String id) =>
      _db.collection('renungan').doc(id).delete();

  // SIARAN VIDEO
  Stream<List<VideoSiaran>> watchSiaran({String? kategori}) {
    Query query = _db.collection('siaran').orderBy('tanggal', descending: true);
    if (kategori != null) query = query.where('kategori', isEqualTo: kategori);
    return query.snapshots().map((s) => s.docs.map(VideoSiaran.fromFirestore).toList());
  }

  Future<void> addSiaran(VideoSiaran video) =>
      _db.collection('siaran').add(video.toFirestore());

  Future<void> deleteSiaran(String id) =>
      _db.collection('siaran').doc(id).delete();
}
