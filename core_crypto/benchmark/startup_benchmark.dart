// Measures the crypto work on the Secure Suite unlock path with realistic
// dataset sizes. Run AOT for numbers comparable to a release build:
//   dart compile exe benchmark/startup_benchmark.dart -o /tmp/bench && /tmp/bench
import 'dart:convert';

import 'package:core_crypto/core_crypto.dart';

Future<void> main() async {
  const kdf = KeyDerivationService();
  const cipher = CipherService();
  final salt = await SaltGenerator.generate();

  await _time('Argon2id deriveKey (64 MiB, t=3, p=4)', 3, () async {
    await kdf.deriveKey(masterPassword: 'correct horse battery', salt: salt);
  });

  final key = await kdf.deriveKey(masterPassword: 'k', salt: salt);
  for (final rows in [200, 1000, 5000]) {
    final json = _dataset(rows);
    final payload =
        await cipher.encrypt(plaintext: json, keyBytes: key, salt: salt);
    final bytes = payload.toBytes();
    final kb = (bytes.length / 1024).round();
    await _time('decrypt + jsonDecode, $rows rows ($kb KiB)', 5, () async {
      final plain = await cipher.decrypt(
        payload: EncryptedPayload.fromBytes(bytes),
        keyBytes: key,
      );
      jsonDecode(plain);
    });
    await _time('EncryptedPayload.toBytes, $rows rows', 5, () async {
      payload.toBytes();
    });
    await _time('jsonEncode + encrypt + toBytes, $rows rows', 5, () async {
      final p = await cipher.encrypt(
        plaintext: jsonEncode(jsonDecode(json)),
        keyBytes: key,
        salt: salt,
      );
      p.toBytes();
    });
  }
}

String _dataset(int rows) => jsonEncode({
      'version': 1,
      'entries': [
        for (var i = 0; i < rows; i++)
          {
            'id': '0f8fad5b-d9cb-469f-a165-70867728950e-$i',
            'title': 'Grocery shopping at the market $i',
            'username': 'someone$i@example.com',
            'password': 'Xk2!pQ9#vL$i',
            'notes': 'Weekly shop; split with flatmate. Receipt kept.',
            'amountMinor': 12345 + i,
            'category': 'food',
            'createdAt': '2026-01-${(i % 28 + 1).toString().padLeft(2, '0')}'
                'T10:00:00.000',
            'tags': ['home', 'weekly'],
          },
      ],
    });

Future<void> _time(String label, int runs, Future<void> Function() body) async {
  await body(); // warm-up
  final sw = Stopwatch()..start();
  for (var i = 0; i < runs; i++) {
    await body();
  }
  final ms = sw.elapsedMicroseconds / runs / 1000;
  print('${label.padRight(52)} ${ms.toStringAsFixed(1)} ms');
}
