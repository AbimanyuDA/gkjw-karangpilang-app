// lib/data/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supabase_models.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  // ===== BANNER SLIDE =====
  Future<List<BannerSlideModel>> getBannerSlides() async {
    final res = await _client
        .from('banner_slide')
        .select()
        .eq('is_active', true)
        .order('urutan');
    return (res as List).map((e) => BannerSlideModel.fromJson(e)).toList();
  }

  Future<List<BannerSlideModel>> getAllBannerSlides() async {
    final res = await _client
        .from('banner_slide')
        .select()
        .order('urutan');
    return (res as List).map((e) => BannerSlideModel.fromJson(e)).toList();
  }

  Future<void> addBannerSlide(BannerSlideModel item) async =>
      await _client.from('banner_slide').insert(item.toJson());

  Future<void> updateBannerSlide(BannerSlideModel item) async =>
      await _client.from('banner_slide').update(item.toJson()).eq('id', item.id);

  Future<void> deleteBannerSlide(String id) async =>
      await _client.from('banner_slide').delete().eq('id', id);

  // ===== GALERI =====
  Future<List<GaleriModel>> getGaleri({int? tahun}) async {
    var query = _client.from('galeri').select().order('tahun', ascending: false);
    final res = await query;
    final list = (res as List).map((e) => GaleriModel.fromJson(e)).toList();
    if (tahun != null) return list.where((g) => g.tahun == tahun).toList();
    return list;
  }

  Future<List<int>> getGaleriTahun() async {
    final res = await _client.from('galeri').select('tahun');
    final years = (res as List).map((e) => e['tahun'] as int).toSet().toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  Future<void> addGaleri(GaleriModel item) async =>
      await _client.from('galeri').insert(item.toJson());

  Future<void> deleteGaleri(String id) async =>
      await _client.from('galeri').delete().eq('id', id);

  // ===== AGENDA =====
  Future<List<AgendaModel>> getAgenda() async {
    final res = await _client.from('agenda').select().order('tanggal');
    return (res as List).map((e) => AgendaModel.fromJson(e)).toList();
  }

  Future<void> addAgenda(AgendaModel item) async =>
      await _client.from('agenda').insert(item.toJson());

  Future<void> updateAgenda(AgendaModel item) async =>
      await _client.from('agenda').update(item.toJson()).eq('id', item.id);

  Future<void> deleteAgenda(String id) async =>
      await _client.from('agenda').delete().eq('id', id);

  // ===== KEPENDETAAN =====
  Future<List<ProfilModel>> getKependetaan() async {
    final res = await _client.from('kependetaan').select().order('urutan');
    return (res as List).map((e) => ProfilModel.fromJson(e)).toList();
  }

  Future<void> upsertKependetaan(ProfilModel item, {String? id}) async {
    if (id != null) {
      await _client.from('kependetaan').update(item.toJson()).eq('id', id);
    } else {
      await _client.from('kependetaan').insert(item.toJson());
    }
  }

  Future<void> deleteKependetaan(String id) async =>
      await _client.from('kependetaan').delete().eq('id', id);

  // ===== KEMAJELISAN =====
  Future<List<ProfilModel>> getKemajelisan() async {
    final res = await _client.from('kemajelisan').select().order('urutan');
    return (res as List).map((e) => ProfilModel.fromJson(e)).toList();
  }

  Future<void> upsertKemajelisan(ProfilModel item, {String? id}) async {
    if (id != null) {
      await _client.from('kemajelisan').update(item.toJson()).eq('id', id);
    } else {
      await _client.from('kemajelisan').insert(item.toJson());
    }
  }

  Future<void> deleteKemajelisan(String id) async =>
      await _client.from('kemajelisan').delete().eq('id', id);

  // ===== BPM =====
  Future<List<Map<String, dynamic>>> getBpm() async {
    final res = await _client.from('bpm').select().order('urutan');
    return List<Map<String, dynamic>>.from(res);
  }

  // ===== PERWILAYAHAN =====
  Future<List<Map<String, dynamic>>> getPerwilayahan() async {
    final res = await _client.from('perwilayahan').select().order('urutan');
    return List<Map<String, dynamic>>.from(res);
  }

  // ===== PROFIL RUANGAN =====
  Future<List<Map<String, dynamic>>> getProfilRuangan() async {
    final res = await _client.from('profil_ruangan').select().order('urutan');
    return List<Map<String, dynamic>>.from(res);
  }

  // ===== E-PERPUSTAKAAN =====
  Future<List<EperpusModel>> getEperpus() async {
    final res = await _client
        .from('eperpus')
        .select()
        .order('created_at', ascending: false);
    return (res as List).map((e) => EperpusModel.fromJson(e)).toList();
  }

  Future<void> addEperpus(EperpusModel item) async =>
      await _client.from('eperpus').insert(item.toJson());

  Future<void> deleteEperpus(String id) async =>
      await _client.from('eperpus').delete().eq('id', id);

  // ===== INSPIRASI =====
  Future<List<InspirasiModel>> getInspirasi({required String kategori}) async {
    final res =
        await _client.from('inspirasi').select().eq('kategori', kategori);
    return (res as List).map((e) => InspirasiModel.fromJson(e)).toList();
  }

  Future<void> addInspirasi(InspirasiModel item) async =>
      await _client.from('inspirasi').insert(item.toJson());

  Future<void> deleteInspirasi(String id) async =>
      await _client.from('inspirasi').delete().eq('id', id);

  // ===== INFORMASI GEREJA =====
  Future<Map<String, dynamic>?> getInformasiGereja() async {
    final res =
        await _client.from('informasi_gereja').select().limit(1).maybeSingle();
    return res;
  }

  Future<void> updateInformasiGereja(String id, Map<String, dynamic> data) async =>
      await _client.from('informasi_gereja').update(data).eq('id', id);

  // ===== NOTIFIKASI =====
  Future<List<NotifikasiModel>> getNotifikasi() async {
    final res = await _client
        .from('notifikasi')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return (res as List).map((e) => NotifikasiModel.fromJson(e)).toList();
  }

  Future<void> addNotifikasi(NotifikasiModel item) async =>
      await _client.from('notifikasi').insert(item.toJson());

  Future<void> deleteNotifikasi(String id) async =>
      await _client.from('notifikasi').delete().eq('id', id);

  // ===== FAQ =====
  Future<List<FaqModel>> getFaq() async {
    final res = await _client.from('faq').select().order('urutan');
    return (res as List).map((e) => FaqModel.fromJson(e)).toList();
  }

  Future<void> addFaq(FaqModel item) async =>
      await _client.from('faq').insert(item.toJson());

  Future<void> deleteFaq(String id) async =>
      await _client.from('faq').delete().eq('id', id);

  // ===== HUBUNGI KAMI =====
  Future<List<HubungiModel>> getHubungi() async {
    final res = await _client.from('hubungi_kami').select().order('urutan');
    return (res as List).map((e) => HubungiModel.fromJson(e)).toList();
  }

  // ===== TENTANG APLIKASI =====
  Future<Map<String, dynamic>?> getTentang() async {
    final res =
        await _client.from('tentang_aplikasi').select().limit(1).maybeSingle();
    return res;
  }

  // ===== SAPAAN CONFIG =====
  Future<SapaanConfigModel?> getSapaanConfig() async {
    final res = await _client
        .from('sapaan_config')
        .select()
        .limit(1)
        .maybeSingle();
    if (res == null) return null;
    return SapaanConfigModel.fromJson(res);
  }

  Future<void> updateSapaanConfig(SapaanConfigModel item) async =>
      await _client
          .from('sapaan_config')
          .update(item.toJson())
          .eq('id', item.id);

  // ===== SAPAAN AYAT RIWAYAT =====
  Future<List<SapaanAyatRiwayatModel>> getSapaanAyatRiwayat() async {
    final res = await _client
        .from('sapaan_ayat_riwayat')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    return (res as List).map((e) => SapaanAyatRiwayatModel.fromJson(e)).toList();
  }

  Future<void> addSapaanAyatRiwayat(SapaanAyatRiwayatModel item) async =>
      await _client.from('sapaan_ayat_riwayat').insert(item.toJson());

  // ===== SAPAAN JADWAL HARIAN =====
  Future<List<SapaanJadwalHarianModel>> getSapaanJadwalBulan(int tahun, int bulan) async {
    final from = DateTime(tahun, bulan, 1).toIso8601String().substring(0, 10);
    final to = DateTime(tahun, bulan + 1, 0).toIso8601String().substring(0, 10);
    final res = await _client
        .from('sapaan_jadwal_harian')
        .select()
        .gte('tanggal', from)
        .lte('tanggal', to)
        .order('tanggal');
    return (res as List).map((e) => SapaanJadwalHarianModel.fromJson(e)).toList();
  }

  Future<SapaanJadwalHarianModel?> getSapaanJadwalTanggal(DateTime tanggal) async {
    final tgl = tanggal.toIso8601String().substring(0, 10);
    final res = await _client
        .from('sapaan_jadwal_harian')
        .select()
        .eq('tanggal', tgl)
        .maybeSingle();
    if (res == null) return null;
    return SapaanJadwalHarianModel.fromJson(res);
  }

  Future<void> upsertSapaanJadwal(SapaanJadwalHarianModel item) async {
    await _client
        .from('sapaan_jadwal_harian')
        .upsert(item.toJson(), onConflict: 'tanggal');
  }
}
