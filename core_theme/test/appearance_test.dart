import 'package:core_theme/core_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('follows the system until a choice is made', () async {
    SharedPreferences.setMockInitialValues({});
    final c = await AppearanceController.load();
    expect(c.mode, ThemeMode.system);
  });

  test('a choice applies at once and survives a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final c = await AppearanceController.load();
    var notified = 0;
    c.addListener(() => notified++);
    await c.setMode(ThemeMode.dark);
    expect(c.mode, ThemeMode.dark);
    expect(notified, 1);

    final reloaded = await AppearanceController.load();
    expect(reloaded.mode, ThemeMode.dark);
  });

  test('is stored as a plain name native code can read', () async {
    SharedPreferences.setMockInitialValues({});
    final c = await AppearanceController.load();
    await c.setMode(ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppearanceController.storageKey), 'light');
    expect(AppearanceController.nativeKey, 'flutter.offlyne_theme_mode');
  });

  test('an unknown stored value falls back to the system', () async {
    SharedPreferences.setMockInitialValues({
      AppearanceController.storageKey: 'sepia',
    });
    expect((await AppearanceController.load()).mode, ThemeMode.system);
  });
}
