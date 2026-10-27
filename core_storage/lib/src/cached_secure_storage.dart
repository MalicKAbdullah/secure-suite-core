import 'package:core_storage/src/interfaces/i_secure_storage.dart';

/// An [ISecureStorage] loaded with one bulk read and served from memory.
///
/// On Android, flutter_secure_storage rebuilds its EncryptedSharedPreferences
/// (a Keystore master-key lookup plus two Tink keyset decrypts) on every call,
/// and runs calls one at a time on a single worker thread. A launch that does
/// N individual reads therefore pays N of those initialisations in series.
/// [load] pays one ([ISecureStorage.readAll]); every later read is a map
/// lookup. Writes and deletes go to the platform first and update memory only
/// once they succeed, so memory never claims a value the platform lacks.
///
/// Every stored value stays in process memory for the app's lifetime. Use it
/// only when:
///  * this process is the sole writer of these keys (no background isolate,
///    native code or extension writes them — those writes would be missed);
///  * no stored value must stay out of memory until a user gesture releases
///    it (e.g. a key that should only be read after a biometric prompt).
final class CachedSecureStorage implements ISecureStorage {
  CachedSecureStorage._(this._inner, this._values);

  /// Reads everything [inner] holds in one platform call.
  static Future<CachedSecureStorage> load(ISecureStorage inner) async =>
      CachedSecureStorage._(inner, Map.of(await inner.readAll()));

  final ISecureStorage _inner;
  final Map<String, String> _values;

  @override
  Future<String?> read({required String key}) async => _values[key];

  @override
  Future<Map<String, String>> readAll() async => Map.of(_values);

  @override
  Future<void> write({required String key, required String value}) async {
    await _inner.write(key: key, value: value);
    _values[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    // Memory mirrors the platform (this process is the sole writer), so a key
    // missing here is missing there too and needs no round trip.
    if (!_values.containsKey(key)) return;
    await _inner.delete(key: key);
    _values.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    await _inner.deleteAll();
    _values.clear();
  }
}
