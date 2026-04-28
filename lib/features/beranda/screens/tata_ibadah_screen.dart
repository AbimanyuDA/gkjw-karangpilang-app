// lib/features/beranda/screens/tata_ibadah_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/pdf_list_screen.dart';
import '../../../providers/providers.dart';

class TataIbadahScreen extends ConsumerWidget {
  const TataIbadahScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PdfListScreen(
    title: 'Tata Ibadah',
    asyncItems: ref.watch(tataIbadahProvider),
    icon: Icons.book,
  );
}
