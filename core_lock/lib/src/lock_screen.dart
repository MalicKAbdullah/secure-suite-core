import 'dart:async';

import 'package:core_crypto/core_crypto.dart';
import 'package:core_lock/src/lock_attempt.dart';
import 'package:core_lock/src/lock_controller.dart';
import 'package:core_lock/src/lock_layout.dart';
import 'package:core_theme/core_theme.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Full-screen cover shown while the app is locked, laid out by [LockLayout].
///
/// The app tile and name, the password field, the Unlock button and a quiet
/// "Forgot password?" link, which swaps in the recovery-key reset. With
/// fingerprint unlock on, the system prompt starts once when the screen
/// appears and a round fingerprint button low on the screen brings it back;
/// without it, the password field is focused.
final class LockScreen extends StatefulWidget {
  const LockScreen({required this.controller, this.appMark, super.key});

  final LockController controller;

  /// The app's tile, usually a `SuiteAppIcon`. Without one, a tile in the
  /// theme accent with a lock glyph is shown.
  final Widget? appMark;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _password = TextEditingController();
  final _focus = FocusNode();
  Timer? _ticker;
  Duration _cooldown = Duration.zero;
  bool _checking = false;
  bool _prompting = false;
  bool _recovering = false;
  String? _error;
  int _failures = 0;

  LockController get _c => widget.controller;
  bool get _coolingDown => _cooldown > Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncCooldown();
      _autoPrompt();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _password.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Reads the persisted cooldown and counts it down once a second.
  Future<void> _syncCooldown() async {
    final remaining = await _c.cooldownRemaining();
    if (!mounted) return;
    _ticker?.cancel();
    setState(() => _cooldown = remaining);
    if (remaining <= Duration.zero) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _cooldown -= const Duration(seconds: 1);
        if (_cooldown <= Duration.zero) {
          _cooldown = Duration.zero;
          _error = null;
          _ticker?.cancel();
        }
      });
    });
  }

  Future<void> _autoPrompt() async {
    if (!_c.autoPromptArmed) return;
    _prompting = true;
    await _c.autoUnlock();
    _prompting = false;
  }

  /// The system prompt shows its own mismatch and cancel feedback, so a
  /// failed or dismissed prompt adds nothing here; the password stays ready.
  Future<void> _fingerprint() async {
    if (_prompting || _checking) return;
    _prompting = true;
    await _c.unlockWithBiometric();
    _prompting = false;
  }

  Future<void> _submitPassword() async {
    final value = _password.text;
    if (_checking || _coolingDown) return;
    if (value.isEmpty) {
      _focus.requestFocus();
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
    });
    final result = await _c.unlockWithPassword(value);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _password.clear();
      if (result is! LockAttemptSuccess) {
        _failures++;
        _error = 'Incorrect password.';
      }
    });
    if (result is! LockAttemptSuccess) {
      await _syncCooldown();
      if (mounted && !_coolingDown) _focus.requestFocus();
    }
  }

  void _openRecovery() => setState(() {
        _error = null;
        _recovering = true;
      });

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    final biometric = _c.biometricEnabled;
    final mark = widget.appMark ??
        Container(
          width: LockLayout.markSize,
          height: LockLayout.markSize,
          decoration: BoxDecoration(
            color: c.accent,
            borderRadius: BorderRadius.circular(
              LockLayout.markSize * SuiteAppIcon.cornerFraction,
            ),
          ),
          child: Icon(Icons.lock_rounded, size: 28, color: c.onAccent),
        );

    final List<Widget> controls;
    if (_recovering) {
      controls = [
        _RecoveryForm(
          controller: _c,
          onBack: () => setState(() => _recovering = false),
          onCooldown: _syncCooldown,
        ),
      ];
    } else {
      final error = _coolingDown
          ? 'Too many attempts. Try again in '
              '${formatLockCountdown(_cooldown)}.'
          : _error;
      controls = [
        LockShake(
          trigger: _failures,
          child: AppTextField(
            controller: _password,
            focusNode: _focus,
            label: 'Password',
            obscureText: true,
            autofocus: !biometric,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.go,
            errorText: error,
            onSubmitted: (_) => _submitPassword(),
          ),
        ),
        const SizedBox(height: LockLayout.gap),
        VaultButton(
          label: 'Unlock',
          isLoading: _checking,
          onPressed: _coolingDown ? null : _submitPassword,
        ),
        // Hidden while typing so it is never cut in half by the keyboard
        // edge on small phones; it returns when the keyboard closes.
        if (MediaQuery.viewInsetsOf(context).bottom == 0) ...[
          const SizedBox(height: AppSpacing.sm),
          LockTextLink(
            label: 'Forgot password?',
            onPressed: _checking ? null : _openRecovery,
          ),
        ],
      ];
    }

    return LockLayout(
      mark: mark,
      title: _c.appName,
      message: _recovering ? 'Reset your password' : null,
      bottom: biometric ? LockBiometricButton(onPressed: _fingerprint) : null,
      children: controls,
    );
  }
}

