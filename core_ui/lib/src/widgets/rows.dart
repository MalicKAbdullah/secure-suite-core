import 'package:core_theme/core_theme.dart';
import 'package:flutter/material.dart';

/// A rounded-square badge holding an icon or a monogram — the leading
/// element of list rows (a category, an account, a vault item).
final class IconBadge extends StatelessWidget {
  const IconBadge({
    this.icon,
    this.monogram,
    this.color,
    this.size = 40,
    this.solid = false,
    super.key,
  }) : assert(icon != null || monogram != null, 'icon or monogram');

  final IconData? icon;

  /// One or two letters shown instead of an icon.
  final String? monogram;

  /// The tint. Defaults to the neutral secondary text colour.
  final Color? color;
  final double size;

  /// Solid fill with white glyph instead of a soft tint.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    final tint = color ?? c.textSecondary;
    final bg = solid
        ? tint
        : color == null
            ? c.surfaceAlt
            : tint.withValues(alpha: 0.12);
    final fg = solid ? AppColors.white : tint;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: icon != null
          ? Icon(icon, size: size * 0.5, color: fg)
          : Text(
              monogram!,
              style: AppTextStyles.labelStrong.copyWith(
                color: fg,
                fontSize: size * 0.38,
                height: 1,
              ),
            ),
    );
  }
}

/// The suite list row: leading badge, title + subtitle, and a trailing
/// column (an amount over a date, a value, a chevron). Rows inside a
/// [RowGroup] get hairline separators inset to the text column.
final class AppListRow extends StatelessWidget {
  const AppListRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.trailingSubtitle,
    this.showChevron = false,
    this.onTap,
    this.onLongPress,
    this.dense = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;

  /// Usually a `MoneyText` or a short value text.
  final Widget? trailing;

  /// Small grey line under [trailing] ("Today", "2 of 3").
  final String? trailingSubtitle;
  final bool showChevron;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: dense ? 52 : 66),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: dense ? AppSpacing.sm : AppSpacing.smd,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.smd + 2),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null || trailingSubtitle != null) ...[
                const SizedBox(width: AppSpacing.smd),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (trailing != null) trailing!,
                    if (trailingSubtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        trailingSubtitle!,
                        style: AppTextStyles.caption.copyWith(
                          color: c.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              if (showChevron) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.chevron_right_rounded, color: c.textTertiary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A card-shaped group of rows with inset hairline separators — the
/// grouped-list pattern for settings and transaction days.
final class RowGroup extends StatelessWidget {
  const RowGroup({
    required this.children,
    this.separatorIndent = 68,
    super.key,
  });

  final List<Widget> children;

  /// Left inset of separators, aligning them with the row text. 68 matches
  /// an [AppListRow] with a 40 px [IconBadge].
  final double separatorIndent;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: c.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: separatorIndent,
                color: c.hairline,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}
