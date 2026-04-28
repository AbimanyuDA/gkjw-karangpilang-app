// lib/features/gereja/screens/bpm_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/profil_list_screen.dart';
import '../../../providers/providers.dart';

class BpmScreen extends ConsumerWidget {
  const BpmScreen({super.key});
  @override
  Widget build(context, ref) {
    final data = ref.watch(bpmProvider);
    return data.when(
      loading: () => Scaffold(appBar: AppBar(title: const Text('Badan Pembantu Majelis')),
          body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(title: const Text('Badan Pembantu Majelis')),
          body: const Center(child: Text('Gagal memuat data'))),
      data: (items) => ProfilListScreen(
        title: 'Badan Pembantu Majelis',
        items: items,
        jabatanKey: 'ketua',
        bioKey: 'deskripsi',
      ),
    );
  }
}
