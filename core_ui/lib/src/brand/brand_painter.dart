import 'dart:ui' as ui;

import 'package:core_ui/src/brand/brand_geometry.dart';
import 'package:flutter/widgets.dart';

/// Parses the absolute M/L/C/A/Z subset of SVG path data that the brand
/// geometry is written in. Anything else is a generator bug, so it throws.
Path parseBrandPath(String data) {
  final tokens = RegExp(r'[MLCAZ]|-?\d*\.?\d+')
      .allMatches(data)
      .map((m) => m.group(0)!)
      .toList();
  final path = Path();
  var i = 0;
  double next() => double.parse(tokens[i++]);
  while (i < tokens.length) {
    final command = tokens[i++];
    switch (command) {
      case 'M':
        path.moveTo(next(), next());
      case 'L':
        path.lineTo(next(), next());
      case 'C':
        path.cubicTo(next(), next(), next(), next(), next(), next());
      case 'A':
        final rx = next();
        final ry = next();
        final rotation = next();
        final largeArc = next() != 0;
        final clockwise = next() != 0;
        path.arcToPoint(
          Offset(next(), next()),
          radius: Radius.elliptical(rx, ry),
          rotation: rotation,
          largeArc: largeArc,
          clockwise: clockwise,
        );
      case 'Z':
        path.close();
      default:
        throw FormatException('Unsupported brand path command', command);
    }
  }
  return path;
}

final Map<String, Path> _cache = {};

Path _path(String data) => _cache.putIfAbsent(data, () => parseBrandPath(data));

/// Paints brand shapes (24-unit grid) into a square of [extent] logical
/// pixels starting at [origin].
void paintBrandShapes(
  Canvas canvas,
  List<BrandShape> shapes, {
  required Offset origin,
  required double extent,
  required Color ink,
  required Color dot,
}) {
  final scale = extent / 24;
  canvas
    ..save()
    ..translate(origin.dx, origin.dy)
    ..scale(scale);
  for (final shape in shapes) {
    final paint = Paint()
      ..isAntiAlias = true
      ..color = shape.dot ? dot : ink;
    if (shape.stroke) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = brandStroke
        ..strokeCap = ui.StrokeCap.round
        ..strokeJoin = ui.StrokeJoin.round;
    }
    canvas.drawPath(_path(shape.path), paint);
  }
  canvas.restore();
}
