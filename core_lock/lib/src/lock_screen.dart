import 'package:core_lock/src/lock_controller.dart';
import 'package:core_theme/core_theme.dart';
import 'package:flutter/material.dart';

/// Full-screen cover shown while the app is locked. A fingerprint is the
/// primary unlock (auto-prompted once per lock when enabled); the app-set
/// password is always available underneath.
final class LockScreen extends StatefulWidget {
  const LockScreen({required this.controller, super.key});

  final LockController controller;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  LockController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoPrompt());
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _autoPrompt() async {
    if (!_c.autoPromptArmed) return;
    setState(() => _busy = true);
    await _c.autoUnlock();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _fingerprint() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await _c.unlockWithBiometric();
    if (mounted) {
      setState(() {
        _busy = false;
        if (!ok) {
          _error = "Fingerprint didn't match. Try again or use your password.";
        }
      });
    }
  }

  Future<void> _submitPassword() async {
    if (_busy) return;
    final value = _password.text;
    if (value.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await _c.unlockWithPassword(value);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) {
        _password.clear();
      } else {
        _error = 'Incorrect password.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.6),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 44,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(_c.appName, style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Locked to keep your data private.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _submitPassword(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    errorText: _error,
                    suffixIcon: _c.biometricEnabled
                        ? IconButton(
                            tooltip: 'Use fingerprint',
                            onPressed: _busy ? null : _fingerprint,
                            icon: const Icon(Icons.fingerprint),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _submitPassword,
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Unlock ${_c.appName}'),
                  ),
                ),
                if (_c.biometricEnabled) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: _busy ? null : _fingerprint,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Use fingerprint'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
