import 'package:core_theme/core_theme.dart';
import 'package:flutter/material.dart';

/// An empty state set in type rather than illustration: an optional large
/// figure or icon ring, a headline, a sentence, and the next action.
final class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.title,
    this.message,
    this.icon,
    this.figure,
    this.action,
    this.secondaryAction,
    this.compact = false,
    super.key,
  });

  final String title;
  final String? message;

  /// A glyph inside a hairline ring.
  final IconData? icon;

  /// A large typographic figure ("0", "—", "Rs 0") shown instead of [icon].
  final String? figure;
  final Widget? action;
  final Widget? secondaryAction;

  /// Inline variant for inside cards: tighter, left-aligned.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    final align =
        compact ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final textAlign = compact ? TextAlign.start : TextAlign.center;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align,
      children: [
        if (figure != null) ...[
          Text(
            figure!,
            style: AppTextStyles.heroXL.copyWith(
              color: c.textTertiary.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ] else if (icon != null) ...[
          Container(
            width: compact ? 44 : 64,
            height: compact ? 44 : 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.border),
            ),
            child: Icon(icon, size: compact ? 20 : 26, color: c.textSecondary),
          ),
          SizedBox(height: compact ? AppSpacing.smd : AppSpacing.mdl),
        ],
        Text(
          title,
          textAlign: textAlign,
          style: (compact ? AppTextStyles.h4 : AppTextStyles.h2).copyWith(
            color: c.textPrimary,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              message!,
              textAlign: textAlign,
              style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary),
            ),
          ),
        ],
        if (action != null) ...[
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
          action!,
        ],
        if (secondaryAction != null) ...[
          const SizedBox(height: AppSpacing.sm),
          secondaryAction!,
        ],
      ],
    );
    if (compact) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.mdl),
        child: content,
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: content,
      ),
    );
  }
}

/// The original empty state; renders an [AppEmptyState] with [message] as
/// its headline.
final class VaultEmptyState extends StatelessWidget {
  const VaultEmptyState({
    required this.message,
    this.icon = Icons.lock_outline,
    this.action,
    super.key,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) =>
      AppEmptyState(title: message, icon: icon, action: action);
}

/// A placeholder block that shimmers while content loads. Static when the
/// platform asks for reduced motion.
final class Skeleton extends StatefulWidget {
  const Skeleton({
    this.width,
    this.height = 14,
    this.radius = AppSpacing.radiusXs,
    this.circle = false,
    super.key,
  });

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.shimmer,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = SuiteColors.of(context);
    final base = s.surfaceAlt;
    final glint = Color.lerp(base, s.surface, 0.6)!;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value * 3 - 1;
        return Container(
          width: widget.circle ? widget.height : widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius:
                widget.circle ? null : BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(t - 1, 0),
              end: Alignment(t + 1, 0),
              colors: [base, glint, base],
              stops: const [0.3, 0.5, 0.7],
            ),
          ),
        );
      },
    );
  }
}

/// A skeleton shaped like an [AppListRow] with a leading badge.
final class SkeletonRow extends StatelessWidget {
  const SkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.smd + 1,
      ),
      child: Row(
        children: [
          Skeleton(width: 40, height: 40, radius: 12),
          SizedBox(width: AppSpacing.smd + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                  widthFactor: 0.55,
                  child: Skeleton(height: 13),
                ),
                SizedBox(height: 8),
                FractionallySizedBox(
                  widthFactor: 0.32,
                  child: Skeleton(height: 10),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Skeleton(width: 64, height: 13),
        ],
      ),
    );
  }
}

/// A rounded progress bar. A [value] above 1 renders the overflow in the
/// negative colour (an over-spent budget); [marker] draws a tick at an
/// expected position (where spending should be by today).
final class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    required this.value,
    this.color,
    this.height = 8,
    this.marker,
    super.key,
  });

  final double value;
  final Color? color;
  final double height;
  final double? marker;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    final over = value > 1;
    final fill = over ? c.negative : (color ?? c.accent);
    return Semantics(
      value: '${(value * 100).round()}%',
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: ShapeDecoration(
                    color: c.surfaceAlt,
                    shape: const StadiumBorder(),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: value.clamp(0.0, 1.0)),
                  duration: AppMotion.slow,
                  curve: AppMotion.emphasized,
                  builder: (context, v, _) => Container(
                    width: v == 0 ? 0 : (w * v).clamp(height, w),
                    decoration: ShapeDecoration(
                      color: fill,
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
                if (marker != null)
                  Positioned(
                    left: (w * marker!.clamp(0.0, 1.0)) - 1,
                    top: -3,
                    bottom: -3,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: c.textPrimary,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A single bar split into proportional coloured parts (spending by
/// category, vault health by severity). Parts are separated by a 2 px gap.
final class SegmentedBar extends StatelessWidget {
  const SegmentedBar({
    required this.values,
    this.colors,
    this.height = 10,
    super.key,
  });

  final List<double> values;
  final List<Color>? colors;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    final palette = colors ?? c.chart;
    final total = values.fold<double>(0, (a, b) => a + b);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      // Childless ColoredBoxes size to their minimum, so the bar fills its
      // width and the segments stretch to its height.
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: total <= 0
            ? ColoredBox(color: c.surfaceAlt)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < values.length; i++)
                    if (values[i] > 0)
                      Expanded(
                        flex: (values[i] / total * 1000).round().clamp(1, 1000),
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: i == values.length - 1 ? 0 : 2,
                          ),
                          child: ColoredBox(
                            color: palette[i % palette.length],
                          ),
                        ),
                      ),
                ],
              ),
      ),
    );
  }
}
