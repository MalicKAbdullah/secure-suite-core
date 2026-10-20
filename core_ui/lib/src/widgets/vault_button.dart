import 'package:core_theme/core_theme.dart';
import 'package:flutter/material.dart';

enum VaultButtonVariant { primary, secondary, destructive }

/// The suite button: a pill, 54 px tall (40 px when [compact]). Primary is
/// filled in the accent, secondary is a hairline outline in ink, and
/// destructive is filled in the negative colour.
final class VaultButton extends StatelessWidget {
  const VaultButton({
    required this.label,
    required this.onPressed,
    this.variant = VaultButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.compact = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final VaultButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final fg = switch (variant) {
      VaultButtonVariant.primary => c.onAccent,
      VaultButtonVariant.secondary => c.textPrimary,
      VaultButtonVariant.destructive => scheme.onError,
    };
    final height =
        compact ? AppSpacing.buttonHeightSm : AppSpacing.buttonHeight;
    final child = isLoading
        ? SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: compact ? 16 : 18),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: compact
                      ? AppTextStyles.labelStrong
                      : AppTextStyles.button,
                ),
              ),
            ],
          );
    final size = Size(64, height);
    final padding = EdgeInsets.symmetric(
      horizontal: compact ? AppSpacing.md : AppSpacing.lg,
    );
    final onTap = isLoading ? null : onPressed;

    final button = switch (variant) {
      VaultButtonVariant.primary => FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            minimumSize: size,
            padding: padding,
            disabledBackgroundColor:
                isLoading ? c.accent.withValues(alpha: 0.7) : null,
          ),
          child: child,
        ),
      VaultButtonVariant.secondary => OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            minimumSize: size,
            padding: padding,
            side: BorderSide(color: c.border),
          ),
          child: child,
        ),
      VaultButtonVariant.destructive => FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
            minimumSize: size,
            padding: padding,
          ),
          child: child,
        ),
    };

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
