import 'package:core_storage/src/interfaces/i_secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class SecureStorageImpl implements ISecureStorage {
  const SecureStorageImpl(this._storage);

  final FlutterSecureStorage _storage;

  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(
        key: key,
        value: value,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );

  @override
  Future<String?> read({required String key}) =>
      _storage.read(key: key, aOptions: _androidOptions, iOptions: _iosOptions);

  @override
  Future<void> delete({required String key}) => _storage.delete(
    key: key,
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  @override
  Future<void> deleteAll() =>
      _storage.deleteAll(aOptions: _androidOptions, iOptions: _iosOptions);

  @override
  Future<Map<String, String>> readAll() =>
      _storage.readAll(aOptions: _androidOptions, iOptions: _iosOptions);
}
