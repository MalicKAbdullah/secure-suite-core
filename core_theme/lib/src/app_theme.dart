import 'package:core_theme/src/app_colors.dart';
import 'package:core_theme/src/app_spacing.dart';
import 'package:core_theme/src/app_text_styles.dart';
import 'package:core_theme/src/suite_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Builds the suite theme. Every app shares the same cool-neutral shell,
/// typography, and flat hairline component language; each passes its own
/// [AppAccent] (see [AppAccents]) for identity.
abstract final class AppTheme {
  /// Neutral (ink) themes.
  static ThemeData get light => build(Brightness.light);
  static ThemeData get dark => build(Brightness.dark);

  /// A theme whose accent is derived from a single [seed] colour.
  static ThemeData seeded(Brightness brightness, Color seed) =>
      build(brightness, accent: AppAccent.fromSeed(seed));

  static ThemeData build(
    Brightness brightness, {
    AppAccent accent = AppColors.neutralAccent,
  }) {
    final isDark = brightness == Brightness.dark;
    final accentColor = accent.color(brightness);
    final onAccent = accent.onAccent(brightness);
    final background = AppColors.background(brightness);
    final surface = AppColors.surface(brightness);
    final surfaceAlt = AppColors.surfaceAlt(brightness);
    final border = AppColors.border(brightness);
    final hairline = AppColors.hairline(brightness);
    final textPrimary = AppColors.textPrimary(brightness);
    final textSecondary = AppColors.textSecondary(brightness);
    final textTertiary = AppColors.textTertiary(brightness);
    final error = AppColors.error(brightness);
    final inverse = isDark ? Brightness.light : Brightness.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: accentColor,
      onPrimary: onAccent,
      primaryContainer: accent.container(brightness),
      onPrimaryContainer: textPrimary,
      secondary: textPrimary,
      onSecondary: surface,
      // Every container/tertiary role is set explicitly: the raw
      // ColorScheme() constructor falls back to secondary/primary for unset
      // roles, which paints text in its own background colour on widgets
      // that read secondaryContainer (Card, ListTile).
      secondaryContainer: surfaceAlt,
      onSecondaryContainer: textPrimary,
      tertiary: accentColor,
      onTertiary: onAccent,
      tertiaryContainer: accent.container(brightness),
      onTertiaryContainer: textPrimary,
      surface: surface,
      onSurface: textPrimary,
      surfaceDim: background,
      surfaceBright: surface,
      surfaceContainerLowest: surface,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: surfaceAlt,
      surfaceContainerHighest: surfaceAlt,
      onSurfaceVariant: textSecondary,
      error: error,
      onError: isDark ? AppColors.gray950 : AppColors.white,
      errorContainer: AppColors.errorContainer(brightness),
      onErrorContainer: textPrimary,
      outline: border,
      outlineVariant: hairline,
      shadow: Colors.black,
      scrim: Colors.black.withValues(alpha: isDark ? 0.6 : 0.36),
      inverseSurface: AppColors.textPrimary(brightness),
      onInverseSurface: AppColors.surface(brightness),
      inversePrimary: accent.color(inverse),
    );

