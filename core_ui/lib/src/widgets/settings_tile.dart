import 'package:core_theme/core_theme.dart';
import 'package:flutter/material.dart';

/// A standard settings row: leading icon, title, optional subtitle, and either
/// a [trailing] widget (a Switch, a value label) or a chevron when [onTap] is
/// set. Keeps every app's Settings list visually identical.
final class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// When true and no [trailing] is given, shows a chevron for tap-through
  /// rows. Set false for terminal rows (e.g. an informational tile).
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final subtle = Theme.of(context).colorScheme.onSurfaceVariant;
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: AppTextStyles.body),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(color: subtle),
            ),
      trailing:
          trailing ??
          (onTap != null && showChevron
              ? Icon(Icons.chevron_right, color: subtle)
              : null),
      onTap: onTap,
    );
  }
}
