import 'dart:async';
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
  _FakeStorage([Map<String, String>? seed]) : _m = {...?seed};
  final Map<String, String> _m;
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
  int prompts = 0;
  @override
  Future<bool> canAuthenticate() async => true;
  @override
  Future<bool> authenticate({required String reason}) {
    prompts++;
    return Future.value(false);
  }
}

/// Reversible, fast stand-in for Argon2 so tests stay quick and deterministic.
final class _FakeHasher implements IPasswordHasher {
  _FakeHasher({this.hang = false});

  /// Leaves verification running forever (the Argon2 wait).
  final bool hang;
  @override
  Future<String> hash(String password) async => 'h:$password';
  @override
  Future<bool> verify(String password, String stored) =>
      hang ? Completer<bool>().future : Future.value(stored == 'h:$password');
}

final _now = DateTime(2026, 10, 20, 21, 41);
const _key = 'gallery_lock';

LockController _controller({
  required bool biometric,
  bool hangHash = false,
  Duration? cooldown,
  String appName = 'Budgetly',
}) =>
    LockController(
      deviceAuth: _FakeAuth(),
      hasher: _FakeHasher(hang: hangHash),
      storage: _FakeStorage({
        '${_key}_verifier': 'h:right',
        '${_key}_recovery': 'h:x',
        if (cooldown != null) ...{
          '${_key}_failed_attempts': '5',
          '${_key}_lockout_until':
              '${_now.add(cooldown).millisecondsSinceEpoch}',
        },
      }),
      clock: () => _now,
      storageKey: _key,
      appName: appName,
      enabled: true,
      biometricEnabled: biometric,
    );

