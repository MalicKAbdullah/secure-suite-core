import 'package:flutter/material.dart';

/// The suite type scale on the Mona Sans superfamily (OFL, bundled — no
/// runtime font fetching):
///
/// * **Mona Sans Display** — hero numbers, display and h1/h2. Its display
///   cut is drawn for large sizes: tighter apertures and spacing that hold
///   together at 40–72 px where the text cut would look loose.
/// * **Mona Sans** — everything readers read: body, labels, list rows.
/// * **Mona Sans Mono** — passwords, codes, IDs: every glyph the same width
///   and `0/O`, `1/l/I` unambiguous.
///
/// Mona Sans figures are proportional by default, so every numeric style
/// turns on `tnum`: digits share one width and columns of amounts align.
abstract final class AppTextStyles {
  /// Package fonts must be referenced with the `packages/<pkg>/` prefix.
  static const String fontFamily = 'packages/core_theme/MonaSans';
  static const String displayFamily = 'packages/core_theme/MonaSansDisplay';
  static const String monoFamily = 'packages/core_theme/MonaSansMono';

  static const List<FontFeature> _tnum = [FontFeature.tabularFigures()];

  // Hero — the one number a screen exists to show (balance, vault score).
  static const TextStyle heroXL = TextStyle(
    fontFamily: displayFamily,
    fontSize: 64,
    fontWeight: FontWeight.w500,
    letterSpacing: -2.4,
    height: 1.0,
    fontFeatures: _tnum,
  );

  static const TextStyle hero = TextStyle(
    fontFamily: displayFamily,
    fontSize: 56,
    fontWeight: FontWeight.w500,
    letterSpacing: -2.0,
    height: 1.02,
    fontFeatures: _tnum,
  );

  // Display — standout moments (onboarding, lock-screen clock).
  static const TextStyle displayHuge = TextStyle(
    fontFamily: displayFamily,
    fontSize: 56,
    fontWeight: FontWeight.w600,
    letterSpacing: -2.0,
    height: 1.0,
  );

  static const TextStyle display = TextStyle(
    fontFamily: displayFamily,
    fontSize: 40,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.2,
    height: 1.08,
  );

  // Headings
  static const TextStyle h1 = TextStyle(
    fontFamily: displayFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.9,
    height: 1.12,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: displayFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.18,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 19,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.26,
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
    height: 1.3,
  );

  // Body
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.05,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.05,
    height: 1.47,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.42,
  );

  // Labels & supporting text
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.3,
  );

  static const TextStyle labelStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.05,
    height: 1.2,
  );

  static const TextStyle hint = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.05,
    height: 1.35,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.33,
  );

  /// Small caps-style eyebrow above a group or metric ("THIS MONTH").
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.9,
    height: 1.3,
  );

  // Numbers — tabular figures so digits align in stats, money, and timers.
  static const TextStyle numberLarge = TextStyle(
    fontFamily: displayFamily,
    fontSize: 34,
    fontWeight: FontWeight.w500,
    letterSpacing: -1.0,
    height: 1.08,
    fontFeatures: _tnum,
  );

  static const TextStyle numberMedium = TextStyle(
    fontFamily: displayFamily,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.6,
    height: 1.12,
    fontFeatures: _tnum,
  );

  static const TextStyle number = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.2,
    fontFeatures: _tnum,
  );

  static const TextStyle numberSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.2,
    fontFeatures: _tnum,
  );

  /// Secrets, codes, and generated passwords.
  static const TextStyle code = TextStyle(
    fontFamily: monoFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.4,
  );

  static const TextStyle codeLarge = TextStyle(
    fontFamily: monoFamily,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    height: 1.3,
  );
}
