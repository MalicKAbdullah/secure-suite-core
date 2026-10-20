import 'package:flutter/animation.dart';

/// Motion tokens. Movement is short and decelerating: things arrive quickly
/// and settle, never bounce on data. The one spring-like curve is reserved
/// for direct-manipulation feedback (segmented thumb, keypad press).
abstract final class AppMotion {
  /// Press states, toggles, colour changes.
  static const Duration instant = Duration(milliseconds: 90);

  /// Selection moves, chips, field focus.
  static const Duration fast = Duration(milliseconds: 160);

  /// Cards and content entering, sheet open.
  static const Duration base = Duration(milliseconds: 240);

  /// Screen-level transitions, lock screen reveal, chart draw-in.
  static const Duration slow = Duration(milliseconds: 420);

  /// Skeleton shimmer period.
  static const Duration shimmer = Duration(milliseconds: 1400);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutQuart;
  static const Curve exit = Curves.easeInCubic;
  static const Curve settle = Cubic(0.2, 0.9, 0.25, 1.06);
}