    final base = ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      fontFamily: AppTextStyles.fontFamily,
      useMaterial3: true,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [SuiteColors.from(brightness, accent)],
    );

    final radius = BorderRadius.circular(AppSpacing.radiusMd);
    final radiusLg = BorderRadius.circular(AppSpacing.radiusLg);
    const pill = StadiumBorder();
    WidgetStateProperty<T> sel<T>(T on, T off) =>
        WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? on : off,
        );
    OutlineInputBorder field(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: c, width: w),
        );

    return base.copyWith(
      textTheme: _textTheme(brightness),
      primaryTextTheme: _textTheme(brightness),
      dividerColor: hairline,
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
        titleSpacing: AppSpacing.gutter,
        toolbarHeight: 60,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.h3.copyWith(color: textPrimary),
        iconTheme: IconThemeData(color: textPrimary, size: 22),
        actionsIconTheme: IconThemeData(color: textPrimary, size: 22),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accent.container(brightness),
        indicatorShape: pill,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => AppTextStyles.caption.copyWith(
            color:
                s.contains(WidgetState.selected) ? textPrimary : textTertiary,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color:
                s.contains(WidgetState.selected) ? accentColor : textTertiary,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: accent.container(brightness),
        selectedIconTheme: IconThemeData(color: accentColor),
        unselectedIconTheme: IconThemeData(color: textTertiary),
      ),
      dividerTheme: DividerThemeData(
        color: hairline,
        thickness: AppSpacing.hairline,
        space: AppSpacing.hairline,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radiusLg,
          side: BorderSide(color: hairline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: accentColor,
          foregroundColor: onAccent,
          disabledBackgroundColor: surfaceAlt,
          disabledForegroundColor: textTertiary,
          textStyle: AppTextStyles.button,
          shape: pill,
          minimumSize: const Size(64, AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: surfaceAlt,
          foregroundColor: textPrimary,
          shadowColor: Colors.transparent,
          textStyle: AppTextStyles.button,
          shape: pill,
          minimumSize: const Size(64, AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          side: BorderSide(color: border),
          foregroundColor: textPrimary,
          textStyle: AppTextStyles.button,
          shape: pill,
          minimumSize: const Size(64, AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          textStyle: AppTextStyles.labelStrong,
          shape: pill,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.smd),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: textPrimary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: onAccent,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.mdl),
        ),
        extendedTextStyle: AppTextStyles.button,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: textPrimary,
        disabledColor: surfaceAlt,
        labelStyle: AppTextStyles.label.copyWith(color: textPrimary),
        secondaryLabelStyle: AppTextStyles.label.copyWith(
          color: AppColors.surface(brightness),
        ),
        side: BorderSide(color: border),
        shape: pill,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.smd,
          vertical: AppSpacing.sm,
        ),
        showCheckmark: false,
        elevation: 0,
        pressElevation: 0,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: sel(textPrimary, surface),
          foregroundColor: sel(surface, textSecondary),
          side: WidgetStatePropertyAll(BorderSide(color: border)),
          textStyle: const WidgetStatePropertyAll(AppTextStyles.labelStrong),
          shape: const WidgetStatePropertyAll(pill),
          minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(surfaceAlt),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: const WidgetStatePropertyAll(pill),
        side: WidgetStateProperty.resolveWith(
          (s) => BorderSide(
            color: s.contains(WidgetState.focused)
                ? accentColor
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        constraints: const BoxConstraints(minHeight: 48),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
        textStyle: WidgetStatePropertyAll(
          AppTextStyles.body.copyWith(color: textPrimary),
        ),
        hintStyle: WidgetStatePropertyAll(
          AppTextStyles.body.copyWith(color: textTertiary),
        ),
      ),
      searchViewTheme: SearchViewThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        dividerColor: hairline,
        headerTextStyle: AppTextStyles.body.copyWith(color: textPrimary),
        headerHintStyle: AppTextStyles.body.copyWith(color: textTertiary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        hoverColor: Colors.transparent,
        isDense: false,
        hintStyle: AppTextStyles.hint.copyWith(color: textTertiary),
        labelStyle: AppTextStyles.body.copyWith(color: textSecondary),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (s) => AppTextStyles.label.copyWith(
            color: s.contains(WidgetState.error)
                ? error
                : s.contains(WidgetState.focused)
                    ? accentColor
                    : textSecondary,
          ),
        ),
        helperStyle: AppTextStyles.caption.copyWith(color: textSecondary),
        errorStyle: AppTextStyles.caption.copyWith(color: error),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        contentPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md + 2,
          AppSpacing.md,
          AppSpacing.md - 2,
        ),
        border: field(Colors.transparent),
        enabledBorder: field(Colors.transparent),
        disabledBorder: field(Colors.transparent),
        focusedBorder: field(accentColor, 1.5),
        errorBorder: field(error),
        focusedErrorBorder: field(error, 1.5),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accentColor,
        selectionColor: accentColor.withValues(alpha: 0.24),
        selectionHandleColor: accentColor,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        titleTextStyle: AppTextStyles.h3.copyWith(color: textPrimary),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: textSecondary,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: border,
        dragHandleSize: const Size(36, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: AppTextStyles.label.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radius),
        insetPadding: const EdgeInsets.all(AppSpacing.md),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: sel(onAccent, isDark ? AppColors.gray400 : AppColors.white),
        trackColor:
            sel(accentColor, isDark ? AppColors.gray700 : AppColors.gray300),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        trackOutlineWidth: const WidgetStatePropertyAll(0),
        thumbIcon: const WidgetStatePropertyAll(null),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: sel(accentColor, Colors.transparent),
        checkColor: WidgetStatePropertyAll(onAccent),
        side: BorderSide(color: textTertiary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        ),
      ),
      radioTheme: RadioThemeData(fillColor: sel(accentColor, textTertiary)),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor: surfaceAlt,
        thumbColor: accentColor,
        overlayColor: accentColor.withValues(alpha: 0.10),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
        valueIndicatorColor: scheme.inverseSurface,
        valueIndicatorTextStyle: AppTextStyles.numberSmall.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accentColor,
        linearTrackColor: surfaceAlt,
        circularTrackColor: surfaceAlt,
        linearMinHeight: 6,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        titleTextStyle: AppTextStyles.body.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
        subtitleTextStyle: AppTextStyles.bodySmall.copyWith(
          color: textSecondary,
        ),
        leadingAndTrailingTextStyle: AppTextStyles.number.copyWith(
          color: textPrimary,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        minVerticalPadding: AppSpacing.smd,
        horizontalTitleGap: AppSpacing.smd,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: textSecondary,
        collapsedIconColor: textSecondary,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        textStyle: AppTextStyles.label.copyWith(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: border),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          side: WidgetStatePropertyAll(BorderSide(color: border)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: radius),
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: textPrimary,
        unselectedLabelColor: textTertiary,
        labelStyle: AppTextStyles.labelStrong,
        unselectedLabelStyle: AppTextStyles.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: textPrimary, width: 2),
          borderRadius: BorderRadius.circular(2),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: hairline,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        textStyle: AppTextStyles.caption.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: accentColor,
        textColor: onAccent,
        textStyle: AppTextStyles.caption,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        headerBackgroundColor: surface,
        headerForegroundColor: textPrimary,
        dividerColor: hairline,
        todayBorder: BorderSide(color: accentColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final primary = AppColors.textPrimary(brightness);
    final secondary = AppColors.textSecondary(brightness);

    return TextTheme(
      displayLarge: AppTextStyles.displayHuge.copyWith(color: primary),
      displaySmall: AppTextStyles.h1.copyWith(color: primary),
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
      labelLarge: AppTextStyles.labelStrong.copyWith(color: primary),
      labelMedium: AppTextStyles.caption.copyWith(color: secondary),
      labelSmall: AppTextStyles.overline.copyWith(color: secondary),
    );
  }
}
