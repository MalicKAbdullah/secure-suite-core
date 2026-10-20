import 'dart:async';
import 'dart:math' as math;

import 'package:core_crypto/core_crypto.dart';
import 'package:core_lock/src/lock_attempt.dart';
import 'package:core_lock/src/lock_controller.dart';
import 'package:core_theme/core_theme.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Full-screen cover shown while the app is locked. A fingerprint is the
/// primary unlock (auto-prompted once per lock when enabled); the app-set
/// password is always available underneath, and "Forgot password?" resets it
/// with the recovery key.
final class LockScreen extends StatefulWidget {
  const LockScreen({required this.controller, this.appMark, super.key});

  final LockController controller;

  /// The app's mark at the top of the screen, usually a `SuiteAppIcon`.
  /// Without one, a tile in the theme accent with a lock glyph is shown.
  final Widget? appMark;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with TickerProviderStateMixin {
  final _password = TextEditingController();
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  )..forward();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  Timer? _tick;
  DateTime _now = DateTime.now();
  bool _busy = false;
  bool _recovering = false;
  String? _error;

  LockController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoPrompt());
    _scheduleTick();
  }

  /// Re-renders the clock on each minute boundary — one timer per minute
  /// rather than a periodic poll.
  void _scheduleTick() {
    final now = DateTime.now();
    final next = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ).add(const Duration(minutes: 1));
    _tick = Timer(next.difference(now), () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _scheduleTick();
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _enter.dispose();
    _shake.dispose();
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
          _shake.forward(from: 0);
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
    final result = await _c.unlockWithPassword(value);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result is LockAttemptSuccess) {
        _password.clear();
      } else {
        _error = lockAttemptError(result, wrong: 'Incorrect password.');
        _shake.forward(from: 0);
      }
    });
  }

  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String get _greeting => switch (_now.hour) {
        < 5 => 'Good night',
        < 12 => 'Good morning',
        < 17 => 'Good afternoon',
        < 22 => 'Good evening',
        _ => 'Good night',
      };

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    final use24h = MediaQuery.maybeAlwaysUse24HourFormatOf(context) ?? false;
    final hour =
        use24h ? _now.hour : (_now.hour % 12 == 0 ? 12 : _now.hour % 12);
    final time = '${use24h ? hour.toString().padLeft(2, '0') : hour}:'
        '${_now.minute.toString().padLeft(2, '0')}';
    final date =
        '${_days[_now.weekday - 1]}, ${_now.day} ${_months[_now.month - 1]}';
    final entrance = CurvedAnimation(
      parent: _enter,
      curve: AppMotion.emphasized,
    );

    Widget rise(Widget child, double from) => AnimatedBuilder(
          animation: entrance,
          builder: (context, child) => Opacity(
            opacity: entrance.value,
            child: Transform.translate(
              offset: Offset(0, from * (1 - entrance.value)),
              child: child,
            ),
          ),
          child: child,
        );

    final mark = widget.appMark ??
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: c.accent,
            borderRadius: BorderRadius.circular(56 * 0.3),
          ),
          child: Icon(Icons.lock_rounded, size: 26, color: c.onAccent),
        );

    final field = AnimatedBuilder(
      animation: _shake,
      builder: (context, child) => Transform.translate(
        offset: Offset(
          math.sin(_shake.value * math.pi * 6) * 8 * (1 - _shake.value),
          0,
        ),
        child: child,
      ),
      child: AppTextField(
        controller: _password,
        label: 'Password',
        obscureText: true,
        autofillHints: const [AutofillHints.password],
        textInputAction: TextInputAction.go,
        errorText: _error,
        onSubmitted: (_) => _submitPassword(),
      ),
    );

    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          // The family mark, oversized and near-invisible, gives the screen
          // texture without showing anything from inside the app.
          Positioned(
            right: -150,
            top: 72,
            child: ExcludeSemantics(
              child: SuiteMark(
                size: 460,
                color: c.accent.withValues(alpha: 0.04),
                accentColor: c.accent.withValues(alpha: 0.08),
                variant: SuiteMarkVariant.accent,
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        rise(
                          Row(
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: FittedBox(child: mark),
                              ),
                              const SizedBox(width: AppSpacing.smd),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _c.appName,
                                      style: AppTextStyles.h4.copyWith(
                                        color: c.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Locked to keep your data private.',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: c.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 18,
                                color: c.textTertiary,
                              ),
                            ],
                          ),
                          8,
                        ),
                        if (_recovering) ...[
                          const SizedBox(height: AppSpacing.xl),
                          _RecoveryPanel(
                            controller: _c,
                            onBack: () => setState(() => _recovering = false),
                          ),
                          const Spacer(),
                        ] else ...[
                          const Spacer(flex: 2),
                          rise(
                            Column(
                              children: [
                                Text(
                                  time,
                                  style: AppTextStyles.heroXL.copyWith(
                                    fontSize: 88,
                                    letterSpacing: -4,
                                    fontWeight: FontWeight.w400,
                                    color: c.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  '$_greeting · $date',
                                  style: AppTextStyles.label.copyWith(
                                    color: c.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            16,
                          ),
                          if (_c.biometricEnabled) ...[
                            const SizedBox(height: AppSpacing.xxl),
                            rise(
                              _BiometricButton(
                                busy: _busy,
                                onPressed: _busy ? null : _fingerprint,
                              ),
                              24,
                            ),
                          ],
                          const Spacer(flex: 2),
                          rise(field, 28),
                          const SizedBox(height: AppSpacing.smd),
                          rise(
                            VaultButton(
                              label: 'Unlock ${_c.appName}',
                              isLoading: _busy,
                              onPressed: _busy ? null : _submitPassword,
                            ),
                            32,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          rise(
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => setState(() {
                                        _error = null;
                                        _recovering = true;
                                      }),
                              child: Text(
                                'Forgot password?',
                                style: AppTextStyles.label.copyWith(
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                            32,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        const SuiteEndorsement(),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Forgot password?": the recovery key plus a new password resets the
/// password and unlocks, under the same attempt cooldown as the password.
final class _RecoveryPanel extends StatefulWidget {
  const _RecoveryPanel({required this.controller, required this.onBack});

  final LockController controller;
  final VoidCallback onBack;

  @override
  State<_RecoveryPanel> createState() => _RecoveryPanelState();
}

class _RecoveryPanelState extends State<_RecoveryPanel> {
  final _key = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final Future<bool> _hasKey = widget.controller.hasRecoveryKey();
  bool _busy = false;
  String? _error;

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
      setState(() => _error = problem);
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
        _error = lockAttemptError(
          result,
          wrong: 'That recovery key is not right.',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    final appName = widget.controller.appName;
    final back = TextButton(
      onPressed: _busy ? null : widget.onBack,
      child: Text(
        'Back to password',
        style: AppTextStyles.label.copyWith(color: c.textSecondary),
      ),
    );
    return FutureBuilder<bool>(
      future: _hasKey,
      builder: (context, snapshot) {
        final hasKey = snapshot.data;
        if (hasKey == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Reset your password',
              style: AppTextStyles.h3.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              hasKey
                  ? 'Enter the recovery key you saved when you set up the '
                      'lock, then choose a new password. Your data stays as '
                      'it is.'
                  : 'No recovery key was set up for $appName, so a '
                      'forgotten password cannot be reset. Unlock with your '
                      'fingerprint, then create a recovery key in Settings.',
              style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary),
            ),
            if (hasKey) ...[
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _key,
                label: 'Recovery key',
                hint: 'XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX',
                monospace: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.smd),
              AppTextField(
                controller: _password,
                label: 'New password',
                obscureText: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.smd),
              AppTextField(
                controller: _confirm,
                label: 'Confirm new password',
                obscureText: true,
                textInputAction: TextInputAction.go,
                errorText: _error,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.smd),
              VaultButton(
                label: 'Reset password and unlock',
                isLoading: _busy,
                onPressed: _busy ? null : _submit,
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            back,
          ],
        );
      },
    );
  }
}

/// The primary unlock: a large fingerprint target on a soft accent disc,
/// that breathes a few times when the screen appears, and a travelling arc
/// while the system prompt is up. The breathing is finite so the screen
/// settles (and `pumpAndSettle` returns); both stop under reduced motion.
final class _BiometricButton extends StatefulWidget {
  const _BiometricButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback? onPressed;

  @override
  State<_BiometricButton> createState() => _BiometricButtonState();
}

class _BiometricButtonState extends State<_BiometricButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _breathed = false;

  @override
  void didUpdateWidget(_BiometricButton old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _sync() {
    final still = MediaQuery.of(context).disableAnimations;
    if (!_breathed && !still) {
      _breathed = true;
      _breath.repeat(reverse: true, count: 6);
    }
    final animate = widget.busy && !still;
    if (animate && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!animate && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    return Semantics(
      button: true,
      label: 'Use fingerprint',
      child: Column(
        children: [
          SizedBox.square(
            dimension: 112,
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulse, _breath]),
              builder: (context, child) => CustomPaint(
                painter: _RingPainter(
                  progress: _pulse.value,
                  breath: Curves.easeInOut.transform(_breath.value),
                  color: c.accent,
                  track: c.border,
                ),
                child: child,
              ),
              child: Center(
                child: Material(
                  color: c.accentContainer,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: widget.onPressed,
                    child: SizedBox.square(
                      dimension: 88,
                      child: Icon(
                        Icons.fingerprint_rounded,
                        size: 44,
                        color: c.accent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.smd),
          Text(
            widget.busy ? 'Waiting for fingerprint…' : 'Use fingerprint',
            style: AppTextStyles.labelStrong.copyWith(color: c.textPrimary),
          ),
        ],
      ),
    );
  }
}

final class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.breath,
    required this.color,
    required this.track,
  });

  final double progress;
  final double breath;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 1;
    if (breath > 0) {
      canvas.drawCircle(
        center,
        44 + (r - 44) * breath,
        Paint()..color = color.withValues(alpha: 0.10 * breath),
      );
    }
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = track,
    );
    if (progress == 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2 + progress * math.pi * 2,
      math.pi * 0.6,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.breath != breath ||
      old.color != color ||
      old.track != track;
}
