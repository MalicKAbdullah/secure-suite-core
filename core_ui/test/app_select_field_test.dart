import 'package:core_theme/core_theme.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('picks from the sheet, null being a real choice', (tester) async {
    String? value = 'a';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(Brightness.light, accent: AppAccents.budgetly),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => AppSelectField<String?>(
              label: 'Category',
              value: value,
              options: const [
                AppSelectOption(value: null, label: 'None'),
                AppSelectOption(value: 'a', label: 'Food'),
              ],
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Food'), findsOneWidget);
    await tester.tap(find.byType(AppSelectField<String?>));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();
    expect(value, isNull);
    expect(find.text('None'), findsOneWidget);
  });
}
