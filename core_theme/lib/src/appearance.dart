import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's light/dark choice: follow the system, or always light or dark.
///
/// Stored in plain shared preferences, not secure storage: it is not secret,
/// and it has to be readable before the app is unlocked (the lock screen
/// follows it) and by native code (OpenLock's lock overlay). Load it once
/// before `runApp` and bind `MaterialApp.themeMode` to [mode] so the first
/// frame already has the right theme.
///
/// On Android the value lives in the `FlutterSharedPreferences` file under
/// [nativeKey], as one of `system`, `light` or `dark`.
final class AppearanceController extends ChangeNotifier {
  AppearanceController._(this._prefs, this._mode);

  /// The key passed to `SharedPreferences`.
  static const String storageKey = 'offlyne_theme_mode';

  /// The same key as native Android code sees it (the plugin adds the
  /// `flutter.` prefix).
  static const String nativeKey = 'flutter.$storageKey';

  final SharedPreferences _prefs;
  ThemeMode _mode;

  /// Reads the saved choice; [ThemeMode.system] when none was made.
  static Future<AppearanceController> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppearanceController._(prefs, _parse(prefs.getString(storageKey)));
  }

  ThemeMode get mode => _mode;

  /// Applies [mode] at once and saves it.
  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _prefs.setString(storageKey, mode.name);
  }

  static ThemeMode _parse(String? raw) => ThemeMode.values.firstWhere(
        (m) => m.name == raw,
        orElse: () => ThemeMode.system,
      );
}
