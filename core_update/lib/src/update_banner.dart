import 'package:core_theme/core_theme.dart';
import 'package:core_update/src/update_service.dart';
import 'package:flutter/material.dart';

/// Clean, dismissable "update available" card. Place it at the top of a
/// home/dashboard list. Styled to match the shared AppBanner (info tint).
final class UpdateBanner extends StatelessWidget {
  const UpdateBanner({
    required this.info,
    required this.onUpdate,
    required this.onDismiss,
    super.key,
  });

  final UpdateInfo info;

  /// Opens the download (typically [IUpdateService.openDownload]).
  final VoidCallback onUpdate;

  /// Hides the card until the next newer release.
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final accent = AppColors.info(brightness);
    final scheme = Theme.of(context).colorScheme;
    final firstLine = info.notes.isEmpty
        ? "You're on an older version — grab the latest."
        : info.notes.split('\n').firstWhere(
              (l) => l.trim().isNotEmpty,
              orElse: () => "You're on an older version — grab the latest.",
            );

    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.system_update_alt, color: accent, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Update available · v${info.version}',
                  style: AppTextStyles.labelStrong
                      .copyWith(color: scheme.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            firstLine,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall
                .copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onDismiss, child: const Text('Later')),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(onPressed: onUpdate, child: const Text('Update')),
            ],
          ),
        ],
      ),
    );
  }
}
