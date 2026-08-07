import 'package:core_theme/core_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    final theme = AppTheme.build(brightness, accent: AppColors.tealAccent);
    final scheme = theme.colorScheme;
    final titleColor = theme.listTileTheme.titleTextStyle?.color;
    final subtitleColor = theme.listTileTheme.subtitleTextStyle?.color;

    test(
      '$brightness: every M3 container/tertiary role is explicitly set '
      '(none silently falls back to secondary/primary)',
      () {
        // A raw ColorScheme() leaves these null unless passed explicitly,
        // in which case Flutter falls back to secondary/primary/etc. —
        // exactly the bug this test guards against.
        expect(scheme.secondaryContainer, isNot(equals(scheme.secondary)));
        expect(scheme.tertiary, isNot(equals(scheme.secondary)));
        expect(scheme.tertiaryContainer, isNot(equals(scheme.tertiary)));
        expect(scheme.errorContainer, isNot(equals(scheme.error)));
      },
    );

    test(
      '$brightness: ListTile title text is never the same color as a '
      'Card painted with colorScheme.secondaryContainer',
      () {
        // This is the exact combination that produced an invisible-text
        // "white box": a Card colored with secondaryContainer, containing
        // a ListTile whose title uses the theme's fixed title color.
        expect(titleColor, isNotNull);
        expect(titleColor, isNot(equals(scheme.secondaryContainer)));
        expect(subtitleColor, isNotNull);
        expect(subtitleColor, isNot(equals(scheme.secondaryContainer)));
      },
    );
  }
}
