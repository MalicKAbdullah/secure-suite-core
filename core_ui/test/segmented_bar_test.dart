import 'package:core_theme/core_theme.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.build(Brightness.light, accent: AppAccents.budgetly),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );

void main() {
  testWidgets('segments fill the bar height and split its width', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const Column(children: [SegmentedBar(values: [3, 1])])),
    );
    final boxes = find.descendant(
      of: find.byType(SegmentedBar),
      matching: find.byType(ColoredBox),
    );
    expect(boxes, findsNWidgets(2));
    final first = tester.getSize(boxes.at(0));
    final second = tester.getSize(boxes.at(1));
    expect(first.height, 10);
    expect(second.height, 10);
    expect(first.width, greaterThan(second.width));
    expect(second.width, greaterThan(0));
  });

  testWidgets('an empty bar still shows its track', (tester) async {
    await tester.pumpWidget(
      _host(const Column(children: [SegmentedBar(values: [0, 0])])),
    );
    final track = find.descendant(
      of: find.byType(SegmentedBar),
      matching: find.byType(ColoredBox),
    );
    final size = tester.getSize(track);
    expect(size.height, 10);
    expect(size.width, greaterThan(0));
  });
}
