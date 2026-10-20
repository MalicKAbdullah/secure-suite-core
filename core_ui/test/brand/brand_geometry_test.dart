import 'package:core_ui/src/brand/app_icon.dart';
import 'package:core_ui/src/brand/brand_geometry.dart';
import 'package:core_ui/src/brand/brand_painter.dart';
import 'package:core_ui/src/brand/suite_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bounds of the drawn outline itself. `Path.getBounds` includes curve
/// control points, which sit outside the arcs, so it overstates the extent.
Rect _outline(String data) {
  var bounds = Rect.zero;
  var first = true;
  for (final metric in parseBrandPath(data).computeMetrics()) {
    for (var d = 0.0; d <= metric.length; d += 0.05) {
      final p = metric.getTangentForOffset(d)!.position;
      bounds = first
          ? Rect.fromPoints(p, p)
          : bounds.expandToInclude(Rect.fromPoints(p, p));
      first = false;
    }
  }
  return bounds;
}

void main() {
  const grid = Rect.fromLTWH(0, 0, 24, 24);

  test('the mark stays inside its 24-unit grid', () {
    for (final shape in suiteMarkShapes) {
      final bounds = _outline(shape.path);
      expect(grid.inflate(0.01).contains(bounds.topLeft), isTrue);
      expect(grid.inflate(0.01).contains(bounds.bottomRight), isTrue);
    }
  });

  for (final app in SuiteApp.values) {
    test('${app.name} glyph, stroke included, stays on the 24-unit grid', () {
      for (final shape in app.glyph) {
        final pad = shape.stroke ? brandStroke / 2 : 0.0;
        final bounds = _outline(shape.path).inflate(pad);
        expect(grid.inflate(0.01).contains(bounds.topLeft), isTrue);
        expect(grid.inflate(0.01).contains(bounds.bottomRight), isTrue);
      }
      expect(app.glyph.where((s) => s.dot), hasLength(1),
          reason: 'every glyph carries exactly one family dot');
    });
  }

  testWidgets('brand widgets lay out at their stated sizes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SuiteMark(size: suiteMarkMinSize),
              SuiteAppIcon(app: SuiteApp.vaultly, size: 40),
              SuiteEndorsement(),
              SuiteLockup(),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(SuiteAppIcon)), const Size.square(40));
    expect(find.bySemanticsLabel('by $suiteName'), findsOneWidget);
  });
}
