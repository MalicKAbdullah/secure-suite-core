// Brand geometry. The SVG masters and Android drawables under brand/
// are exported from exactly these paths; change them together or the
// painted icons and the launcher icons will disagree.

import 'package:flutter/foundation.dart';

/// One drawn element of a brand shape, in 24-unit grid space.
@immutable
final class BrandShape {
  const BrandShape(this.path, {this.stroke = false, this.dot = false});

  /// Absolute SVG path data using only M, L, C, A and Z.
  final String path;

  /// Stroked at [brandStroke] with round caps and joins; else filled.
  final bool stroke;

  /// The family dot: takes the dot color where a variant has one.
  final bool dot;
}

/// Stroke weight shared by every app glyph, in grid units.
const double brandStroke = 2;

/// Glyph grid extent on the 108-unit adaptive icon canvas.
const double brandGlyphExtent = 44;

const List<BrandShape> suiteMarkShapes = [
  BrandShape(
      'M22.188 9.46 A10.5 10.5 0 1 1 14.54 1.812 L13.452 6.178 A6 6 0 1 0 17.822 10.548 Z'),
  BrandShape(
      'M15.584 6.166 A2.25 2.25 0 1 1 20.084 6.166 A2.25 2.25 0 1 1 15.584 6.166 Z',
      dot: true),
];

const List<BrandShape> budgetlyGlyph = [
  BrandShape('M6 19.5 L6 11.5', stroke: true),
  BrandShape('M12 19.5 L12 4.5', stroke: true),
  BrandShape('M18 19.5 L18 15', stroke: true),
  BrandShape('M16 8.5 A2 2 0 1 1 20 8.5 A2 2 0 1 1 16 8.5 Z', dot: true),
];

const List<BrandShape> vaultlyGlyph = [
  BrandShape(
      'M3.184 16.066 A4.75 4.75 0 1 1 12.684 16.066 A4.75 4.75 0 1 1 3.184 16.066 Z',
      stroke: true),
  BrandShape('M11.293 12.707 L18.718 5.282 L21.016 7.581', stroke: true),
  BrandShape('M16.066 7.934 L18.01 9.879', stroke: true),
  BrandShape(
      'M6.434 16.066 A1.5 1.5 0 1 1 9.434 16.066 A1.5 1.5 0 1 1 6.434 16.066 Z',
      dot: true),
];

const List<BrandShape> openlockGlyph = [
  BrandShape('M8 11 L8 8 A4 4 0 0 1 16 8 L16 11', stroke: true),
  BrandShape(
      'M7.5 11 L16.5 11 A3 3 0 0 1 19.5 14 L19.5 18.5 A3 3 0 0 1 16.5 21.5 L7.5 21.5 A3 3 0 0 1 4.5 18.5 L4.5 14 A3 3 0 0 1 7.5 11 Z',
      stroke: true),
  BrandShape('M10 16.25 A2 2 0 1 1 14 16.25 A2 2 0 1 1 10 16.25 Z', dot: true),
];

const List<BrandShape> reflectGlyph = [
  BrandShape(
      'M10.514 4.514 A8.5 8.5 0 1 0 19.486 13.486 A6.5 6.5 0 0 1 10.514 4.514 Z',
      stroke: true),
  BrandShape('M15.25 6.75 A2 2 0 1 1 19.25 6.75 A2 2 0 1 1 15.25 6.75 Z',
      dot: true),
];

const List<BrandShape> ledgerlyGlyph = [
  BrandShape(
      'M7.5 2.5 L16.5 2.5 A3 3 0 0 1 19.5 5.5 L19.5 18.5 A3 3 0 0 1 16.5 21.5 L7.5 21.5 A3 3 0 0 1 4.5 18.5 L4.5 5.5 A3 3 0 0 1 7.5 2.5 Z',
      stroke: true),
  BrandShape('M8.5 8 L15.5 8', stroke: true),
  BrandShape('M8.5 12 L15.5 12', stroke: true),
  BrandShape('M8.5 16.5 L11.5 16.5', stroke: true),
  BrandShape('M13.5 16.5 A2 2 0 1 1 17.5 16.5 A2 2 0 1 1 13.5 16.5 Z',
      dot: true),
];

const List<BrandShape> dosewiseGlyph = [
  BrandShape(
      'M9.328 17.828 L17.828 9.328 A4 4 0 0 0 12.172 3.672 L3.672 12.172 A4 4 0 0 0 9.328 17.828 Z',
      stroke: true),
  BrandShape('M7.922 7.922 L13.578 13.578', stroke: true),
  BrandShape('M16.5 18.5 A2 2 0 1 1 20.5 18.5 A2 2 0 1 1 16.5 18.5 Z',
      dot: true),
];

const List<BrandShape> wardenGlyph = [
  BrandShape(
      'M12 2.75 L19.25 5.5 L19.25 11.25 C19.25 15.9 16.2 19.55 12 21.25 C7.8 19.55 4.75 15.9 4.75 11.25 L4.75 5.5 Z',
      stroke: true),
  BrandShape('M8.75 9.5 L15.25 9.5', stroke: true),
  BrandShape('M10.25 13 L13.75 13', stroke: true),
  BrandShape(
      'M10.25 16.75 A1.75 1.75 0 1 1 13.75 16.75 A1.75 1.75 0 1 1 10.25 16.75 Z',
      dot: true),
];
