import 'package:core_theme/core_theme.dart';
import 'package:flutter/material.dart';

/// The suite card: a flat surface with a hairline edge — no shadow. Depth
/// comes from the surface sitting one step lighter (or darker) than the
/// page, not from elevation.
final class VaultCard extends StatelessWidget {
  const VaultCard({
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.radius = AppSpacing.radiusLg,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  /// Overrides the surface colour (e.g. an accent container for a promo).
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    return Material(
      color: color ?? c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side:
            BorderSide(color: color == null ? c.hairline : Colors.transparent),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
          child: child,
        ),
      ),
    );
  }
}
