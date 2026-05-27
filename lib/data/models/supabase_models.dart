// lib/data/models/supabase_models.dart

// ── BANNER SLIDE ──
class BannerSlideModel {
  final String id;
  final String imageUrl;
  final String? judul;
  final String? linkUrl;
  final int urutan;
  final bool isActive;
  final DateTime createdAt;

  const BannerSlideModel({
    required this.id,
    required this.imageUrl,
    this.judul,
    this.linkUrl,
    required this.urutan,
    required this.isActive,
    required this.createdAt,
  });

  factory BannerSlideModel.fromJson(Map<String, dynamic> json) =>
      BannerSlideModel(
        id: json['id'],
        imageUrl: json['image_url'] ?? '',
        judul: json['judul'],
        linkUrl: json['link_url'],
        urutan: json['urutan'] ?? 0,
        isActive: json['is_active'] ?? true,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'image_url': imageUrl,
        'judul': judul,
        'link_url': linkUrl,
        'urutan': urutan,
        'is_active': isActive,
      };
}

class GaleriModel {
  final String id;
  final String judul;
  final String? deskripsi;
  final int tahun;
  final String? komisi;
  final String imageUrl; // maps to 'foto_url' in DB
  final DateTime createdAt;

  const GaleriModel({
    required this.id,
    required this.judul,
    this.deskripsi,
    required this.tahun,
    this.komisi,
    required this.imageUrl,
    required this.createdAt,
  });

  factory GaleriModel.fromJson(Map<String, dynamic> json) => GaleriModel(
        id: json['id'],
        judul: json['judul'],
        deskripsi: json['deskripsi'],
        tahun: json['tahun'],
        komisi: json['komisi'],
        imageUrl: json['foto_url'] ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'judul': judul,
        'deskripsi': deskripsi,
        'tahun': tahun,
        'komisi': komisi,
        'foto_url': imageUrl,
      };
}

class AgendaModel {
  final String id;
  final String judul;
  final String? deskripsi;
  final DateTime tanggal;
  final String? lokasi; // maps to 'tempat' in DB

  const AgendaModel({
    required this.id,
    required this.judul,
    this.deskripsi,
    required this.tanggal,
    this.lokasi,
  });

  factory AgendaModel.fromJson(Map<String, dynamic> json) => AgendaModel(
        id: json['id'],
        judul: json['judul'],
        deskripsi: json['deskripsi'],
        tanggal: DateTime.parse(json['tanggal']),
        lokasi: json['tempat'] ?? json['lokasi'],
      );

  Map<String, dynamic> toJson() => {
        'judul': judul,
        'deskripsi': deskripsi,
        'tanggal': tanggal.toIso8601String(),
        'tempat': lokasi,
      };
}

class ProfilModel {
  final String id;
  final String nama;
  final String jabatan;
  final String? fotoUrl;
  final String? bio;
  final String? komisi;
  final int urutan;

  const ProfilModel({
    required this.id,
    required this.nama,
    required this.jabatan,
    this.fotoUrl,
    this.bio,
    this.komisi,
    this.urutan = 0,
  });

  factory ProfilModel.fromJson(Map<String, dynamic> json) => ProfilModel(
        id: json['id'],
        nama: json['nama'],
        jabatan: json['jabatan'],
        fotoUrl: json['foto_url'],
        bio: json['bio'],
        komisi: json['komisi'],
        urutan: json['urutan'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'nama': nama,
        'jabatan': jabatan,
        'foto_url': fotoUrl,
        'bio': bio,
        'komisi': komisi,
        'urutan': urutan,
      };
}

class EperpusModel {
  final String id;
  final String judul;
  final String? penulis;
  final String? deskripsi;
  final String? coverUrl;
  final String fileUrl;
  final int? tahun;

  const EperpusModel({
    required this.id,
    required this.judul,
    this.penulis,
    this.deskripsi,
    this.coverUrl,
    required this.fileUrl,
    this.tahun,
  });

  factory EperpusModel.fromJson(Map<String, dynamic> json) => EperpusModel(
        id: json['id'],
        judul: json['judul'],
        penulis: json['penulis'],
        deskripsi: json['deskripsi'],
        coverUrl: json['cover_url'],
        fileUrl: json['file_url'] ?? '',
        tahun: json['tahun'],
      );

