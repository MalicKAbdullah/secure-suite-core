import 'package:core_lock/src/lock_attempt.dart';
import 'package:core_lock/src/lock_controller.dart';
import 'package:flutter/material.dart';

/// Re-confirms the owner before an in-app secret is shown or changed (a
/// backup passphrase reveal, a new recovery key): a fresh fingerprint when
/// biometric unlock is on, otherwise — or if the fingerprint fails — the app
/// password, under the shared attempt cooldown. With the app lock off there
/// is nothing to prove against, so it asks for a deliberate confirmation.
///
/// Wire it to `AutoBackupSection.onRevealGate`:
/// `onRevealGate: () => confirmAppLockIdentity(context, lock, reason: …)`.
Future<bool> confirmAppLockIdentity(
  BuildContext context,
  LockController controller, {
  required String reason,
}) async {
  if (!controller.isEnabled) return _confirm(context, reason);
  if (controller.biometricEnabled &&
      await controller.confirmWithBiometric(reason)) {
    return true;
  }
  if (!context.mounted) return false;
  final password = await askAppLockPassword(context, title: reason);
  if (password == null) return false;
  final result = await controller.verifyPassword(password);
  if (result is LockAttemptSuccess) return true;
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(lockAttemptError(result, wrong: 'Incorrect password.')),
      ),
    );
  }
  return false;
}

/// A dialog asking for the app password; null when cancelled.
Future<String?> askAppLockPassword(
  BuildContext context, {
  required String title,
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        obscureText: true,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Your password'),
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

Future<bool> _confirm(BuildContext context, String title) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: const Text(
          'It will appear on screen. Make sure nobody else can see it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Show'),
          ),
        ],
      ),
    ) ==
    true;
