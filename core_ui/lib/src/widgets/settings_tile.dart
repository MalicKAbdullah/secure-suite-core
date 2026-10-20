import 'package:core_ui/src/widgets/rows.dart';
import 'package:flutter/material.dart';

/// A standard settings row: icon badge, title, optional subtitle, and either
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
    this.iconColor,
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

  /// Tints the badge; neutral when null.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return AppListRow(
      leading: IconBadge(icon: icon, color: iconColor, size: 36),
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      showChevron: trailing == null && onTap != null && showChevron,
      onTap: onTap,
      dense: subtitle == null,
    );
  }
}
