import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gkjw_karangpilang/core/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('default follows the phone theme', () async {
    final c = await ThemeController.load();
    expect(c.mode, ThemeMode.system);
    expect(c.effectiveBrightness(Brightness.dark), Brightness.dark);
    expect(c.effectiveBrightness(Brightness.light), Brightness.light);
  });

  test('toggle flips what is currently visible and overrides the phone', () async {
    final c = await ThemeController.load();
    var notified = 0;
    c.addListener(() => notified++);

    await c.toggle(Brightness.light); // HP terang → pilih gelap
    expect(c.mode, ThemeMode.dark);
    expect(c.effectiveBrightness(Brightness.light), Brightness.dark);

    await c.toggle(Brightness.dark);
    expect(c.mode, ThemeMode.light);
    expect(notified, 2);
  });

  test('choice survives an app restart', () async {
    final first = await ThemeController.load();
    await first.toggle(Brightness.light);

    final reopened = await ThemeController.load();
    expect(reopened.mode, ThemeMode.dark);
  });

  test('long press returns to following the phone', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    final c = await ThemeController.load();
    await c.followSystem();

    expect(c.mode, ThemeMode.system);
    expect((await ThemeController.load()).mode, ThemeMode.system);
  });

  test('ignores an unknown stored value', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'ungu'});
    expect((await ThemeController.load()).mode, ThemeMode.system);
  });
}
