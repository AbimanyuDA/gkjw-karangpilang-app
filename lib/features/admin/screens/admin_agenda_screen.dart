// lib/features/admin/screens/admin_agenda_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/supabase_models.dart';
import '../../../data/services/supabase_service.dart';
import '../../../providers/providers.dart';

class AdminAgendaScreen extends ConsumerStatefulWidget {
  const AdminAgendaScreen({super.key});

  @override
  ConsumerState<AdminAgendaScreen> createState() => _AdminAgendaScreenState();
}

class _AdminAgendaScreenState extends ConsumerState<AdminAgendaScreen> {
  final _service = SupabaseService();

  void _showAddDialog({AgendaModel? existing}) {
    final judulCtrl = TextEditingController(text: existing?.judul);
    final lokasiCtrl = TextEditingController(text: existing?.lokasi ?? '');
    final deskCtrl = TextEditingController(text: existing?.deskripsi ?? '');
    DateTime selectedDate = existing?.tanggal ?? DateTime.now();
    TimeOfDay selectedTime = existing != null
        ? TimeOfDay(hour: existing.tanggal.hour, minute: existing.tanggal.minute)
        : TimeOfDay.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Tambah Agenda' : 'Edit Agenda'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: judulCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Judul Kegiatan *',
                    prefixIcon: Icon(Icons.event),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lokasiCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deskCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
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
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setDialogState(() => selectedTime = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Waktu',
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(
                      selectedTime.format(ctx),
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
                if (judulCtrl.text.isEmpty) return;
                final tanggal = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                final agenda = AgendaModel(
                  id: existing?.id ?? '',
                  judul: judulCtrl.text.trim(),
                  tanggal: tanggal,
                  lokasi: lokasiCtrl.text.trim(),
                  deskripsi: deskCtrl.text.trim(),
                );
                if (existing == null) {
                  await _service.addAgenda(agenda);
                } else {
                  await _service.updateAgenda(agenda);
                }
                ref.invalidate(agendaProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final agendaAsync = ref.watch(agendaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Agenda')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: agendaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Gagal memuat')),
        data: (items) => items.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_outlined,
                        size: 64, color: AppColors.textLight),
                    SizedBox(height: 12),
                    Text('Belum ada agenda',
                        style: TextStyle(fontFamily: 'Poppins')),
                  ],
                ),
              )
            : ListView.separated(
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
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.event,
                            color: AppColors.primary, size: 24),
                      ),
                      title: Text(item.judul,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        DateFormat('d MMM yyyy, HH:mm', 'id_ID')
                            .format(item.tanggal),
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: AppColors.primary),
                            onPressed: () => _showAddDialog(existing: item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Hapus Agenda?'),
                                  content: Text('Hapus "${item.judul}"?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Batal')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.error),
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _service.deleteAgenda(item.id);
                                ref.invalidate(agendaProvider);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
