import 'package:core_theme/core_theme.dart';
import 'package:core_ui/src/widgets/charts.dart';
import 'package:flutter/material.dart';

/// Which direction of change is good news.
enum DeltaPolarity {
  /// Up is good (income, savings, vault score).
  upIsGood,

  /// Up is bad (spending, weak passwords, missed doses).
  upIsBad,

  /// Neither — direction only.
  neutral,
}

/// A change indicator: an arrow and a figure on a soft tinted pill,
/// coloured by whether the change is good news under [polarity].
final class DeltaBadge extends StatelessWidget {
  const DeltaBadge({
    required this.delta,
    this.label,
    this.polarity = DeltaPolarity.upIsGood,
    this.subtle = false,
    super.key,
  });

  /// The signed change. Its sign picks the arrow.
  final double delta;

  /// What to print; defaults to `delta` as a percentage with one decimal.
  final String? label;
  final DeltaPolarity polarity;

  /// Text and arrow only, no pill.
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    final up = delta > 0;
    final flat = delta == 0;
    final good = switch (polarity) {
      DeltaPolarity.upIsGood => up,
      DeltaPolarity.upIsBad => !up,
      DeltaPolarity.neutral => null,
    };
    final ink = flat || good == null
        ? c.textSecondary
        : good
            ? c.positive
            : c.negative;
    final bg = flat || good == null
        ? c.surfaceAlt
        : good
            ? c.positiveContainer
            : c.negativeContainer;
    final text = label ?? '${delta.abs().toStringAsFixed(1)}%';
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A labelled zero is a status ("11 days left"), not a change.
        if (!(flat && label != null)) ...[
          Icon(
            flat
                ? Icons.remove_rounded
                : up
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
            size: 13,
            color: ink,
          ),
          const SizedBox(width: 3),
        ],
        Text(
          text,
          style: AppTextStyles.numberSmall.copyWith(
            color: ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    if (subtle) return content;
    return DecoratedBox(
      decoration: ShapeDecoration(color: bg, shape: const StadiumBorder()),
      child: Padding(
        padding: EdgeInsets.fromLTRB(flat && label != null ? 9 : 7, 4, 9, 4),
        child: content,
      ),
    );
  }
}

/// The home-screen hero: one big number, its change, a trend line, and a
/// row of supporting figures underneath. It is the card a dashboard is
/// built around, so it is the only card that uses the hero type size.
final class HeroMetricCard extends StatelessWidget {
  const HeroMetricCard({
    required this.label,
    required this.value,
    this.delta,
    this.deltaCaption,
    this.trend,
    this.trendReference,
    this.trendColor,
    this.footer = const [],
    this.trailing,
    this.onTap,
    super.key,
  });

  /// The eyebrow above the number ("Balance · October").
  final String label;

  /// The number, usually a `MoneyText` with [AppTextStyles.hero].
  final Widget value;
  final Widget? delta;

  /// Grey text after [delta] ("vs last month").
  final String? deltaCaption;
  final List<double>? trend;
  final double? trendReference;
  final Color? trendColor;

  /// Supporting figures, laid out as equal columns divided by hairlines.
  final List<Widget> footer;

  /// Top-right slot (a period picker, an icon button).
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    final radius = BorderRadius.circular(AppSpacing.radiusXl);
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: c.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.mdl,
                AppSpacing.mdl,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextStyles.label.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.smd,
                AppSpacing.lg,
                0,
              ),
              child: value,
            ),
            if (delta != null || deltaCaption != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.smd,
                  AppSpacing.lg,
                  0,
                ),
                child: Row(
                  children: [
                    if (delta != null) delta!,
                    if (delta != null && deltaCaption != null)
                      const SizedBox(width: AppSpacing.sm),
                    if (deltaCaption != null)
                      Flexible(
                        child: Text(
                          deltaCaption!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: c.textTertiary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (trend != null) ...[
              const SizedBox(height: AppSpacing.mdl),
              Sparkline(
                values: trend!,
                reference: trendReference,
                color: trendColor,
                height: 72,
              ),
            ] else
              const SizedBox(height: AppSpacing.lg),
            if (footer.isNotEmpty) ...[
              Divider(height: 1, color: c.hairline),
              // Separators are each cell's own left edge rather than
              // VerticalDividers: those need IntrinsicHeight, which the
              // shrink-to-fit figures (LayoutBuilder) cannot answer.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < footer.length; i++)
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: i == 0
                              ? null
                              : Border(left: BorderSide(color: c.hairline)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            i == 0 ? AppSpacing.lg : AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.smd,
                            AppSpacing.mdl,
                          ),
                          child: footer[i],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A card holding one metric for a 2-up dashboard grid: label, figure,
/// optional delta, and an optional inline visual (a progress bar, a tiny
/// sparkline).
final class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.delta,
    this.caption,
    this.visual,
    this.onTap,
    super.key,
  });

  final String label;
  final Widget value;
  final IconData? icon;
  final Color? iconColor;
  final Widget? delta;
  final String? caption;
  final Widget? visual;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: c.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.mdl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: iconColor ?? c.textSecondary),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.smd),
              value,
              if (delta != null || caption != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    if (delta != null) delta!,
                    if (delta != null && caption != null)
                      const SizedBox(width: 6),
                    if (caption != null)
                      Flexible(
                        child: Text(
                          caption!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: c.textTertiary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              if (visual != null) ...[
                const SizedBox(height: AppSpacing.md),
                visual!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
