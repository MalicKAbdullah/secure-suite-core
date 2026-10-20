import 'package:core_theme/core_theme.dart';
import 'package:flutter/material.dart';

/// A section title with an optional supporting figure and trailing action
/// ("See all"). Standardises the spacing and type above card groups so
/// every screen's sections align identically.
final class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// A quiet line under the title ("3 due this week").
  final String? subtitle;

  /// Replaces the action with a custom widget (a total, a toggle).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xs,
        0,
        AppSpacing.smd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h3.copyWith(
                    color: c.textPrimary,
                    fontSize: 18,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (actionLabel != null && onAction != null)
            InkWell(
              onTap: onAction,
              customBorder: const StadiumBorder(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: AppTextStyles.labelStrong.copyWith(
                        color: c.accent,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: c.accent,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
