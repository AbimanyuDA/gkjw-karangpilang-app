// lib/features/gereja/models/teks_format.dart
//
// Format teks sederhana ala WhatsApp untuk isian admin:
//   - baris diawali "- ", "• " atau "* "  → poin
//   - baris diawali "1. " / "1) "          → daftar bernomor
//   - baris kosong                         → paragraf baru

sealed class BlokTeks {
  const BlokTeks();
}

/// Paragraf biasa; baris-barisnya tetap dipisah seperti yang diketik admin.
final class Paragraf extends BlokTeks {
  final String teks;
  const Paragraf(this.teks);

  @override
  bool operator ==(Object other) => other is Paragraf && other.teks == teks;
  @override
  int get hashCode => teks.hashCode;
  @override
  String toString() => 'Paragraf($teks)';
}

/// Daftar poin (bullet) atau bernomor.
final class Daftar extends BlokTeks {
  final List<String> poin;

  /// Nomor poin pertama; null untuk poin tanpa nomor.
  final int? mulai;
  const Daftar(this.poin, {this.mulai});

  bool get bernomor => mulai != null;

  @override
  bool operator ==(Object other) =>
      other is Daftar &&
      other.mulai == mulai &&
      other.poin.length == poin.length &&
      Iterable.generate(poin.length).every((i) => other.poin[i] == poin[i]);
  @override
  int get hashCode => Object.hash(mulai, Object.hashAll(poin));
  @override
  String toString() => 'Daftar($poin, mulai: $mulai)';
}

final _poin = RegExp(r'^\s*[-•*]\s+(.+)$');
final _nomor = RegExp(r'^\s*(\d{1,3})[.)]\s+(.+)$');

List<BlokTeks> parseTeks(String teks) {
  final blok = <BlokTeks>[];
  final paragraf = <String>[];
  final daftar = <String>[];
  int? mulai;
  var bernomor = false;

  void tutupParagraf() {
    if (paragraf.isEmpty) return;
    blok.add(Paragraf(paragraf.join('\n')));
    paragraf.clear();
  }

  void tutupDaftar() {
    if (daftar.isEmpty) return;
    blok.add(Daftar(List.unmodifiable(daftar), mulai: bernomor ? mulai : null));
    daftar.clear();
  }

  for (final baris in teks.split('\n')) {
    final bersih = baris.trim();
    final nomor = _nomor.firstMatch(baris);
    final poin = nomor == null ? _poin.firstMatch(baris) : null;

    if (bersih.isEmpty) {
      tutupParagraf();
      tutupDaftar();
    } else if (nomor != null || poin != null) {
      tutupParagraf();
      final jenisBernomor = nomor != null;
      // Ganti jenis daftar (poin ↔ nomor) memulai daftar baru.
      if (daftar.isNotEmpty && bernomor != jenisBernomor) tutupDaftar();
      if (daftar.isEmpty) {
        bernomor = jenisBernomor;
        mulai = jenisBernomor ? int.parse(nomor.group(1)!) : null;
      }
      daftar.add((nomor?.group(2) ?? poin!.group(1)!).trim());
    } else {
      tutupDaftar();
      paragraf.add(bersih);
    }
  }
  tutupParagraf();
  tutupDaftar();
  return List.unmodifiable(blok);
}
