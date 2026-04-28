// lib/features/admin/screens/admin_siaran_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/pdf_item_model.dart';
import '../../../data/services/firestore_service.dart';
import '../../../providers/providers.dart';
import 'package:dio/dio.dart' as dio;
import '../../../env.dart';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class AdminSiaranScreen extends ConsumerStatefulWidget {
  const AdminSiaranScreen({super.key});
  @override
  ConsumerState<AdminSiaranScreen> createState() => _AdminSiaranScreenState();
}

class _AdminSiaranScreenState extends ConsumerState<AdminSiaranScreen> {
  final _service = FirestoreService();

  // YouTube Data API v3 key
  static final _ytApiKey = Env.youtubeApiKey;

  static const _kategoriList = [
    {'value': 'umum', 'label': 'Ibadah Umum'},
    {'value': 'anak', 'label': 'Ibadah Anak'},
    {'value': 'remaja', 'label': 'Ibadah Remaja'},
    {'value': 'sekolah_minggu', 'label': 'Sekolah Minggu'},
  ];

  static const _months = {
    'januari': 1, 'jan': 1,
    'februari': 2, 'feb': 2,
    'maret': 3, 'mar': 3,
    'april': 4, 'apr': 4,
    'mei': 5,
    'juni': 6, 'jun': 6,
    'juli': 7, 'jul': 7,
    'agustus': 8, 'agu': 8, 'aug': 8,
    'september': 9, 'sep': 9,
    'oktober': 10, 'okt': 10, 'oct': 10,
    'november': 11, 'nov': 11,
    'desember': 12, 'des': 12, 'dec': 12,
  };

