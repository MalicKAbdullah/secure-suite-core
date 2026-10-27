import 'package:core_lock/src/identity_check.dart';
import 'package:core_lock/src/lock_attempt.dart';
import 'package:core_lock/src/lock_controller.dart';
import 'package:core_lock/src/recovery_key_view.dart';
import 'package:core_theme/core_theme.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Drop-in Settings section for the app lock — identical across every Secure
/// Suite app. Renders the whole flow from a [LockController]:
///
///  * off  → "App lock" switch that opens a set-password
///    form (with an optional "use fingerprint" toggle when available), then
///    shows the new recovery key once;
///  * on   → the switch turns it off (after confirming the password), plus
///    "Use fingerprint", "Change password" (a fresh fingerprint stands in for
///    the current password when the session was opened with one) and
///    "Recovery key" (re-auth, then a new key replaces the old) rows.
///
/// State-management-agnostic: pass the same controller your app already builds.
final class AppLockSettings extends StatefulWidget {
  const AppLockSettings({required this.controller, super.key});

  final LockController controller;

  @override
  State<AppLockSettings> createState() => _AppLockSettingsState();
}

class _AppLockSettingsState extends State<AppLockSettings> {
  bool _biometricAvailable = false;
  bool? _hasRecoveryKey;

  LockController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onChange);
    _probe();
  }

  @override
  void dispose() {
    _c.removeListener(_onChange);
    super.dispose();
  }

  /// The gate's one-time offer can create a key while this is mounted.
  void _onChange() {
    if (!mounted) return;
    setState(() {});
    _c.hasRecoveryKey().then((has) {
      if (mounted && has != _hasRecoveryKey) {
        setState(() => _hasRecoveryKey = has);
      }
    });
  }

  Future<void> _probe() async {
    final can = await _c.canUseBiometric();
    final hasKey = await _c.hasRecoveryKey();
    if (mounted) {
      setState(() {
        _biometricAvailable = can;
        _hasRecoveryKey = hasKey;
      });
    }
  }

  void _snack(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _turnOn() async {
    final result = await Navigator.of(context).push<_SetupResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _SetPasswordScreen(
          appName: _c.appName,
          biometricAvailable: _biometricAvailable,
        ),
      ),
    );
    if (result == null) return;
    await _c.enable(
      password: result.password,
      useBiometric: result.useBiometric,
    );
    await _showNewRecoveryKey();
    _snack('App lock is on.');
  }

  Future<void> _turnOff() async {
    final password = await askAppLockPassword(
      context,
      title: 'Turn off app lock',
    );
    if (password == null) return;
    final result = await _c.disable(password);
    if (result is LockAttemptSuccess) setState(() => _hasRecoveryKey = false);
    _snack(
      result is LockAttemptSuccess
          ? 'App lock is off.'
          : lockAttemptError(result, wrong: 'Incorrect password.'),
    );
  }

  Future<void> _changePassword() async {
    final withBiometric = _c.canChangePasswordWithBiometric;
    final result = await Navigator.of(context).push<_ChangeResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ChangePasswordScreen(askCurrent: !withBiometric),
      ),
    );
    if (result == null) return;
    final outcome = await _c.changePassword(
      currentPassword: withBiometric ? null : result.currentPassword,
      newPassword: result.newPassword,
    );
    _snack(
      outcome is LockAttemptSuccess
          ? 'Password changed.'
          : lockAttemptError(
              outcome,
              wrong: withBiometric
                  ? 'Fingerprint not confirmed.'
                  : 'Current password is incorrect.',
            ),
    );
  }

  Future<void> _recoveryKey() async {
    if (!await confirmAppLockIdentity(
      context,
      _c,
      reason: 'Create a new recovery key',
    )) {
      return;
    }
    if (_hasRecoveryKey == true && mounted) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Replace your recovery key?'),
          content: const Text(
            'Your current recovery key will stop working. Recovery keys are '
            'never stored, so the current one cannot be shown again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Create new key'),
            ),
          ],
        ),
      );
      if (replace != true) return;
    }
    await _showNewRecoveryKey();
  }

  /// Creates a recovery key and shows it until the user confirms saving it.
  Future<void> _showNewRecoveryKey() async {
    final key = await _c.createRecoveryKey();
    if (!mounted) return;
    setState(() => _hasRecoveryKey = true);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (routeContext) => PopScope(
          canPop: false,
          child: RecoveryKeyView(
            recoveryKey: key,
            appName: _c.appName,
            onDone: () => Navigator.pop(routeContext),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RowGroup(
      children: [
        SettingsTile(
          icon: Icons.lock_outline_rounded,
          title: 'App lock',
          subtitle: _c.isEnabled
              ? 'Fingerprint or password to open'
              : 'Ask for a password to open ${_c.appName}',
          trailing: Switch(
            value: _c.isEnabled,
            onChanged: (v) => v ? _turnOn() : _turnOff(),
          ),
          onTap: () => _c.isEnabled ? _turnOff() : _turnOn(),
        ),
        if (_c.isEnabled) ...[
          SettingsTile(
            icon: Icons.fingerprint_rounded,
            title: 'Use fingerprint',
            subtitle: _biometricAvailable
                ? 'Unlock without typing'
                : 'Add a fingerprint in your phone settings first',
            trailing: Switch(
              value: _c.biometricEnabled,
              onChanged:
                  _biometricAvailable ? (v) => _c.setBiometricEnabled(v) : null,
            ),
            onTap: _biometricAvailable
                ? () => _c.setBiometricEnabled(!_c.biometricEnabled)
                : null,
          ),
          SettingsTile(
            icon: Icons.password_rounded,
            title: 'Change password',
            subtitle: _c.canChangePasswordWithBiometric
                ? 'Confirm with your fingerprint'
                : null,
            onTap: _changePassword,
          ),
          SettingsTile(
            icon: Icons.key_rounded,
            title: 'Recovery key',
            subtitle: switch (_hasRecoveryKey) {
              true => 'Set · replace it if you lost it',
              false => 'Not set · resets a forgotten password',
              null => null,
            },
            onTap: _recoveryKey,
          ),
        ],
      ],
    );
  }
}

class _SetupResult {
  const _SetupResult(this.password, this.useBiometric);
  final String password;
  final bool useBiometric;
}

class _SetPasswordScreen extends StatefulWidget {
  const _SetPasswordScreen({
    required this.appName,
    required this.biometricAvailable,
  });

  final String appName;
  final bool biometricAvailable;

  @override
  State<_SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<_SetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _useBiometric = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final pw = _password.text;
    if (pw.length < 6) {
      setState(() => _error = 'Use at least 6 characters.');
      return;
    }
    if (pw != _confirm.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    Navigator.pop(
      context,
      _SetupResult(pw, widget.biometricAvailable && _useBiometric),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set a password'),
        actions: [
          TextButton(onPressed: _submit, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'This password unlocks ${widget.appName}. It is separate from your '
            "phone's PIN, and it is the fallback if fingerprint ever fails — so "
            'pick something you will remember.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _password,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _confirm,
            obscureText: true,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Confirm password',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
          ),
          if (widget.biometricAvailable) ...[
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Also use fingerprint'),
              value: _useBiometric,
              onChanged: (v) => setState(() => _useBiometric = v),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _submit,
            child: const Text('Turn on app lock'),
          ),
        ],
      ),
    );
  }
}

class _ChangeResult {
  const _ChangeResult(this.currentPassword, this.newPassword);
  final String currentPassword;
  final String newPassword;
}

class _ChangePasswordScreen extends StatefulWidget {
  const _ChangePasswordScreen({required this.askCurrent});

  /// False when a fresh fingerprint proves identity instead.
  final bool askCurrent;

  @override
  State<_ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<_ChangePasswordScreen> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (_new.text.length < 6) {
      setState(() => _error = 'Use at least 6 characters.');
      return;
    }
    if (_new.text != _confirm.text) {
      setState(() => _error = 'New passwords do not match.');
      return;
    }
    Navigator.pop(context, _ChangeResult(_old.text, _new.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change password'),
        actions: [
          TextButton(onPressed: _submit, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (widget.askCurrent) ...[
            TextField(
              controller: _old,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Current password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ] else ...[
            Text(
              "You'll confirm with your fingerprint when you save.",
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          TextField(
            controller: _new,
            obscureText: true,
            autofocus: !widget.askCurrent,
            decoration: const InputDecoration(
              labelText: 'New password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _confirm,
            obscureText: true,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Confirm new password',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _submit,
            child: const Text('Change password'),
          ),
        ],
      ),
    );
  }
}
