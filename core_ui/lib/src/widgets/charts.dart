import 'dart:math' as math;

import 'package:core_theme/core_theme.dart';
import 'package:flutter/material.dart';

/// A compact trend line: no axes, no grid — the shape of the series, its
/// last point marked, and an optional reference line (a budget, an average).
final class Sparkline extends StatelessWidget {
  const Sparkline({
    required this.values,
    this.color,
    this.height = 56,
    this.strokeWidth = 2,
    this.fill = true,
    this.showLastPoint = true,
    this.reference,
    super.key,
  });

  final List<double> values;
  final Color? color;
  final double height;
  final double strokeWidth;

  /// Paints a faint wash under the line.
  final bool fill;
  final bool showLastPoint;

  /// A value drawn as a dashed horizontal line.
  final double? reference;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values,
          color: color ?? c.accent,
          strokeWidth: strokeWidth,
          fill: fill,
          showLastPoint: showLastPoint,
          reference: reference,
          referenceColor: c.textTertiary,
          surface: c.surface,
        ),
      ),
    );
  }
}

final class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
    required this.fill,
    required this.showLastPoint,
    required this.reference,
    required this.referenceColor,
    required this.surface,
  });

  final List<double> values;
  final Color color;
  final double strokeWidth;
  final bool fill;
  final bool showLastPoint;
  final double? reference;
  final Color referenceColor;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    var lo = values.reduce(math.min);
    var hi = values.reduce(math.max);
    if (reference != null) {
      lo = math.min(lo, reference!);
      hi = math.max(hi, reference!);
    }
    final span = hi - lo == 0 ? 1.0 : hi - lo;
    // Inset so the stroke and end dot are never clipped by the box.
    final pad = strokeWidth + 3;
    final h = size.height - pad * 2;
    final w = size.width - pad * 2;
    Offset at(int i, double v) => Offset(
          w * i / (values.length - 1),
          pad + h - (v - lo) / span * h,
        );

    final points = [for (var i = 0; i < values.length; i++) at(i, values[i])];
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      // Monotone-ish smoothing: control points at the horizontal midpoint
      // keep the curve from overshooting between samples.
      final p0 = points[i - 1];
      final p1 = points[i];
      final mx = (p0.dx + p1.dx) / 2;
      line.cubicTo(mx, p0.dy, mx, p1.dy, p1.dx, p1.dy);
    }

    if (fill) {
      final area = Path.from(line)
        ..lineTo(points.last.dx, size.height)
        ..lineTo(points.first.dx, size.height)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.16),
              color.withValues(alpha: 0),
            ],
          ).createShader(Offset.zero & size),
      );
    }

    if (reference != null) {
      final y = at(0, reference!).dy;
      final dash = Paint()
        ..color = referenceColor
        ..strokeWidth = 1;
      for (var x = 0.0; x < size.width; x += 6) {
        canvas.drawLine(
            Offset(x, y), Offset(math.min(x + 3, size.width), y), dash);
      }
    }

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (showLastPoint) {
      final p = points.last;
      canvas.drawCircle(p, strokeWidth + 3, Paint()..color = surface);
      canvas.drawCircle(p, strokeWidth + 1.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values ||
      old.color != color ||
      old.reference != reference ||
      old.surface != surface;
}

/// A small vertical bar chart (days of a week, months of a year). One bar
/// can be highlighted in the accent; the rest sit back in a neutral tone.
final class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    required this.values,
    this.labels,
    this.highlightIndex,
    this.color,
    this.height = 96,
    this.barRadius = 5,
    super.key,
  });

  final List<double> values;

  /// One label per bar, drawn underneath in caption size.
  final List<String>? labels;
  final int? highlightIndex;
  final Color? color;
  final double height;
  final double barRadius;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    final peak = values.isEmpty ? 1.0 : values.reduce(math.max);
    final max = peak <= 0 ? 1.0 : peak;
    final accent = color ?? c.accent;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: math.max(values[i] / max, 0.04),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: i == highlightIndex
                                ? accent
                                : highlightIndex == null
                                    ? accent.withValues(alpha: 0.85)
                                    : c.border.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(barRadius),
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                  if (labels != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      labels![i],
                      maxLines: 1,
                      style: AppTextStyles.caption.copyWith(
                        color: i == highlightIndex
                            ? c.textPrimary
                            : c.textTertiary,
                        fontWeight: i == highlightIndex
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One slice of a [DonutChart].
@immutable
final class DonutSegment {
  const DonutSegment({required this.value, this.color, this.label});

  final double value;

  /// Defaults to the theme's chart series, in order.
  final Color? color;
  final String? label;
}

/// A ring chart with hairline gaps between slices and an optional centre
/// widget (a total, a percentage).
final class DonutChart extends StatelessWidget {
  const DonutChart({
    required this.segments,
    this.size = 140,
    this.thickness = 14,
    this.center,
    this.gapDegrees = 2.5,
    super.key,
  });

  final List<DonutSegment> segments;
  final double size;
  final double thickness;
  final Widget? center;
  final double gapDegrees;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    final colors = [
      for (var i = 0; i < segments.length; i++)
        segments[i].color ?? c.chart[i % c.chart.length],
    ];
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _DonutPainter(
          values: [for (final s in segments) s.value],
          colors: colors,
          thickness: thickness,
          gap: gapDegrees * math.pi / 180,
          track: c.surfaceAlt,
        ),
        child: center == null ? null : Center(child: center),
      ),
    );
  }
}

final class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.values,
    required this.colors,
    required this.thickness,
    required this.gap,
    required this.track,
  });

  final List<double> values;
  final List<Color> colors;
  final double thickness;
  final double gap;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - thickness) / 2,
    );
    final total = values.fold<double>(0, (a, b) => a + b);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.butt;
    if (total <= 0) {
      canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
      return;
    }
    final visible = values.where((v) => v > 0).length;
    final gaps = visible > 1 ? gap : 0.0;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final sweep = values[i] / total * math.pi * 2;
      canvas.drawArc(
        rect,
        start + gaps / 2,
        math.max(sweep - gaps, 0.001),
        false,
        paint..color = colors[i],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.values != values || old.colors != colors || old.track != track;
}

/// A dot + label + value line used as a chart legend.
final class ChartLegendRow extends StatelessWidget {
  const ChartLegendRow({
    required this.color,
    required this.label,
    this.value,
    super.key,
  });

  final Color color;
  final String label;
  final Widget? value;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(color: c.textSecondary),
            ),
          ),
          if (value != null) value!,
        ],
      ),
    );
  }
}