  Map<String, dynamic> toJson() => {
        'judul': judul,
        'penulis': penulis,
        'deskripsi': deskripsi,
        'cover_url': coverUrl,
        'file_url': fileUrl,
        'tahun': tahun,
      };
}

class InspirasiModel {
  final String id;
  final String kategori;
  final String teks;
  final String warna;

  const InspirasiModel({
    required this.id,
    required this.kategori,
    required this.teks,
    required this.warna,
  });

  factory InspirasiModel.fromJson(Map<String, dynamic> json) => InspirasiModel(
        id: json['id'],
        kategori: json['kategori'],
        teks: json['teks'],
        warna: json['warna'] ?? '#3B82F6',
      );

  Map<String, dynamic> toJson() => {
        'kategori': kategori,
        'teks': teks,
        'warna': warna,
      };
}

class FaqModel {
  final String id;
  final String pertanyaan;
  final String jawaban;
  final int urutan;

  const FaqModel({
    required this.id,
    required this.pertanyaan,
    required this.jawaban,
    required this.urutan,
  });

  factory FaqModel.fromJson(Map<String, dynamic> json) => FaqModel(
        id: json['id'],
        pertanyaan: json['pertanyaan'],
        jawaban: json['jawaban'],
        urutan: json['urutan'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'pertanyaan': pertanyaan,
        'jawaban': jawaban,
        'urutan': urutan,
      };
}

class HubungiModel {
  final String id;
  final String nama;
  final String jenis; // 'telepon', 'email', 'whatsapp', 'maps'
  final String nilai;
  final String? ikon;
  final int urutan;

  const HubungiModel({
    required this.id,
    required this.nama,
    required this.jenis,
    required this.nilai,
    this.ikon,
    this.urutan = 0,
  });

  factory HubungiModel.fromJson(Map<String, dynamic> json) => HubungiModel(
        id: json['id'],
        nama: json['nama'],
        jenis: json['jenis'],
        nilai: json['nilai'],
        ikon: json['ikon'],
        urutan: json['urutan'] ?? 0,
      );
}

class NotifikasiModel {
  final String id;
  final String judul;
  final String pesan;
  final bool isActive;
  final DateTime createdAt;

  const NotifikasiModel({
    required this.id,
    required this.judul,
    required this.pesan,
    required this.isActive,
    required this.createdAt,
  });

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) => NotifikasiModel(
        id: json['id'],
        judul: json['judul'],
        pesan: json['pesan'],
        isActive: json['is_active'] ?? true,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'judul': judul,
        'pesan': pesan,
        'is_active': isActive,
      };
}

class SapaanConfigModel {
  final String id;
  final int jamPagi;
  final int menitPagi;
  final int jamMalam;
  final int menitMalam;
  final String ayatPagi;
  final String ayatMalam;
  final DateTime updatedAt;

  const SapaanConfigModel({
    required this.id,
    required this.jamPagi,
    required this.menitPagi,
    required this.jamMalam,
    required this.menitMalam,
    required this.ayatPagi,
    required this.ayatMalam,
    required this.updatedAt,
  });

  factory SapaanConfigModel.fromJson(Map<String, dynamic> json) =>
      SapaanConfigModel(
        id: json['id'] ?? '',
        jamPagi: json['jam_pagi'] ?? 7,
        menitPagi: json['menit_pagi'] ?? 0,
        jamMalam: json['jam_malam'] ?? 19,
        menitMalam: json['menit_malam'] ?? 0,
        ayatPagi: json['ayat_pagi'] ?? '',
        ayatMalam: json['ayat_malam'] ?? '',
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'jam_pagi': jamPagi,
        'menit_pagi': menitPagi,
        'jam_malam': jamMalam,
        'menit_malam': menitMalam,
        'ayat_pagi': ayatPagi,
        'ayat_malam': ayatMalam,
      };

  SapaanConfigModel copyWith({
    String? id,
    int? jamPagi,
    int? menitPagi,
    int? jamMalam,
    int? menitMalam,
    String? ayatPagi,
    String? ayatMalam,
    DateTime? updatedAt,
  }) {
    return SapaanConfigModel(
      id: id ?? this.id,
      jamPagi: jamPagi ?? this.jamPagi,
      menitPagi: menitPagi ?? this.menitPagi,
      jamMalam: jamMalam ?? this.jamMalam,
      menitMalam: menitMalam ?? this.menitMalam,
      ayatPagi: ayatPagi ?? this.ayatPagi,
      ayatMalam: ayatMalam ?? this.ayatMalam,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

