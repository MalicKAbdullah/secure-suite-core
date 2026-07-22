import 'package:core_theme/core_theme.dart';
import 'package:core_update/src/update_service.dart';
import 'package:flutter/material.dart';

/// Clean, dismissable "update available" card. Place it at the top of a
/// home/dashboard list. Shows just the new version (not release notes),
/// an update icon, and Update now / Remind later actions — consistent
/// across every Secure Suite app.
final class UpdateBanner extends StatefulWidget {
  const UpdateBanner({
    required this.info,
    required this.onUpdate,
    required this.onDismiss,
    super.key,
  });

  final UpdateInfo info;

  /// Downloads + installs (typically [IUpdateService.openDownload]). Awaited so
  /// the card can show a "Downloading…" state.
  final Future<void> Function() onUpdate;

  /// Hides the card until the next newer release.
  final VoidCallback onDismiss;

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> {
  bool _busy = false;

  Future<void> _update() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onUpdate();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final accent = AppColors.info(brightness);
    final scheme = Theme.of(context).colorScheme;

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
              Icon(Icons.system_update, color: accent, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Update v${widget.info.version} is here',
                      style: AppTextStyles.labelStrong
                          .copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _busy
                          ? 'Downloading the update…'
                          : 'A new version is ready to install.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _busy ? null : widget.onDismiss,
                child: const Text('Remind later'),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: _busy ? null : _update,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Update now'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
