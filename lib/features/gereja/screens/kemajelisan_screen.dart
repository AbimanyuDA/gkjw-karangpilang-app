// lib/features/gereja/screens/kemajelisan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/profil_list_screen.dart';
import '../../../providers/providers.dart';

class KemajelisanScreen extends ConsumerWidget {
  const KemajelisanScreen({super.key});
  @override
  Widget build(context, ref) {
    final data = ref.watch(kemajelisanProvider);
    return data.when(
      loading: () => Scaffold(appBar: AppBar(title: const Text('Kemajelisan')),
          body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(title: const Text('Kemajelisan')),
          body: const Center(child: Text('Gagal memuat data'))),
      data: (items) => ProfilListScreen(
        title: 'Kemajelisan',
        items: items.map((e) => {
          'nama': e.nama, 'jabatan': e.jabatan,
          'foto_url': e.fotoUrl, 'bio': e.komisi,
        }).toList(),
      ),
    );
  }
}
