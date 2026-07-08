// Argon2id parameters follow OWASP 2023 recommended minimums.
abstract final class CryptoConstants {
  static const int aesKeyLengthBytes = 32;
  static const int gcmNonceLengthBytes = 12;
  static const int gcmTagLengthBits = 128;
  static const int saltLengthBytes = 32;

  static const int argon2Memory = 65536;
  static const int argon2Iterations = 3;
  static const int argon2Parallelism = 4;
}
