import 'package:core_theme/src/app_colors.dart';
import 'package:core_theme/src/app_spacing.dart';
import 'package:core_theme/src/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Builds the suite theme. Every app shares the same neutral shell,
/// typography, and component language; each passes its own [AppAccent]
/// for identity (DoseWise teal, Ledgerly indigo, Reflect violet,
/// VaultKey emerald).
abstract final class AppTheme {
  /// Neutral (monochrome) themes — kept for backward compatibility.
  static ThemeData get light => build(Brightness.light);
  static ThemeData get dark => build(Brightness.dark);

  static ThemeData build(
    Brightness brightness, {
    AppAccent accent = AppColors.neutralAccent,
  }) {
    final isDark = brightness == Brightness.dark;
    final accentColor = accent.color(brightness);
    final background = AppColors.background(brightness);
    final surface = AppColors.surface(brightness);
    final border = AppColors.border(brightness);
    final textPrimary = AppColors.textPrimary(brightness);
    final textSecondary = AppColors.textSecondary(brightness);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: accentColor,
      onPrimary: accent.onAccent(brightness),
      primaryContainer: accent.container(brightness),
      onPrimaryContainer: textPrimary,
      secondary: textPrimary,
      onSecondary: surface,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: AppColors.surfaceAlt(brightness),
      onSurfaceVariant: textSecondary,
      error: AppColors.error(brightness),
      onError: isDark ? AppColors.gray950 : AppColors.white,
      outline: border,
      outlineVariant: border,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: AppColors.surface(
        isDark ? Brightness.light : Brightness.dark,
      ),
      onInverseSurface: AppColors.textPrimary(
        isDark ? Brightness.light : Brightness.dark,
      ),
      inversePrimary: accent.color(isDark ? Brightness.light : Brightness.dark),
    );

    final radius = BorderRadius.circular(AppSpacing.borderRadius);
    final radiusLg = BorderRadius.circular(AppSpacing.borderRadiusLg);

    final base = ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: AppTextStyles.fontFamily,
      useMaterial3: true,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: _textTheme(brightness),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.h3.copyWith(color: textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accent.container(brightness),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTextStyles.caption.copyWith(
            color: states.contains(WidgetState.selected)
                ? textPrimary
                : textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? (isDark ? accentColor : accent.light)
                : textSecondary,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radiusLg,
          side: BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: accentColor,
          foregroundColor: accent.onAccent(brightness),
          disabledBackgroundColor: AppColors.surfaceAlt(brightness),
          disabledForegroundColor: AppColors.textTertiary(brightness),
          textStyle: AppTextStyles.labelStrong,
          shape: RoundedRectangleBorder(borderRadius: radius),
          minimumSize: const Size.fromHeight(52),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: surface,
          foregroundColor: textPrimary,
          shadowColor: Colors.transparent,
          textStyle: AppTextStyles.labelStrong,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: border),
          ),
          minimumSize: const Size.fromHeight(52),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          side: BorderSide(color: border),
          foregroundColor: textPrimary,
          textStyle: AppTextStyles.labelStrong,
          shape: RoundedRectangleBorder(borderRadius: radius),
          minimumSize: const Size.fromHeight(52),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? accentColor : accent.light,
          textStyle: AppTextStyles.labelStrong,
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: accent.onAccent(brightness),
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: radiusLg),
        extendedTextStyle: AppTextStyles.labelStrong,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: accent.container(brightness),
        disabledColor: AppColors.surfaceAlt(brightness),
        labelStyle: AppTextStyles.label.copyWith(color: textPrimary),
        secondaryLabelStyle: AppTextStyles.label.copyWith(color: textPrimary),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: 6,
        ),
        showCheckmark: false,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: surface,
          foregroundColor: textSecondary,
          selectedForegroundColor: textPrimary,
          selectedBackgroundColor: accent.container(brightness),
          side: BorderSide(color: border),
          textStyle: AppTextStyles.label,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: AppTextStyles.hint.copyWith(
          color: AppColors.textTertiary(brightness),
        ),
        labelStyle: AppTextStyles.label.copyWith(color: textSecondary),
        floatingLabelStyle: AppTextStyles.label.copyWith(
          color: isDark ? accentColor : accent.light,
        ),
        errorStyle: AppTextStyles.caption.copyWith(
          color: AppColors.error(brightness),
        ),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: accentColor, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: AppColors.error(brightness)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide:
              BorderSide(color: AppColors.error(brightness), width: 1.6),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: radiusLg),
        titleTextStyle: AppTextStyles.h3.copyWith(color: textPrimary),
        contentTextStyle:
            AppTextStyles.bodyMedium.copyWith(color: textSecondary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        showDragHandle: true,
        dragHandleColor: border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.borderRadiusLg + 4),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.gray100 : AppColors.gray900,
        contentTextStyle: AppTextStyles.label.copyWith(
          color: isDark ? AppColors.gray900 : AppColors.gray50,
        ),
        actionTextColor: isDark ? accent.light : accent.dark,
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: radius),
        insetPadding: const EdgeInsets.all(AppSpacing.md),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accent.onAccent(brightness)
              : textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accentColor
              : AppColors.surfaceAlt(brightness),
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : border,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accentColor
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(accent.onAccent(brightness)),
        side: BorderSide(color: textSecondary, width: 1.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accentColor
              : textSecondary,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor: AppColors.surfaceAlt(brightness),
        thumbColor: accentColor,
        overlayColor: accentColor.withValues(alpha: 0.12),
        trackHeight: 4,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accentColor,
        linearTrackColor: AppColors.surfaceAlt(brightness),
        circularTrackColor: AppColors.surfaceAlt(brightness),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        titleTextStyle: AppTextStyles.h4.copyWith(color: textPrimary),
        subtitleTextStyle:
            AppTextStyles.bodySmall.copyWith(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        textStyle: AppTextStyles.label.copyWith(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: border),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: textPrimary,
        unselectedLabelColor: textSecondary,
        labelStyle: AppTextStyles.labelStrong,
        unselectedLabelStyle: AppTextStyles.label,
        indicatorColor: accentColor,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: border,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.gray100 : AppColors.gray900,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        textStyle: AppTextStyles.caption.copyWith(
          color: isDark ? AppColors.gray900 : AppColors.gray50,
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: accent.container(brightness),
        headerForegroundColor: textPrimary,
        shape: RoundedRectangleBorder(borderRadius: radiusLg),
      ),
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final primary = AppColors.textPrimary(brightness);
    final secondary = AppColors.textSecondary(brightness);

    return TextTheme(
      displayLarge: AppTextStyles.displayHuge.copyWith(color: primary),
      displayMedium: AppTextStyles.display.copyWith(color: primary),
      headlineLarge: AppTextStyles.h1.copyWith(color: primary),
      headlineMedium: AppTextStyles.h2.copyWith(color: primary),
      headlineSmall: AppTextStyles.h3.copyWith(color: primary),
      titleLarge: AppTextStyles.h3.copyWith(color: primary),
      titleMedium: AppTextStyles.h4.copyWith(color: primary),
      titleSmall: AppTextStyles.labelStrong.copyWith(color: primary),
      bodyLarge: AppTextStyles.body.copyWith(color: primary),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: primary),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: secondary),
      labelLarge: AppTextStyles.label.copyWith(color: primary),
      labelMedium: AppTextStyles.caption.copyWith(color: secondary),
      labelSmall: AppTextStyles.overline.copyWith(color: secondary),
    );
  }
}
