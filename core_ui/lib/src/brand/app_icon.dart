import 'package:core_ui/src/brand/brand_geometry.dart';
import 'package:core_ui/src/brand/brand_painter.dart';
import 'package:flutter/material.dart';

/// Every app in the family, with its display name, icon accent and glyph.
enum SuiteApp {
  budgetly('Budgetly', Color(0xFF0F62D6), Color(0xFF6AA6FF), budgetlyGlyph),
  vaultly('Vaultly', Color(0xFF7341E6), Color(0xFFB197FF), vaultlyGlyph),
  openlock('OpenLock', Color(0xFF007E9C), Color(0xFF3FD0EE), openlockGlyph),
  reflect('Reflect', Color(0xFFC81E5B), Color(0xFFFF6B9A), reflectGlyph),
  ledgerly('Ledgerly', Color(0xFF4A4FE0), Color(0xFF9298FF), ledgerlyGlyph),
  dosewise('DoseWise', Color(0xFF08805F), Color(0xFF3EDDA6), dosewiseGlyph),
  warden('Warden', Color(0xFF457A0C), Color(0xFFA6E33C), wardenGlyph);

  const SuiteApp(
      this.displayName, this.accentLight, this.accentDark, this.glyph);

  final String displayName;

  /// Accent on light surfaces, and the launcher icon's fill.
  final Color accentLight;

  /// Accent on dark surfaces.
  final Color accentDark;

  /// The app's glyph on the shared 24-unit grid.
  final List<BrandShape> glyph;
}

/// How a [SuiteAppIcon] is colored.
enum SuiteIconStyle {
  /// The launcher icon: accent fill, white glyph.
  color,

  /// Ink fill, white glyph, the family dot in the app's dark accent. For
  /// in-app surfaces where seven accent tiles would be loud.
  ink,

  /// Single-color glyph on a tinted tile — how Android 13 themed icons
  /// render the monochrome layer.
  mono,
}

/// The app icon, drawn from the same geometry as the Android drawables.
///
/// Construction (shared by all apps): the visible tile is 72 of the adaptive
/// icon's 108 units and the glyph's 24-unit grid spans [brandGlyphExtent]
/// (44) of them, centred, so every glyph sits on the same 14-unit keyline
/// inside the tile at every size.
final class SuiteAppIcon extends StatelessWidget {
  const SuiteAppIcon({
    required this.app,
    this.size = 48,
    this.style = SuiteIconStyle.color,
    this.fill,
    this.ink,
    this.fullBleed = false,
    super.key,
  });

  final SuiteApp app;
  final double size;
  final SuiteIconStyle style;

  /// Tile color override. Defaults per [style].
  final Color? fill;

  /// Glyph color override. Defaults per [style].
  final Color? ink;

  /// Square, uncornered tile (store listings, where the store applies its
  /// own mask).
  final bool fullBleed;

  /// Tile corner radius as a fraction of the tile size; matches the parent
  /// mark's module corners (3 of 10).
  static const double cornerFraction = 0.3;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (tile, glyph, dot) = switch (style) {
      SuiteIconStyle.color => (
          fill ?? app.accentLight,
          ink ?? const Color(0xFFFFFFFF),
          ink ?? const Color(0xFFFFFFFF),
        ),
      SuiteIconStyle.ink => (
          fill ?? const Color(0xFF0E1116),
          ink ?? const Color(0xFFFFFFFF),
          app.accentDark,
        ),
      SuiteIconStyle.mono => (
          fill ?? scheme.surfaceContainerHighest,
          ink ?? scheme.onSurface,
          ink ?? scheme.onSurface,
        ),
    };
    return Semantics(
      label: app.displayName,
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _AppIconPainter(
          glyph: app.glyph,
          tile: tile,
          ink: glyph,
          dot: dot,
          radius: fullBleed ? 0 : size * cornerFraction,
        ),
      ),
    );
  }
}

final class _AppIconPainter extends CustomPainter {
  const _AppIconPainter({
    required this.glyph,
    required this.tile,
    required this.ink,
    required this.dot,
    required this.radius,
  });

  final List<BrandShape> glyph;
  final Color tile;
  final Color ink;
  final Color dot;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Offset.zero & Size.square(s), Radius.circular(radius)),
      Paint()..color = tile,
    );
    final extent = s * brandGlyphExtent / 72;
    paintBrandShapes(
      canvas,
      glyph,
      origin: Offset((s - extent) / 2, (s - extent) / 2),
      extent: extent,
      ink: ink,
      dot: dot,
    );
  }

  @override
  bool shouldRepaint(_AppIconPainter old) =>
      old.glyph != glyph ||
      old.tile != tile ||
      old.ink != ink ||
      old.dot != dot ||
      old.radius != radius;
}
