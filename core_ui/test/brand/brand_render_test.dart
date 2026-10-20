// Renders the brand contact sheet and every app's launcher PNGs.
//
// Skipped unless GALLERY=1, because pixels differ per host OS and CI runs on
// Linux. Run from core_ui/:
//   GALLERY=1 flutter test test/brand/brand_render_test.dart
// Optional: BRAND_OUT=<dir> for the contact sheet (defaults to build/brand).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:core_ui/src/brand/app_icon.dart';
import 'package:core_ui/src/brand/brand_geometry.dart';
import 'package:core_ui/src/brand/brand_painter.dart';
import 'package:core_ui/src/brand/suite_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _family = 'packages/core_theme/MonaSans';
const _paper = Color(0xFFF6F7F9);
const _ink = Color(0xFF0E1116);
const _night = Color(0xFF0A0C10);

final bool _enabled = Platform.environment['GALLERY'] == '1';

Future<void> _loadFamily(String family, RegExp files) async {
  final dirs = [
    Directory('../core_theme/fonts'),
    if (Platform.environment['MONA_DIR'] case final String d) Directory(d),
  ];
  final loader = FontLoader(family);
  var found = 0;
  for (final dir in dirs) {
    if (!dir.existsSync()) continue;
    for (final file in dir.listSync().whereType<File>()) {
      if (!files.hasMatch(file.uri.pathSegments.last)) continue;
      final bytes = file.readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
      found++;
    }
    if (found > 0) break;
  }
  expect(found, greaterThan(0), reason: '$family files not found');
  await loader.load();
}

Future<void> _loadFonts() async {
  await _loadFamily(
      _family, RegExp(r'^MonaSans-(Regular|Medium|SemiBold|Bold)\.ttf$'));
  await _loadFamily(suiteWordmarkFamily,
      RegExp(r'^MonaSansDisplay-(Regular|Medium|SemiBold|Bold)\.ttf$'));
}

Future<void> _capture(WidgetTester tester, Widget child, Size size, String path,
    {double ratio = 2}) async {
  final key = GlobalKey();
  await tester.binding.setSurfaceSize(size);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: _family),
      home: RepaintBoundary(
        key: key,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Material(
            type: MaterialType.transparency,
            child: SizedBox.fromSize(size: size, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: ratio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path)..createSync(recursive: true);
    file.writeAsBytesSync(data!.buffer.asUint8List());
  });
}

/// The adaptive-icon foreground layer: glyph only, on the 108-unit canvas.
final class _Foreground extends CustomPainter {
  const _Foreground(this.app, this.color);

  final SuiteApp app;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 108;
    final offset = (108 - brandGlyphExtent) / 2 * unit;
    paintBrandShapes(
      canvas,
      app.glyph,
      origin: Offset(offset, offset),
      extent: brandGlyphExtent * unit,
      ink: color,
      dot: color,
    );
  }

  @override
  bool shouldRepaint(_Foreground old) => false;
}

Widget _label(String text, Color color, {double size = 13}) => Text(
      text,
      style: TextStyle(
        fontFamily: _family,
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 0.2,
      ),
    );

Widget _iconRow(SuiteIconStyle style, Color text, {Color? fill}) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final app in SuiteApp.values)
          Column(
            children: [
              SuiteAppIcon(app: app, size: 120, style: style, fill: fill),
              const SizedBox(height: 14),
              _label(app.displayName, text),
            ],
          ),
      ],
    );

