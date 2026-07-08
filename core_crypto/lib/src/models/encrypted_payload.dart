import 'dart:typed_data';

final class EncryptedPayload {
  const EncryptedPayload({
    required this.ciphertext,
    required this.nonce,
    required this.salt,
  });

  factory EncryptedPayload.fromBytes(Uint8List bytes) {
    const saltEnd = CryptoPayloadLayout.saltEnd;
    const nonceEnd = CryptoPayloadLayout.nonceEnd;

    return EncryptedPayload(
      salt: bytes.sublist(0, saltEnd),
      nonce: bytes.sublist(saltEnd, nonceEnd),
      ciphertext: bytes.sublist(nonceEnd),
    );
  }

  final Uint8List ciphertext;
  final Uint8List nonce;
  final Uint8List salt;

  Uint8List toBytes() {
    return Uint8List.fromList([...salt, ...nonce, ...ciphertext]);
  }
}

abstract final class CryptoPayloadLayout {
  static const int saltEnd = 32;
  static const int nonceEnd = saltEnd + 12;
}
