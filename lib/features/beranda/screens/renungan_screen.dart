// lib/features/beranda/screens/renungan_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/pdf_list_screen.dart';
import '../../../providers/providers.dart';

class RenunganScreen extends ConsumerWidget {
  const RenunganScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PdfListScreen(
    title: 'Renungan Harian',
    asyncItems: ref.watch(renunganProvider),
    icon: Icons.auto_stories,
  );
}