/// "Forgot password?": the recovery key plus a new password resets the
/// password and unlocks, under the same attempt cooldown as the password.
final class _RecoveryForm extends StatefulWidget {
  const _RecoveryForm({
    required this.controller,
    required this.onBack,
    required this.onCooldown,
  });

  final LockController controller;
  final VoidCallback onBack;
  final Future<void> Function() onCooldown;

  @override
  State<_RecoveryForm> createState() => _RecoveryFormState();
}

class _RecoveryFormState extends State<_RecoveryForm> {
  final _key = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final Future<bool> _hasKey = widget.controller.hasRecoveryKey();
  bool _busy = false;
  String? _error;
  int _failures = 0;

  @override
  void dispose() {
    _key.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final String? problem;
    if (RecoveryKey.normalize(_key.text) == null) {
      problem = 'A recovery key has ${RecoveryKey.length} letters and '
          'numbers, like XXXX-XXXX-…';
    } else if (_password.text.length < 6) {
      problem = 'Use at least 6 characters for the new password.';
    } else if (_password.text != _confirm.text) {
      problem = 'New passwords do not match.';
    } else {
      problem = null;
    }
    if (problem != null) {
      setState(() {
        _error = problem;
        _failures++;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.controller.resetWithRecoveryKey(
      recoveryKey: _key.text,
      newPassword: _password.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result is! LockAttemptSuccess) {
        _failures++;
        _error = lockAttemptError(
          result,
          wrong: 'That recovery key is not right.',
        );
      }
    });
    if (result is! LockAttemptSuccess) await widget.onCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    final appName = widget.controller.appName;
    return FutureBuilder<bool>(
      future: _hasKey,
      builder: (context, snapshot) {
        final hasKey = snapshot.data;
        if (hasKey == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              hasKey
                  ? 'Enter the recovery key you saved, then choose a new '
                      'password. Your data is kept.'
                  : 'No recovery key was set up for $appName, so a '
                      'forgotten password cannot be reset. Unlock with your '
                      'fingerprint, then create a recovery key in Settings.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary),
            ),
            if (hasKey) ...[
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _key,
                label: 'Recovery key',
                hint: 'XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX',
                monospace: true,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: LockLayout.gap),
              AppTextField(
                controller: _password,
                label: 'New password',
                obscureText: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: LockLayout.gap),
              LockShake(
                trigger: _failures,
                child: AppTextField(
                  controller: _confirm,
                  label: 'Confirm new password',
                  obscureText: true,
                  textInputAction: TextInputAction.go,
                  errorText: _error,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(height: LockLayout.gap),
              VaultButton(
                label: 'Reset and unlock',
                isLoading: _busy,
                onPressed: _submit,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            LockTextLink(
              label: 'Back to unlock',
              onPressed: _busy ? null : widget.onBack,
            ),
          ],
        );
      },
    );
  }
}
