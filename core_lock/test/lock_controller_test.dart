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

void main() {
  late _FakeStorage storage;
  late DateTime now;
  LockController make(_FakeAuth auth, {bool enabled = false}) => LockController(
        deviceAuth: auth,
        storage: storage,
        clock: () => now,
        storageKey: 'test_lock',
        appName: 'Test',
        enabled: enabled,
      );

  setUp(() {
    storage = _FakeStorage();
    now = DateTime(2026, 7, 21, 9);
  });

  test('starts locked when enabled; unlock succeeds', () async {
    final c = make(_FakeAuth(), enabled: true);
    expect(c.isLocked, isTrue);
    expect(await c.unlock(), isTrue);
    expect(c.isLocked, isFalse);
  });

  test('enabling requires a successful auth + persists', () async {
    final good = _FakeAuth();
    final c = make(good);
    expect(await c.setEnabled(true), isTrue);
    expect(c.isEnabled, isTrue);
    expect(await LockController.readEnabled(storage, 'test_lock'), isTrue);

    final bad = _FakeAuth(succeeds: false);
    final c2 = make(bad);
    expect(await c2.setEnabled(true), isFalse);
    expect(c2.isEnabled, isFalse);
  });

  test('re-locks after backgrounding beyond the grace window', () async {
    final c = make(_FakeAuth(), enabled: true);
    await c.unlock();
    expect(c.isLocked, isFalse);
    c.onLifecycleChanged(AppLifecycleState.paused);
    now = now.add(const Duration(minutes: 1));
    c.onLifecycleChanged(AppLifecycleState.resumed);
    expect(c.isLocked, isTrue);
  });

  test('short background does not re-lock', () async {
    final c = make(_FakeAuth(), enabled: true);
    await c.unlock();
    c.onLifecycleChanged(AppLifecycleState.paused);
    now = now.add(const Duration(seconds: 5));
    c.onLifecycleChanged(AppLifecycleState.resumed);
    expect(c.isLocked, isFalse);
  });

  test('unlockWithoutAuth only works when auth is unavailable', () async {
    final locked = make(_FakeAuth(), enabled: true);
    expect(await locked.unlockWithoutAuth(), isFalse);
    expect(locked.isLocked, isTrue);

    final noAuth = make(_FakeAuth(available: false), enabled: true);
    expect(await noAuth.unlockWithoutAuth(), isTrue);
    expect(noAuth.isLocked, isFalse);
  });
}
