import 'package:core_lock/src/device_auth.dart';
import 'package:core_storage/core_storage.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, ChangeNotifier;

/// Owns the optional app-lock state: whether the lock is enabled (persisted in
/// platform secure storage) and whether the app is currently locked.
///
/// Pure Dart apart from [AppLifecycleState] — testable with a fake
/// [IDeviceAuth], an in-memory [ISecureStorage], and a fixed clock.
final class LockController extends ChangeNotifier {
  LockController({
    required IDeviceAuth deviceAuth,
    required ISecureStorage storage,
    required DateTime Function() clock,
    required String storageKey,
    required String appName,
    bool enabled = false,
    this.backgroundGrace = const Duration(seconds: 30),
  })  : _deviceAuth = deviceAuth,
        _storage = storage,
        _clock = clock,
        _storageKey = storageKey,
        _appName = appName,
        _enabled = enabled,
        _locked = enabled,
        _autoPromptArmed = enabled;

  /// Backgrounding for longer than this re-locks the app.
  final Duration backgroundGrace;

  final IDeviceAuth _deviceAuth;
  final ISecureStorage _storage;
  final DateTime Function() _clock;
  final String _storageKey;
  final String _appName;

  bool _enabled;
  bool _locked;
  bool _autoPromptArmed;
  bool _authInFlight = false;
  DateTime? _backgroundedAt;

  bool get isEnabled => _enabled;
  bool get isLocked => _locked;
  bool get autoPromptArmed => _autoPromptArmed;
  String get appName => _appName;

  /// Reads the persisted flag before the controller exists, so main() can
  /// construct the app already locked (no unlocked flash on cold start).
  static Future<bool> readEnabled(
    ISecureStorage storage,
    String storageKey,
  ) async =>
      await storage.read(key: storageKey) == 'true';

  Future<bool> canAuthenticate() => _deviceAuth.canAuthenticate();

  /// Turns the lock on/off. Enabling requires one successful authentication.
  Future<bool> setEnabled(bool enabled) async {
    if (enabled == _enabled) return true;
    if (enabled) {
      if (!await _deviceAuth.canAuthenticate()) return false;
      if (!await _prompt('Confirm to turn on app lock')) return false;
    }
    _enabled = enabled;
    if (enabled) {
      await _storage.write(key: _storageKey, value: 'true');
    } else {
      _locked = false;
      _autoPromptArmed = false;
      await _storage.delete(key: _storageKey);
    }
    notifyListeners();
    return true;
  }

  /// Fires the automatic unlock prompt once per locked session (latched).
  Future<bool> autoUnlock() async {
    if (!_autoPromptArmed) return false;
    _autoPromptArmed = false;
    return unlock();
  }

  Future<bool> unlock() async {
    if (!_locked) return true;
    if (_authInFlight) return false;
    if (!await _prompt('Unlock $_appName')) return false;
    _locked = false;
    _backgroundedAt = null;
    _autoPromptArmed = false;
    notifyListeners();
    return true;
  }

  /// Escape hatch so a device with no biometric/credential can't lock the
  /// user out. Only unlocks when authentication is genuinely unavailable;
  /// data stays encrypted at rest regardless, so this leaks nothing.
  Future<bool> unlockWithoutAuth() async {
    if (!_locked) return true;
    if (await _deviceAuth.canAuthenticate()) return false;
    _locked = false;
    _backgroundedAt = null;
    _autoPromptArmed = false;
    notifyListeners();
    return true;
  }

  /// Re-locks when the app was backgrounded past [backgroundGrace].
  void onLifecycleChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused || AppLifecycleState.hidden:
        if (!_authInFlight) _backgroundedAt ??= _clock();
      case AppLifecycleState.resumed:
        final backgroundedAt = _backgroundedAt;
        _backgroundedAt = null;
        if (_enabled &&
            !_locked &&
            backgroundedAt != null &&
            _clock().difference(backgroundedAt) > backgroundGrace) {
          _locked = true;
          _autoPromptArmed = true;
          notifyListeners();
        }
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break;
    }
  }

  Future<bool> _prompt(String reason) async {
    _authInFlight = true;
    try {
      return await _deviceAuth.authenticate(reason: reason);
    } finally {
      _authInFlight = false;
    }
  }
}
