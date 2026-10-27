import 'dart:math' as math;

import 'package:core_theme/core_theme.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// The one lock-screen composition every Offlyne app uses: on the app's flat
/// background, a single centred column — the app tile, the app name, then
/// the unlock controls — a little above the middle of the screen. An
/// optional [bottom] control (the fingerprint button) sits low in thumb
/// reach, above the "by Offlyne" endorsement.
///
/// [LockScreen] builds on it; apps with their own unlock (a master password,
/// a PIN keypad) pass their controls as [children] so every lock in the
/// suite has the same structure, spacing and type.
///
/// The column is placed by alignment rather than flex spacers so it never
/// depends on intrinsic heights. With the keyboard up the tile shrinks, the
/// gaps tighten and [bottom] and the endorsement step aside, so the field and
/// its button stay above the keyboard and nothing overlaps.
final class LockLayout extends StatefulWidget {
  const LockLayout({
    required this.mark,
    required this.title,
    required this.children,
    this.message,
    this.bottom,
    super.key,
  });

  /// The app tile, usually a `SuiteAppIcon`; drawn at [markSize] whatever
  /// size it was built at.
  final Widget mark;

  /// The app name.
  final String title;

  /// An optional line under the name, only when the screen is not the plain
  /// unlock (e.g. "Reset your password").
  final String? message;

  /// The unlock controls, top to bottom. Space them with [LockLayout.gap].
  final List<Widget> children;

  /// A control pinned low on the screen, usually [LockBiometricButton].
  final Widget? bottom;

  static const double markSize = 64;

  /// The space between stacked unlock controls.
  static const double gap = AppSpacing.smd;

  /// Content never grows wider than this, so tablets keep phone proportions.
  static const double maxWidth = 380;

  @override
  State<LockLayout> createState() => _LockLayoutState();
}

class _LockLayoutState extends State<LockLayout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_enter.isDismissed) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _enter.value = 1;
      } else {
        _enter.forward();
      }
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    const compactMark = 48.0;
    final settle = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.base;
    final entrance = CurvedAnimation(
      parent: _enter,
      curve: AppMotion.emphasized,
    );
    final message = widget.message;
    final bottom = widget.bottom;

    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: LockLayout.maxWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: AnimatedContainer(
              duration: settle,
              curve: AppMotion.standard,
              width: keyboardOpen ? compactMark : LockLayout.markSize,
              height: keyboardOpen ? compactMark : LockLayout.markSize,
              child: FittedBox(child: widget.mark),
            ),
          ),
          AnimatedContainer(
            duration: settle,
            height: keyboardOpen ? AppSpacing.smd : AppSpacing.md,
          ),
          Semantics(
            header: true,
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.h2.copyWith(color: c.textPrimary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary),
            ),
          ],
          AnimatedContainer(
            duration: settle,
            height: keyboardOpen ? AppSpacing.lg : AppSpacing.xl,
          ),
          ...widget.children,
        ],
      ),
    );

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: keyboardOpen,
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: keyboardOpen ? AppSpacing.md : AppSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: box.maxHeight -
                    (keyboardOpen ? AppSpacing.md : AppSpacing.lg) * 2,
              ),
              // y = -0.2 leaves 2 parts of the free space above the column
              // and 3 below: the tile and name sit in the upper middle.
              child: Align(
                alignment: const Alignment(0, -0.2),
                child: AnimatedBuilder(
                  animation: entrance,
                  builder: (context, child) => Opacity(
                    opacity: entrance.value,
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - entrance.value)),
                      child: child,
                    ),
                  ),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: keyboardOpen
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.mdl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (bottom != null) ...[
                      bottom,
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    const SuiteEndorsement(),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Fingerprint unlock as a quiet round icon button (56 dp, tonal accent).
/// The system prompt already starts on its own when the lock appears; this
/// brings it back after the user dismissed it.
final class LockBiometricButton extends StatelessWidget {
  const LockBiometricButton({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  static const double size = 56;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    return Semantics(
      button: true,
      label: 'Unlock with fingerprint',
      excludeSemantics: true,
      child: Tooltip(
        message: 'Unlock with fingerprint',
        child: Material(
          color: c.accentContainer,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox.square(
              dimension: size,
              child: Icon(
                Icons.fingerprint_rounded,
                size: 28,
                color: c.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A quiet centred text link under the unlock controls ("Forgot password?",
/// "Back to unlock").
final class LockTextLink extends StatelessWidget {
  const LockTextLink({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    return Center(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: c.textSecondary,
          minimumSize: const Size(48, AppSpacing.tapTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
        child: Text(label, style: AppTextStyles.label),
      ),
    );
  }
}

/// Shakes [child] sideways each time [trigger] changes — the wrong-secret
/// cue. Under reduced motion it stays still; the error text carries the
/// message on its own.
final class LockShake extends StatefulWidget {
  const LockShake({required this.trigger, required this.child, super.key});

  final int trigger;
  final Widget child;

  @override
  State<LockShake> createState() => _LockShakeState();
}

class _LockShakeState extends State<LockShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void didUpdateWidget(LockShake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger &&
        !MediaQuery.disableAnimationsOf(context)) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _shake,
        builder: (context, child) => Transform.translate(
          offset: Offset(
            math.sin(_shake.value * math.pi * 6) * 8 * (1 - _shake.value),
            0,
          ),
          child: child,
        ),
        child: widget.child,
      );
}

/// A cooldown as a countdown clock: "0:28", "4:05".
String formatLockCountdown(Duration remaining) {
  final total =
      remaining.inSeconds + (remaining.inMilliseconds % 1000 > 0 ? 1 : 0);
  final seconds = (total % 60).toString().padLeft(2, '0');
  return '${total ~/ 60}:$seconds';
}
