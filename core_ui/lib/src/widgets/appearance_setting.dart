import 'package:core_theme/core_theme.dart';
import 'package:core_ui/src/widgets/selection.dart';
import 'package:core_ui/src/widgets/settings_tile.dart';
import 'package:flutter/material.dart';

/// The Settings row for [AppearanceController]: "Appearance" with a
/// System · Light · Dark segmented control. The theme changes as soon as a
/// segment is tapped.
final class AppearanceSetting extends StatelessWidget {
  const AppearanceSetting({required this.controller, super.key});

  final AppearanceController controller;

  static const _segments = [
    AppSegment(value: ThemeMode.system, label: 'System'),
    AppSegment(value: ThemeMode.light, label: 'Light'),
    AppSegment(value: ThemeMode.dark, label: 'Dark'),
  ];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SettingsTile(
              icon: Icons.contrast_rounded,
              title: 'Appearance',
              showChevron: false,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: AppSegmentedControl<ThemeMode>(
                segments: _segments,
                selected: controller.mode,
                onChanged: controller.setMode,
              ),
            ),
          ],
        ),
      );
}
