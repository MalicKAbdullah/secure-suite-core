import 'package:core_theme/core_theme.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('tapping a segment switches the app theme', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appearance = await AppearanceController.load();
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: appearance,
        builder: (context, _) => MaterialApp(
          theme: AppTheme.build(Brightness.light, accent: AppAccents.budgetly),
          darkTheme:
              AppTheme.build(Brightness.dark, accent: AppAccents.budgetly),
          themeMode: appearance.mode,
          home: Scaffold(body: AppearanceSetting(controller: appearance)),
        ),
      ),
    );
    expect(find.text('Appearance'), findsOneWidget);
    BuildContext ctx() => tester.element(find.text('Appearance'));
    expect(Theme.of(ctx()).brightness, Brightness.light);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(appearance.mode, ThemeMode.dark);
    expect(Theme.of(ctx()).brightness, Brightness.dark);

    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(appearance.mode, ThemeMode.system);
  });
}
