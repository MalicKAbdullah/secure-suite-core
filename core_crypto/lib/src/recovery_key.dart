import 'dart:math';

/// A human-friendly, high-entropy recovery key: 28 Crockford base32
/// characters (140 bits from a secure RNG) shown in groups of four, e.g.
/// `7K3M-Q9ZD-…`.
///
/// Crockford's alphabet omits I, L, O and U, so [normalize] can fold the
/// look-alikes people mistype (O→0, I/L→1) and ignore case, spaces and dashes.
/// The key is a secret on par with the password: apps store only a verifier
/// or a wrap derived from it, never the key itself.
abstract final class RecoveryKey {
  static const String alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  static const int length = 28;
  static const int groupLength = 4;

  /// A fresh key in display form (grouped with dashes).
  static String generate({Random? random}) {
    final rng = random ?? Random.secure();
    final raw = List.generate(
      length,
      (_) => alphabet[rng.nextInt(alphabet.length)],
    ).join();
    return format(raw);
  }

  /// The canonical form of [input] (uppercase, no separators, look-alikes
  /// folded), or null when it cannot be a recovery key. Derive keys and
  /// verifiers from this form so formatting never affects the result.
  static String? normalize(String input) {
    final buffer = StringBuffer();
    for (final rune in input.toUpperCase().runes) {
      final ch = String.fromCharCode(rune);
      if (ch == '-' || ch.trim().isEmpty) continue;
      final folded = switch (ch) {
        'O' => '0',
        'I' || 'L' => '1',
        _ => ch,
      };
      if (!alphabet.contains(folded)) return null;
      buffer.write(folded);
    }
    final out = buffer.toString();
    return out.length == length ? out : null;
  }

  /// Groups a canonical key for display.
  static String format(String normalized) {
    final groups = <String>[];
    for (var i = 0; i < normalized.length; i += groupLength) {
      groups.add(
        normalized.substring(i, min(i + groupLength, normalized.length)),
      );
    }
    return groups.join('-');
  }
}
