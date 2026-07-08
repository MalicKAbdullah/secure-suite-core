import 'dart:math';
import 'dart:typed_data';

import 'package:core_crypto/src/crypto_constants.dart';

abstract final class SaltGenerator {
  static Future<Uint8List> generate() async {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(
        CryptoConstants.saltLengthBytes,
        (_) => random.nextInt(256),
      ),
    );
  }
}
