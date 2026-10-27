import 'dart:math' as math;

import 'package:core_theme/core_theme.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// The one lock-screen composition every Offlyne app uses: on the app's flat
/// background, a single centred column — the app tile, the app name, one
/// short line, then the unlock controls — sitting a little below the middle
/// of the screen so it stays in thumb reach, with the "by Offlyne"
/// endorsement at the bottom.
///
/// [LockScreen] builds on it; apps with their own unlock (a master password,
/// a PIN keypad) pass their controls as [children] so every lock in the
/// suite has the same structure, spacing and type.
///
/// The column is placed by alignment rather than flex spacers so it never
/// depends on intrinsic heights. When the keyboard opens the free space
/// collapses first, then the column scrolls; the endorsement steps aside so
/// nothing overlaps.
final class LockLayout extends StatefulWidget {
  const LockLayout({
    required this.mark,
    required this.title,
    required this.message,
    required this.children,
    super.key,
  });

  /// The app tile, usually a `SuiteAppIcon`; drawn at [markSize] whatever
  /// size it was built at.
  final Widget mark;

  /// The app name.
  final String title;

  /// One short line under the name, e.g. "Unlock to continue".
  final String message;

  /// The unlock controls, top to bottom. Space them with [LockLayout.gap].
  final List<Widget> children;

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
    // With the keyboard up the header tightens so the field and its button
    // stay above the keyboard on small phones.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    const compactMark = 48.0;
    final settle = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.base;
    final entrance = CurvedAnimation(
      parent: _enter,
      curve: AppMotion.emphasized,
    );

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
            height: keyboardOpen ? AppSpacing.smd : AppSpacing.mdl,
          ),
          Semantics(
            header: true,
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.h2.copyWith(color: c.textPrimary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary),
          ),
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
              // y = 0.2 splits the free space 3:2 above and below, so the
              // column sits a little below the middle, in thumb reach.
              child: Align(
                alignment: const Alignment(0, 0.2),
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
          : const SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.mdl),
                child: Center(heightFactor: 1, child: SuiteEndorsement()),
              ),
            ),
    );
  }
}

/// The fingerprint unlock: a full-width primary pill. While the system
/// prompt is up it reads "Waiting for fingerprint…" and ignores taps, without
/// greying out, since nothing is wrong.
final class LockFingerprintButton extends StatelessWidget {
  const LockFingerprintButton({
    required this.onPressed,
    this.waiting = false,
    this.variant = VaultButtonVariant.primary,
    super.key,
  });

  final VoidCallback onPressed;
  final bool waiting;

  /// Secondary when a PIN keypad is the main control below it.
  final VaultButtonVariant variant;

  @override
  Widget build(BuildContext context) => VaultButton(
        label: waiting ? 'Waiting for fingerprint…' : 'Use fingerprint',
        icon: Icons.fingerprint_rounded,
        variant: variant,
        onPressed: waiting ? () {} : onPressed,
      );
}

/// A hairline "or" between the fingerprint button and the password field.
final class LockDivider extends StatelessWidget {
  const LockDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    final line = Expanded(child: Container(height: 1, color: c.hairline));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          line,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.smd),
            child: Text(
              'or',
              style: AppTextStyles.caption.copyWith(color: c.textTertiary),
            ),
          ),
          line,
        ],
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
