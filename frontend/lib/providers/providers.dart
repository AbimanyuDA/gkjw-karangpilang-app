// lib/providers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api/api_client.dart';
import '../data/models/content_models.dart';
import '../data/models/pdf_item_model.dart';
import '../data/services/auth_controller.dart';
import '../data/services/content_service.dart';

// ── Infrastruktur (di-override di main.dart) ─────────────────────
final authControllerProvider = Provider<AuthController>(
    (ref) => throw UnimplementedError('override authControllerProvider di main.dart'));

final apiClientProvider = Provider<ApiClient>(
    (ref) => throw UnimplementedError('override apiClientProvider di main.dart'));

final contentServiceProvider =
    Provider<ContentService>((ref) => ContentService(ref.watch(apiClientProvider)));

// ── Konten ───────────────────────────────────────────────────────
// Semua provider konten memakai autoDispose: data diambil ulang setiap layar
// dibuka lagi, sehingga warta yang baru diunggah admin langsung terlihat.

final dokumenProvider = FutureProvider.autoDispose.family<List<PdfItem>, DokumenKategori>(
    (ref, kategori) => ref.watch(contentServiceProvider).getDokumen(kategori));

final wartaProvider = dokumenProvider(DokumenKategori.warta);
final tataIbadahProvider = dokumenProvider(DokumenKategori.tataIbadah);
final renunganProvider = dokumenProvider(DokumenKategori.renungan);

// Siaran
final siaranKategoriProvider = StateProvider<String?>((ref) => null);
final siaranProvider = FutureProvider.autoDispose((ref) {
  final kategori = ref.watch(siaranKategoriProvider);
  return ref.watch(contentServiceProvider).getSiaran(kategori: kategori);
});

final galeriTahunProvider = FutureProvider.autoDispose<List<int>>(
    (ref) => ref.watch(contentServiceProvider).getGaleriTahun());

final selectedTahunProvider = StateProvider<int?>((ref) => null);
final galeriProvider = FutureProvider.autoDispose((ref) {
  final tahun = ref.watch(selectedTahunProvider);
  return ref.watch(contentServiceProvider).getGaleri(tahun: tahun);
});

final agendaProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(contentServiceProvider).getAgenda());

final kependetaanProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(contentServiceProvider).getKependetaan());

final kemajelisanProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(contentServiceProvider).getKemajelisan());

final bpmProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(contentServiceProvider).getBpm());

final perwilayahanProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(contentServiceProvider).getPerwilayahan());

final profilRuanganProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(contentServiceProvider).getProfilRuangan());

final gerejaCoversProvider = FutureProvider.autoDispose<List<GerejaCoverModel>>(
    (ref) => ref.watch(contentServiceProvider).getGerejaCovers());

final eperpusProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(contentServiceProvider).getEperpus());

final inspirasiKategoriProvider = StateProvider<String>((ref) => 'dewasa');
final inspirasiProvider = FutureProvider.autoDispose((ref) {
  final kategori = ref.watch(inspirasiKategoriProvider);
  return ref.watch(contentServiceProvider).getInspirasi(kategori: kategori);
});

final informasiGerejaProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(contentServiceProvider).getInformasiGereja());

final notifikasiProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(contentServiceProvider).getNotifikasi());

final faqProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(contentServiceProvider).getFaq());

final hubungiProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(contentServiceProvider).getHubungi());

final tentangProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(contentServiceProvider).getTentang());

final sapaanConfigProvider = FutureProvider.autoDispose<SapaanConfigModel?>(
    (ref) => ref.watch(contentServiceProvider).getSapaanConfig());
