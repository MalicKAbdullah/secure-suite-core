import 'package:core_theme/core_theme.dart';
import 'package:flutter/material.dart';

/// Whether a [MoneyText] colours itself by sign.
enum MoneyTone {
  /// Primary text colour regardless of sign.
  neutral,

  /// Positive amounts in the positive colour, negative in the negative.
  signed,

  /// Always the negative colour (an expense list shown without minus signs).
  negative,

  /// Always the positive colour.
  positive,
}

/// Formats [amount] with grouped thousands and a fixed number of
/// [decimals]. Negative amounts use a true minus sign (U+2212), which is the
/// width of a plus sign and sits on the figure's centre line.
String formatMoney(
  num amount, {
  String currency = '',
  int decimals = 2,
  bool showPlus = false,
  String groupSeparator = ',',
  String decimalSeparator = '.',
}) {
  final parts = _MoneyParts.of(
    amount,
    decimals: decimals,
    groupSeparator: groupSeparator,
    decimalSeparator: decimalSeparator,
  );
  final sign = parts.negative ? '−' : (showPlus && amount > 0 ? '+' : '');
  final cur = currency.isEmpty ? '' : '$currency ';
  return '$sign$cur${parts.whole}${parts.fraction}';
}

final class _MoneyParts {
  const _MoneyParts(this.negative, this.whole, this.fraction);

  factory _MoneyParts.of(
    num amount, {
    required int decimals,
    required String groupSeparator,
    required String decimalSeparator,
  }) {
    final fixed = amount.abs().toStringAsFixed(decimals);
    final dot = fixed.indexOf('.');
    final intPart = dot < 0 ? fixed : fixed.substring(0, dot);
    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(groupSeparator);
      buf.write(intPart[i]);
    }
    final frac = dot < 0 ? '' : '$decimalSeparator${fixed.substring(dot + 1)}';
    // A value that rounds to zero is never shown as "−0.00".
    final isZero = double.parse(fixed) == 0;
    return _MoneyParts(amount < 0 && !isZero, buf.toString(), frac);
  }

  final bool negative;
  final String whole;
  final String fraction;
}

/// An amount of money set the way finance apps set it: tabular figures, a
/// true minus, and the currency and minor units at a reduced size so the
/// whole-number part carries the reading.
///
/// Shrinks to fit a bounded width rather than ellipsizing — a truncated
/// balance is a different number, not a shorter one.
final class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    this.currency = '',
    this.decimals = 2,
    this.style,
    this.tone = MoneyTone.neutral,
    this.showPlus = false,
    this.color,
    this.minorScale,
    this.dimMinor = true,
    this.groupSeparator = ',',
    this.decimalSeparator = '.',
    this.alignment = AlignmentDirectional.centerStart,
    super.key,
  });

  final num amount;
  final String currency;
  final int decimals;

  /// Base style for the whole-number part. Defaults to
  /// [AppTextStyles.number].
  final TextStyle? style;
  final MoneyTone tone;
  final bool showPlus;

  /// Overrides the tone colour.
  final Color? color;

  /// Size of the currency and minor units relative to the whole part. When
  /// null it follows the size: display figures drop the minor units to 60%,
  /// row-size figures only to 80% so they stay legible. Use 1.0 for inline
  /// amounts in running text.
  final double? minorScale;

  /// Whether the currency and minor units are drawn in the secondary colour.
  final bool dimMinor;
  final String groupSeparator;
  final String decimalSeparator;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    final base = (style ?? AppTextStyles.number).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final parts = _MoneyParts.of(
      amount,
      decimals: decimals,
      groupSeparator: groupSeparator,
      decimalSeparator: decimalSeparator,
    );
    final ink = color ??
        switch (tone) {
          MoneyTone.neutral => base.color ?? c.textPrimary,
          MoneyTone.positive => c.positive,
          MoneyTone.negative => c.negative,
          MoneyTone.signed => parts.negative
              ? c.negative
              : amount > 0
                  ? c.positive
                  : (base.color ?? c.textPrimary),
        };
    final minorInk = dimMinor && tone == MoneyTone.neutral && color == null
        ? c.textSecondary
        : ink;
    final size = base.fontSize ?? 17;
    final scale = minorScale ?? (size >= 30 ? 0.6 : 0.8);
    final minor = base.copyWith(
      color: minorInk,
      fontSize: size * scale,
      letterSpacing: (base.letterSpacing ?? 0) * scale,
    );
    final sign = parts.negative ? '−' : (showPlus && amount > 0 ? '+' : '');
    final semantic = formatMoney(
      amount,
      currency: currency,
      decimals: decimals,
      showPlus: showPlus,
      groupSeparator: groupSeparator,
      decimalSeparator: decimalSeparator,
    );

    final text = Text.rich(
      TextSpan(
        style: base.copyWith(color: ink),
        children: [
          if (sign.isNotEmpty) TextSpan(text: sign),
          if (currency.isNotEmpty) TextSpan(text: '$currency ', style: minor),
          TextSpan(text: parts.whole),
          if (parts.fraction.isNotEmpty)
            TextSpan(text: parts.fraction, style: minor),
        ],
      ),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
      semanticsLabel: semantic,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) return text;
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment,
          child: text,
        );
      },
    );
  }
}
