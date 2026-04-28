// lib/features/gereja/screens/kependetaan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/profil_list_screen.dart';
import '../../../providers/providers.dart';

class KependetaanScreen extends ConsumerWidget {
  const KependetaanScreen({super.key});
  @override
  Widget build(context, ref) {
    final data = ref.watch(kependetaanProvider);
    return data.when(
      loading: () => Scaffold(appBar: AppBar(title: const Text('Kependetaan')),
          body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(title: const Text('Kependetaan')),
          body: const Center(child: Text('Gagal memuat data'))),
      data: (items) => ProfilListScreen(
        title: 'Kependetaan',
        items: items.map((e) => {
          'nama': e.nama, 'jabatan': e.jabatan,
          'foto_url': e.fotoUrl, 'bio': e.bio,
        }).toList(),
      ),
    );
  }
}
