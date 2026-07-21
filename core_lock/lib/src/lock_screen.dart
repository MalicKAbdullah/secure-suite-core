import 'package:core_lock/src/lock_controller.dart';
import 'package:core_theme/core_theme.dart';
import 'package:flutter/material.dart';

/// Full-screen cover shown while the app is locked. Auto-fires the biometric /
/// credential prompt once per lock (via the controller's latch); the button is
/// always present so it can never flicker away.
final class LockScreen extends StatefulWidget {
  const LockScreen({required this.controller, super.key});

  final LockController controller;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _failed = false;
  bool _busy = false;
  bool? _canAuthenticate;

  LockController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoPrompt());
    _probe();
  }

  Future<void> _probe() async {
    final can = await _c.canAuthenticate();
    if (mounted) setState(() => _canAuthenticate = can);
  }

  Future<void> _autoPrompt() async {
    if (!_c.autoPromptArmed) return;
    await _attempt(auto: true);
  }

  Future<void> _attempt({bool auto = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = auto ? await _c.autoUnlock() : await _c.unlock();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failed = !ok;
    });
  }

  Future<void> _enterWithoutAuth() async {
    if (_busy) return;
    setState(() => _busy = true);
    await _c.unlockWithoutAuth();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unavailable = _canAuthenticate == false;
    final message = unavailable
        ? 'No fingerprint, face, or screen lock is set up on this device. '
            'Your data stays encrypted — you can still enter ${_c.appName}.'
        : _failed
            ? "Unlocking didn't finish. Try again when you're ready."
            : 'Locked to keep your data private.';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
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
                    unavailable ? Icons.lock_outline : Icons.fingerprint,
                    size: 44,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(_c.appName, style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (unavailable)
                  FilledButton.icon(
                    onPressed: _busy ? null : _enterWithoutAuth,
                    icon: const Icon(Icons.lock_open_outlined),
                    label: Text('Enter ${_c.appName}'),
                  )
                else
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _attempt(),
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.fingerprint),
                    label: Text('Unlock ${_c.appName}'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
