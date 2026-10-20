import 'package:flutter/material.dart';

/// An app's identity color for each brightness, plus the soft container
/// tint used for selected chips, badges and highlighted surfaces.
///
/// The suite shell (neutrals, semantics, type) is shared; the accent is the
/// only thing that changes between apps.
@immutable
final class AppAccent {
  const AppAccent({
    required this.light,
    required this.dark,
    required this.containerLight,
    required this.containerDark,
    required this.onAccentLight,
    required this.onAccentDark,
  });

  /// Derives a full accent from one seed color: the seed is used as-is in
  /// light mode, and lifted in lightness for dark mode so it keeps the same
  /// perceived weight on a near-black surface.
  factory AppAccent.fromSeed(Color seed) {
    final hsl = HSLColor.fromColor(seed);
    final dark = hsl
        .withLightness((hsl.lightness + 0.24).clamp(0.0, 0.78))
        .withSaturation((hsl.saturation * 0.95).clamp(0.0, 1.0))
        .toColor();
    return AppAccent(
      light: seed,
      dark: dark,
      containerLight: Color.alphaBlend(
        seed.withValues(alpha: 0.10),
        AppColors.white,
      ),
      containerDark: Color.alphaBlend(
        dark.withValues(alpha: 0.16),
        AppColors.surfaceDark,
      ),
      onAccentLight: AppColors.white,
      onAccentDark: AppColors.backgroundDark,
    );
  }

  final Color light;
  final Color dark;
  final Color containerLight;
  final Color containerDark;
  final Color onAccentLight;
  final Color onAccentDark;

  Color color(Brightness b) => b == Brightness.dark ? dark : light;
  Color container(Brightness b) =>
      b == Brightness.dark ? containerDark : containerLight;
  Color onAccent(Brightness b) =>
      b == Brightness.dark ? onAccentDark : onAccentLight;
}

/// One accent per Secure Suite app. Hues are spread round the cool half of
/// the wheel so any two apps are told apart at a glance, and none sits in
/// the orange/terracotta band.
abstract final class AppAccents {
  /// Budgetly — cobalt.
  static const AppAccent budgetly = AppAccent(
    light: Color(0xFF0F62D6),
    dark: Color(0xFF6AA6FF),
    containerLight: Color(0xFFE7EFFB),
    containerDark: Color(0xFF202C3F),
    onAccentLight: AppColors.white,
    onAccentDark: AppColors.backgroundDark,
  );

  /// Vaultly — violet.
  static const AppAccent vaultly = AppAccent(
    light: Color(0xFF7341E6),
    dark: Color(0xFFB197FF),
    containerLight: Color(0xFFF1ECFC),
    containerDark: Color(0xFF2B2A3F),
    onAccentLight: AppColors.white,
    onAccentDark: AppColors.backgroundDark,
  );

  /// OpenLock — cyan.
  static const AppAccent openlock = AppAccent(
    light: Color(0xFF007E9C),
    dark: Color(0xFF3FD0EE),
    containerLight: Color(0xFFE6F2F5),
    containerDark: Color(0xFF19333C),
    onAccentLight: AppColors.white,
    onAccentDark: AppColors.backgroundDark,
  );

  /// Reflect — berry.
  static const AppAccent reflect = AppAccent(
    light: Color(0xFFC81E5B),
    dark: Color(0xFFFF6B9A),
    containerLight: Color(0xFFFAE8EF),
    containerDark: Color(0xFF38232E),
    onAccentLight: AppColors.white,
    onAccentDark: AppColors.backgroundDark,
  );

  /// Ledgerly — indigo.
  static const AppAccent ledgerly = AppAccent(
    light: Color(0xFF4A4FE0),
    dark: Color(0xFF9298FF),
    containerLight: Color(0xFFEDEDFC),
    containerDark: Color(0xFF262A3F),
    onAccentLight: AppColors.white,
    onAccentDark: AppColors.backgroundDark,
  );

  /// DoseWise — jade.
  static const AppAccent dosewise = AppAccent(
    light: Color(0xFF08805F),
    dark: Color(0xFF3EDDA6),
    containerLight: Color(0xFFE6F2EF),
    containerDark: Color(0xFF193530),
    onAccentLight: AppColors.white,
    onAccentDark: AppColors.backgroundDark,
  );

  /// Warden — lime.
  static const AppAccent warden = AppAccent(
    light: Color(0xFF457A0C),
    dark: Color(0xFFA6E33C),
    containerLight: Color(0xFFECF2E7),
    containerDark: Color(0xFF2A361F),
    onAccentLight: AppColors.white,
    onAccentDark: AppColors.backgroundDark,
  );

  /// Every suite accent, in brand order.
  static const List<AppAccent> all = [
    budgetly,
    vaultly,
    openlock,
    reflect,
    ledgerly,
    dosewise,
    warden,
  ];
}

abstract final class AppColors {
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // Cool neutral ramp ("graphite"): a faint blue cast keeps whites crisp and
  // darks inky without reading as tinted.
  static const Color gray50 = Color(0xFFF6F7F9);
  static const Color gray100 = Color(0xFFEEF0F3);
  static const Color gray200 = Color(0xFFE2E5EA);
  static const Color gray300 = Color(0xFFCDD2DA);
  static const Color gray400 = Color(0xFF9AA2AF);
  static const Color gray500 = Color(0xFF6E7684);
  static const Color gray600 = Color(0xFF4F5663);
  static const Color gray700 = Color(0xFF353A44);
  static const Color gray800 = Color(0xFF22262E);
  static const Color gray900 = Color(0xFF14171C);
  static const Color gray950 = Color(0xFF0A0C10);