Widget _app(
  LockController c,
  Brightness b, {
  SuiteApp app = SuiteApp.budgetly,
  AppAccent accent = AppAccents.budgetly,
}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(b, accent: accent),
      home: LockScreen(
        controller: c,
        appMark: SuiteAppIcon(app: app, size: 56),
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
  await family(AppTextStyles.monoFamily, [
    for (final w in ['Regular', 'Medium', 'SemiBold'])
      '$fonts/MonaSansMono-$w.ttf',
  ]);
  await family('MaterialIcons', [
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
}

void main() {
  testWidgets('shows only the app, the field, Unlock and the link', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_controller(biometric: false), Brightness.light),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Budgetly'), findsOneWidget);
    expect(find.text('Unlock'), findsOneWidget);
    expect(find.text('by Offlyne'), findsOneWidget);
    expect(find.textContaining(':'), findsNothing);
    expect(find.byTooltip('Unlock with fingerprint'), findsNothing);
  });

  testWidgets('a wrong password shows the error and keeps the screen', (
    tester,
  ) async {
    final c = _controller(biometric: false);
    await tester.pumpWidget(_app(c, Brightness.light));
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(find.byType(TextField), 'nope');
    await tester.pump();
    await tester.tap(find.text('Unlock'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Incorrect password.'), findsOneWidget);
    expect(c.isLocked, isTrue);
  });

  testWidgets('the right password unlocks', (tester) async {
    final c = _controller(biometric: false);
    await tester.pumpWidget(_app(c, Brightness.light));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'right');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pump();
    expect(c.isLocked, isFalse);
  });

  testWidgets('a cooldown counts down and blocks Unlock until it ends', (
    tester,
  ) async {
    final c = _controller(
      biometric: false,
      cooldown: const Duration(seconds: 28),
    );
    await tester.pumpWidget(_app(c, Brightness.light));
    await tester.pump();
    await tester.pump();
    expect(find.text('Too many attempts. Try again in 0:28.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Too many attempts. Try again in 0:25.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'right');
    await tester.pump();
    final unlock = tester.widget<VaultButton>(
      find.widgetWithText(VaultButton, 'Unlock'),
    );
    expect(unlock.onPressed, isNull);

    await tester.pump(const Duration(seconds: 26));
    expect(find.textContaining('Too many attempts'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('prompts once on appear; the fingerprint button re-prompts', (
    tester,
  ) async {
    final auth = _FakeAuth();
    final c = LockController(
      deviceAuth: auth,
      hasher: _FakeHasher(),
      storage: _FakeStorage(),
      clock: () => _now,
      storageKey: _key,
      appName: 'Budgetly',
      enabled: true,
      biometricEnabled: true,
    );
    await tester.pumpWidget(_app(c, Brightness.dark));
    await tester.pump(const Duration(seconds: 1));
    expect(auth.prompts, 1);
    expect(find.byTooltip('Unlock with fingerprint'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.byTooltip('Unlock with fingerprint'));
    await tester.pump();
    expect(auth.prompts, 2);
  });

  testWidgets('Forgot password? swaps in the recovery form and back', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_controller(biometric: true), Brightness.light),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Forgot password?'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Reset your password'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));
    await tester.ensureVisible(find.text('Back to unlock'));
    await tester.tap(find.text('Back to unlock'));
    await tester.pump();
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  test('formatLockCountdown reads as a clock', () {
    expect(formatLockCountdown(const Duration(seconds: 28)), '0:28');
    expect(formatLockCountdown(const Duration(milliseconds: 4100)), '0:05');
    expect(formatLockCountdown(const Duration(minutes: 4, seconds: 5)), '4:05');
  });

  group('gallery', () {
    setUpAll(_loadFonts);
    final shots = <String>[];

    Future<void> shot(
      WidgetTester tester,
      String name,
      Widget app, {
      Size size = const Size(390, 844),
      double textScale = 1,
      double keyboard = 0,
      Future<void> Function()? act,
    }) async {
      tester.view.devicePixelRatio = 3;
      tester.view.physicalSize = size * 3;
      tester.view.padding = const FakeViewPadding(top: 24 * 3, bottom: 16 * 3);
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        RepaintBoundary(
          child: Stack(
            textDirection: TextDirection.ltr,
            children: [
              app,
              // Stands in for the system keyboard, which a test cannot draw.
              if (keyboard > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: keyboard,
                  child: const ColoredBox(color: Color(0xFFB9BEC6)),
                ),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      if (act != null) await act();
      if (keyboard > 0) {
        tester.view.viewInsets = FakeViewPadding(bottom: keyboard * 3);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byType(RepaintBoundary).first,
        );
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$_galleryOut/$name.png')
            .writeAsBytesSync(data!.buffer.asUint8List());
      });
      shots.add(name);
      await tester.pumpWidget(const SizedBox());
    }

    Future<void> wrong(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField), 'nope');
      await tester.pump();
      await tester.tap(find.text('Unlock'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
    }

    for (final b in Brightness.values) {
      final n = b.name;
      testWidgets('biometric $n', (t) async {
        await shot(t, '01-biometric-$n', _app(_controller(biometric: true), b));
      });
      testWidgets('password $n', (t) async {
        await shot(
          t,
          '02-password-$n',
          _app(_controller(biometric: false), b),
          act: () async {
            FocusManager.instance.primaryFocus?.unfocus();
            await t.pump();
          },
        );
      });
      testWidgets('recovery $n', (t) async {
        await shot(
          t,
          '08-recovery-$n',
          _app(_controller(biometric: true), b),
          act: () async {
            await t.tap(find.text('Forgot password?'));
            await t.pump();
            await t.pump(const Duration(milliseconds: 500));
          },
        );
      });
    }
    testWidgets('error', (t) async {
      await shot(
        t,
        '04-error-light',
        _app(_controller(biometric: true), Brightness.light),
        act: () => wrong(t),
      );
    });
    testWidgets('cooldown', (t) async {
      await shot(
        t,
        '05-cooldown-dark',
        _app(
          _controller(biometric: false, cooldown: const Duration(seconds: 28)),
          Brightness.dark,
        ),
        act: () async {
          FocusManager.instance.primaryFocus?.unfocus();
          await t.pump();
        },
      );
    });
    testWidgets('checking', (t) async {
      await shot(
        t,
        '06-checking-light',
        _app(_controller(biometric: false, hangHash: true), Brightness.light),
        act: () async {
          await t.enterText(find.byType(TextField), 'password');
          await t.pump();
          await t.tap(find.text('Unlock'));
          await t.pump();
          await t.pump(const Duration(milliseconds: 300));
        },
      );
    });
    testWidgets('keyboard', (t) async {
      await shot(
        t,
        '07-keyboard-light',
        _app(_controller(biometric: true), Brightness.light),
        keyboard: 336,
        act: () async {
          await t.tap(find.byType(TextField));
          await t.enterText(find.byType(TextField), 'secret');
          await t.pump();
        },
      );
    });
    testWidgets('small phone', (t) async {
      await shot(
        t,
        '09-small-360x640-light',
        _app(_controller(biometric: true), Brightness.light),
        size: const Size(360, 640),
      );
    });
    testWidgets('small phone keyboard', (t) async {
      await shot(
        t,
        '10-small-keyboard-dark',
        _app(_controller(biometric: false), Brightness.dark),
        size: const Size(360, 640),
        keyboard: 280,
      );
    });
    testWidgets('large text', (t) async {
      await shot(
        t,
        '11-large-text-1.3-light',
        _app(_controller(biometric: true), Brightness.light),
        size: const Size(360, 640),
        textScale: 1.3,
      );
    });
    testWidgets('tablet', (t) async {
      await shot(
        t,
        '12-tablet-dark',
        _app(_controller(biometric: true), Brightness.dark),
        size: const Size(820, 1180),
      );
    });
    for (final (app, accent, dark) in [
      (SuiteApp.ledgerly, AppAccents.ledgerly, false),
      (SuiteApp.dosewise, AppAccents.dosewise, true),
    ]) {
      testWidgets('accent ${app.displayName}', (t) async {
        final b = dark ? Brightness.dark : Brightness.light;
        await shot(
          t,
          '13-${app.displayName.toLowerCase()}-${b.name}',
          _app(
            _controller(biometric: true, appName: app.displayName),
            b,
            app: app,
            accent: accent,
          ),
        );
      });
    }

    testWidgets('contact sheet', (t) async {
      await t.runAsync(() async {
        const cell = 390.0;
        const pad = 24.0;
        final images = <ui.Image>[];
        for (final name in shots) {
          final codec = await ui.instantiateImageCodec(
            File('$_galleryOut/$name.png').readAsBytesSync(),
          );
          images.add((await codec.getNextFrame()).image);
        }
        const cols = 6;
        final rows = (images.length / cols).ceil();
        const cellH = 844.0;
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawRect(
          Rect.fromLTWH(
              0, 0, cols * (cell + pad) + pad, rows * (cellH + pad) + pad),
          Paint()..color = const Color(0xFF8A919C),
        );
        for (var i = 0; i < images.length; i++) {
          final img = images[i];
          final scale = (cell / img.width).clamp(0.0, cellH / img.height);
          final dst = Rect.fromLTWH(
            pad + (i % cols) * (cell + pad),
            pad + (i ~/ cols) * (cellH + pad),
            img.width * scale,
            img.height * scale,
          );
          canvas.drawImageRect(
            img,
            Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
            dst,
            Paint()..filterQuality = FilterQuality.medium,
          );
        }
        final sheet = await recorder.endRecording().toImage(
              (cols * (cell + pad) + pad).round(),
              (rows * (cellH + pad) + pad).round(),
            );
        final data = await sheet.toByteData(format: ui.ImageByteFormat.png);
        File('$_galleryOut/00-contact-sheet.png')
            .writeAsBytesSync(data!.buffer.asUint8List());
      });
    });
  }, skip: _galleryOut == null);
}
