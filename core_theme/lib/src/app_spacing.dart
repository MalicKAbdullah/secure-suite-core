/// Spacing runs on a 4 pt grid; radii follow a concentric rule — an inner
/// element's radius is the outer radius minus the padding between them.
abstract final class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double smd = 12.0;
  static const double md = 16.0;
  static const double mdl = 20.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  /// Horizontal page gutter on phones.
  static const double gutter = 20.0;

  /// Inner padding of a standard card.
  static const double cardPadding = 20.0;

  static const double radiusXs = 6.0;
  static const double radiusSm = 10.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 22.0;
  static const double radiusXl = 28.0;
  static const double radiusPill = 999.0;

  /// Inputs, small cards, banners.
  static const double borderRadius = radiusMd;

  /// Cards and sheets.
  static const double borderRadiusLg = radiusLg;

  static const double hairline = 1.0;
  static const double iconSize = 24.0;
  static const double iconSizeSm = 18.0;

  /// Minimum touch target.
  static const double tapTarget = 48.0;
  static const double buttonHeight = 54.0;
  static const double buttonHeightSm = 40.0;
  static const double fieldHeight = 58.0;
}
