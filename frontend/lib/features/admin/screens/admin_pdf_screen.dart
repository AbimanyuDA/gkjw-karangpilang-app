// lib/features/admin/screens/admin_pdf_screen.dart
// Admin CRUD untuk Warta, Tata Ibadah, Renungan
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/pdf_item_model.dart';
import '../../../providers/providers.dart';

enum PdfKoleksi {
  warta(DokumenKategori.warta),
  tataIbadah(DokumenKategori.tataIbadah),
  renungan(DokumenKategori.renungan);

  const PdfKoleksi(this.kategori);
  final DokumenKategori kategori;
}

class AdminPdfScreen extends ConsumerStatefulWidget {
  final PdfKoleksi koleksi;
  const AdminPdfScreen({super.key, required this.koleksi});

  @override
  ConsumerState<AdminPdfScreen> createState() => _AdminPdfScreenState();
}

class _AdminPdfScreenState extends ConsumerState<AdminPdfScreen> {
  String get _title => switch (widget.koleksi) {
        PdfKoleksi.warta => 'Warta Jemaat',
        PdfKoleksi.tataIbadah => 'Tata Ibadah',
        PdfKoleksi.renungan => 'Renungan Harian',
      };

  void _showAddDialog() {
    final judulCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    File? selectedFile;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Tambah $_title'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: judulCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Judul',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Area Pilih File PDF
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        selectedFile == null ? Icons.upload_file : Icons.picture_as_pdf,
                        size: 40,
                        color: selectedFile == null ? Colors.grey : AppColors.error,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedFile == null 
                          ? 'Pilih File PDF' 
                          : selectedFile!.path.split('/').last,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans', 
                          fontSize: 12,
                          color: selectedFile == null ? Colors.grey : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: isUploading ? null : () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf'],
                          );
                          if (result != null && result.files.single.path != null) {
                            setDialogState(() {
                              selectedFile = File(result.files.single.path!);
                            });
                          }
                        },
                        icon: const Icon(Icons.search),
                        label: const Text('Cari File PDF'),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                InkWell(
                  onTap: isUploading ? null : () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat('d MMMM yyyy', 'id_ID').format(selectedDate),
                      style: const TextStyle(fontFamily: 'PlusJakartaSans'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: (isUploading || selectedFile == null || judulCtrl.text.isEmpty) 
                  ? null 
                  : () async {
                setDialogState(() => isUploading = true);
                
                try {
                  // 1. Upload file PDF ke server, 2. simpan datanya
                  final uploaded = await ref
                      .read(apiClientProvider)
                      .upload('dokumen', selectedFile!);
                  final item = PdfItem(
                    id: '',
                    judul: judulCtrl.text.trim(),
                    url: uploaded.url,
                    tanggal: selectedDate,
                  );
                  await ref
                      .read(contentServiceProvider)
                      .addDokumen(widget.koleksi.kategori, item);
                  ref.invalidate(dokumenProvider(widget.koleksi.kategori));
                  if (ctx.mounted) Navigator.pop(ctx);
                } on Exception catch (e) {
                  setDialogState(() => isUploading = false);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Gagal upload: $e')),
                    );
                  }
                }
              },
              child: isUploading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Upload & Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _delete(PdfItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus?'),
        content: Text('Hapus "${item.judul}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final service = ref.read(contentServiceProvider);
      await service.deleteDokumen(item.id);
      await service.deleteFile(item.url);
      ref.invalidate(dokumenProvider(widget.koleksi.kategori));
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: ref.watch(dokumenProvider(widget.koleksi.kategori)).when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Gagal memuat: $e',
              style: const TextStyle(fontFamily: 'PlusJakartaSans')),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.picture_as_pdf_outlined,
                      size: 64, color: AppColors.textLight),
                  const SizedBox(height: 12),
                  Text('Belum ada $_title',
                      style: const TextStyle(fontFamily: 'PlusJakartaSans')),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf,
                        color: AppColors.error, size: 24),
                  ),
                  title: Text(item.judul,
                      style: const TextStyle(
                          fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    DateFormat('d MMMM yyyy', 'id_ID').format(item.tanggal),
                    style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 12,
                        color: AppColors.textSecondary),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () => _delete(item),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
