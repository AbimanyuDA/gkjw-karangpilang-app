// lib/data/services/content_service.dart
// Satu pintu akses konten ke backend GKJW (menggantikan SupabaseService & FirestoreService).
// Endpoint publik: /xxx  —  endpoint admin (butuh login): /admin/xxx
import '../../core/config/api_config.dart';
import '../api/api_client.dart';
import '../models/content_models.dart';
import '../models/pdf_item_model.dart';

class ContentService {
  ContentService(this._api);
  final ApiClient _api;

  // Batas item per permintaan (server maksimal 200).
  static const _pageSize = 50;
  static const _all = 200;

  // ===== FILE =====
  /// Hapus file hasil upload berdasarkan URL-nya. URL dari luar server kita
  /// (mis. link Google Drive atau data lama) diabaikan.
  Future<void> deleteFile(String url) =>
      _api.deleteFileByUrl(url, filesUrlPrefix: ApiConfig.filesUrl);

  // ===== BANNER SLIDE =====
  Future<List<BannerSlideModel>> getBannerSlides() async =>
      (await _api.getList('/banners')).map(BannerSlideModel.fromJson).toList();

  Future<List<BannerSlideModel>> getAllBannerSlides() async =>
      (await _api.getList('/admin/banners', query: {'limit': _all}))
          .map(BannerSlideModel.fromJson)
          .toList();

  Future<void> addBannerSlide(BannerSlideModel item) =>
      _api.post('/admin/banners', item.toJson());

  Future<void> updateBannerSlide(BannerSlideModel item) =>
      _api.put('/admin/banners/${item.id}', item.toJson());

  Future<void> deleteBannerSlide(String id) => _api.delete('/admin/banners/$id');

  // ===== GALERI =====
  Future<List<GaleriModel>> getGaleri({int? tahun}) async => (await _api.getList(
        '/galeri',
        query: {'limit': _all, 'tahun': ?tahun},
      ))
          .map(GaleriModel.fromJson)
          .toList();

  Future<List<int>> getGaleriTahun() => _api.getValues<int>('/galeri/tahun');

  Future<void> addGaleri(GaleriModel item) => _api.post('/admin/galeri', item.toJson());

  Future<void> deleteGaleri(String id) => _api.delete('/admin/galeri/$id');

  // ===== AGENDA =====
  Future<List<AgendaModel>> getAgenda() async =>
      (await _api.getList('/agenda', query: {'limit': _all})).map(AgendaModel.fromJson).toList();

  Future<void> addAgenda(AgendaModel item) => _api.post('/admin/agenda', item.toJson());

  Future<void> updateAgenda(AgendaModel item) =>
      _api.put('/admin/agenda/${item.id}', item.toJson());

  Future<void> deleteAgenda(String id) => _api.delete('/admin/agenda/$id');

  // ===== PROFIL GEREJA =====
  Future<List<ProfilModel>> getKependetaan() async =>
      (await _api.getList('/kependetaan', query: {'limit': _all})).map(ProfilModel.fromJson).toList();

  Future<List<ProfilModel>> getKemajelisan() async =>
      (await _api.getList('/kemajelisan', query: {'limit': _all})).map(ProfilModel.fromJson).toList();

  Future<List<Map<String, dynamic>>> getBpm() => _api.getList('/bpm', query: {'limit': _all});

  Future<List<Map<String, dynamic>>> getPerwilayahan() =>
      _api.getList('/perwilayahan', query: {'limit': _all});

  Future<List<Map<String, dynamic>>> getProfilRuangan() =>
      _api.getList('/profil-ruangan', query: {'limit': _all});

  Future<Map<String, dynamic>?> getInformasiGereja() => _api.getObject('/informasi-gereja');

  // ===== COVER HALAMAN GEREJA =====
  Future<List<GerejaCoverModel>> getGerejaCovers() async =>
      (await _api.getList('/gereja-covers')).map(GerejaCoverModel.fromJson).toList();

  /// Buat atau ganti cover untuk satu menu.
  Future<void> setGerejaCover(String key, String imageUrl) =>
      _api.post('/admin/gereja-covers', {'key': key, 'image_url': imageUrl});

  Future<void> deleteGerejaCover(String id) => _api.delete('/admin/gereja-covers/$id');

  // ===== E-PERPUSTAKAAN =====
  Future<List<EperpusModel>> getEperpus() async =>
      (await _api.getList('/eperpus', query: {'limit': _all})).map(EperpusModel.fromJson).toList();

  // ===== INSPIRASI =====
  Future<List<InspirasiModel>> getInspirasi({required String kategori}) async =>
      (await _api.getList('/inspirasi', query: {'kategori': kategori, 'limit': _all}))
          .map(InspirasiModel.fromJson)
          .toList();

  // ===== NOTIFIKASI =====
  Future<List<NotifikasiModel>> getNotifikasi() async =>
      (await _api.getList('/notifikasi')).map(NotifikasiModel.fromJson).toList();

  Future<void> addNotifikasi(NotifikasiModel item) =>
      _api.post('/admin/notifikasi', item.toJson());

  Future<void> deleteNotifikasi(String id) => _api.delete('/admin/notifikasi/$id');

  // ===== FAQ / HUBUNGI / TENTANG =====
  Future<List<FaqModel>> getFaq() async =>
      (await _api.getList('/faq', query: {'limit': _all})).map(FaqModel.fromJson).toList();

  Future<List<HubungiModel>> getHubungi() async =>
      (await _api.getList('/hubungi-kami')).map(HubungiModel.fromJson).toList();

  Future<Map<String, dynamic>?> getTentang() => _api.getObject('/tentang-aplikasi');

  // ===== SAPAAN CONFIG =====
  Future<SapaanConfigModel?> getSapaanConfig() async {
    final res = await _api.getObject('/sapaan-config');
    return res == null ? null : SapaanConfigModel.fromJson(res);
  }

  Future<void> updateSapaanConfig(SapaanConfigModel item) =>
      _api.put('/admin/sapaan-config', item.toJson());

  // ===== DOKUMEN PDF (Warta, Tata Ibadah, Renungan) =====
  Future<List<PdfItem>> getDokumen(DokumenKategori kategori) async => (await _api.getList(
        '/dokumen',
        query: {'kategori': kategori.apiValue, 'limit': _pageSize},
      ))
          .map(PdfItem.fromJson)
          .toList();

  Future<void> addDokumen(DokumenKategori kategori, PdfItem item) =>
      _api.post('/admin/dokumen', item.toJson(kategori));

  Future<void> deleteDokumen(String id) => _api.delete('/admin/dokumen/$id');

  // ===== SIARAN VIDEO =====
  Future<List<VideoSiaran>> getSiaran({String? kategori}) async => (await _api.getList(
        '/siaran',
        query: {'limit': _pageSize, 'kategori': ?kategori},
      ))
          .map(VideoSiaran.fromJson)
          .toList();

  Future<void> addSiaran(VideoSiaran video) => _api.post('/admin/siaran', video.toJson());

  Future<void> deleteSiaran(String id) => _api.delete('/admin/siaran/$id');
}
