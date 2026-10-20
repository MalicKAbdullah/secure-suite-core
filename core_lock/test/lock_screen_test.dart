import 'dart:io';
import 'dart:ui' as ui;

import 'package:core_lock/core_lock.dart';
import 'package:core_storage/core_storage.dart';
import 'package:core_theme/core_theme.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeStorage implements ISecureStorage {
  final Map<String, String> _m = {};
  @override
  Future<void> write({required String key, required String value}) async =>
      _m[key] = value;
  @override
  Future<String?> read({required String key}) async => _m[key];
  @override
  Future<void> delete({required String key}) async => _m.remove(key);
  @override
  Future<void> deleteAll() async => _m.clear();
  @override
  Future<Map<String, String>> readAll() async => Map.of(_m);
}

final class _FakeAuth implements IDeviceAuth {
  _FakeAuth({this.succeeds = true});
  bool succeeds;
  int prompts = 0;
  @override
  Future<bool> canAuthenticate() async => true;
  @override
  Future<bool> authenticate({required String reason}) async {
    prompts++;
    return succeeds;
  }
}

/// Reversible, fast stand-in for Argon2 so tests stay quick and deterministic.
final class _FakeHasher implements IPasswordHasher {
  @override
  Future<String> hash(String password) async => 'h:$password';
  @override
  Future<bool> verify(String password, String stored) async =>
      stored == 'h:$password';
}

LockController _controller({required bool biometric}) => LockController(
      deviceAuth: _FakeAuth(succeeds: false),
      hasher: _FakeHasher(),
      storage: _FakeStorage(),
      clock: () => DateTime(2026, 10, 20, 21, 41),
      storageKey: 'gallery_lock',
      appName: 'Budgetly',
      enabled: true,
      biometricEnabled: biometric,
    );

Widget _app(LockController c, Brightness b) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(b, accent: AppAccents.budgetly),
      home: LockScreen(
        controller: c,
        appMark: const SuiteAppIcon(app: SuiteApp.budgetly, size: 56),
      ),
    );

/// `GALLERY=<dir> flutter test test/lock_screen_test.dart` writes previews.
final String? _galleryOut = Platform.environment['GALLERY'];

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(
          Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
    }
    await loader.load();
  }

  const fonts = '../core_theme/fonts';
  final root = Platform.environment['FLUTTER_ROOT'] ??
      '/Users/abdullah/development/flutter';
  await family(AppTextStyles.fontFamily, [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
      '$fonts/MonaSans-$w.ttf',
  ]);
  await family(AppTextStyles.displayFamily, [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
      '$fonts/MonaSansDisplay-$w.ttf',
  ]);
  await family('MaterialIcons', [
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
}

void main() {
  testWidgets('a wrong password shows the error and keeps the screen', (
    tester,
  ) async {
    final c = _controller(biometric: false);
    await tester.pumpWidget(_app(c, Brightness.light));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Unlock Budgetly'), findsOneWidget);
    expect(find.text('by Offlyne'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'nope');
    await tester.tap(find.text('Unlock Budgetly'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Incorrect password.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offers the fingerprint when biometrics are enabled', (
    tester,
  ) async {
    await tester
        .pumpWidget(_app(_controller(biometric: true), Brightness.dark));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Use fingerprint'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('gallery', () {
    setUpAll(_loadFonts);
    for (final b in Brightness.values) {
      for (final bio in [true, false]) {
        testWidgets('lock screen ${b.name} biometric=$bio', (tester) async {
          tester.view.devicePixelRatio = 3;
          tester.view.physicalSize = const Size(390 * 3, 844 * 3);
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            RepaintBoundary(child: _app(_controller(biometric: bio), b)),
          );
          await tester.pump(const Duration(seconds: 1));
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byType(RepaintBoundary).first,
            );
            final image = await boundary.toImage(pixelRatio: 2);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            File('$_galleryOut/lock-${b.name}${bio ? '' : '-password'}.png')
                .writeAsBytesSync(data!.buffer.asUint8List());
          });
        });
      }
    }
  }, skip: _galleryOut == null);
}
