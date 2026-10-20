import 'package:core_theme/core_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The visual treatment of an [AppTextField].
enum AppFieldStyle {
  /// A soft filled box; the label floats inside it and the edge lights up
  /// in the accent on focus. The default for forms.
  filled,

  /// Bare text over a hairline that thickens into the accent on focus —
  /// for amount entry and dense settings forms.
  underline,

  /// A hairline outline — for fields sitting directly on a filled surface.
  outlined,
}

/// The suite text field: floating label, optional clear button, password
/// reveal, helper and error lines, and three visual styles.
final class AppTextField extends StatefulWidget {
  const AppTextField({
    this.controller,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.fieldStyle = AppFieldStyle.filled,
    this.obscureText = false,
    this.clearable = true,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.inputFormatters,
    this.autofillHints,
    this.prefixIcon,
    this.prefixText,
    this.suffixIcon,
    this.suffixText,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.monospace = false,
    this.textAlign = TextAlign.start,
    this.textStyle,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    super.key,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final AppFieldStyle fieldStyle;

  /// Hides the text and adds a reveal toggle.
  final bool obscureText;

  /// Shows a clear button while the field is focused and non-empty.
  final bool clearable;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final IconData? prefixIcon;
  final String? prefixText;

  /// Replaces the clear/reveal affordances when set.
  final Widget? suffixIcon;
  final String? suffixText;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;

  /// Sets the value in Mona Sans Mono — passwords, codes, keys.
  final bool monospace;
  final TextAlign textAlign;
  final TextStyle? textStyle;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  TextEditingController? _ownController;
  FocusNode? _ownFocus;
  bool _revealed = false;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
    _focus.addListener(_changed);
  }

  @override
  void didUpdateWidget(AppTextField old) {
    super.didUpdateWidget(old);
    final oldController = old.controller ?? _ownController;
    if (oldController != _controller) {
      oldController?.removeListener(_changed);
      _controller.addListener(_changed);
    }
    final oldFocus = old.focusNode ?? _ownFocus;
    if (oldFocus != _focus) {
      oldFocus?.removeListener(_changed);
      _focus.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _focus.removeListener(_changed);
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  Widget? _suffix(SuiteColors c) {
    if (widget.suffixIcon != null) return widget.suffixIcon;
    if (widget.obscureText) {
      return IconButton(
        tooltip: _revealed ? 'Hide' : 'Show',
        onPressed: () => setState(() => _revealed = !_revealed),
        icon: Icon(
          _revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: c.textSecondary,
        ),
      );
    }
    final showClear = widget.clearable &&
        widget.enabled &&
        !widget.readOnly &&
        _focus.hasFocus &&
        _controller.text.isNotEmpty;
    if (!showClear) return null;
    return IconButton(
      tooltip: 'Clear',
      onPressed: () {
        _controller.clear();
        widget.onChanged?.call('');
      },
      icon: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: c.textTertiary.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.close_rounded, size: 13, color: c.textPrimary),
      ),
    );
  }

  InputDecoration _decoration(BuildContext context, SuiteColors c) {
    final theme = Theme.of(context).inputDecorationTheme;
    final radius = BorderRadius.circular(AppSpacing.radiusMd);
    final base = InputDecoration(
      labelText: widget.label,
      hintText: widget.hint,
      helperText: widget.helper,
      errorText: widget.errorText,
      errorMaxLines: 3,
      helperMaxLines: 3,
      prefixIcon:
          widget.prefixIcon == null ? null : Icon(widget.prefixIcon, size: 20),
      prefixText: widget.prefixText,
      suffixText: widget.suffixText,
      suffixIcon: _suffix(c),
      counterText: widget.maxLength == null ? null : '',
    );
    switch (widget.fieldStyle) {
      case AppFieldStyle.filled:
        return base.applyDefaults(theme);
      case AppFieldStyle.underline:
        UnderlineInputBorder line(Color color, double w) =>
            UnderlineInputBorder(
                borderSide: BorderSide(color: color, width: w));
        return base
            .copyWith(
              filled: false,
              contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 10),
              border: line(c.border, 1),
              enabledBorder: line(c.border, 1),
              disabledBorder: line(c.hairline, 1),
              focusedBorder: line(c.accent, 2),
              errorBorder: line(c.negative, 1),
              focusedErrorBorder: line(c.negative, 2),
            )
            .applyDefaults(theme);
      case AppFieldStyle.outlined:
        AppFieldBorder box(Color color, double w) => AppFieldBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: color, width: w),
            );
        return base
            .copyWith(
              filled: true,
              fillColor: c.surface,
              border: box(c.border, 1),
              enabledBorder: box(c.border, 1),
              disabledBorder: box(c.hairline, 1),
              focusedBorder: box(c.accent, 1.5),
              errorBorder: box(c.negative, 1),
              focusedErrorBorder: box(c.negative, 1.5),
            )
            .applyDefaults(theme);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    final style = widget.textStyle ??
        (widget.monospace ? AppTextStyles.code : AppTextStyles.body).copyWith(
          color: widget.enabled ? c.textPrimary : c.textTertiary,
        );
    return TextField(
      controller: _controller,
      focusNode: _focus,
      obscureText: widget.obscureText && !_revealed,
      obscuringCharacter: '•',
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      inputFormatters: widget.inputFormatters,
      autofillHints: widget.autofillHints,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      textAlign: widget.textAlign,
      style: style,
      cursorWidth: 2,
      cursorRadius: const Radius.circular(1),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      decoration: _decoration(context, c),
    );
  }
}

/// The original suite field. Keeps its constructor; renders as a filled
/// [AppTextField] whose label floats inside the field.
final class VaultTextField extends StatelessWidget {
  const VaultTextField({
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.errorText,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? errorText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      hint: hint,
      obscureText: obscureText,
      keyboardType: keyboardType,
      suffixIcon: suffixIcon,
      errorText: errorText,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}
