import 'package:core_lock/core_lock.dart';
import 'package:core_storage/core_storage.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';

final class _FakeStorage implements ISecureStorage {
  final Map<String, String> _m = {};
  @override
  Future<void> write({required String key, required String value}) async =>
      _m[key] = value;
  @override
  Future<String?> read({required String key}) async => _m[key];
  @override
  Future<void> delete({required String key}) async => _m.remove(key);
  @override
  Future<void> deleteAll() async => _m.clear();
  @override
  Future<Map<String, String>> readAll() async => Map.of(_m);
}

final class _FakeAuth implements IDeviceAuth {
  _FakeAuth({this.available = true, this.succeeds = true});
  bool available;
  bool succeeds;
  int prompts = 0;
  @override
  Future<bool> canAuthenticate() async => available;
  @override
  Future<bool> authenticate({required String reason}) async {
    prompts++;
    return succeeds;
  }
}

/// Reversible, fast stand-in for Argon2 so tests stay quick and deterministic.
final class _FakeHasher implements IPasswordHasher {
  @override
  Future<String> hash(String password) async => 'h:$password';
  @override
  Future<bool> verify(String password, String stored) async =>
      stored == 'h:$password';
}

void main() {
  late _FakeStorage storage;
  late DateTime now;

  LockController make(
    _FakeAuth auth, {
    bool enabled = false,
    bool biometricEnabled = false,
  }) =>
      LockController(
        deviceAuth: auth,
        hasher: _FakeHasher(),
        storage: storage,
        clock: () => now,
        storageKey: 'test_lock',
        appName: 'Test',
        enabled: enabled,
        biometricEnabled: biometricEnabled,
      );

  setUp(() {
    storage = _FakeStorage();
    now = DateTime(2026, 7, 21, 9);
  });

  test('enable sets a password verifier + persists flags', () async {
    final auth = _FakeAuth();
    final c = make(auth);
    expect(await c.enable(password: 'hunter2'), isTrue);
    expect(c.isEnabled, isTrue);
    expect(c.isLocked, isFalse);
    expect(c.biometricEnabled, isTrue); // device supports it
    expect(await LockController.readEnabled(storage, 'test_lock'), isTrue);
    expect(
      await LockController.readBiometricEnabled(storage, 'test_lock'),
      isTrue,
    );
  });

  test('enable without biometric leaves it off', () async {
    final c = make(_FakeAuth(available: false));
    await c.enable(password: 'pw');
    expect(c.biometricEnabled, isFalse); // no enrolled biometrics
  });

  test('failed fingerprint keeps the lock; password still works', () async {
    final auth = _FakeAuth(succeeds: false);
    final c = make(auth, enabled: true, biometricEnabled: true);
    await storage.write(key: 'test_lock_verifier', value: 'h:pw');
    expect(await c.unlockWithBiometric(), isFalse);
    expect(c.isLocked, isTrue);
    expect(await c.unlockWithPassword('pw'), isTrue);
    expect(c.isLocked, isFalse);
  });

  test('password unlock: right unlocks, wrong does not', () async {
    final c = make(_FakeAuth(), enabled: true);
    await storage.write(key: 'test_lock_verifier', value: 'h:secret');
    expect(c.isLocked, isTrue);
    expect(await c.unlockWithPassword('nope'), isFalse);
    expect(c.isLocked, isTrue);
    expect(await c.unlockWithPassword('secret'), isTrue);
    expect(c.isLocked, isFalse);
  });

  test('biometric unlock only when biometric enabled', () async {
    final auth = _FakeAuth();
    final noBio = make(auth, enabled: true);
    expect(await noBio.unlockWithBiometric(), isFalse);
    expect(auth.prompts, 0);

    final withBio = make(auth, enabled: true, biometricEnabled: true);
    expect(await withBio.unlockWithBiometric(), isTrue);
    expect(auth.prompts, 1);
  });

  test('autoUnlock fires biometric once, only when armed + enabled', () async {
    final auth = _FakeAuth();
    final c = make(auth, enabled: true, biometricEnabled: true);
    expect(c.autoPromptArmed, isTrue);
    expect(await c.autoUnlock(), isTrue);
    expect(auth.prompts, 1);
    // Latched: a second autoUnlock does not prompt again.
    expect(await c.autoUnlock(), isFalse);
    expect(auth.prompts, 1);
  });

  test('disable requires the current password', () async {
    final c = make(_FakeAuth(), enabled: true, biometricEnabled: true);
    await storage.write(key: 'test_lock_verifier', value: 'h:pw');
    expect(await c.disable('wrong'), isFalse);
    expect(c.isEnabled, isTrue);
    expect(await c.disable('pw'), isTrue);
    expect(c.isEnabled, isFalse);
    expect(await storage.read(key: 'test_lock_verifier'), isNull);
  });

  test('changePassword verifies the old one', () async {
    final c = make(_FakeAuth(), enabled: true);
    await storage.write(key: 'test_lock_verifier', value: 'h:old');
    expect(
      await c.changePassword(oldPassword: 'bad', newPassword: 'new'),
      isFalse,
    );
    expect(
      await c.changePassword(oldPassword: 'old', newPassword: 'new'),
      isTrue,
    );
    expect(await c.unlockWithPassword('new'), isTrue);
  });

  test('re-locks after backgrounding beyond the grace window', () async {
    final c = make(_FakeAuth(), enabled: true, biometricEnabled: true);
    await storage.write(key: 'test_lock_verifier', value: 'h:pw');
    await c.unlockWithPassword('pw');
    expect(c.isLocked, isFalse);
    c.onLifecycleChanged(AppLifecycleState.paused);
    now = now.add(const Duration(minutes: 1));
    c.onLifecycleChanged(AppLifecycleState.resumed);
    expect(c.isLocked, isTrue);
  });

  test('short background does not re-lock', () async {
    final c = make(_FakeAuth(), enabled: true);
    await storage.write(key: 'test_lock_verifier', value: 'h:pw');
    await c.unlockWithPassword('pw');
    c.onLifecycleChanged(AppLifecycleState.paused);
    now = now.add(const Duration(seconds: 5));
    c.onLifecycleChanged(AppLifecycleState.resumed);
    expect(c.isLocked, isFalse);
  });

  test('setBiometricEnabled needs enrolled biometrics to turn on', () async {
    final c = make(_FakeAuth(available: false), enabled: true);
    expect(await c.setBiometricEnabled(true), isFalse);
    expect(c.biometricEnabled, isFalse);
  });
}
