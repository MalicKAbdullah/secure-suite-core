import 'dart:io';
import 'dart:ui' as ui;

import 'package:core_theme/core_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gallery renders only run on request: `GALLERY=<out dir> flutter test
/// test/gallery`. Pixel output differs per platform, so they are previews
/// for design review, not CI goldens.
final String? galleryOut = Platform.environment['GALLERY'];

Future<void> loadGalleryFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      final bytes = File(f).readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  const fonts = '../core_theme/fonts';
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
      '/Users/abdullah/development/flutter';
  await family(AppTextStyles.fontFamily, [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
      '$fonts/MonaSans-$w.ttf',
  ]);
  await family(AppTextStyles.displayFamily, [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
      '$fonts/MonaSansDisplay-$w.ttf',
  ]);
  await family(AppTextStyles.monoFamily, [
    for (final w in ['Regular', 'Medium', 'SemiBold'])
      '$fonts/MonaSansMono-$w.ttf',
  ]);
  await family('MaterialIcons', [
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
}

/// Pumps [child] at phone width in both brightnesses and writes
/// `<name>-light.png` / `<name>-dark.png` side by side as `<name>.png`.
Future<void> renderBoard(
  WidgetTester tester,
  String name,
  Widget Function() child, {
  AppAccent accent = AppAccents.budgetly,
  double width = 390,
  double height = 1600,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = Size(width * 2 * 2 + 2 * 2, height * 2);
  addTearDown(tester.view.reset);
  final key = GlobalKey();
  Widget pane(Brightness b) => SizedBox(
        width: width,
        height: height,
        child: Theme(
          data: AppTheme.build(b, accent: accent),
          child: Builder(
            builder: (context) => Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: DefaultTextStyle(
                style: AppTextStyles.body.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                child: child(),
              ),
            ),
          ),
        ),
      );
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(Brightness.light, accent: accent),
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 1600),
          disableAnimations: true,
        ),
        child: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: const Color(0xFF808080),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                pane(Brightness.light),
                const SizedBox(width: 2),
                pane(Brightness.dark),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(galleryOut!).createSync(recursive: true);
    File('$galleryOut/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
}
