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

    Widget app(Widget child) => MaterialApp(
          theme: theme,
          home: Scaffold(body: Center(child: child)),
        );

    Color? iconColor(WidgetTester tester) => tester
        .widget<RichText>(
          find.descendant(
              of: find.byType(Icon), matching: find.byType(RichText)),
        )
        .text
        .style
        ?.color;

    testWidgets('$brightness: filled icon buttons paint their icon onPrimary',
        (tester) async {
      await tester.pumpWidget(app(
        IconButton.filled(onPressed: () {}, icon: const Icon(Icons.add)),
      ));
      expect(iconColor(tester), scheme.onPrimary);
    });

    testWidgets('$brightness: standard icon buttons use onSurfaceVariant',
        (tester) async {
      await tester.pumpWidget(app(
        IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
      ));
      expect(iconColor(tester), scheme.onSurfaceVariant);
    });

    testWidgets('$brightness: app bar actions use the app bar foreground',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
          appBar: AppBar(actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
          ]),
        ),
      ));
      expect(iconColor(tester), theme.appBarTheme.foregroundColor);
    });

    testWidgets('$brightness: ListTile subtitle stays quieter than its title',
        (tester) async {
      await tester.pumpWidget(app(
        const ListTile(title: Text('Title'), subtitle: Text('Subtitle')),
      ));
      Color? colorOf(String text) => tester
          .widget<RichText>(
            find.descendant(
                of: find.text(text), matching: find.byType(RichText)),
          )
          .text
          .style
          ?.color;
      expect(colorOf('Title'), titleColor);
      expect(colorOf('Subtitle'), subtitleColor);
      expect(colorOf('Subtitle'), isNot(equals(colorOf('Title'))));
    });

    testWidgets('$brightness: FilledButton is primary, .tonal stays tonal',
        (tester) async {
      Material materialOf(String label) => tester.widget<Material>(
            find
                .ancestor(of: find.text(label), matching: find.byType(Material))
                .first,
          );
      await tester.pumpWidget(app(Column(children: [
        FilledButton(onPressed: () {}, child: const Text('filled')),
        FilledButton.tonal(onPressed: () {}, child: const Text('tonal')),
      ])));
      expect(materialOf('filled').color, scheme.primary);
      expect(materialOf('filled').textStyle?.color, scheme.onPrimary);
      expect(materialOf('tonal').color, scheme.secondaryContainer);
      expect(materialOf('tonal').textStyle?.color, scheme.onSecondaryContainer);
    });
  }
}
