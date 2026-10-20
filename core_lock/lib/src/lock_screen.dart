import 'dart:async';
import 'dart:math' as math;

import 'package:core_lock/src/lock_controller.dart';
import 'package:core_theme/core_theme.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// Full-screen cover shown while the app is locked. A fingerprint is the
/// primary unlock (auto-prompted once per lock when enabled); the app-set
/// password is always available underneath.
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
    final next = DateTime(now.year, now.month, now.day, now.hour, now.minute)
        .add(const Duration(minutes: 1));
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
    final ok = await _c.unlockWithPassword(value);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) {
        _password.clear();
      } else {
        _error = 'Incorrect password.';
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
    final entrance =
        CurvedAnimation(parent: _enter, curve: AppMotion.emphasized);

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
      body: SafeArea(
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
                              child: FittedBox(child: mark)),
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
                          Icon(Icons.lock_outline_rounded,
                              size: 18, color: c.textTertiary),
                        ],
                      ),
                      8,
                    ),
                    const Spacer(),
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
                    const Spacer(),
                    if (_c.biometricEnabled)
                      rise(
                        _BiometricButton(
                          busy: _busy,
                          onPressed: _busy ? null : _fingerprint,
                        ),
                        24,
                      ),
                    const SizedBox(height: AppSpacing.xl),
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
                    const SizedBox(height: AppSpacing.lg),
                    const SuiteEndorsement(),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The primary unlock: a large fingerprint target on a soft accent disc,
/// with a slow breathing ring while the system prompt is up.
final class _BiometricButton extends StatefulWidget {
  const _BiometricButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback? onPressed;

  @override
  State<_BiometricButton> createState() => _BiometricButtonState();
}

class _BiometricButtonState extends State<_BiometricButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

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
    final animate = widget.busy && !MediaQuery.of(context).disableAnimations;
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
              animation: _pulse,
              builder: (context, child) => CustomPaint(
                painter: _RingPainter(
                  progress: _pulse.value,
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
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 1;
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
      old.progress != progress || old.color != color || old.track != track;
}
