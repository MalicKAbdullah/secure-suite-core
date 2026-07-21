import 'package:core_lock/src/lock_controller.dart';
import 'package:core_theme/core_theme.dart';
import 'package:flutter/material.dart';

/// Drop-in Settings section for the app lock — identical across every Secure
/// Suite app. Renders the whole flow from a [LockController]:
///
///  * off  → "Require a password to open" switch that opens a set-password
///    form (with an optional "use fingerprint" toggle when available);
///  * on   → the switch turns it off (after confirming the password), plus
///    "Use fingerprint" and "Change password" rows.
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

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _probe() async {
    final can = await _c.canUseBiometric();
    if (mounted) setState(() => _biometricAvailable = can);
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
    _snack('App lock is on.');
  }

  Future<void> _turnOff() async {
    final password =
        await _promptPassword('Turn off app lock', 'Your password');
    if (password == null) return;
    final ok = await _c.disable(password);
    _snack(ok ? 'App lock is off.' : 'Incorrect password.');
  }

  Future<void> _changePassword() async {
    final result = await Navigator.of(context).push<_ChangeResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _ChangePasswordScreen(),
      ),
    );
    if (result == null) return;
    final ok = await _c.changePassword(
      oldPassword: result.oldPassword,
      newPassword: result.newPassword,
    );
    _snack(ok ? 'Password changed.' : 'Current password is incorrect.');
  }

  Future<String?> _promptPassword(String title, String label) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline),
            title: const Text('Require a password to open'),
            subtitle: Text(
              _c.isEnabled
                  ? 'Unlock with your fingerprint or password'
                  : 'Protect ${_c.appName} with a password you set',
            ),
            value: _c.isEnabled,
            onChanged: (v) => v ? _turnOn() : _turnOff(),
          ),
          if (_c.isEnabled) ...[
            const Divider(height: 1),
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Use fingerprint'),
              subtitle: Text(
                _biometricAvailable
                    ? 'Unlock with a fingerprint instead of typing'
                    : 'Add a fingerprint on your device to enable this',
              ),
              value: _c.biometricEnabled,
              onChanged:
                  _biometricAvailable ? (v) => _c.setBiometricEnabled(v) : null,
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.password_outlined),
              title: const Text('Change password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _changePassword,
            ),
          ],
        ],
      ),
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
  const _ChangeResult(this.oldPassword, this.newPassword);
  final String oldPassword;
  final String newPassword;
}

class _ChangePasswordScreen extends StatefulWidget {
  const _ChangePasswordScreen();

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
          TextField(
            controller: _new,
            obscureText: true,
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
