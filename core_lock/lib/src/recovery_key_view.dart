import 'package:core_lock/src/lock_controller.dart';
import 'package:core_theme/core_theme.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows a freshly created recovery key exactly once: the key, a copy
/// button, the warning that it is the last way back in, and an "I've saved
/// it" confirmation that enables [onDone].
///
/// Exported for apps with their own lock (e.g. a master-password vault) so
/// every app presents its recovery key the same way.
final class RecoveryKeyView extends StatefulWidget {
  const RecoveryKeyView({
    required this.recoveryKey,
    required this.appName,
    required this.onDone,
    super.key,
  });

  final String recoveryKey;
  final String appName;
  final VoidCallback onDone;

  @override
  State<RecoveryKeyView> createState() => _RecoveryKeyViewState();
}

class _RecoveryKeyViewState extends State<RecoveryKeyView> {
  bool _saved = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.recoveryKey));
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(const SnackBar(content: Text('Recovery key copied.')));
  }

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Icon(Icons.key_rounded, size: 40, color: c.accent),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your recovery key',
              style: AppTextStyles.h2.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'If you forget your ${widget.appName} password and your '
              'fingerprint is not available, this key lets you set a new '
              'password. It is shown only now — ${widget.appName} keeps no '
              'copy.',
              style: AppTextStyles.body.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            VaultCard(
              child: SelectableText(
                widget.recoveryKey,
                key: const ValueKey('recovery-key-text'),
                textAlign: TextAlign.center,
                style: AppTextStyles.codeLarge.copyWith(
                  color: c.textPrimary,
                  letterSpacing: 1.5,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.smd),
            VaultButton(
              label: 'Copy',
              icon: Icons.copy_rounded,
              variant: VaultButtonVariant.secondary,
              onPressed: _copy,
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppBanner(
              kind: BannerKind.warning,
              icon: Icons.warning_amber_rounded,
              title: 'Keep it somewhere safe, away from this phone',
              message: 'Without your password, your fingerprint and this '
                  'recovery key, the app cannot be unlocked and its data '
                  'cannot be recovered.',
            ),
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _saved,
              onChanged: (v) => setState(() => _saved = v ?? false),
              title: const Text("I've saved my recovery key"),
            ),
            const SizedBox(height: AppSpacing.md),
            VaultButton(
              label: 'Done',
              onPressed: _saved ? widget.onDone : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// The one-time offer [AppLockGate] shows after an unlock when the lock has
/// no recovery key yet: create one now, or later from Settings.
final class RecoveryKeyOffer extends StatefulWidget {
  const RecoveryKeyOffer({required this.controller, super.key});

  final LockController controller;

  @override
  State<RecoveryKeyOffer> createState() => _RecoveryKeyOfferState();
}

class _RecoveryKeyOfferState extends State<RecoveryKeyOffer> {
  String? _key;
  bool _busy = false;

  Future<void> _create() async {
    setState(() => _busy = true);
    final key = await widget.controller.createRecoveryKey();
    if (mounted) setState(() => _key = key);
  }

  @override
  Widget build(BuildContext context) {
    final key = _key;
    final c = SuiteColors.of(context);
    final appName = widget.controller.appName;
    if (key != null) {
      return RecoveryKeyView(
        recoveryKey: key,
        appName: appName,
        onDone: widget.controller.finishRecoveryPrompt,
      );
    }
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Icon(Icons.key_rounded, size: 40, color: c.accent),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Set up a recovery key',
                style: AppTextStyles.h2.copyWith(color: c.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'A recovery key lets you reset your $appName password if you '
                'forget it and your fingerprint is not working. Without one, '
                'a forgotten password cannot be reset.',
                style: AppTextStyles.body.copyWith(color: c.textSecondary),
              ),
              const Spacer(),
              VaultButton(
                label: 'Create recovery key',
                isLoading: _busy,
                onPressed: _busy ? null : _create,
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed:
                      _busy ? null : widget.controller.finishRecoveryPrompt,
                  child: const Text('Not now — I can do this in Settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
