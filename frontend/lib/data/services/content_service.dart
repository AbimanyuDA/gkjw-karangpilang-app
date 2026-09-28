// lib/data/services/content_service.dart
// Satu pintu baca konten dari backend GKJW (menggantikan SupabaseService & FirestoreService).
// Aplikasi hanya membaca; konten dikelola lewat website admin (folder admin-web/).
import '../api/api_client.dart';
import '../models/content_models.dart';
import '../models/pdf_item_model.dart';

class ContentService {
  ContentService(this._api);
  final ApiClient _api;

  // Batas item per permintaan (server maksimal 200).
  static const _pageSize = 50;
  static const _all = 200;

  Future<List<BannerSlideModel>> getBannerSlides() async =>
      (await _api.getList('/banners')).map(BannerSlideModel.fromJson).toList();

  Future<List<GaleriModel>> getGaleri({int? tahun}) async =>
      (await _api.getList('/galeri', query: {'limit': _all, 'tahun': ?tahun}))
          .map(GaleriModel.fromJson)
          .toList();

  Future<List<int>> getGaleriTahun() => _api.getValues<int>('/galeri/tahun');

  Future<List<AgendaModel>> getAgenda() async =>
      (await _api.getList('/agenda', query: {'limit': _all})).map(AgendaModel.fromJson).toList();

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

  Future<List<GerejaCoverModel>> getGerejaCovers() async =>
      (await _api.getList('/gereja-covers')).map(GerejaCoverModel.fromJson).toList();

  Future<List<EperpusModel>> getEperpus() async =>
      (await _api.getList('/eperpus', query: {'limit': _all})).map(EperpusModel.fromJson).toList();

  Future<List<InspirasiModel>> getInspirasi({required String kategori}) async =>
      (await _api.getList('/inspirasi', query: {'kategori': kategori, 'limit': _all}))
          .map(InspirasiModel.fromJson)
          .toList();

  Future<List<NotifikasiModel>> getNotifikasi() async =>
      (await _api.getList('/notifikasi')).map(NotifikasiModel.fromJson).toList();

  Future<List<FaqModel>> getFaq() async =>
      (await _api.getList('/faq', query: {'limit': _all})).map(FaqModel.fromJson).toList();

  Future<List<HubungiModel>> getHubungi() async =>
      (await _api.getList('/hubungi-kami')).map(HubungiModel.fromJson).toList();

  Future<Map<String, dynamic>?> getTentang() => _api.getObject('/tentang-aplikasi');

  Future<SapaanConfigModel?> getSapaanConfig() async {
    final res = await _api.getObject('/sapaan-config');
    return res == null ? null : SapaanConfigModel.fromJson(res);
  }

  /// Warta, Tata Ibadah, atau Renungan.
  Future<List<PdfItem>> getDokumen(DokumenKategori kategori) async => (await _api.getList(
        '/dokumen',
        query: {'kategori': kategori.apiValue, 'limit': _pageSize},
      ))
          .map(PdfItem.fromJson)
          .toList();

  Future<List<VideoSiaran>> getSiaran({String? kategori}) async =>
      (await _api.getList('/siaran', query: {'limit': _pageSize, 'kategori': ?kategori}))
          .map(VideoSiaran.fromJson)
          .toList();
}
