import 'package:flutter/material.dart';

/// A rounded-rectangle field border that is not an outline border, so a
/// floating label settles *inside* the field (the filled-field layout)
/// instead of cutting a notch into the edge.
final class AppFieldBorder extends InputBorder {
  const AppFieldBorder({
    super.borderSide = BorderSide.none,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });

  final BorderRadius borderRadius;

  @override
  bool get isOutline => false;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderSide.width);

  @override
  AppFieldBorder copyWith(
          {BorderSide? borderSide, BorderRadius? borderRadius}) =>
      AppFieldBorder(
        borderSide: borderSide ?? this.borderSide,
        borderRadius: borderRadius ?? this.borderRadius,
      );

  @override
  ShapeBorder scale(double t) => AppFieldBorder(
        borderSide: borderSide.scale(t),
        borderRadius: borderRadius * t,
      );

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..addRRect(
      borderRadius.toRRect(rect).deflate(borderSide.width),
    );

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(borderRadius.toRRect(rect));

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (borderSide.style == BorderStyle.none || borderSide.width == 0) return;
    final rrect = borderRadius.toRRect(rect).deflate(borderSide.width / 2);
    canvas.drawRRect(rrect, borderSide.toPaint());
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is AppFieldBorder) {
      return AppFieldBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        borderRadius: BorderRadius.lerp(a.borderRadius, borderRadius, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is AppFieldBorder) {
      return AppFieldBorder(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        borderRadius: BorderRadius.lerp(borderRadius, b.borderRadius, t)!,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  bool operator ==(Object other) =>
      other is AppFieldBorder &&
      other.borderSide == borderSide &&
      other.borderRadius == borderRadius;

  @override
  int get hashCode => Object.hash(borderSide, borderRadius);
}
