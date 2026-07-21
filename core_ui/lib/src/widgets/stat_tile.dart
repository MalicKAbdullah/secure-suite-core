import 'package:core_theme/core_theme.dart';
import 'package:flutter/material.dart';

/// A compact metric: a small label above a big tabular-figure value, with an
/// optional caption underneath. Left-aligned so several tiles line up in a
/// row and their digits sit in true columns (the number styles use tabular
/// figures). Use for dashboards and stat rows.
final class StatTile extends StatelessWidget {
  const StatTile({
    required this.label,
    required this.value,
    this.caption,
    this.valueColor,
    this.icon,
    super.key,
  });

  final String label;
  final String value;
  final String? caption;
  final Color? valueColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final subtle = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: subtle),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(color: subtle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.numberLarge.copyWith(color: valueColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(
            caption!,
            style: AppTextStyles.caption.copyWith(color: subtle),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