  // Legacy accent names, mapped onto the suite accents.
  static const AppAccent tealAccent = AppAccents.dosewise;
  static const AppAccent indigoAccent = AppAccents.ledgerly;
  static const AppAccent violetAccent = AppAccents.reflect;
  static const AppAccent emeraldAccent = AppAccents.vaultly;

  static const AppAccent neutralAccent = AppAccent(
    light: gray900,
    dark: gray50,
    containerLight: gray100,
    containerDark: gray800,
    onAccentLight: white,
    onAccentDark: gray950,
  );

  // Semantics. Money uses positive/negative; success/error are the same hues
  // under their system names.
  static const Color positiveLight = Color(0xFF0E9F55);
  static const Color positiveDark = Color(0xFF3DD68C);
  static const Color negativeLight = Color(0xFFDC3B42);
  static const Color negativeDark = Color(0xFFFF6B70);

  static const Color errorLight = negativeLight;
  static const Color errorDark = negativeDark;
  static const Color successLight = positiveLight;
  static const Color successDark = positiveDark;
  static const Color warningLight = Color(0xFFB58100);
  static const Color warningDark = Color(0xFFF2C14E);
  static const Color infoLight = Color(0xFF1F6FEB);
  static const Color infoDark = Color(0xFF6CB0FF);

  static const Color errorContainerLight = Color(0xFFFDECEC);
  static const Color errorContainerDark = Color(0xFF2A1416);
  static const Color successContainerLight = Color(0xFFE6F6EC);
  static const Color successContainerDark = Color(0xFF0F231A);
  static const Color warningContainerLight = Color(0xFFFBF3DC);
  static const Color warningContainerDark = Color(0xFF261F0E);
  static const Color infoContainerLight = Color(0xFFE8F0FE);
  static const Color infoContainerDark = Color(0xFF111D30);

  // Light shell.
  static const Color backgroundLight = gray50;
  static const Color surfaceLight = white;
  static const Color surfaceAltLight = gray100;
  static const Color borderLight = gray200;
  static const Color hairlineLight = Color(0xFFE8EBEF);
  static const Color textPrimaryLight = Color(0xFF0E1116);
  static const Color textSecondaryLight = Color(0xFF5B6371);
  static const Color textTertiaryLight = Color(0xFF7F8794);
  static const Color primaryLight = textPrimaryLight;
  static const Color onPrimaryLight = white;

  // Dark shell.
  static const Color backgroundDark = gray950;
  static const Color surfaceDark = Color(0xFF12151A);
  static const Color surfaceAltDark = Color(0xFF1B1F26);
  static const Color borderDark = Color(0xFF262B34);
  static const Color hairlineDark = Color(0xFF1F232B);
  static const Color textPrimaryDark = Color(0xFFEDEFF3);
  static const Color textSecondaryDark = Color(0xFF9BA3B1);
  static const Color textTertiaryDark = Color(0xFF687080);
  static const Color primaryDark = textPrimaryDark;
  static const Color onPrimaryDark = gray950;

  static bool _d(Brightness b) => b == Brightness.dark;

  static Color background(Brightness b) =>
      _d(b) ? backgroundDark : backgroundLight;
  static Color surface(Brightness b) => _d(b) ? surfaceDark : surfaceLight;
  static Color surfaceAlt(Brightness b) =>
      _d(b) ? surfaceAltDark : surfaceAltLight;
  static Color border(Brightness b) => _d(b) ? borderDark : borderLight;

  /// Dividers inside a card — one step quieter than [border].
  static Color hairline(Brightness b) => _d(b) ? hairlineDark : hairlineLight;
  static Color textPrimary(Brightness b) =>
      _d(b) ? textPrimaryDark : textPrimaryLight;
  static Color textSecondary(Brightness b) =>
      _d(b) ? textSecondaryDark : textSecondaryLight;
  static Color textTertiary(Brightness b) =>
      _d(b) ? textTertiaryDark : textTertiaryLight;

  static Color positive(Brightness b) => _d(b) ? positiveDark : positiveLight;
  static Color negative(Brightness b) => _d(b) ? negativeDark : negativeLight;
  static Color error(Brightness b) => _d(b) ? errorDark : errorLight;
  static Color success(Brightness b) => _d(b) ? successDark : successLight;
  static Color warning(Brightness b) => _d(b) ? warningDark : warningLight;
  static Color info(Brightness b) => _d(b) ? infoDark : infoLight;

  static Color errorContainer(Brightness b) =>
      _d(b) ? errorContainerDark : errorContainerLight;
  static Color successContainer(Brightness b) =>
      _d(b) ? successContainerDark : successContainerLight;
  static Color warningContainer(Brightness b) =>
      _d(b) ? warningContainerDark : warningContainerLight;
  static Color infoContainer(Brightness b) =>
      _d(b) ? infoContainerDark : infoContainerLight;

  /// Categorical series for charts, starting from the app accent. Ordered so
  /// adjacent slices of a donut never share a hue family.
  static List<Color> chartSeries(Brightness b, AppAccent accent) => [
        accent.color(b),
        _d(b) ? const Color(0xFF7DD3C0) : const Color(0xFF2A9D8F),
        _d(b) ? const Color(0xFFF2C14E) : const Color(0xFFC99A06),
        _d(b) ? const Color(0xFFB197FF) : const Color(0xFF7A5AF8),
        _d(b) ? const Color(0xFFFF8FA3) : const Color(0xFFD6457A),
        _d(b) ? const Color(0xFF8B95A5) : const Color(0xFF7B8494),
      ];
}
