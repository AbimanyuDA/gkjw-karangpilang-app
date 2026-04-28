// lib/data/services/sapaan_preference_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SapaanPreferenceService {
  static const String _keyPagi = 'sapaan_pagi_enabled';
  static const String _keyMalam = 'sapaan_malam_enabled';

  Future<bool> getSapaanPagiEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPagi) ?? false;
  }

  Future<bool> getSapaanMalamEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMalam) ?? false;
  }

  Future<void> setSapaanPagiEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPagi, value);
  }

  Future<void> setSapaanMalamEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMalam, value);
  }
}
