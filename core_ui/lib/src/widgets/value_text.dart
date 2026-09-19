import 'package:flutter/material.dart';

/// A number that shrinks to fit rather than losing digits.
///
/// Money is the one kind of text that must never be truncated: "Rs 123,4…"
/// is not a smaller version of the amount, it is a different number. An
/// ellipsis on a label costs the reader a word; on a balance it costs them
/// the meaning of the screen.
///
/// So this scales the text down until it fits and never past its natural
/// size, which keeps a row of figures visually consistent while guaranteeing
/// every digit survives. [minScale] stops the shrinking before the number
/// becomes unreadable — past that the caller has given it too little room and
/// should change the layout instead of hiding the problem.
///
/// Needs a bounded width, so it belongs inside an `Expanded`, `Flexible`, or a
/// sized box; in an unbounded `Row` it lays out at full size like any `Text`.
final class ValueText extends StatelessWidget {
  const ValueText(
    this.text, {
    this.style,
    this.color,
    this.alignment = AlignmentDirectional.centerStart,
    this.minScale = 0.6,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final Color? color;

  /// Where the number sits once it is smaller than the space it was given.
  final AlignmentGeometry alignment;

  /// Smallest fraction of the natural size this will shrink to.
  final double minScale;

  @override
  Widget build(BuildContext context) {
    final resolved = (style ?? DefaultTextStyle.of(context).style).copyWith(
      color: color,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final child = Text(
          text,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: resolved,
        );
        if (!constraints.hasBoundedWidth) return child;

        final painter = TextPainter(
          text: TextSpan(text: text, style: resolved),
          maxLines: 1,
          textDirection: Directionality.of(context),
        )..layout();
        final natural = painter.width;
        painter.dispose();

        // Already fits, or the floor is reached: hand the text over as is and
        // let FittedBox do nothing rather than round-tripping through a scale.
        if (natural <= constraints.maxWidth || natural == 0) {
          return Align(alignment: alignment, child: child);
        }
        final scale = constraints.maxWidth / natural;
        if (scale >= minScale) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignment,
            child: child,
          );
        }
        // Below the floor the number would be unreadable, so it is rendered at
        // the floor and allowed to clip — a visible overflow the layout should
        // be fixed for, not a silently wrong figure.
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment,
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: resolved.copyWith(
              fontSize: (resolved.fontSize ?? 14) * minScale,
            ),
          ),
        );
      },
    );
  }
}
