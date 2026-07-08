import 'dart:typed_data';

import 'package:core_crypto/core_crypto.dart';
import 'package:test/test.dart';

void main() {
  const cipher = CipherService();
  const kdf = KeyDerivationService();

  Uint8List keyOf(int seed) =>
      Uint8List.fromList(List.generate(32, (i) => (i * 7 + seed) & 0xff));

  group('CipherService', () {
    test('encrypt/decrypt round-trips plaintext', () async {
      final salt = await cipher.generateSalt();
      final payload = await cipher.encrypt(
        plaintext: 'hello secure suite',
        keyBytes: keyOf(1),
        salt: salt,
      );

      final decrypted = await cipher.decrypt(
        payload: payload,
        keyBytes: keyOf(1),
      );

      expect(decrypted, 'hello secure suite');
    });

    test('round-trips unicode and empty plaintext', () async {
      final salt = await cipher.generateSalt();
      for (final text in ['', 'héllo 🌍 दवा 薬', 'a' * 10000]) {
        final payload = await cipher.encrypt(
          plaintext: text,
          keyBytes: keyOf(2),
          salt: salt,
        );
        expect(
          await cipher.decrypt(payload: payload, keyBytes: keyOf(2)),
          text,
        );
      }
    });

    test('decrypt fails with the wrong key', () async {
      final salt = await cipher.generateSalt();
      final payload = await cipher.encrypt(
        plaintext: 'secret',
        keyBytes: keyOf(3),
        salt: salt,
      );

      expect(
        () => cipher.decrypt(payload: payload, keyBytes: keyOf(4)),
        throwsA(anything),
      );
    });

    test('decrypt fails when ciphertext is tampered with', () async {
      final salt = await cipher.generateSalt();
      final payload = await cipher.encrypt(
        plaintext: 'secret',
        keyBytes: keyOf(5),
        salt: salt,
      );

      final tampered = Uint8List.fromList(payload.ciphertext);
      tampered[0] ^= 0xff;

      expect(
        () => cipher.decrypt(
          payload: EncryptedPayload(
            ciphertext: tampered,
            nonce: payload.nonce,
            salt: payload.salt,
          ),
          keyBytes: keyOf(5),
        ),
        throwsA(anything),
      );
    });

    test('uses a fresh nonce per encryption', () async {
      final salt = await cipher.generateSalt();
      final a = await cipher.encrypt(
        plaintext: 'same',
        keyBytes: keyOf(6),
        salt: salt,
      );
      final b = await cipher.encrypt(
        plaintext: 'same',
        keyBytes: keyOf(6),
        salt: salt,
      );

      expect(a.nonce, isNot(equals(b.nonce)));
      expect(a.ciphertext, isNot(equals(b.ciphertext)));
    });
  });

  group('EncryptedPayload', () {
    test('toBytes/fromBytes round-trips the layout', () async {
      final salt = await cipher.generateSalt();
      final payload = await cipher.encrypt(
        plaintext: 'layout check',
        keyBytes: keyOf(7),
        salt: salt,
      );

      final restored = EncryptedPayload.fromBytes(payload.toBytes());

      expect(restored.salt, payload.salt);
      expect(restored.nonce, payload.nonce);
      expect(restored.ciphertext, payload.ciphertext);
      expect(
        await cipher.decrypt(payload: restored, keyBytes: keyOf(7)),
        'layout check',
      );
    });
  });

  group('SaltGenerator', () {
    test(
      'produces salts of the configured length and distinct values',
      () async {
        final a = await cipher.generateSalt();
        final b = await cipher.generateSalt();

        expect(a.length, 32);
        expect(b.length, 32);
        expect(a, isNot(equals(b)));
      },
    );
  });

  group('KeyDerivationService', () {
    test(
      'is deterministic for the same password and salt',
      () async {
        final salt = Uint8List.fromList(List.filled(32, 9));

        final k1 = await kdf.deriveKey(
          masterPassword: 'pässwörd 🔑',
          salt: salt,
        );
        final k2 = await kdf.deriveKey(
          masterPassword: 'pässwörd 🔑',
          salt: salt,
        );

        expect(k1, equals(k2));
        expect(k1.length, 32);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'differs across passwords and across salts',
      () async {
        final saltA = Uint8List.fromList(List.filled(32, 1));
        final saltB = Uint8List.fromList(List.filled(32, 2));

        final k1 = await kdf.deriveKey(masterPassword: 'one', salt: saltA);
        final k2 = await kdf.deriveKey(masterPassword: 'two', salt: saltA);
        final k3 = await kdf.deriveKey(masterPassword: 'one', salt: saltB);

        expect(k1, isNot(equals(k2)));
        expect(k1, isNot(equals(k3)));
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });

  group('PasswordGenerator', () {
    test('generates passwords honouring requested length', () {
      final password = PasswordGenerator.generate(length: 24);
      expect(password.length, 24);
    });

    test('respects character-class toggles', () {
      final lettersOnly = PasswordGenerator.generate(
        length: 200,
        includeNumbers: false,
        includeSymbols: false,
      );
      expect(lettersOnly.contains(RegExp('[0-9]')), isFalse);
      expect(
        lettersOnly.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]')),
        isFalse,
      );
    });
  });
}
