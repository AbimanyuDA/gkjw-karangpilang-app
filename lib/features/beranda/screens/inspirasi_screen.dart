// lib/features/beranda/screens/inspirasi_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'dart:async';
import 'dart:math';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';

class InspirasiScreen extends ConsumerStatefulWidget {
  const InspirasiScreen({super.key});

  @override
  ConsumerState<InspirasiScreen> createState() => _InspirasiScreenState();
}

class _InspirasiScreenState extends ConsumerState<InspirasiScreen> {
  final StreamController<int> _controller = StreamController<int>();
  int _selected = 0;
  bool _spinning = false;
  String? _result;

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  void _spin(int count) {
    if (_spinning || count == 0) return;
    setState(() {
      _spinning = true;
      _result = null;
    });
    final next = Random().nextInt(count);
    _controller.add(next);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _selected = next;
          _spinning = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final kategori = ref.watch(inspirasiKategoriProvider);
    final inspirasiAsync = ref.watch(inspirasiProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inspirasi Harian')),
      body: Column(
        children: [
          // Toggle kategori
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      ref.read(inspirasiKategoriProvider.notifier).state = 'anak';
                      setState(() { _result = null; _selected = 0; });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: kategori == 'anak' ? AppColors.primary : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '🌟 Anak-anak',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: kategori == 'anak' ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      ref.read(inspirasiKategoriProvider.notifier).state = 'dewasa';
                      setState(() { _result = null; _selected = 0; });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: kategori == 'dewasa' ? AppColors.primary : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '✨ Dewasa',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: kategori == 'dewasa' ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: inspirasiAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Center(child: Text('Gagal memuat inspirasi')),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('Belum ada inspirasi', style: TextStyle(fontFamily: 'Poppins')));
                }
                final slices = items.map((item) => FortuneItem(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      item.teks.length > 30 ? '${item.teks.substring(0, 30)}...' : item.teks,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  style: FortuneItemStyle(
                    color: Color(int.parse(item.warna.replaceAll('#', '0xFF'))),
                    borderColor: Colors.white,
                    borderWidth: 2,
                  ),
                )).toList();

                return Column(
                  children: [
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 300,
                      child: FortuneWheel(
                        selected: _controller.stream,
                        items: slices,
                        animateFirst: false,
                        onAnimationEnd: () {
                          setState(() {
                            _result = items[_selected].teks;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_result != null)
                      AnimatedOpacity(
                        opacity: _result != null ? 1 : 0,
                        duration: const Duration(milliseconds: 500),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              const Text('Challenge Hari Ini! 🎉',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _result!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _spinning ? null : () => _spin(items.length),
                      icon: _spinning
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.casino, size: 20),
                      label: Text(_spinning ? 'Sedang berputar...' : 'Putar Roda!'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
