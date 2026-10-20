import 'package:core_theme/core_theme.dart';
import 'package:flutter/material.dart';

/// A pill search field: magnifier, clear button, optional trailing action
/// (a filter or sort button).
final class AppSearchField extends StatefulWidget {
  const AppSearchField({
    this.controller,
    this.hint = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.trailing,
    this.autofocus = false,
    this.focusNode,
    super.key,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  TextEditingController? _own;
  FocusNode? _ownFocus;

  TextEditingController get _c =>
      widget.controller ?? (_own ??= TextEditingController());
  FocusNode get _f => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _c.addListener(_changed);
    _f.addListener(_changed);
  }

  @override
  void dispose() {
    _c.removeListener(_changed);
    _f.removeListener(_changed);
    _own?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    final focused = _f.hasFocus;
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      height: 48,
      decoration: ShapeDecoration(
        color: focused ? c.surface : c.surfaceAlt,
        shape: StadiumBorder(
          side: BorderSide(
            color: focused ? c.accent : Colors.transparent,
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(Icons.search_rounded, size: 20, color: c.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _c,
              focusNode: _f,
              autofocus: widget.autofocus,
              textInputAction: TextInputAction.search,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              style: AppTextStyles.body.copyWith(color: c.textPrimary),
              cursorWidth: 2,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppTextStyles.body.copyWith(color: c.textTertiary),
                filled: false,
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          if (_c.text.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              onPressed: () {
                _c.clear();
                widget.onChanged?.call('');
              },
              icon: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: c.textTertiary.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.close_rounded, size: 13, color: c.textPrimary),
              ),
            )
          else if (widget.trailing == null)
            const SizedBox(width: 16),
          if (widget.trailing != null) ...[
            widget.trailing!,
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

/// One option of an [AppSegmentedControl].
@immutable
final class AppSegment<T> {
  const AppSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// An iOS-style segmented control: equal segments on a recessed pill track,
/// with a raised thumb that slides to the selection.
final class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.height = 40,
    super.key,
  });

  final List<AppSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final index = segments.indexWhere((s) => s.value == selected);
    final n = segments.length;
    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: ShapeDecoration(
        color: c.surfaceAlt,
        shape: const StadiumBorder(),
      ),
      child: Stack(
        children: [
          if (index >= 0)
            AnimatedAlign(
              duration: AppMotion.base,
              curve: AppMotion.settle,
              alignment: Alignment(n == 1 ? 0 : -1 + 2 * index / (n - 1), 0),
              child: FractionallySizedBox(
                widthFactor: 1 / n,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: dark ? AppColors.gray700 : c.surface,
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: dark ? Colors.transparent : c.border,
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Row(
            children: [
              for (final s in segments)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: s.value == selected,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(s.value),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (s.icon != null) ...[
                              Icon(
                                s.icon,
                                size: 16,
                                color: s.value == selected
                                    ? c.textPrimary
                                    : c.textSecondary,
                              ),
                              const SizedBox(width: 6),
                            ],
                            AnimatedDefaultTextStyle(
                              duration: AppMotion.fast,
                              style: AppTextStyles.labelStrong.copyWith(
                                color: s.value == selected
                                    ? c.textPrimary
                                    : c.textSecondary,
                              ),
                              child: Text(s.label, maxLines: 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A pill filter/choice chip. Selected chips invert to ink, so selection
/// reads without leaning on the accent colour.
final class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.count,
    this.color,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  /// A trailing tally ("Food 12").
  final int? count;

  /// A category dot before the label.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    final fg = selected ? c.surface : c.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: ShapeDecoration(
              color: selected ? c.textPrimary : c.surface,
              shape: StadiumBorder(
                side: BorderSide(
                  color: selected ? c.textPrimary : c.border,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (color != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (icon != null) ...[
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: AppTextStyles.numberSmall.copyWith(
                      color: selected
                          ? c.surface.withValues(alpha: 0.7)
                          : c.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
