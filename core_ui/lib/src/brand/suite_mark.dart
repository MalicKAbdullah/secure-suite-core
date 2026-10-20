import 'package:core_ui/src/brand/brand_geometry.dart';
import 'package:core_ui/src/brand/brand_painter.dart';
import 'package:flutter/material.dart';

/// The family name. The symbol never spells it; the wordmark sets it.
const String suiteName = 'Offlyne';

/// Font family of the wordmark (bundled by core_theme).
const String suiteWordmarkFamily = 'packages/core_theme/MonaSansDisplay';

/// Smallest size the mark may render at; below this the break in the ring
/// closes up and the dot merges with it.
const double suiteMarkMinSize = 16;

/// How the parent mark is colored.
enum SuiteMarkVariant {
  /// One color throughout.
  mono,

  /// Ring in ink, the dot in the app's accent.
  accent,
}

/// The family's parent mark: a heavy O whose ring is broken where a signal
/// would leave, with the family dot sealing the break. Ink defaults to the ambient [IconTheme] color so the mark follows
/// light and dark themes on its own.
final class SuiteMark extends StatelessWidget {
  const SuiteMark({
    this.size = 24,
    this.variant = SuiteMarkVariant.mono,
    this.color,
    this.accentColor,
    this.semanticLabel = suiteName,
    super.key,
  }) : assert(size >= suiteMarkMinSize, 'SuiteMark below its minimum size');

  final double size;
  final SuiteMarkVariant variant;

  /// Ring color. Defaults to the ambient icon color.
  final Color? color;

  /// Dot color for [SuiteMarkVariant.accent]. Defaults to
  /// `ColorScheme.primary`.
  final Color? accentColor;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ink = color ??
        IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface;
    final dot = switch (variant) {
      SuiteMarkVariant.mono => ink,
      SuiteMarkVariant.accent =>
        accentColor ?? Theme.of(context).colorScheme.primary,
    };
    return Semantics(
      label: semanticLabel,
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _SuiteMarkPainter(ink: ink, dot: dot),
      ),
    );
  }
}

final class _SuiteMarkPainter extends CustomPainter {
  const _SuiteMarkPainter({required this.ink, required this.dot});

  final Color ink;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    paintBrandShapes(
      canvas,
      suiteMarkShapes,
      origin: Offset.zero,
      extent: size.shortestSide,
      ink: ink,
      dot: dot,
    );
  }

  @override
  bool shouldRepaint(_SuiteMarkPainter old) => old.ink != ink || old.dot != dot;
}

/// The endorsement lockup: the parent mark followed by "by Offlyne".
/// Sits quietly under an app's own name on splash, lock and About screens.
/// The mark is sized to the text's cap height band so the two read as one
/// line at any text size.
final class SuiteEndorsement extends StatelessWidget {
  const SuiteEndorsement({
    this.style,
    this.color,
    this.accentColor,
    this.variant = SuiteMarkVariant.mono,
    super.key,
  });

  /// Text style. Defaults to `textTheme.labelMedium`.
  final TextStyle? style;

  /// Color of both mark and text. Defaults to `onSurfaceVariant`.
  final Color? color;

  final Color? accentColor;
  final SuiteMarkVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = color ?? theme.colorScheme.onSurfaceVariant;
    final base = (style ?? theme.textTheme.labelMedium ?? const TextStyle())
        .copyWith(color: ink);
    final fontSize = base.fontSize ?? 12;
    final markSize =
        (fontSize * 1.15).clamp(suiteMarkMinSize, double.infinity).toDouble();
    return Semantics(
      label: 'by $suiteName',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SuiteMark(
            size: markSize,
            color: ink,
            variant: variant,
            accentColor: accentColor,
            semanticLabel: null,
          ),
          SizedBox(width: markSize * 0.4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'by ',
                  style: base.copyWith(fontWeight: FontWeight.w400),
                ),
                TextSpan(
                  text: suiteName,
                  style: base.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Offlyne" wordmark, set in Mona Sans Display. The y, the letter that
/// makes the name, carries the accent in [SuiteMarkVariant.accent] and is
/// opened up with a touch of extra space either side in both variants, so it
/// reads as chosen rather than mistyped.
final class SuiteWordmark extends StatelessWidget {
  const SuiteWordmark({
    this.fontSize = 28,
    this.color,
    this.accentColor,
    this.variant = SuiteMarkVariant.mono,
    super.key,
  });

  final double fontSize;
  final Color? color;
  final Color? accentColor;
  final SuiteMarkVariant variant;

  /// Tracking of the whole word, as a fraction of the font size.
  static const double tracking = -0.02;

  /// Extra space either side of the y, as a fraction of the font size.
  static const double yRoom = 0.025;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? Theme.of(context).colorScheme.onSurface;
    final yColor = switch (variant) {
      SuiteMarkVariant.mono => ink,
      SuiteMarkVariant.accent =>
        accentColor ?? Theme.of(context).colorScheme.primary,
    };
    final base = TextStyle(
      fontFamily: suiteWordmarkFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      height: 1,
      letterSpacing: fontSize * tracking,
      color: ink,
    );
    final open = base.copyWith(letterSpacing: fontSize * (tracking + yRoom));
    return Semantics(
      label: suiteName,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'Offl', style: open),
            TextSpan(text: 'y', style: open.copyWith(color: yColor)),
            TextSpan(text: 'ne', style: base),
          ],
        ),
        textHeightBehavior: const TextHeightBehavior(
          applyHeightToFirstAscent: false,
          applyHeightToLastDescent: false,
        ),
      ),
    );
  }
}

/// The full lockup: mark, then wordmark, sharing one optical height. The mark
/// is 1.1x the wordmark's font size and sits 0.4x of it away.
final class SuiteLockup extends StatelessWidget {
  const SuiteLockup({
    this.fontSize = 28,
    this.color,
    this.accentColor,
    this.variant = SuiteMarkVariant.mono,
    super.key,
  });

  final double fontSize;
  final Color? color;
  final Color? accentColor;
  final SuiteMarkVariant variant;

  @override
  Widget build(BuildContext context) {
    final markSize =
        (fontSize * 1.1).clamp(suiteMarkMinSize, double.infinity).toDouble();
    return Semantics(
      label: suiteName,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SuiteMark(
            size: markSize,
            color: color,
            accentColor: accentColor,
            variant: variant,
            semanticLabel: null,
          ),
          SizedBox(width: fontSize * 0.4),
          SuiteWordmark(
            fontSize: fontSize,
            color: color,
            accentColor: accentColor,
            variant: variant,
          ),
        ],
      ),
    );
  }
}
