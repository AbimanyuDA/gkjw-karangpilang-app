// lib/features/admin/screens/admin_siaran_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/pdf_item_model.dart';
import '../../../data/services/content_service.dart';
import '../../../data/services/youtube_metadata_service.dart';
import '../../../providers/providers.dart';

class AdminSiaranScreen extends ConsumerStatefulWidget {
  const AdminSiaranScreen({super.key});
  @override
  ConsumerState<AdminSiaranScreen> createState() => _AdminSiaranScreenState();
}

class _AdminSiaranScreenState extends ConsumerState<AdminSiaranScreen> {
  ContentService get _service => ref.read(contentServiceProvider);

  final _youtube = YoutubeMetadataService();

  static const _kategoriList = [
    {'value': 'umum', 'label': 'Ibadah Umum'},
    {'value': 'anak', 'label': 'Ibadah Anak'},
    {'value': 'remaja', 'label': 'Ibadah Remaja'},
    {'value': 'sekolah_minggu', 'label': 'Sekolah Minggu'},
  ];

  void _showAddDialog() {
    final judulCtrl = TextEditingController();
    final ytCtrl = TextEditingController();
    final deskripsiCtrl = TextEditingController();
    String selectedKat = 'umum';
    DateTime selectedDate = DateTime.now();
    bool isFetchingTitle = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> fetchYoutubeData(String url) async {
            if (url.isEmpty) return;
            final ytId = YoutubeMetadataService.extractVideoId(url);
            if (ytId == null) return;

            setDialogState(() => isFetchingTitle = true);
            try {
              final meta = await _youtube.fetch(ytId);
              if (!ctx.mounted) return;
              if (meta == null) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Gagal mengambil data video. Isi judul secara manual.')),
                );
                return;
              }
              setDialogState(() {
                judulCtrl.text = meta.title;
                if (meta.description.isNotEmpty) deskripsiCtrl.text = meta.description;
                final date = meta.date;
                if (date != null) selectedDate = date;
              });
            } finally {
              if (ctx.mounted) setDialogState(() => isFetchingTitle = false);
            }
          }

          return AlertDialog(
            title: const Text('Tambah Siaran'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ytCtrl,
                    onChanged: (val) {
                      if (val.contains('youtube.com') || val.contains('youtu.be')) {
                        fetchYoutubeData(val);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Link YouTube *',
                      hintText: 'Paste link youtube disini',
                      prefixIcon: const Icon(Icons.play_circle_outlined),
                      helperText: 'Otomatis mendeteksi judul & tanggal',
                      suffixIcon: isFetchingTitle 
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: judulCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Judul Ibadah (Otomatis) *',
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedKat,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: _kategoriList.map((k) => DropdownMenuItem(
                      value: k['value'],
                      child: Text(k['label']!,
                          style: const TextStyle(fontFamily: 'PlusJakartaSans')),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => selectedKat = v!),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setDialogState(() => selectedDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Ibadah (Otomatis)',
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
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (judulCtrl.text.isEmpty || ytCtrl.text.isEmpty) return;
                  
                  final ytId = YoutubeMetadataService.extractVideoId(ytCtrl.text);
                  if (ytId == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Link YouTube tidak valid')),
                    );
                    return;
                  }

                  final video = VideoSiaran(
                    id: '',
                    judul: judulCtrl.text.trim(),
                    youtubeId: ytId,
                    kategori: selectedKat,
                    tanggal: selectedDate,
                    deskripsi: deskripsiCtrl.text.trim().isNotEmpty ? deskripsiCtrl.text.trim() : null,
                  );
                  try {
                    await _service.addSiaran(video);
                    ref.invalidate(siaranProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } on Exception catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Gagal menyimpan: $e')),
                      );
                    }
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final siaranAsync = ref.watch(siaranProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Siaran')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Siaran'),
      ),
      body: siaranAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Gagal memuat')),
        data: (videos) => videos.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.live_tv_outlined, size: 64, color: AppColors.textLight),
                    SizedBox(height: 12),
                    Text('Belum ada siaran', style: TextStyle(fontFamily: 'PlusJakartaSans')),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: videos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final v = videos[index];
                  return Card(
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: 'https://img.youtube.com/vi/${v.youtubeId}/default.jpg',
                          width: 60,
                          height: 45,
                          fit: BoxFit.cover,
                          memCacheWidth: 120,
                          placeholder: (_, __) => Container(
                            width: 60, height: 45,
                            color: AppColors.gold500.withValues(alpha: 0.16),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: 60, height: 45,
                            color: AppColors.gold500.withValues(alpha: 0.16),
                            child: const Icon(Icons.play_circle, color: AppColors.primary),
                          ),
                        ),
                      ),
                      title: Text(v.judul,
                          style: const TextStyle(
                              fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${_formatKat(v.kategori)} • ${DateFormat('d MMM yyyy', 'id_ID').format(v.tanggal)}',
                        style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 11),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Hapus siaran?'),
                              content: Text('Hapus "${v.judul}"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );
                          if (ok != true) return;
                          try {
                            await _service.deleteSiaran(v.id);
                            ref.invalidate(siaranProvider);
                          } on Exception catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gagal menghapus: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _formatKat(String k) => switch (k) {
    'umum' => 'Ibadah Umum',
    'anak' => 'Ibadah Anak',
    'remaja' => 'Ibadah Remaja',
    'sekolah_minggu' => 'Sekolah Minggu',
    _ => k,
  };
}
