import 'package:core_theme/core_theme.dart';
import 'package:flutter/material.dart';

/// Semantic tone of an [AppBanner].
enum BannerKind { info, success, warning, error }

/// An inline, tappable notice card — the in-app nudge pattern (e.g. "3
/// captured transactions to review", "Backup failed", "2 weak passwords").
/// Tinted by [kind] using the shared semantic colors, with an optional
/// trailing action button and/or chevron.
final class AppBanner extends StatelessWidget {
  const AppBanner({
    required this.title,
    this.message,
    this.kind = BannerKind.info,
    this.icon,
    this.onTap,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? message;
  final BannerKind kind;
  final IconData? icon;
  final VoidCallback? onTap;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final accent = switch (kind) {
      BannerKind.info => AppColors.info(brightness),
      BannerKind.success => AppColors.success(brightness),
      BannerKind.warning => AppColors.warning(brightness),
      BannerKind.error => AppColors.error(brightness),
    };
    final defaultIcon = switch (kind) {
      BannerKind.info => Icons.info_outline_rounded,
      BannerKind.success => Icons.check_circle_outline_rounded,
      BannerKind.warning => Icons.warning_amber_rounded,
      BannerKind.error => Icons.error_outline_rounded,
    };
    final c = SuiteColors.of(context);
    final onSurface = c.textPrimary;
    final subtle = c.textSecondary;
    final container = switch (kind) {
      BannerKind.info => c.infoContainer,
      BannerKind.success => c.positiveContainer,
      BannerKind.warning => c.warningContainer,
      BannerKind.error => c.negativeContainer,
    };

    return Material(
      color: container,
      borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.smd + 2,
            AppSpacing.smd,
            AppSpacing.smd + 2,
          ),
          child: Row(
            children: [
              Icon(icon ?? defaultIcon, color: accent, size: 20),
              const SizedBox(width: AppSpacing.smd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.labelStrong.copyWith(
                        color: onSurface,
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        message!,
                        style: AppTextStyles.bodySmall.copyWith(color: subtle),
                      ),
                    ],
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(onPressed: onAction, child: Text(actionLabel!))
              else if (onTap != null)
                Icon(Icons.chevron_right_rounded, color: subtle),
            ],
          ),
        ),
      ),
    );
  }
}
