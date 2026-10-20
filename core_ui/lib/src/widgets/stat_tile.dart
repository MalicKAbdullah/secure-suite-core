import 'package:core_theme/core_theme.dart';
import 'package:core_ui/src/widgets/value_text.dart';
import 'package:flutter/material.dart';

/// How loud a [StatTile]'s number is.
enum StatTileSize {
  /// The default. Sized for two or three tiles sitting side by side, where a
  /// display-size number would dominate the screen and crowd its neighbours.
  compact,

  /// A single number that is the whole point of its card.
  hero,
}

/// A metric: a small label above a tabular-figure value, with an optional
/// caption underneath. Left-aligned so several tiles line up in a row and
/// their digits sit in true columns.
///
/// The value shrinks to fit its column instead of being ellipsized, so a row
/// of tiles stays readable at large amounts.
final class StatTile extends StatelessWidget {
  const StatTile({
    required this.label,
    required this.value,
    this.caption,
    this.valueColor,
    this.icon,
    this.size = StatTileSize.compact,
    this.dotColor,
    super.key,
  });

  final String label;
  final String value;
  final String? caption;
  final Color? valueColor;
  final IconData? icon;
  final StatTileSize size;

  /// A small legend dot before the label, tying the tile to a chart series.
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (dotColor != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ] else if (icon != null) ...[
              Icon(icon, size: 15, color: c.textSecondary),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(color: c.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: size == StatTileSize.hero ? 8 : 5),
        ValueText(
          value,
          style: switch (size) {
            StatTileSize.compact => AppTextStyles.number,
            StatTileSize.hero => AppTextStyles.numberLarge,
          },
          color: valueColor ?? c.textPrimary,
        ),
        if (caption != null) ...[
          const SizedBox(height: 3),
          Text(
            caption!,
            style: AppTextStyles.caption.copyWith(color: c.textTertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