  /// Coba ekstrak tanggal dari judul video (misal: "Ibadah 27 April 2025" atau "Ibadah 20/04/2025")
  DateTime? _parseDateFromTitle(String title) {
    final monthNames = _months.keys.join('|');
    // Format: "27 April 2025" atau "5 Apr 2025"
    final re1 = RegExp(r'(\d{1,2})\s+(' + monthNames + r')\s+(\d{4})', caseSensitive: false);
    final m1 = re1.firstMatch(title);
    if (m1 != null) {
      final day = int.tryParse(m1.group(1)!) ?? 1;
      final month = _months[m1.group(2)!.toLowerCase()];
      final year = int.tryParse(m1.group(3)!) ?? DateTime.now().year;
      if (month != null) return DateTime(year, month, day);
    }
    // Format: "27/04/2025" atau "27-04-2025"
    final re2 = RegExp(r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})');
    final m2 = re2.firstMatch(title);
    if (m2 != null) {
      return DateTime(
        int.tryParse(m2.group(3)!) ?? DateTime.now().year,
        int.tryParse(m2.group(2)!) ?? 1,
        int.tryParse(m2.group(1)!) ?? 1,
      );
    }
    return null;
  }

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
            try {
              final regExp = RegExp(r'.*(?:youtu.be\/|v\/|u\/\w\/|embed\/|live\/|shorts\/|watch\?v=|\&v=)([^#\&\?]*).*');
              final match = regExp.firstMatch(url);
              String? ytId;
              if (match != null && match.group(1)?.length == 11) {
                ytId = match.group(1);
              }
              
              if (ytId == null || ytId.isEmpty) return;

              setDialogState(() => isFetchingTitle = true);
              
              bool isTitleComplete = false;
              bool isDescComplete = false;
              bool isDateComplete = false;
              String fetchedTitle = '';
              String fetchedDesc = '';
              DateTime? fetchedDate;

              // Header browser agar tidak diblokir oleh server pihak ketiga
              final browserHeaders = {
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Accept': 'application/json, text/plain, */*',
              };

              // 1. Coba oEmbed dulu — resmi dari YouTube, selalu bisa, memberikan judul
              try {
                final oembedUrl = 'https://www.youtube.com/oembed?url=${Uri.encodeComponent('https://www.youtube.com/watch?v=$ytId')}&format=json';
                final response = await dio.Dio().get(oembedUrl, options: dio.Options(headers: browserHeaders));
                if (response.statusCode == 200 && response.data['title'] != null) {
                  fetchedTitle = response.data['title'];
                  isTitleComplete = true;
                }
              } catch (e) {
                debugPrint('oEmbed error: $e');
              }

              // 2. YouTube Data API v3 — gratis, paling andal, dapat deskripsi & tanggal lengkap
              if ((!isDescComplete || !isDateComplete) && _ytApiKey != 'GANTI_DENGAN_API_KEY_ANDA') {
                try {
                  final response = await dio.Dio().get(
                    'https://www.googleapis.com/youtube/v3/videos',
                    queryParameters: {
                      'part': 'snippet',
                      'id': ytId,
                      'key': _ytApiKey,
                    },
                  );
                  if (response.statusCode == 200) {
                    final items = response.data['items'];
                    if (items != null && items.isNotEmpty) {
                      final snippet = items[0]['snippet'];
                      if (!isTitleComplete && snippet['title'] != null) {
                        fetchedTitle = snippet['title'];
                        isTitleComplete = true;
                      }
                      if (!isDescComplete && snippet['description'] != null && snippet['description'].toString().isNotEmpty) {
                        fetchedDesc = snippet['description'];
                        isDescComplete = true;
                      }
                      if (!isDateComplete && snippet['publishedAt'] != null) {
                        fetchedDate = DateTime.tryParse(snippet['publishedAt']);
                        isDateComplete = true;
                      }
                    }
                  }
                } catch (e) {
                  debugPrint('YouTube API v3 error: $e');
                }
              }

              // 3. Parse tanggal dari judul video (pendekatan paling andal untuk video siaran gereja)
              // Kebanyakan video ibadah sudah menyertakan tanggal di judulnya
              if (!isDateComplete && fetchedTitle.isNotEmpty) {
                final parsedDate = _parseDateFromTitle(fetchedTitle);
                if (parsedDate != null) {
                  fetchedDate = parsedDate;
                  isDateComplete = true;
                  debugPrint('Tanggal berhasil di-parse dari judul: $parsedDate');
                }
              }

              // 4. Jika deskripsi masih kosong, coba YoutubeExplode sebagai last resort
              if (!isDescComplete) {
                final yt = YoutubeExplode();
                try {
                  final video = await yt.videos.get(ytId);
                  if (!isTitleComplete && video.title.isNotEmpty) { fetchedTitle = video.title; isTitleComplete = true; }
                  if (!isDescComplete && video.description.isNotEmpty) { fetchedDesc = video.description; isDescComplete = true; }
                  if (!isDateComplete) {
                    final ytDate = video.uploadDate ?? video.publishDate;
                    if (ytDate != null) { fetchedDate = ytDate; isDateComplete = true; }
                  }
                } catch (e) {
                  debugPrint('YoutubeExplode fallback error: $e');
                } finally {
                  yt.close();
                }
              }

              if (ctx.mounted) {
                if (isTitleComplete) {
                  setDialogState(() {
                    judulCtrl.text = fetchedTitle;
                    if (fetchedDesc.isNotEmpty) deskripsiCtrl.text = fetchedDesc;
                    if (fetchedDate != null) selectedDate = fetchedDate!;
                  });
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Gagal mengambil data. Server YouTube membatasi permintaan.')),
                  );
                }
              }
            } catch (e) {
              debugPrint('General Error: $e');
            } finally {
              if (ctx.mounted) {
                setDialogState(() => isFetchingTitle = false);
              }
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
                          style: const TextStyle(fontFamily: 'Poppins')),
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
                        style: const TextStyle(fontFamily: 'Poppins'),
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
                  
                  final regExp = RegExp(r'.*(?:youtu.be\/|v\/|u\/\w\/|embed\/|live\/|shorts\/|watch\?v=|\&v=)([^#\&\?]*).*');
                  final match = regExp.firstMatch(ytCtrl.text.trim());
                  String ytId = ytCtrl.text.trim();
                  if (match != null && match.group(1)?.length == 11) {
                    ytId = match.group(1)!;
                  }

                  final video = VideoSiaran(
                    id: '',
                    judul: judulCtrl.text.trim(),
                    youtubeId: ytId,
                    kategori: selectedKat,
                    tanggal: selectedDate,
                    deskripsi: deskripsiCtrl.text.trim().isNotEmpty ? deskripsiCtrl.text.trim() : null,
                  );
                  await _service.addSiaran(video);
                  if (ctx.mounted) Navigator.pop(ctx);
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
                    Text('Belum ada siaran', style: TextStyle(fontFamily: 'Poppins')),
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
                        child: Image.network(
                          'https://img.youtube.com/vi/${v.youtubeId}/default.jpg',
                          width: 60,
                          height: 45,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 60, height: 45,
                            color: AppColors.primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.play_circle, color: AppColors.primary),
                          ),
                        ),
                      ),
                      title: Text(v.judul,
                          style: const TextStyle(
                              fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${_formatKat(v.kategori)} • ${DateFormat('d MMM yyyy', 'id_ID').format(v.tanggal)}',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 11),
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
                          if (ok == true) await _service.deleteSiaran(v.id);
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
