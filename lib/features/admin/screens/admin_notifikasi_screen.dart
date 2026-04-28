// lib/features/admin/screens/admin_notifikasi_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/supabase_models.dart';
import '../../../data/services/groq_service.dart';
import '../../../data/services/supabase_service.dart';
import '../../../providers/providers.dart';

class AdminNotifikasiScreen extends ConsumerStatefulWidget {
  const AdminNotifikasiScreen({super.key});
  @override
  ConsumerState<AdminNotifikasiScreen> createState() =>
      _AdminNotifikasiScreenState();
}

class _AdminNotifikasiScreenState extends ConsumerState<AdminNotifikasiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = SupabaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    final judulCtrl = TextEditingController();
    final pesanCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kirim Notifikasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: judulCtrl,
              decoration: const InputDecoration(
                labelText: 'Judul *',
                prefixIcon: Icon(Icons.notifications_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pesanCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Pesan *',
                prefixIcon: Icon(Icons.message_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (judulCtrl.text.isEmpty || pesanCtrl.text.isEmpty) return;
              await _service.addNotifikasi(NotifikasiModel(
                id: '',
                judul: judulCtrl.text.trim(),
                pesan: pesanCtrl.text.trim(),
                isActive: true,
                createdAt: DateTime.now(),
              ));
              ref.invalidate(notifikasiProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Notifikasi'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          labelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Riwayat Push'),
            Tab(text: 'Jadwal Sapaan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RiwayatNotifikasiTab(
            onAddPressed: _showAddDialog,
          ),
          const _JadwalSapaanTab(),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) {
          if (_tabController.index == 0) {
            return FloatingActionButton.extended(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add_alert),
              label: const Text('Kirim Notifikasi'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ── Tab 1: Riwayat Notifikasi ──
class _RiwayatNotifikasiTab extends ConsumerWidget {
  final VoidCallback onAddPressed;

  const _RiwayatNotifikasiTab({required this.onAddPressed});

  String _formatTanggal(DateTime dt) {
    const hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final h = hari[dt.weekday - 1];
    final b = bulan[dt.month - 1];
    final jam = dt.hour.toString().padLeft(2, '0');
    final menit = dt.minute.toString().padLeft(2, '0');
    return '$h, ${dt.day} $b ${dt.year} · $jam:$menit';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(notifikasiProvider);
    final service = SupabaseService();

    return data.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Gagal memuat')),
      data: (items) => items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: AppColors.textLight),
                  SizedBox(height: 12),
                  Text('Belum ada notifikasi',
                      style: TextStyle(fontFamily: 'Poppins')),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final item = items[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.notifications,
                              color: AppColors.error, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.judul,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.pesan,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      size: 12, color: AppColors.textLight),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTanggal(item.createdAt),
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.error, size: 20),
                          onPressed: () async {
                            await service.deleteNotifikasi(item.id);
                            ref.invalidate(notifikasiProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ── Tab 2: Jadwal Sapaan (Calendar UI) ──
class _JadwalSapaanTab extends ConsumerStatefulWidget {
  const _JadwalSapaanTab();

  @override
  ConsumerState<_JadwalSapaanTab> createState() => _JadwalSapaanTabState();
}

class _JadwalSapaanTabState extends ConsumerState<_JadwalSapaanTab> {
  final _service = SupabaseService();
  final _groqService = GroqService();
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  final _temaCtrl = TextEditingController();
  final _ayatPagiCtrl = TextEditingController();
  final _ayatMalamCtrl = TextEditingController();
  
  bool _isSaving = false;
  bool _isGeneratingPagi = false;
  bool _isGeneratingMalam = false;
  bool _isAutoGenerating = false;
  int _autoGenProgress = 0;
  int _autoGenTotal = 0;

  // Jam notifikasi per tanggal (default dari sapaan_config)
  TimeOfDay _jamPagi = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _jamMalam = const TimeOfDay(hour: 19, minute: 0);

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDefaultJam();
      _loadSelectedDate();
    });
  }

  Future<void> _loadDefaultJam() async {
    try {
      final config = await _service.getSapaanConfig();
      if (config != null && mounted) {
        setState(() {
          _jamPagi = TimeOfDay(hour: config.jamPagi, minute: config.menitPagi);
          _jamMalam = TimeOfDay(hour: config.jamMalam, minute: config.menitMalam);
        });
      }
    } catch (e) {
      debugPrint('Failed to load default jam: $e');
    }
  }

  @override
  void dispose() {
    _temaCtrl.dispose();
    _ayatPagiCtrl.dispose();
    _ayatMalamCtrl.dispose();
    super.dispose();
  }

  void _loadSelectedDate() async {
    if (_selectedDay == null) return;
    final data = await _service.getSapaanJadwalTanggal(_selectedDay!);
    if (mounted) {
      setState(() {
        _temaCtrl.text = data?.tema ?? '';
        _ayatPagiCtrl.text = data?.ayatPagi ?? '';
        _ayatMalamCtrl.text = data?.ayatMalam ?? '';
        // Jam tetap dari _jamPagi/_jamMalam (loaded dari sapaan_config)
      });
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _loadSelectedDate();
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });
    // Update provider to load new month data
    ref.read(sapaanJadwalBulanParamProvider.notifier).state =
        (focusedDay.year, focusedDay.month);
  }

  Future<void> _generatePagi() async {
    final tema = _temaCtrl.text.trim();
    if (tema.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan tema terlebih dahulu')),
      );
      return;
    }
    setState(() => _isGeneratingPagi = true);
    try {
      final ayat = await _groqService.generateAyatAlkitab(tema, 'pagi');
      if (mounted) {
        setState(() {
          _ayatPagiCtrl.text = ayat;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal generate: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPagi = false);
    }
  }

  Future<void> _generateMalam() async {
    final tema = _temaCtrl.text.trim();
    if (tema.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan tema terlebih dahulu')),
      );
      return;
    }
    setState(() => _isGeneratingMalam = true);
    try {
      final ayat = await _groqService.generateAyatAlkitab(tema, 'malam');
      if (mounted) {
        setState(() {
          _ayatMalamCtrl.text = ayat;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal generate: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingMalam = false);
    }
  }

  Future<void> _simpanTanggalIni() async {
    if (_selectedDay == null) return;
    
    final ayatPagi = _ayatPagiCtrl.text.trim();
    final ayatMalam = _ayatMalamCtrl.text.trim();
    
    if (ayatPagi.isEmpty && ayatMalam.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi minimal satu ayat')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Simpan ayat per tanggal
      final model = SapaanJadwalHarianModel(
        id: '',
        tanggal: _selectedDay!,
        ayatPagi: ayatPagi.isEmpty ? null : ayatPagi,
        ayatMalam: ayatMalam.isEmpty ? null : ayatMalam,
        tema: _temaCtrl.text.trim().isEmpty ? null : _temaCtrl.text.trim(),
        sumberPagi: 'manual',
        sumberMalam: 'manual',
        updatedAt: DateTime.now(),
      );
      await _service.upsertSapaanJadwal(model);

      // Update jam global di sapaan_config
      final config = await _service.getSapaanConfig();
      if (config != null) {
        await _service.updateSapaanConfig(config.copyWith(
          jamPagi: _jamPagi.hour,
          menitPagi: _jamPagi.minute,
          jamMalam: _jamMalam.hour,
          menitMalam: _jamMalam.minute,
        ));
      }

      ref.invalidate(sapaanJadwalBulanProvider);
      ref.invalidate(sapaanConfigProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil disimpan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _autoGenerateBulanIni() async {
    final temaCtrl = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Auto-Generate Bulan Ini'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Generate ayat pagi dan malam untuk semua tanggal di bulan ini?',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: temaCtrl,
              decoration: const InputDecoration(
                labelText: 'Tema (opsional)',
                hintText: 'Contoh: pengharapan, kasih...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final tema = temaCtrl.text.trim().isEmpty ? 'pengharapan' : temaCtrl.text.trim();
    final year = _focusedDay.year;
    final month = _focusedDay.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    setState(() {
      _isAutoGenerating = true;
      _autoGenProgress = 0;
      _autoGenTotal = daysInMonth;
    });

    try {
      for (int day = 1; day <= daysInMonth; day++) {
        final tanggal = DateTime(year, month, day);
        
        // Generate pagi
        final ayatPagi = await _groqService.generateAyatAlkitab(tema, 'pagi');
        // Generate malam
        final ayatMalam = await _groqService.generateAyatAlkitab(tema, 'malam');
        
        // Upsert
        final model = SapaanJadwalHarianModel(
          id: '',
          tanggal: tanggal,
          ayatPagi: ayatPagi,
          ayatMalam: ayatMalam,
          tema: tema,
          sumberPagi: 'ai',
          sumberMalam: 'ai',
          updatedAt: DateTime.now(),
        );
        await _service.upsertSapaanJadwal(model);
        
        if (mounted) {
          setState(() {
            _autoGenProgress = day;
          });
        }
      }

      ref.invalidate(sapaanJadwalBulanProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil generate semua tanggal!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAutoGenerating = false;
          _autoGenProgress = 0;
          _autoGenTotal = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jadwalData = ref.watch(sapaanJadwalBulanProvider);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendar
              jadwalData.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (jadwalList) => _CalendarWidget(
                  focusedDay: _focusedDay,
                  selectedDay: _selectedDay,
                  jadwalList: jadwalList,
                  onDaySelected: _onDaySelected,
                  onPageChanged: _onPageChanged,
                ),
              ),
              const SizedBox(height: 16),
              
              // Auto-Generate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isAutoGenerating ? null : _autoGenerateBulanIni,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Auto-Generate Bulan Ini'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Selected Date Detail
              if (_selectedDay != null) ...[
                Text(
                  'Tanggal: ${_selectedDay!.day} ${_getMonthName(_selectedDay!.month)} ${_selectedDay!.year}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Jam Notifikasi ──
                Card(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.schedule, size: 16, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'Jam Pengiriman Notifikasi',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Berlaku global untuk semua jemaat',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _TimePickerTile(
                                label: 'Sapaan Pagi',
                                time: _jamPagi,
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: _jamPagi,
                                    helpText: 'Pilih jam sapaan pagi',
                                    builder: (context, child) => MediaQuery(
                                      data: MediaQuery.of(context).copyWith(
                                        alwaysUse24HourFormat: true,
                                      ),
                                      child: child!,
                                    ),
                                  );
                                  if (picked != null) {
                                    setState(() => _jamPagi = picked);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TimePickerTile(
                                label: 'Sapaan Malam',
                                time: _jamMalam,
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: _jamMalam,
                                    helpText: 'Pilih jam sapaan malam',
                                    builder: (context, child) => MediaQuery(
                                      data: MediaQuery.of(context).copyWith(
                                        alwaysUse24HourFormat: true,
                                      ),
                                      child: child!,
                                    ),
                                  );
                                  if (picked != null) {
                                    setState(() => _jamMalam = picked);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Tema
                TextField(
                  controller: _temaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tema (opsional)',
                    hintText: 'Contoh: pengharapan, kasih...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Ayat Pagi
                const Text(
                  'Ayat Pagi',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _ayatPagiCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan ayat pagi...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isGeneratingPagi ? null : _generatePagi,
                    icon: _isGeneratingPagi
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_isGeneratingPagi ? 'Generating...' : 'Generate Pagi'),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Ayat Malam
                const Text(
                  'Ayat Malam',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _ayatMalamCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan ayat malam...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isGeneratingMalam ? null : _generateMalam,
                    icon: _isGeneratingMalam
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_isGeneratingMalam ? 'Generating...' : 'Generate Malam'),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Simpan Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _simpanTanggalIni,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Tanggal Ini'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Auto-Generate Progress Overlay
        if (_isAutoGenerating)
          Container(
            color: Colors.black54,
            child: Center(
              child: Card(
                margin: const EdgeInsets.all(32),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Generating $_autoGenProgress/$_autoGenTotal...',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Mohon tunggu, jangan tutup layar',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }
}

// ── Custom Calendar Widget ──
class _CalendarWidget extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final List<SapaanJadwalHarianModel> jadwalList;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final void Function(DateTime focusedDay) onPageChanged;

  const _CalendarWidget({
    required this.focusedDay,
    required this.selectedDay,
    required this.jadwalList,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  static const _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  static const _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  Color _dotColor(DateTime day) {
    final jadwal = jadwalList.where((j) =>
        j.tanggal.year == day.year &&
        j.tanggal.month == day.month &&
        j.tanggal.day == day.day).firstOrNull;

    if (jadwal == null) return Colors.grey.shade300;
    if (jadwal.isComplete) return Colors.green;
    if (jadwal.hasPagi || jadwal.hasMalam) return Colors.amber;
    return Colors.grey.shade300;
  }

  @override
  Widget build(BuildContext context) {
    final year = focusedDay.year;
    final month = focusedDay.month;

    // First day of month (weekday: 1=Mon, 7=Sun)
    final firstDay = DateTime(year, month, 1);
    // Days in month
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Leading empty cells (Mon=0 offset, Sun=6 offset)
    final leadingBlanks = (firstDay.weekday - 1) % 7;

    final today = DateTime.now();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Month navigation header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    final prev = DateTime(year, month - 1, 1);
                    onPageChanged(prev);
                  },
                ),
                Text(
                  '${_monthNames[month - 1]} $year',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    final next = DateTime(year, month + 1, 1);
                    onPageChanged(next);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Day-of-week labels
            Row(
              children: _dayLabels.map((label) {
                return Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // Calendar grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.85,
              ),
              itemCount: leadingBlanks + daysInMonth,
              itemBuilder: (context, index) {
                if (index < leadingBlanks) {
                  return const SizedBox.shrink();
                }

                final dayNum = index - leadingBlanks + 1;
                final day = DateTime(year, month, dayNum);
                final isSelected = selectedDay != null &&
                    selectedDay!.year == day.year &&
                    selectedDay!.month == day.month &&
                    selectedDay!.day == day.day;
                final isToday = today.year == day.year &&
                    today.month == day.month &&
                    today.day == day.day;
                final dotColor = _dotColor(day);

                return GestureDetector(
                  onTap: () => onDaySelected(day, day),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : isToday
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNum',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white70 : dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Legend
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: Colors.green, label: 'Lengkap'),
                const SizedBox(width: 16),
                _LegendDot(color: Colors.amber, label: 'Sebagian'),
                const SizedBox(width: 16),
                _LegendDot(color: Colors.grey, label: 'Kosong'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  _formatTime(time),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.edit, size: 14, color: AppColors.textLight),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
