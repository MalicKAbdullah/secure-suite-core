import 'package:core_theme/core_theme.dart';
import 'package:flutter/material.dart';

/// A list/section title with an optional trailing action (e.g. "Manage",
/// "See all"). Standardises the spacing and type used above card groups so
/// every screen's sections align identically.
final class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.h4.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
