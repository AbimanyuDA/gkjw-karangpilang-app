// lib/providers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/firestore_service.dart';
import '../data/services/supabase_service.dart';

// Services
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());
final supabaseServiceProvider = Provider<SupabaseService>((ref) => SupabaseService());

// PDF Streams (Firestore)
final wartaProvider = StreamProvider((ref) =>
    ref.watch(firestoreServiceProvider).watchWarta());

final tataIbadahProvider = StreamProvider((ref) =>
    ref.watch(firestoreServiceProvider).watchTataIbadah());

final renunganProvider = StreamProvider((ref) =>
    ref.watch(firestoreServiceProvider).watchRenungan());

// Siaran
final siaranKategoriProvider = StateProvider<String?>((ref) => null);
final siaranProvider = StreamProvider((ref) {
  final kategori = ref.watch(siaranKategoriProvider);
  return ref.watch(firestoreServiceProvider).watchSiaran(kategori: kategori);
});

// Supabase Providers
final galeriTahunProvider = FutureProvider<List<int>>(
    (ref) => ref.watch(supabaseServiceProvider).getGaleriTahun());

final selectedTahunProvider = StateProvider<int?>((ref) => null);
final galeriProvider = FutureProvider((ref) {
  final tahun = ref.watch(selectedTahunProvider);
  return ref.watch(supabaseServiceProvider).getGaleri(tahun: tahun);
});

final agendaProvider = FutureProvider(
    (ref) => ref.watch(supabaseServiceProvider).getAgenda());

final kependetaanProvider = FutureProvider(
    (ref) => ref.watch(supabaseServiceProvider).getKependetaan());

final kemajelisanProvider = FutureProvider(
    (ref) => ref.watch(supabaseServiceProvider).getKemajelisan());

final bpmProvider = FutureProvider(
    (ref) => ref.watch(supabaseServiceProvider).getBpm());

final perwilayahanProvider = FutureProvider(
    (ref) => ref.watch(supabaseServiceProvider).getPerwilayahan());

final profilRuanganProvider = FutureProvider(
    (ref) => ref.watch(supabaseServiceProvider).getProfilRuangan());

final eperpusProvider = FutureProvider(
    (ref) => ref.watch(supabaseServiceProvider).getEperpus());

final inspirasiKategoriProvider = StateProvider<String>((ref) => 'dewasa');
final inspirasiProvider = FutureProvider((ref) {
  final kategori = ref.watch(inspirasiKategoriProvider);
  return ref.watch(supabaseServiceProvider).getInspirasi(kategori: kategori);
});

final informasiGerejaProvider = FutureProvider(
    (ref) => ref.watch(supabaseServiceProvider).getInformasiGereja());

final notifikasiProvider = FutureProvider(
    (ref) => ref.watch(supabaseServiceProvider).getNotifikasi());

final faqProvider = FutureProvider(
    (ref) => ref.watch(supabaseServiceProvider).getFaq());

final hubungiProvider = FutureProvider(
    (ref) => ref.watch(supabaseServiceProvider).getHubungi());

final tentangProvider = FutureProvider(
    (ref) => ref.watch(supabaseServiceProvider).getTentang());
