import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders [child] in a box of exactly [width] so the shrink behaviour is
/// driven by a known constraint rather than the test surface size.
Widget _boxed(Widget child, {required double width}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    );

void main() {
  const big = TextStyle(fontSize: 34, fontWeight: FontWeight.w700);

  testWidgets('keeps every digit when the number does not fit', (tester) async {
    await tester.pumpWidget(
      _boxed(const ValueText('Rs 1,234,567', style: big), width: 80),
    );

    // The whole amount is still in the tree: nothing was ellipsized away.
    expect(find.text('Rs 1,234,567'), findsOneWidget);
    final text = tester.widget<Text>(find.text('Rs 1,234,567'));
    expect(text.overflow, TextOverflow.visible);
    expect(text.maxLines, 1);
  });

  testWidgets('scales a too-wide number down to fit its box', (tester) async {
    await tester.pumpWidget(
      _boxed(const ValueText('Rs 1,234,567', style: big), width: 80),
    );

    expect(find.byType(FittedBox), findsOneWidget);
    expect(
      tester.getSize(find.text('Rs 1,234,567')).width,
      greaterThan(80),
      reason: 'the child lays out at natural width; FittedBox scales it',
    );
    // What the user sees is bounded by the box it was given.
    expect(tester.getSize(find.byType(ValueText)).width, lessThanOrEqualTo(80));
  });

  testWidgets('leaves a number that already fits at natural size', (
    tester,
  ) async {
    await tester.pumpWidget(
      _boxed(const ValueText('Rs 12', style: big), width: 400),
    );

    // No scaling stage at all when there is room, so short and long values in
    // sibling columns render at the same size.
    expect(find.byType(FittedBox), findsNothing);
    expect(find.text('Rs 12'), findsOneWidget);
  });

  testWidgets('renders plainly when width is unbounded', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: const [ValueText('Rs 1,234,567', style: big)],
          ),
        ),
      ),
    );

    expect(find.text('Rs 1,234,567'), findsOneWidget);
    expect(find.byType(FittedBox), findsNothing);
  });

  testWidgets('StatTile shows its whole value in a narrow column', (
    tester,
  ) async {
    await tester.pumpWidget(
      _boxed(
        const StatTile(label: 'Spent', value: 'Rs 987,654'),
        width: 90,
      ),
    );

    expect(find.text('Rs 987,654'), findsOneWidget);
    expect(find.text('Spent'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('three StatTiles in a row never overflow', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: StatTile(label: 'Spent', value: 'Rs 123,456'),
                ),
                Expanded(
                  child: StatTile(label: 'Income', value: 'Rs 654,321'),
                ),
                Expanded(child: StatTile(label: 'Net', value: '-Rs 530,865')),
              ],
            ),
          ),
        ),
      ),
    );

    // A RenderFlex overflow would surface here; this is the dashboard bug.
    expect(tester.takeException(), isNull);
    expect(find.text('Rs 123,456'), findsOneWidget);
    expect(find.text('Rs 654,321'), findsOneWidget);
    expect(find.text('-Rs 530,865'), findsOneWidget);
  });
}
