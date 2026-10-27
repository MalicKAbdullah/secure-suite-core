import 'dart:async';

import 'package:core_crypto/core_crypto.dart';
import 'package:core_lock/core_lock.dart';
import 'package:core_storage/core_storage.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';

final class _FakeStorage implements ISecureStorage {
  final Map<String, String> _m = {};

  /// When set, deletes wait for it — a slow platform round trip.
  Completer<void>? deleteGate;
  @override
  Future<void> write({required String key, required String value}) async =>
      _m[key] = value;
  @override
  Future<String?> read({required String key}) async => _m[key];
  @override
  Future<void> delete({required String key}) async {
    await deleteGate?.future;
    _m.remove(key);
  }

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
  String? lastReason;
  @override
  Future<bool> canAuthenticate() async => available;
  @override
  Future<bool> authenticate({required String reason}) async {
    prompts++;
    lastReason = reason;
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

  final ok = isA<LockAttemptSuccess>();
  final rejected = isA<LockAttemptRejected>();

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
    expect(await c.unlockWithPassword('pw'), ok);
    expect(c.isLocked, isFalse);
  });

  test('password unlock: right unlocks, wrong does not', () async {
    final c = make(_FakeAuth(), enabled: true);
    await storage.write(key: 'test_lock_verifier', value: 'h:secret');
    expect(c.isLocked, isTrue);
    expect(await c.unlockWithPassword('nope'), rejected);
    expect(c.isLocked, isTrue);
    expect(await c.unlockWithPassword('secret'), ok);
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

  test('biometric unlock shows the app before clearing attempt counters',
      () async {
    final c = make(_FakeAuth(), enabled: true, biometricEnabled: true);
    storage.deleteGate = Completer<void>();
    final unlocking = c.unlockWithBiometric();
    await Future<void>.delayed(Duration.zero);
    expect(c.isLocked, isFalse);
    storage.deleteGate!.complete();
    expect(await unlocking, isTrue);
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
    expect(await c.disable('wrong'), rejected);
    expect(c.isEnabled, isTrue);
    expect(await c.disable('pw'), ok);
    expect(c.isEnabled, isFalse);
    expect(await storage.read(key: 'test_lock_verifier'), isNull);
  });

  test('changePassword verifies the old one', () async {
    final c = make(_FakeAuth(), enabled: true);
    await storage.write(key: 'test_lock_verifier', value: 'h:old');
    expect(
      await c.changePassword(currentPassword: 'bad', newPassword: 'new'),
      rejected,
    );
    expect(
      await c.changePassword(currentPassword: 'old', newPassword: 'new'),
      ok,
    );
    expect(await c.unlockWithPassword('new'), ok);
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

  group('recovery key', () {
    Future<LockController> unlocked(_FakeAuth auth) async {
      final c = make(auth);
      await c.enable(password: 'old-password');
      return c;
    }

    test('stores only a verifier, never the key', () async {
      final c = await unlocked(_FakeAuth());
      final key = await c.createRecoveryKey();
      expect(await c.hasRecoveryKey(), isTrue);
      final normalized = RecoveryKey.normalize(key)!;
      for (final value in (await storage.readAll()).values) {
        expect(value, isNot(contains(key)));
        expect(value, isNot(normalized));
      }
    });

    test('resets a forgotten password and unlocks', () async {
      final c = await unlocked(_FakeAuth(available: false));
      final key = await c.createRecoveryKey();
      c.onLifecycleChanged(AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 5));
      c.onLifecycleChanged(AppLifecycleState.resumed);
      expect(c.isLocked, isTrue);

      final result = await c.resetWithRecoveryKey(
        recoveryKey: key.toLowerCase().replaceAll('-', ' '),
        newPassword: 'new-password',
      );
      expect(result, ok);
      expect(c.isLocked, isFalse);
      expect(c.unlockedWith, UnlockMethod.recoveryKey);
      expect(await c.verifyPassword('old-password'), rejected);
      expect(await c.verifyPassword('new-password'), ok);
    });

    test('a wrong or malformed key is rejected and changes nothing', () async {
      final c = make(_FakeAuth(), enabled: true);
      await storage.write(key: 'test_lock_verifier', value: 'h:pw');
      await storage.write(
        key: 'test_lock_recovery',
        value: 'h:${RecoveryKey.normalize(RecoveryKey.generate())!}',
      );
      expect(
        await c.resetWithRecoveryKey(
          recoveryKey: RecoveryKey.generate(),
          newPassword: 'x-new-pass',
        ),
        rejected,
      );
      expect(
        await c.resetWithRecoveryKey(recoveryKey: 'abc', newPassword: 'x'),
        rejected,
      );
      expect(c.isLocked, isTrue);
      expect(await c.verifyPassword('pw'), ok);
    });

    test('regenerating invalidates the previous key', () async {
      final c = await unlocked(_FakeAuth());
      final first = await c.createRecoveryKey();
      final second = await c.createRecoveryKey();
      c.onLifecycleChanged(AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 5));
      c.onLifecycleChanged(AppLifecycleState.resumed);

      expect(
        await c.resetWithRecoveryKey(recoveryKey: first, newPassword: 'np'),
        rejected,
      );
      expect(
        await c.resetWithRecoveryKey(recoveryKey: second, newPassword: 'np'),
        ok,
      );
    });

    test('no recovery key means no reset', () async {
      final c = make(_FakeAuth(), enabled: true);
      await storage.write(key: 'test_lock_verifier', value: 'h:pw');
      expect(await c.hasRecoveryKey(), isFalse);
      expect(
        await c.resetWithRecoveryKey(
          recoveryKey: RecoveryKey.generate(),
          newPassword: 'np',
        ),
        rejected,
      );
      expect(c.isLocked, isTrue);
    });

    test('can only be created while unlocked', () async {
      final c = make(_FakeAuth(), enabled: true);
      expect(c.createRecoveryKey, throwsStateError);
    });

    test('disable removes the recovery verifier', () async {
      final c = await unlocked(_FakeAuth());
      await c.createRecoveryKey();
      await c.disable('old-password');
      expect(await c.hasRecoveryKey(), isFalse);
    });
  });

  group('attempt cooldown', () {
    test('five free failures, then an escalating cooldown', () async {
      final c = make(_FakeAuth(), enabled: true);
      await storage.write(key: 'test_lock_verifier', value: 'h:pw');
      for (var i = 0; i < 4; i++) {
        final r = await c.unlockWithPassword('bad');
        expect((r as LockAttemptRejected).cooldown, isNull);
      }
      final fifth = await c.unlockWithPassword('bad') as LockAttemptRejected;
      expect(fifth.cooldown, LockCooldown.base);

      // Even the right password is not checked during the cooldown.
      expect(await c.unlockWithPassword('pw'), isA<LockAttemptCoolingDown>());
      expect(c.isLocked, isTrue);

      now = now.add(const Duration(seconds: 31));
      final sixth = await c.unlockWithPassword('bad') as LockAttemptRejected;
      expect(sixth.cooldown, const Duration(seconds: 60));
      now = now.add(const Duration(seconds: 61));
      expect(await c.unlockWithPassword('pw'), ok);
      expect(await c.cooldownRemaining(), Duration.zero);
    });

    test('recovery-key guesses share the password cooldown', () async {
      final c = make(_FakeAuth(), enabled: true);
      await storage.write(key: 'test_lock_verifier', value: 'h:pw');
      await storage.write(key: 'test_lock_recovery', value: 'h:none');
      for (var i = 0; i < 5; i++) {
        await c.resetWithRecoveryKey(
          recoveryKey: RecoveryKey.generate(),
          newPassword: 'np',
        );
      }
      expect(await c.unlockWithPassword('pw'), isA<LockAttemptCoolingDown>());
    });

    test('cooldown is capped', () {
      expect(LockCooldown.after(4), Duration.zero);
      expect(LockCooldown.after(50), LockCooldown.max);
    });
  });

  group('change password', () {
    test('a fingerprint session confirms with a fresh fingerprint', () async {
      final auth = _FakeAuth();
      final c = make(auth, enabled: true, biometricEnabled: true);
      await storage.write(key: 'test_lock_verifier', value: 'h:pw');
      await c.unlockWithBiometric();
      expect(c.canChangePasswordWithBiometric, isTrue);

      auth.succeeds = false;
      expect(
        await c.changePassword(currentPassword: null, newPassword: 'n1'),
        rejected,
      );
      auth.succeeds = true;
      final before = auth.prompts;
      expect(
        await c.changePassword(currentPassword: null, newPassword: 'n1'),
        ok,
      );
      expect(auth.prompts, before + 1);
      expect(await c.verifyPassword('n1'), ok);
    });

    test('a password session must give the current password', () async {
      final auth = _FakeAuth();
      final c = make(auth, enabled: true, biometricEnabled: true);
      await storage.write(key: 'test_lock_verifier', value: 'h:pw');
      await c.unlockWithPassword('pw');
      expect(c.canChangePasswordWithBiometric, isFalse);
      expect(
        await c.changePassword(currentPassword: null, newPassword: 'n1'),
        rejected,
      );
      expect(auth.prompts, 0);
      expect(await c.verifyPassword('pw'), ok);
    });
  });

  group('one-time recovery offer', () {
    test('due after an unlock without a key, until finished', () async {
      final c = make(_FakeAuth(), enabled: true);
      await storage.write(key: 'test_lock_verifier', value: 'h:pw');
      expect(c.recoveryPromptDue, isFalse);
      await c.unlockWithPassword('pw');
      await Future<void>.delayed(Duration.zero);
      expect(c.recoveryPromptDue, isTrue);

      await c.finishRecoveryPrompt();
      expect(c.recoveryPromptDue, isFalse);

      c.onLifecycleChanged(AppLifecycleState.paused);
      now = now.add(const Duration(minutes: 5));
      c.onLifecycleChanged(AppLifecycleState.resumed);
      await c.unlockWithPassword('pw');
      await Future<void>.delayed(Duration.zero);
      expect(c.recoveryPromptDue, isFalse);
    });

    test('not offered when a key exists', () async {
      final c = make(_FakeAuth(), enabled: true);
      await storage.write(key: 'test_lock_verifier', value: 'h:pw');
      await storage.write(key: 'test_lock_recovery', value: 'h:k');
      await c.unlockWithPassword('pw');
      await Future<void>.delayed(Duration.zero);
      expect(c.recoveryPromptDue, isFalse);
    });
  });
}
