import 'package:flutter/material.dart';

/// An accent pair: the brand color for each brightness, plus soft container
/// tints used for chips, badges, and highlighted surfaces.
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

abstract final class AppColors {
  // Monochrome palette
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // Grays (zinc)
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF4F4F5);
  static const Color gray200 = Color(0xFFE4E4E7);
  static const Color gray300 = Color(0xFFD4D4D8);
  static const Color gray400 = Color(0xFFA1A1AA);
  static const Color gray500 = Color(0xFF71717A);
  static const Color gray600 = Color(0xFF52525B);
  static const Color gray700 = Color(0xFF3F3F46);
  static const Color gray800 = Color(0xFF27272A);
  static const Color gray900 = Color(0xFF18181B);
  static const Color gray950 = Color(0xFF0B0B0D);

  // Per-app accents — each app keeps the shared neutral shell but carries
  // its own identity color.
  static const AppAccent tealAccent = AppAccent(
    // DoseWise — health, calm confidence.
    light: Color(0xFF0D9488),
    dark: Color(0xFF2DD4BF),
    containerLight: Color(0xFFCCFBF1),
    containerDark: Color(0xFF134E4A),
    onAccentLight: white,
    onAccentDark: Color(0xFF042F2E),
  );

  static const AppAccent indigoAccent = AppAccent(
    // Ledgerly — professional, financial.
    light: Color(0xFF4F46E5),
    dark: Color(0xFF818CF8),
    containerLight: Color(0xFFE0E7FF),
    containerDark: Color(0xFF312E81),
    onAccentLight: white,
    onAccentDark: Color(0xFF1E1B4B),
  );

  static const AppAccent violetAccent = AppAccent(
    // Reflect — introspective, warm.
    light: Color(0xFF7C3AED),
    dark: Color(0xFFA78BFA),
    containerLight: Color(0xFFEDE9FE),
    containerDark: Color(0xFF4C1D95),
    onAccentLight: white,
    onAccentDark: Color(0xFF2E1065),
  );

  static const AppAccent emeraldAccent = AppAccent(
    // VaultKey — trusted, secure.
    light: Color(0xFF059669),
    dark: Color(0xFF34D399),
    containerLight: Color(0xFFD1FAE5),
    containerDark: Color(0xFF064E3B),
    onAccentLight: white,
    onAccentDark: Color(0xFF022C22),
  );

  static const AppAccent neutralAccent = AppAccent(
    // Fallback — the original monochrome identity.
    light: black,
    dark: white,
    containerLight: gray100,
    containerDark: gray800,
    onAccentLight: white,
    onAccentDark: black,
  );

  // Semantic colors
  static const Color errorLight = Color(0xFFDC2626);
  static const Color errorDark = Color(0xFFF87171);
  static const Color successLight = Color(0xFF16A34A);
  static const Color successDark = Color(0xFF4ADE80);
  static const Color warningLight = Color(0xFFD97706);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color infoLight = Color(0xFF2563EB);
  static const Color infoDark = Color(0xFF60A5FA);

  // Soft semantic containers (badges, banners)
  static const Color errorContainerLight = Color(0xFFFEE2E2);
  static const Color errorContainerDark = Color(0xFF450A0A);
  static const Color successContainerLight = Color(0xFFDCFCE7);
  static const Color successContainerDark = Color(0xFF052E16);
  static const Color warningContainerLight = Color(0xFFFEF3C7);
  static const Color warningContainerDark = Color(0xFF451A03);

  // Theme — light context
  static const Color backgroundLight = gray50;
  static const Color surfaceLight = white;
  static const Color surfaceAltLight = gray100;
  static const Color borderLight = gray200;
  static const Color textPrimaryLight = gray900;
  static const Color textSecondaryLight = gray500;
  static const Color textTertiaryLight = gray400;
  static const Color primaryLight = black;
  static const Color onPrimaryLight = white;

  // Theme — dark context
  static const Color backgroundDark = gray950;
  static const Color surfaceDark = gray900;
  static const Color surfaceAltDark = gray800;
  static const Color borderDark = gray800;
  static const Color textPrimaryDark = gray50;
  static const Color textSecondaryDark = gray400;
  static const Color textTertiaryDark = gray500;
  static const Color primaryDark = white;
  static const Color onPrimaryDark = black;

  static Color background(Brightness brightness) =>
      brightness == Brightness.dark ? backgroundDark : backgroundLight;

  static Color surface(Brightness brightness) =>
      brightness == Brightness.dark ? surfaceDark : surfaceLight;

  static Color surfaceAlt(Brightness brightness) =>
      brightness == Brightness.dark ? surfaceAltDark : surfaceAltLight;

  static Color border(Brightness brightness) =>
      brightness == Brightness.dark ? borderDark : borderLight;

  static Color textPrimary(Brightness brightness) =>
      brightness == Brightness.dark ? textPrimaryDark : textPrimaryLight;

  static Color textSecondary(Brightness brightness) =>
      brightness == Brightness.dark ? textSecondaryDark : textSecondaryLight;

  static Color textTertiary(Brightness brightness) =>
      brightness == Brightness.dark ? textTertiaryDark : textTertiaryLight;

  static Color error(Brightness brightness) =>
      brightness == Brightness.dark ? errorDark : errorLight;

  static Color success(Brightness brightness) =>
      brightness == Brightness.dark ? successDark : successLight;

  static Color warning(Brightness brightness) =>
      brightness == Brightness.dark ? warningDark : warningLight;

  static Color info(Brightness brightness) =>
      brightness == Brightness.dark ? infoDark : infoLight;
}
