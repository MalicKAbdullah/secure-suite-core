import 'package:core_theme/src/app_colors.dart';
import 'package:flutter/material.dart';

/// The suite's semantic palette as a [ThemeExtension], so widgets read
/// money and status colours from the theme instead of branching on
/// brightness themselves. Installed by `AppTheme.build`.
@immutable
final class SuiteColors extends ThemeExtension<SuiteColors> {
  const SuiteColors({
    required this.accent,
    required this.accentContainer,
    required this.onAccent,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.hairline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.positive,
    required this.negative,
    required this.warning,
    required this.info,
    required this.positiveContainer,
    required this.negativeContainer,
    required this.warningContainer,
    required this.infoContainer,
    required this.chart,
  });

  factory SuiteColors.from(Brightness b, AppAccent accent) => SuiteColors(
        accent: accent.color(b),
        accentContainer: accent.container(b),
        onAccent: accent.onAccent(b),
        background: AppColors.background(b),
        surface: AppColors.surface(b),
        surfaceAlt: AppColors.surfaceAlt(b),
        border: AppColors.border(b),
        hairline: AppColors.hairline(b),
        textPrimary: AppColors.textPrimary(b),
        textSecondary: AppColors.textSecondary(b),
        textTertiary: AppColors.textTertiary(b),
        positive: AppColors.positive(b),
        negative: AppColors.negative(b),
        warning: AppColors.warning(b),
        info: AppColors.info(b),
        positiveContainer: AppColors.successContainer(b),
        negativeContainer: AppColors.errorContainer(b),
        warningContainer: AppColors.warningContainer(b),
        infoContainer: AppColors.infoContainer(b),
        chart: AppColors.chartSeries(b, accent),
      );

  /// The suite colours of the nearest theme. Every theme built by
  /// `AppTheme` carries them; a bare `ThemeData` falls back to the neutral
  /// shell derived from its brightness so widgets render in tests and
  /// previews that skip `AppTheme`.
  static SuiteColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<SuiteColors>() ??
        SuiteColors.from(theme.brightness, AppColors.neutralAccent);
  }

  final Color accent;
  final Color accentContainer;
  final Color onAccent;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color hairline;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color positive;
  final Color negative;
  final Color warning;
  final Color info;
  final Color positiveContainer;
  final Color negativeContainer;
  final Color warningContainer;
  final Color infoContainer;

  /// Categorical chart series, accent first.
  final List<Color> chart;

  @override
  SuiteColors copyWith({Color? accent}) => SuiteColors(
        accent: accent ?? this.accent,
        accentContainer: accentContainer,
        onAccent: onAccent,
        background: background,
        surface: surface,
        surfaceAlt: surfaceAlt,
        border: border,
        hairline: hairline,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textTertiary: textTertiary,
        positive: positive,
        negative: negative,
        warning: warning,
        info: info,
        positiveContainer: positiveContainer,
        negativeContainer: negativeContainer,
        warningContainer: warningContainer,
        infoContainer: infoContainer,
        chart: chart,
      );

  @override
  SuiteColors lerp(SuiteColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return SuiteColors(
      accent: l(accent, other.accent),
      accentContainer: l(accentContainer, other.accentContainer),
      onAccent: l(onAccent, other.onAccent),
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      border: l(border, other.border),
      hairline: l(hairline, other.hairline),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      positive: l(positive, other.positive),
      negative: l(negative, other.negative),
      warning: l(warning, other.warning),
      info: l(info, other.info),
      positiveContainer: l(positiveContainer, other.positiveContainer),
      negativeContainer: l(negativeContainer, other.negativeContainer),
      warningContainer: l(warningContainer, other.warningContainer),
      infoContainer: l(infoContainer, other.infoContainer),
      chart: [
        for (var i = 0; i < chart.length && i < other.chart.length; i++)
          l(chart[i], other.chart[i]),
      ],
    );
  }
}
