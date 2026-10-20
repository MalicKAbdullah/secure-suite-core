import 'package:core_theme/core_theme.dart';
import 'package:core_ui/src/widgets/rows.dart';
import 'package:flutter/material.dart';

/// One choice in an [AppSelectField].
final class AppSelectOption<T> {
  const AppSelectOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// The suite picker: a read-only field in the [AppTextField] filled style
/// that opens a bottom sheet of rows, the current choice ticked in the
/// accent. Replaces a Material dropdown in forms.
final class AppSelectField<T> extends StatelessWidget {
  const AppSelectField({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.placeholder,
    this.errorText,
    this.prefixIcon,
    this.enabled = true,
    super.key,
  });

  final String label;
  final List<AppSelectOption<T>> options;

  /// The selected value; shows [placeholder] when no option carries it.
  final T value;
  final ValueChanged<T> onChanged;
  final String? placeholder;
  final String? errorText;
  final IconData? prefixIcon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = SuiteColors.of(context);
    final selected = options.where((o) => o.value == value).firstOrNull;
    return Semantics(
      button: true,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? () => _open(context) : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InputDecorator(
          isEmpty: selected == null && placeholder == null,
          decoration: InputDecoration(
            labelText: label,
            errorText: errorText,
            errorMaxLines: 3,
            enabled: enabled,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
            suffixIcon: Icon(
              Icons.expand_more_rounded,
              size: 20,
              color: c.textSecondary,
            ),
          ),
          child: Text(
            selected?.label ?? placeholder ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              color: selected == null || !enabled
                  ? c.textTertiary
                  : c.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final picked = await showAppSelectSheet<T>(
      context,
      title: label,
      options: options,
      selected: value,
    );
    if (picked != null) onChanged(picked.value);
  }
}

/// A bottom sheet listing [options] under [title]; resolves to the tapped
/// option, or null when dismissed. The option (not its value) is returned so
/// a null value stays a real choice.
Future<AppSelectOption<T>?> showAppSelectSheet<T>(
  BuildContext context, {
  required String title,
  required List<AppSelectOption<T>> options,
  required T selected,
}) {
  return showModalBottomSheet<AppSelectOption<T>>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final c = SuiteColors.of(context);
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              0,
              AppSpacing.gutter,
              AppSpacing.lg,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.smd),
                child: Text(
                  title,
                  style: AppTextStyles.h3.copyWith(color: c.textPrimary),
                ),
              ),
              RowGroup(
                separatorIndent: AppSpacing.md,
                children: [
                  for (final o in options)
                    AppListRow(
                      title: o.label,
                      dense: true,
                      trailing: o.value == selected
                          ? Icon(Icons.check_rounded, color: c.accent)
                          : null,
                      onTap: () => Navigator.of(context).pop(o),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
