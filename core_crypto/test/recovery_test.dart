import 'dart:math';
import 'dart:typed_data';

import 'package:core_crypto/core_crypto.dart';
import 'package:test/test.dart';

void main() {
  group('RecoveryKey', () {
    test('generates grouped keys that normalize to the full length', () {
      final key = RecoveryKey.generate();
      expect(key, matches(RegExp(r'^([0-9A-Z]{4}-){6}[0-9A-Z]{4}$')));
      expect(RecoveryKey.normalize(key), key.replaceAll('-', ''));
    });

    test('keys differ between calls', () {
      final keys = {for (var i = 0; i < 50; i++) RecoveryKey.generate()};
      expect(keys, hasLength(50));
    });

    test('normalize ignores case, spaces, dashes and folds look-alikes', () {
      final key = RecoveryKey.generate(random: Random(1));
      final canonical = RecoveryKey.normalize(key)!;
      final sloppy = key.toLowerCase().replaceAll('-', ' ');
      expect(RecoveryKey.normalize(sloppy), canonical);
      expect(
        RecoveryKey.normalize('O' * 14 + 'I' * 7 + 'L' * 7),
        '0' * 14 + '1' * 14,
      );
    });

    test('normalize rejects wrong length and foreign characters', () {
      expect(RecoveryKey.normalize('ABCD-EFGH'), isNull);
      expect(RecoveryKey.normalize('U' * RecoveryKey.length), isNull);
      expect(RecoveryKey.normalize('${'A' * 27}!'), isNull);
    });
  });

  group('SecretWrapper', () {
    const wrapper = SecretWrapper();
    final secret = Uint8List.fromList(List.generate(32, (i) => i * 3));

    test('recovery key unwraps the secret; a wrong key is rejected', () async {
      final recovery = RecoveryKey.normalize(RecoveryKey.generate())!;
      final wrapped = await wrapper.wrap(secret: secret, passphrase: recovery);

      expect(
        await wrapper.unwrap(wrapped: wrapped, passphrase: recovery),
        secret,
      );
      final other = RecoveryKey.normalize(RecoveryKey.generate())!;
      expect(await wrapper.unwrap(wrapped: wrapped, passphrase: other), isNull);
    });

    test('re-wrapping under a new password keeps the recovery wrap working',
        () async {
      final recovery = RecoveryKey.normalize(RecoveryKey.generate())!;
      final recoveryWrap =
          await wrapper.wrap(secret: secret, passphrase: recovery);
      final oldPasswordWrap =
          await wrapper.wrap(secret: secret, passphrase: 'old password');

      // Password change: unwrap with the old password, wrap under the new.
      final unwrapped = await wrapper.unwrap(
        wrapped: oldPasswordWrap,
        passphrase: 'old password',
      );
      final newPasswordWrap =
          await wrapper.wrap(secret: unwrapped!, passphrase: 'new password');

      expect(
        await wrapper.unwrap(
          wrapped: newPasswordWrap,
          passphrase: 'new password',
        ),
        secret,
      );
      expect(
        await wrapper.unwrap(
          wrapped: newPasswordWrap,
          passphrase: 'old password',
        ),
        isNull,
      );
      expect(
        await wrapper.unwrap(wrapped: recoveryWrap, passphrase: recovery),
        secret,
      );
    });

    test('regenerating the recovery key invalidates the old one', () async {
      final first = RecoveryKey.normalize(RecoveryKey.generate())!;
      final second = RecoveryKey.normalize(RecoveryKey.generate())!;
      // Regeneration replaces the stored wrap with one under the new key.
      final current = await wrapper.wrap(secret: secret, passphrase: second);

      expect(await wrapper.unwrap(wrapped: current, passphrase: first), isNull);
      expect(
        await wrapper.unwrap(wrapped: current, passphrase: second),
        secret,
      );
    });

    test('each wrap uses a fresh salt', () async {
      final a = await wrapper.wrap(secret: secret, passphrase: 'same');
      final b = await wrapper.wrap(secret: secret, passphrase: 'same');
      expect(a, isNot(b));
    });

    test('garbage input is not a wrap', () async {
      expect(
        await wrapper.unwrap(wrapped: 'not base64!', passphrase: 'x'),
        isNull,
      );
    });
  });
}
