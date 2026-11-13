import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FixiColors {
  static const primary = Color(0xFF2F5BFF);
  static const primaryDark = Color(0xFF6F8EFF);
  static const lime = Color(0xFFC6F432);
  static const success = Color(0xFF16B364);
  static const warning = Color(0xFFFFB020);
  static const error = Color(0xFFF04438);
  static const ink = Color(0xFF0E1320);
  static const surfaceLight = Color(0xFFF6F7FB);
  static const surfaceDark = Color(0xFF0B0F1A);
  static const cardDark = Color(0xFF151B2B);

  static Color level(String l) {
    switch (l) {
      case 'plata':
        return const Color(0xFF8E9AAF);
      case 'oro':
        return const Color(0xFFF2A900);
      case 'platino':
        return const Color(0xFF7C5CFF);
      default:
        return const Color(0xFFC77B30);
    }
  }
}

const double rSm = 12, rMd = 16, rLg = 20, rXl = 24;

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final primary = dark ? FixiColors.primaryDark : FixiColors.primary;
  final scheme = ColorScheme.fromSeed(seedColor: FixiColors.primary, brightness: b).copyWith(
    primary: primary,
    onPrimary: dark ? FixiColors.surfaceDark : Colors.white,
    primaryContainer: dark ? const Color(0xFF1E2C66) : const Color(0xFFE3E9FF),
    onPrimaryContainer: dark ? const Color(0xFFDCE3FF) : const Color(0xFF0B1F78),
    secondary: FixiColors.lime,
    onSecondary: FixiColors.ink,
    secondaryContainer: dark ? const Color(0xFF3B4A0C) : const Color(0xFFEBFBB5),
    onSecondaryContainer: dark ? const Color(0xFFE6FFA0) : const Color(0xFF2B3600),
    error: FixiColors.error,
    surface: dark ? FixiColors.cardDark : Colors.white,
    onSurface: dark ? const Color(0xFFF2F4FA) : FixiColors.ink,
    surfaceVariant: dark ? const Color(0xFF1D2438) : const Color(0xFFEBEEF7),
    onSurfaceVariant: dark ? const Color(0xFFA3ACC2) : const Color(0xFF5B6478),
    outline: dark ? const Color(0xFF3A4360) : const Color(0xFFC9CFDF),
    outlineVariant: dark ? const Color(0xFF273049) : const Color(0xFFE3E6F0),
  );

  final base = ThemeData(brightness: b, useMaterial3: true, colorScheme: scheme);
  final body = GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  TextStyle head(TextStyle? s, FontWeight w) => GoogleFonts.plusJakartaSans(textStyle: s, fontWeight: w, color: scheme.onSurface, letterSpacing: -0.3);
  final text = body.copyWith(
    displaySmall: head(body.displaySmall, FontWeight.w800),
    headlineLarge: head(body.headlineLarge, FontWeight.w800),
    headlineMedium: head(body.headlineMedium, FontWeight.w800),
    headlineSmall: head(body.headlineSmall, FontWeight.w800),
    titleLarge: head(body.titleLarge, FontWeight.w700),
    titleMedium: head(body.titleMedium, FontWeight.w700),
    titleSmall: head(body.titleSmall, FontWeight.w700),
  );

  OutlineInputBorder border(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(rMd), borderSide: BorderSide(color: c, width: w));

  return base.copyWith(
    textTheme: text,
    scaffoldBackgroundColor: dark ? FixiColors.surfaceDark : FixiColors.surfaceLight,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
      foregroundColor: scheme.onSurface,
    ),
    cardTheme: CardTheme(
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rLg), side: BorderSide(color: scheme.outlineVariant)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(scheme.outlineVariant),
      enabledBorder: border(scheme.outlineVariant),
      focusedBorder: border(scheme.primary, 2),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error, 2),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(.8)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rMd)),
        textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rMd)),
        textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rSm)),
        textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surface,
      selectedColor: scheme.primary,
      side: BorderSide(color: scheme.outlineVariant),
      labelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      secondaryLabelStyle: text.labelLarge?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w700),
      checkmarkColor: scheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      height: 68,
      labelTextStyle: MaterialStateProperty.resolveWith((s) => GoogleFonts.inter(
          fontSize: 12, fontWeight: s.contains(MaterialState.selected) ? FontWeight.w700 : FontWeight.w500)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFFE8ECF8) : FixiColors.ink,
      contentTextStyle: GoogleFonts.inter(color: dark ? FixiColors.ink : Colors.white, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rMd)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rXl)),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
    splashFactory: InkSparkle.splashFactory,
  );
}