Widget _panel(Color bg, Color text, Color subtle, Brightness b) {
  final dark = b == Brightness.dark;
  return Theme(
    data: ThemeData(
      brightness: b,
      fontFamily: _family,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F62D6),
        brightness: b,
      ).copyWith(
        onSurface: text,
        onSurfaceVariant: subtle,
        surfaceContainerHighest:
            dark ? const Color(0xFF1A1E26) : const Color(0xFFE6E9EE),
        primary: dark ? const Color(0xFF6AA6FF) : const Color(0xFF0F62D6),
      ),
    ),
    child: Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(64, 56, 64, 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SuiteMark(size: 96, color: text),
              const SizedBox(width: 40),
              SuiteMark(
                size: 96,
                color: text,
                variant: SuiteMarkVariant.accent,
              ),
              const SizedBox(width: 40),
              for (final s in [48.0, 32.0, 24.0, 16.0]) ...[
                SuiteMark(size: s, color: text),
                const SizedBox(width: 24),
              ],
              const Spacer(),
              _label(dark ? 'Dark' : 'Light', subtle),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SuiteLockup(fontSize: 52, color: text),
              const SizedBox(width: 56),
              SuiteWordmark(
                fontSize: 52,
                color: text,
                variant: SuiteMarkVariant.accent,
              ),
              const Spacer(),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SuiteEndorsement(),
                  SizedBox(height: 12),
                  SuiteEndorsement(
                    style: TextStyle(fontFamily: _family, fontSize: 16),
                    variant: SuiteMarkVariant.accent,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 56),
          _iconRow(SuiteIconStyle.color, text),
          const SizedBox(height: 40),
          _iconRow(SuiteIconStyle.ink, text,
              fill: dark ? const Color(0xFF1A1E26) : null),
          const SizedBox(height: 40),
          _iconRow(SuiteIconStyle.mono, text),
        ],
      ),
    ),
  );
}

Widget _sheet() => Column(
      children: [
        Expanded(
          child:
              _panel(_paper, _ink, const Color(0xFF5B6472), Brightness.light),
        ),
        Expanded(
          child: _panel(_night, const Color(0xFFECEEF2),
              const Color(0xFF9AA3B2), Brightness.dark),
        ),
      ],
    );

/// A launcher-sized preview: each icon at 48 and 24 logical pixels next to a
/// lock-screen style endorsement, to judge legibility at real sizes.
Widget _small() => Container(
      color: _night,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            for (final app in SuiteApp.values) ...[
              SuiteAppIcon(app: app, size: 48),
              const SizedBox(width: 16),
            ],
          ]),
          const SizedBox(height: 16),
          Row(children: [
            for (final app in SuiteApp.values) ...[
              SuiteAppIcon(app: app, size: 24),
              const SizedBox(width: 12),
            ],
          ]),
        ],
      ),
    );

void main() {
  final outDir = Platform.environment['BRAND_OUT'] ?? 'build/brand';

  testWidgets('brand contact sheet', (tester) async {
    await _loadFonts();
    await _capture(tester, _sheet(), const Size(1500, 1900),
        '$outDir/brand-contact-sheet.png',
        ratio: 1);
    await _capture(tester, _small(), const Size(560, 136),
        '$outDir/brand-icons-small.png');
  }, skip: !_enabled);

  testWidgets('splash branding PNGs', (tester) async {
    await _loadFonts();
    for (final (name, color) in [
      ('offlyne-endorsement', const Color(0xFF5B6472)),
      ('offlyne-endorsement-white', const Color(0xFF9AA3B2)),
    ]) {
      // 200x80 dp is Android 12's splash branding box; 4x covers xxxhdpi.
      await _capture(
        tester,
        Center(
          child: SuiteEndorsement(
            color: color,
            style: const TextStyle(fontFamily: _family, fontSize: 15),
          ),
        ),
        const Size(200, 80),
        '../brand/mark/png/$name.png',
        ratio: 4,
      );
    }
  }, skip: !_enabled);

  testWidgets('launcher PNGs', (tester) async {
    for (final app in SuiteApp.values) {
      final dir = '../brand/icons/${app.name}/png';
      await _capture(tester, SuiteAppIcon(app: app, size: 512, fullBleed: true),
          const Size.square(512), '$dir/icon-1024.png');
      await _capture(tester, SuiteAppIcon(app: app, size: 512, fullBleed: true),
          const Size.square(512), '$dir/play-store-512.png',
          ratio: 1);
      await _capture(
          tester,
          CustomPaint(painter: _Foreground(app, const Color(0xFFFFFFFF))),
          const Size.square(512),
          '$dir/icon-foreground-1024.png');
      await _capture(
          tester,
          CustomPaint(painter: _Foreground(app, const Color(0xFFFFFFFF))),
          const Size.square(512),
          '$dir/icon-monochrome-1024.png');
      // flutter_native_splash treats `image` as 4x: this shows at 96dp.
      await _capture(tester, SuiteAppIcon(app: app, size: 96),
          const Size.square(96), '$dir/splash-tile.png',
          ratio: 4);
    }
  }, skip: !_enabled);
}
