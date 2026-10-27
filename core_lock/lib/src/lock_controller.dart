import 'package:core_crypto/core_crypto.dart';
import 'package:core_lock/src/device_auth.dart';
import 'package:core_lock/src/lock_attempt.dart';
import 'package:core_lock/src/password_hasher.dart';
import 'package:core_storage/core_storage.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, ChangeNotifier;

/// Owns the app-lock state for a Secure Suite app.
///
/// Unlock model (identical across every app): a **fingerprint** is the primary
/// unlock and an **app-set password** — chosen inside the app, never the phone
/// PIN — is the always-available fallback. There is no device-credential path.
/// A **recovery key** (see [RecoveryKey]) resets a forgotten password; only
/// Argon2id verifiers of the password and recovery key are stored. Password
/// and recovery-key attempts share one escalating [LockCooldown].
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
        _recoveryKey = '${storageKey}_recovery',
        _recoveryPromptedKey = '${storageKey}_recovery_prompted',
        _failedKey = '${storageKey}_failed_attempts',
        _lockoutKey = '${storageKey}_lockout_until',
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
  final String _recoveryKey;
  final String _recoveryPromptedKey;
  final String _failedKey;
  final String _lockoutKey;
  final String _appName;

  bool _enabled;
  bool _biometricEnabled;
  bool _locked;
  bool _autoPromptArmed;
  bool _authInFlight = false;
  bool _recoveryPromptDue = false;
  UnlockMethod? _unlockedWith;
  DateTime? _backgroundedAt;

  bool get isEnabled => _enabled;
  bool get isLocked => _locked;
  bool get biometricEnabled => _biometricEnabled;

  /// Whether the auto biometric prompt should fire (once per locked session).
  bool get autoPromptArmed => _autoPromptArmed && _biometricEnabled;
  String get appName => _appName;

  /// How this unlocked session was opened; null while locked or when the
  /// lock is off.
  UnlockMethod? get unlockedWith => _unlockedWith;

  /// True once, after an unlock, for a lock that has no recovery key and has
  /// never offered one: [AppLockGate] then offers to create it.
  bool get recoveryPromptDue => _recoveryPromptDue && !_locked;

  /// Whether [changePassword] may skip the current password: the session was
  /// opened with a fingerprint, which is re-confirmed at change time.
  bool get canChangePasswordWithBiometric =>
      _unlockedWith == UnlockMethod.biometric && _biometricEnabled;

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

  /// Whether a recovery key is set for this lock.
  Future<bool> hasRecoveryKey() async =>
      await _storage.read(key: _recoveryKey) != null;

  /// Time left before another password or recovery-key attempt is checked.
  Future<Duration> cooldownRemaining() async {
    final raw = await _storage.read(key: _lockoutKey);
    if (raw == null) return Duration.zero;
    final until = DateTime.fromMillisecondsSinceEpoch(int.parse(raw));
    final diff = until.difference(_clock());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Turns the lock on by setting the fallback [password]. Optionally enables
  /// biometric unlock too (only takes effect if the device supports it).
  /// Follow with [createRecoveryKey] to give the user a way back in.
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
    _unlockedWith = UnlockMethod.password;
    _recoveryPromptDue = false;
    await _storage.write(key: _enabledKey, value: 'true');
    notifyListeners();
    return true;
  }

  /// Turns the lock off. Requires the current [password] so a thief with an
  /// unlocked session can't silently disable it.
  Future<LockAttempt> disable(String password) async {
    final result = await verifyPassword(password);
    if (result is! LockAttemptSuccess) return result;
    _enabled = false;
    _biometricEnabled = false;
    _locked = false;
    _autoPromptArmed = false;
    _unlockedWith = null;
    _recoveryPromptDue = false;
    for (final key in [
      _enabledKey,
      _verifierKey,
      _biometricKey,
      _recoveryKey,
      _recoveryPromptedKey,
      _failedKey,
      _lockoutKey,
    ]) {
      await _storage.delete(key: key);
    }
    notifyListeners();
    return result;
  }

  /// Sets a new fallback password. Proof of identity is the current
  /// password, or — when [canChangePasswordWithBiometric] and
  /// [currentPassword] is null — a fresh fingerprint.
  Future<LockAttempt> changePassword({
    required String? currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.isEmpty) return const LockAttemptRejected();
    final LockAttempt proof;
    if (currentPassword == null) {
      proof = canChangePasswordWithBiometric &&
              await _prompt('Confirm it’s you to change your password')
          ? const LockAttemptSuccess()
          : const LockAttemptRejected();
    } else {
      proof = await verifyPassword(currentPassword);
    }
    if (proof is! LockAttemptSuccess) return proof;
    await _storage.write(
      key: _verifierKey,
      value: await _hasher.hash(newPassword),
    );
    return proof;
  }

  /// Creates a new recovery key, replacing any earlier one, and returns it in
  /// display form. Only its verifier is stored: show the key to the user now,
  /// it cannot be shown again. Only callable while unlocked.
  Future<String> createRecoveryKey() async {
    if (!_enabled || _locked) {
      throw StateError('A recovery key is created only while unlocked');
    }
    final key = RecoveryKey.generate();
    await _storage.write(
      key: _recoveryKey,
      value: await _hasher.hash(RecoveryKey.normalize(key)!),
    );
    return key;
  }

  /// Ends the one-time recovery-key offer, whether the user created a key or
  /// declined; it is not offered again.
  Future<void> finishRecoveryPrompt() async {
    await _storage.write(key: _recoveryPromptedKey, value: 'true');
    _recoveryPromptDue = false;
    notifyListeners();
  }

  /// Forgotten password: checks [recoveryKey] and, when it matches, sets
  /// [newPassword] and unlocks. Shares the password cooldown.
  Future<LockAttempt> resetWithRecoveryKey({
    required String recoveryKey,
    required String newPassword,
  }) async {
    if (newPassword.isEmpty) return const LockAttemptRejected();
    final result = await _attempt(() async {
      final stored = await _storage.read(key: _recoveryKey);
      final normalized = RecoveryKey.normalize(recoveryKey);
      if (stored == null || normalized == null) return false;
      return _hasher.verify(normalized, stored);
    });
    if (result is! LockAttemptSuccess) return result;
    await _storage.write(
      key: _verifierKey,
      value: await _hasher.hash(newPassword),
    );
    _clearLock(UnlockMethod.recoveryKey);
    return result;
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
    // The home is shown before the attempt counters are cleared: on storage
    // without a cache each delete is a platform round trip, and nothing about
    // the unlock depends on them.
    _clearLock(UnlockMethod.biometric);
    await _resetAttempts();
    return true;
  }

  /// Verifies the fallback [password] and unlocks on success.
  Future<LockAttempt> unlockWithPassword(String password) async {
    if (!_locked) return const LockAttemptSuccess();
    final result = await verifyPassword(password);
    if (result is LockAttemptSuccess) _clearLock(UnlockMethod.password);
    return result;
  }

  /// Checks [password] without changing the lock state (re-auth gates).
  Future<LockAttempt> verifyPassword(String password) => _attempt(() async {
        final stored = await _storage.read(key: _verifierKey);
        if (stored == null) return false;
        return _hasher.verify(password, stored);
      });

  /// Shows the fingerprint prompt for an in-app re-auth gate. False when
  /// biometric unlock is off.
  Future<bool> confirmWithBiometric(String reason) async =>
      _biometricEnabled && !_authInFlight && await _prompt(reason);

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
          _unlockedWith = null;
          notifyListeners();
        }
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break;
    }
  }

  void _clearLock(UnlockMethod method) {
    _locked = false;
    _backgroundedAt = null;
    _autoPromptArmed = false;
    _unlockedWith = method;
    notifyListeners();
    _checkRecoveryPrompt();
  }

  Future<void> _checkRecoveryPrompt() async {
    final due = _enabled &&
        !await hasRecoveryKey() &&
        await _storage.read(key: _recoveryPromptedKey) != 'true';
    if (due == _recoveryPromptDue) return;
    _recoveryPromptDue = due;
    notifyListeners();
  }

  Future<LockAttempt> _attempt(Future<bool> Function() check) async {
    final remaining = await cooldownRemaining();
    if (remaining > Duration.zero) return LockAttemptCoolingDown(remaining);
    if (await check()) {
      await _resetAttempts();
      return const LockAttemptSuccess();
    }
    final raw = await _storage.read(key: _failedKey);
    final failed = (raw == null ? 0 : int.parse(raw)) + 1;
    await _storage.write(key: _failedKey, value: '$failed');
    final cooldown = LockCooldown.after(failed);
    if (cooldown == Duration.zero) return const LockAttemptRejected();
    await _storage.write(
      key: _lockoutKey,
      value: '${_clock().add(cooldown).millisecondsSinceEpoch}',
    );
    return LockAttemptRejected(cooldown: cooldown);
  }

  Future<void> _resetAttempts() async {
    await _storage.delete(key: _failedKey);
    await _storage.delete(key: _lockoutKey);
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
