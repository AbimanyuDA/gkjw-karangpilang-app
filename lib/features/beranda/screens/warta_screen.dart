// lib/features/beranda/screens/warta_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/pdf_list_screen.dart';
import '../../../providers/providers.dart';

class WartaScreen extends ConsumerWidget {
  const WartaScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PdfListScreen(
    title: 'Warta Jemaat',
    asyncItems: ref.watch(wartaProvider),
    icon: Icons.newspaper,
  );
}
