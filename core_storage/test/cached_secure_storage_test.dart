import 'package:core_storage/core_storage.dart';
import 'package:flutter_test/flutter_test.dart';

final class _CountingStorage implements ISecureStorage {
  final Map<String, String> values = {};
  int platformCalls = 0;
  bool failWrites = false;

  @override
  Future<String?> read({required String key}) async {
    platformCalls++;
    return values[key];
  }

  @override
  Future<Map<String, String>> readAll() async {
    platformCalls++;
    return Map.of(values);
  }

  @override
  Future<void> write({required String key, required String value}) async {
    platformCalls++;
    if (failWrites) throw StateError('keystore unavailable');
    values[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    platformCalls++;
    values.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    platformCalls++;
    values.clear();
  }
}

void main() {
  late _CountingStorage inner;

  setUp(() {
    inner = _CountingStorage()
      ..values.addAll({'lock': 'true', 'bio': 'false', 'period': 'month'});
  });

  test('load is one platform call; reads after it are free', () async {
    final cached = await CachedSecureStorage.load(inner);
    expect(await cached.read(key: 'lock'), 'true');
    expect(await cached.read(key: 'bio'), 'false');
    expect(await cached.read(key: 'missing'), isNull);
    expect(await cached.readAll(), inner.values);
    expect(inner.platformCalls, 1);
  });

  test('writes and deletes reach the platform and memory', () async {
    final cached = await CachedSecureStorage.load(inner);
    await cached.write(key: 'period', value: 'year');
    await cached.delete(key: 'bio');
    expect(inner.values, {'lock': 'true', 'period': 'year'});
    expect(await cached.read(key: 'period'), 'year');
    expect(await cached.read(key: 'bio'), isNull);

    await cached.deleteAll();
    expect(inner.values, isEmpty);
    expect(await cached.readAll(), isEmpty);
  });

  test('a failed platform write leaves memory unchanged', () async {
    final cached = await CachedSecureStorage.load(inner);
    inner.failWrites = true;
    await expectLater(
      cached.write(key: 'lock', value: 'false'),
      throwsStateError,
    );
    expect(await cached.read(key: 'lock'), 'true');
  });

  test('readAll hands out a copy', () async {
    final cached = await CachedSecureStorage.load(inner);
    (await cached.readAll())['lock'] = 'tampered';
    expect(await cached.read(key: 'lock'), 'true');
  });
}
