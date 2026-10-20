import 'package:core_theme/core_theme.dart';
import 'package:flutter/material.dart';

/// A bar pinned to the bottom of a form or detail screen: an optional
/// summary on the left (a total, a count) and one or two actions. Sits on
/// the page colour behind a hairline and respects the bottom safe area.
final class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    required this.primary,
    this.secondary,
    this.summary,
    super.key,
  });

  /// Usually a `VaultButton`.
  final Widget primary;
  final Widget? secondary;

  /// Left-hand context, e.g. a label over a `MoneyText`.
  final Widget? summary;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.smd,
            AppSpacing.gutter,
            AppSpacing.smd,
          ),
          child: Row(
            children: [
              if (summary != null) ...[
                Expanded(child: summary!),
                const SizedBox(width: AppSpacing.md),
                primary,
              ] else ...[
                if (secondary != null) ...[
                  Expanded(child: secondary!),
                  const SizedBox(width: AppSpacing.smd),
                ],
                Expanded(child: primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
