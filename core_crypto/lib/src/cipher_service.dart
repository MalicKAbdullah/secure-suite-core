import 'dart:convert';
import 'dart:typed_data';

import 'package:core_crypto/src/crypto_constants.dart';
import 'package:core_crypto/src/models/encrypted_payload.dart';
import 'package:core_crypto/src/salt_generator.dart';
import 'package:cryptography/cryptography.dart';

final class CipherService {
  const CipherService();

  // AesGcm.with256bits defaults to a 12-byte nonce, matching
  // CryptoConstants.gcmNonceLengthBytes and the payload layout.
  static final AesGcm _aesGcm = AesGcm.with256bits();

  Future<EncryptedPayload> encrypt({
    required String plaintext,
    required Uint8List keyBytes,
    required Uint8List salt,
  }) async {
    final secretKey = SecretKeyData(keyBytes);
    final nonce = _aesGcm.newNonce();
    final secretBox = await _aesGcm.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );

    return EncryptedPayload(
      ciphertext: Uint8List.fromList(
        secretBox.cipherText + secretBox.mac.bytes,
      ),
      nonce: Uint8List.fromList(nonce),
      salt: salt,
    );
  }

  Future<String> decrypt({
    required EncryptedPayload payload,
    required Uint8List keyBytes,
  }) async {
    final secretKey = SecretKeyData(keyBytes);
    const macLength = CryptoConstants.gcmTagLengthBits ~/ 8;
    final cipherTextOnly = payload.ciphertext.sublist(
      0,
      payload.ciphertext.length - macLength,
    );
    final mac = Mac(
      payload.ciphertext.sublist(payload.ciphertext.length - macLength),
    );

    final secretBox = SecretBox(cipherTextOnly, nonce: payload.nonce, mac: mac);

    final plainBytes = await _aesGcm.decrypt(secretBox, secretKey: secretKey);
    return utf8.decode(plainBytes);
  }

  Future<Uint8List> generateSalt() => SaltGenerator.generate();
}
