import 'package:core_lock/src/device_auth.dart';
import 'package:core_lock/src/password_hasher.dart';
import 'package:core_storage/core_storage.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, ChangeNotifier;

/// Owns the app-lock state for a Secure Suite app.
///
/// Unlock model (identical across every app): a **fingerprint** is the primary
/// unlock and an **app-set password** — chosen inside the app, never the phone
/// PIN — is the always-available fallback. There is no device-credential path.
///
/// Pure Dart apart from [AppLifecycleState] — testable with a fake
/// [IDeviceAuth], a fake [IPasswordHasher], an in-memory [ISecureStorage], and
/// a fixed clock.
final class LockController extends ChangeNotifier {
  LockController({
    required IDeviceAuth deviceAuth,
    required IPasswordHasher hasher,
    required ISecureStorage storage,
    required DateTime Function() clock,
    required String storageKey,
    required String appName,
    bool enabled = false,
    bool biometricEnabled = false,
    this.backgroundGrace = const Duration(seconds: 30),
  })  : _deviceAuth = deviceAuth,
        _hasher = hasher,
        _storage = storage,
        _clock = clock,
        _enabledKey = storageKey,
        _verifierKey = '${storageKey}_verifier',
        _biometricKey = '${storageKey}_biometric',
        _appName = appName,
        _enabled = enabled,
        _biometricEnabled = biometricEnabled,
        _locked = enabled,
        _autoPromptArmed = enabled && biometricEnabled;

  /// Backgrounding for longer than this re-locks the app.
  final Duration backgroundGrace;

  final IDeviceAuth _deviceAuth;
  final IPasswordHasher _hasher;
  final ISecureStorage _storage;
  final DateTime Function() _clock;
  final String _enabledKey;
  final String _verifierKey;
  final String _biometricKey;
  final String _appName;

  bool _enabled;
  bool _biometricEnabled;
  bool _locked;
  bool _autoPromptArmed;
  bool _authInFlight = false;
  DateTime? _backgroundedAt;

  bool get isEnabled => _enabled;
  bool get isLocked => _locked;
  bool get biometricEnabled => _biometricEnabled;

  /// Whether the auto biometric prompt should fire (once per locked session).
  bool get autoPromptArmed => _autoPromptArmed && _biometricEnabled;
  String get appName => _appName;

  /// Reads the persisted enabled flag before the controller exists, so main()
  /// can construct the app already locked (no unlocked flash on cold start).
  static Future<bool> readEnabled(
    ISecureStorage storage,
    String storageKey,
  ) async =>
      await storage.read(key: storageKey) == 'true';

  /// Reads the persisted biometric-enabled flag (see [readEnabled]).
  static Future<bool> readBiometricEnabled(
    ISecureStorage storage,
    String storageKey,
  ) async =>
      await storage.read(key: '${storageKey}_biometric') == 'true';

  /// Whether the device has enrolled biometrics available to turn on.
  Future<bool> canUseBiometric() => _deviceAuth.canAuthenticate();

  /// Turns the lock on by setting the fallback [password]. Optionally enables
  /// biometric unlock too (only takes effect if the device supports it).
  Future<bool> enable({
    required String password,
    bool useBiometric = true,
  }) async {
    if (password.isEmpty) return false;
    final verifier = await _hasher.hash(password);
    await _storage.write(key: _verifierKey, value: verifier);

    final bio = useBiometric && await _deviceAuth.canAuthenticate();
    _biometricEnabled = bio;
    await _storage.write(key: _biometricKey, value: bio ? 'true' : 'false');

    _enabled = true;
    _locked = false;
    _autoPromptArmed = false;
    await _storage.write(key: _enabledKey, value: 'true');
    notifyListeners();
    return true;
  }

  /// Turns the lock off. Requires the current [password] so a thief with an
  /// unlocked session can't silently disable it.
  Future<bool> disable(String password) async {
    if (!await _verifyPassword(password)) return false;
    _enabled = false;
    _biometricEnabled = false;
    _locked = false;
    _autoPromptArmed = false;
    await _storage.delete(key: _enabledKey);
    await _storage.delete(key: _verifierKey);
    await _storage.delete(key: _biometricKey);
    notifyListeners();
    return true;
  }

  /// Changes the fallback password after verifying the old one.
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (newPassword.isEmpty) return false;
    if (!await _verifyPassword(oldPassword)) return false;
    final verifier = await _hasher.hash(newPassword);
    await _storage.write(key: _verifierKey, value: verifier);
    return true;
  }

  /// Turns biometric unlock on (needs enrolled biometrics) or off. The
  /// password fallback always remains.
  Future<bool> setBiometricEnabled(bool enabled) async {
    if (enabled && !await _deviceAuth.canAuthenticate()) return false;
    _biometricEnabled = enabled;
    await _storage.write(key: _biometricKey, value: enabled ? 'true' : 'false');
    notifyListeners();
    return true;
  }

  /// Fires the automatic biometric prompt once per locked session (latched).
  /// No-op when biometric unlock is off — the user types the password instead.
  Future<bool> autoUnlock() async {
    if (!_autoPromptArmed || !_biometricEnabled) return false;
    _autoPromptArmed = false;
    return unlockWithBiometric();
  }

  /// Prompts for a fingerprint and unlocks on success.
  Future<bool> unlockWithBiometric() async {
    if (!_locked) return true;
    if (!_biometricEnabled || _authInFlight) return false;
    if (!await _prompt('Unlock $_appName')) return false;
    _clearLock();
    return true;
  }

  /// Verifies the fallback [password] and unlocks on success.
  Future<bool> unlockWithPassword(String password) async {
    if (!_locked) return true;
    if (!await _verifyPassword(password)) return false;
    _clearLock();
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

  void _clearLock() {
    _locked = false;
    _backgroundedAt = null;
    _autoPromptArmed = false;
    notifyListeners();
  }

  Future<bool> _verifyPassword(String password) async {
    final stored = await _storage.read(key: _verifierKey);
    if (stored == null) return false;
    return _hasher.verify(password, stored);
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
