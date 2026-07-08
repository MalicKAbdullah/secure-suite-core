import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:core_crypto/src/crypto_constants.dart';
import 'package:cryptography/cryptography.dart';

final class KeyDerivationService {
  const KeyDerivationService();

  static final Argon2id _argon2id = Argon2id(
    memory: CryptoConstants.argon2Memory,
    iterations: CryptoConstants.argon2Iterations,
    parallelism: CryptoConstants.argon2Parallelism,
    hashLength: CryptoConstants.aesKeyLengthBytes,
  );

  Future<Uint8List> deriveKey({
    required String masterPassword,
    required Uint8List salt,
  }) {
    // Run Argon2id in a background isolate to keep the UI responsive.
    return Isolate.run(
      () => _deriveKeyTask(_Argon2TaskParams(masterPassword, salt)),
    );
  }

  static Future<Uint8List> _deriveKeyTask(_Argon2TaskParams params) async {
    final secretKey = await _argon2id.deriveKey(
      secretKey: SecretKeyData(utf8.encode(params.password)),
      nonce: params.salt,
    );
    final keyBytes = await secretKey.extractBytes();
    return Uint8List.fromList(keyBytes);
  }
}

class _Argon2TaskParams {
  final String password;
  final Uint8List salt;
  _Argon2TaskParams(this.password, this.salt);
}
