import 'package:core_crypto/core_crypto.dart';
import 'package:core_lock/core_lock.dart';
import 'package:core_storage/core_storage.dart';
import 'package:core_theme/core_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeStorage implements ISecureStorage {
  final Map<String, String> m = {};
  @override
  Future<void> write({required String key, required String value}) async =>
      m[key] = value;
  @override
  Future<String?> read({required String key}) async => m[key];
  @override
  Future<void> delete({required String key}) async => m.remove(key);
  @override
  Future<void> deleteAll() async => m.clear();
  @override
  Future<Map<String, String>> readAll() async => Map.of(m);
}

final class _NoBiometrics implements IDeviceAuth {
  @override
  Future<bool> canAuthenticate() async => false;
  @override
  Future<bool> authenticate({required String reason}) async => false;
}

final class _FakeHasher implements IPasswordHasher {
  @override
  Future<String> hash(String password) async => 'h:$password';
  @override
  Future<bool> verify(String password, String stored) async =>
      stored == 'h:$password';
}

const _key = '7K3M-Q9ZD-4XWB-HN2P-T8RC-6VYF-JG5S';

void main() {
  late _FakeStorage storage;

  setUp(() {
    storage = _FakeStorage()..m['t_lock_verifier'] = 'h:old-password';
  });

  LockController controller() => LockController(
        deviceAuth: _NoBiometrics(),
        hasher: _FakeHasher(),
        storage: storage,
        clock: () => DateTime(2026, 10, 20, 9),
        storageKey: 't_lock',
        appName: 'Budgetly',
        enabled: true,
      );

  Widget app(LockController c) => MaterialApp(
        theme: AppTheme.build(Brightness.light, accent: AppAccents.budgetly),
        builder: (context, child) => AppLockGate(controller: c, child: child!),
        home: const Scaffold(body: Text('Home')),
      );

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> openRecovery(WidgetTester tester, LockController c) async {
    await tester.pumpWidget(app(c));
    await settle(tester);
    await tester.tap(find.text('Forgot password?'));
    await settle(tester);
  }

  testWidgets('recovery key + new password unlocks with the new password', (
    tester,
  ) async {
    storage.m['t_lock_recovery'] = 'h:${RecoveryKey.normalize(_key)}';
    final c = controller();
    await openRecovery(tester, c);

    expect(find.text('Reset your password'), findsOneWidget);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), _key.toLowerCase());
    await tester.enterText(fields.at(1), 'brand-new');
    await tester.enterText(fields.at(2), 'brand-new');
    await tester.tap(find.text('Reset password and unlock'));
    await settle(tester);

    expect(c.isLocked, isFalse);
    expect(find.text('Home'), findsOneWidget);
    expect(storage.m['t_lock_verifier'], 'h:brand-new');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a wrong recovery key keeps the app locked', (tester) async {
    storage.m['t_lock_recovery'] = 'h:${RecoveryKey.normalize(_key)}';
    final c = controller();
    await openRecovery(tester, c);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), RecoveryKey.generate());
    await tester.enterText(fields.at(1), 'brand-new');
    await tester.enterText(fields.at(2), 'brand-new');
    await tester.tap(find.text('Reset password and unlock'));
    await settle(tester);

    expect(c.isLocked, isTrue);
    expect(find.text('That recovery key is not right.'), findsOneWidget);
    expect(storage.m['t_lock_verifier'], 'h:old-password');

    await tester.tap(find.text('Back to password'));
    await settle(tester);
    expect(find.text('Unlock Budgetly'), findsOneWidget);
  });

  testWidgets('without a recovery key it explains there is no reset', (
    tester,
  ) async {
    await openRecovery(tester, controller());
    expect(find.textContaining('No recovery key was set up'), findsOneWidget);
    expect(find.text('Reset password and unlock'), findsNothing);
  });

  testWidgets('an unlock without a key offers one once, shown until saved', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = controller();
    await tester.pumpWidget(app(c));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'old-password');
    await tester.tap(find.text('Unlock Budgetly'));
    await settle(tester);

    expect(find.text('Set up a recovery key'), findsOneWidget);
    await tester.tap(find.text('Create recovery key'));
    await settle(tester);

    expect(find.text('Your recovery key'), findsOneWidget);
    final shown = tester
        .widget<SelectableText>(find.byKey(const ValueKey('recovery-key-text')))
        .data!;
    expect(RecoveryKey.normalize(shown), isNotNull);
    expect(storage.m['t_lock_recovery'], 'h:${RecoveryKey.normalize(shown)}');

    // Done stays disabled until the user confirms saving it.
    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(find.text('Your recovery key'), findsOneWidget);

    await tester.tap(find.text("I've saved my recovery key"));
    await settle(tester);
    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(find.text('Home'), findsOneWidget);
    expect(c.recoveryPromptDue, isFalse);
    expect(storage.m['t_lock_recovery_prompted'], 'true');
  });

  testWidgets('declining the offer does not ask again', (tester) async {
    final c = controller();
    await tester.pumpWidget(app(c));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'old-password');
    await tester.tap(find.text('Unlock Budgetly'));
    await settle(tester);
    await tester.tap(find.textContaining('Not now'));
    await settle(tester);

    expect(find.text('Home'), findsOneWidget);
    expect(storage.m['t_lock_recovery'], isNull);
    expect(storage.m['t_lock_recovery_prompted'], 'true');
  });
}
