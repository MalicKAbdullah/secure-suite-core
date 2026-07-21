import 'dart:convert';
import 'dart:typed_data';

import 'package:core_crypto/core_crypto.dart';

/// Hashes and verifies the app-lock password (the fallback for when biometrics
/// fail or aren't set up). This is a *verifier* only — the stored value can't
/// be reversed to the password and is not the data-encryption key.
abstract interface class IPasswordHasher {
  /// Produces an opaque, storable verifier for [password].
  Future<String> hash(String password);

  /// True when [password] matches the [stored] verifier from [hash].
  Future<bool> verify(String password, String stored);
}

/// Argon2id-backed hasher (via core_crypto). Stored form is
/// `base64(salt):base64(derivedKey)`.
final class Argon2PasswordHasher implements IPasswordHasher {
  const Argon2PasswordHasher([
    this._kdf = const KeyDerivationService(),
  ]);

  final KeyDerivationService _kdf;

  @override
  Future<String> hash(String password) async {
    final salt = await SaltGenerator.generate();
    final key = await _kdf.deriveKey(masterPassword: password, salt: salt);
    return '${base64Encode(salt)}:${base64Encode(key)}';
  }

  @override
  Future<bool> verify(String password, String stored) async {
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    try {
      final salt = Uint8List.fromList(base64Decode(parts[0]));
      final expected = base64Decode(parts[1]);
      final actual = await _kdf.deriveKey(masterPassword: password, salt: salt);
      return _constantTimeEquals(actual, expected);
    } catch (_) {
      return false;
    }
  }

  /// Length-independent, value-constant comparison to avoid timing leaks.
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
