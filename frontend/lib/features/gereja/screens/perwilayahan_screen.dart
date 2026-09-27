// lib/features/gereja/screens/perwilayahan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/profil_list_screen.dart';
import '../../../providers/providers.dart';

class PerwilayahanScreen extends ConsumerWidget {
  const PerwilayahanScreen({super.key});
  @override
  Widget build(context, ref) {
    final data = ref.watch(perwilayahanProvider);
    return data.when(
      loading: () => Scaffold(appBar: AppBar(title: const Text('Perwilayahan')),
          body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(title: const Text('Perwilayahan')),
          body: const Center(child: Text('Gagal memuat data'))),
      data: (items) => ProfilListScreen(
        title: 'Perwilayahan',
        items: items,
        jabatanKey: 'ketua',
        bioKey: 'deskripsi',
      ),
    );
  }
}
