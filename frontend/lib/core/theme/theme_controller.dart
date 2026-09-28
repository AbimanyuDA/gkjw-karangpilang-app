// lib/core/theme/theme_controller.dart
// Pilihan tema pengguna: ikuti HP (default), terang, atau gelap. Disimpan di perangkat.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._(this._prefs, this._mode);

  static const _key = 'theme_mode';

  final SharedPreferences? _prefs;
  ThemeMode _mode;

  ThemeMode get mode => _mode;

  /// Muat pilihan tersimpan; bila penyimpanan gagal, tetap ikuti tema HP.
  static Future<ThemeController> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = ThemeMode.values.asNameMap()[prefs.getString(_key)];
      return ThemeController._(prefs, saved ?? ThemeMode.system);
    } on Exception catch (e) {
      debugPrint('Gagal memuat pilihan tema: $e');
      return ThemeController._(null, ThemeMode.system);
    }
  }

  /// Kecerahan yang benar-benar dipakai, dengan tema HP sebagai acuan bila mode = system.
  Brightness effectiveBrightness(Brightness platform) => switch (_mode) {
        ThemeMode.system => platform,
        ThemeMode.light => Brightness.light,
        ThemeMode.dark => Brightness.dark,
      };

  /// Balik dari tampilan yang sedang terlihat (terang ↔ gelap).
  Future<void> toggle(Brightness current) =>
      setMode(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);

  /// Kembali mengikuti tema HP.
  Future<void> followSystem() => setMode(ThemeMode.system);

  /// Dipakai pemilih tema di halaman Informasi.
  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      await _prefs?.setString(_key, mode.name);
    } on Exception catch (e) {
      debugPrint('Gagal menyimpan pilihan tema: $e');
    }
  }
}
