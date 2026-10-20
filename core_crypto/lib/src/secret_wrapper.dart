import 'dart:convert';
import 'dart:typed_data';

import 'package:core_crypto/src/cipher_service.dart';
import 'package:core_crypto/src/key_derivation_service.dart';
import 'package:core_crypto/src/models/encrypted_payload.dart';
import 'package:core_crypto/src/salt_generator.dart';

/// Encrypts a secret (typically a data key) under a key derived from a
/// passphrase or recovery key: Argon2id (core_crypto parameters, fresh salt
/// per wrap) → AES-256-GCM. The stored form is
/// `base64(salt ‖ nonce ‖ ciphertext ‖ tag)`.
///
/// Wrapping the same secret under several passphrases gives independent ways
/// to unlock it; replacing one wrap (a new password, a regenerated recovery
/// key) leaves the others and the secret itself untouched.
final class SecretWrapper {
  const SecretWrapper({
    KeyDerivationService kdf = const KeyDerivationService(),
    CipherService cipher = const CipherService(),
  })  : _kdf = kdf,
        _cipher = cipher;

  final KeyDerivationService _kdf;
  final CipherService _cipher;

  Future<String> wrap({
    required Uint8List secret,
    required String passphrase,
  }) async {
    final salt = await SaltGenerator.generate();
    final kek = await _kdf.deriveKey(masterPassword: passphrase, salt: salt);
    try {
      final payload = await _cipher.encrypt(
        plaintext: base64Encode(secret),
        keyBytes: kek,
        salt: salt,
      );
      return base64Encode(payload.toBytes());
    } finally {
      kek.fillRange(0, kek.length, 0);
    }
  }

  /// The wrapped secret, or null when [passphrase] is not the one it was
  /// wrapped under (AES-GCM authentication fails) or [wrapped] is not a wrap.
  Future<Uint8List?> unwrap({
    required String wrapped,
    required String passphrase,
  }) async {
    final EncryptedPayload payload;
    try {
      payload = EncryptedPayload.fromBytes(base64Decode(wrapped));
    } on FormatException {
      return null;
    }
    final kek = await _kdf.deriveKey(
      masterPassword: passphrase,
      salt: payload.salt,
    );
    try {
      final plaintext = await _cipher.decrypt(payload: payload, keyBytes: kek);
      return base64Decode(plaintext);
    } on Exception {
      return null;
    } finally {
      kek.fillRange(0, kek.length, 0);
    }
  }
}
