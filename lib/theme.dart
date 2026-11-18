import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colours from the approved Figma mockup (red and maroon theme).
class CnnoColors {
  CnnoColors._();
  static const primary = Color(0xFFA3162F);
  static const maroon = Color(0xFF7A1126);
  static const stripe = Color(0xFFC42D4A);
  static const background = Color(0xFFFFF7F5);
  static const text = Color(0xFF5A0F20);
  static const softPink = Color(0xFFF8E1E5);
  static const muted = Color(0xFF8C6B71);
  static const available = Color(0xFF5E7A3F);
  static const availableBg = Color(0xFFE7EEDD);
  static const card = Colors.white;
}

/// The font is not decided yet (client asked for changes on 5 Nov).
/// Inter is the placeholder from the mockup: change it here only.
TextTheme _textTheme(TextTheme base) => GoogleFonts.interTextTheme(base);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: CnnoColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: CnnoColors.primary,
    onPrimary: Colors.white,
    secondary: CnnoColors.maroon,
    onSecondary: Colors.white,
    surface: CnnoColors.background,
    onSurface: CnnoColors.text,
    primaryContainer: CnnoColors.softPink,
    onPrimaryContainer: CnnoColors.text,
    outline: CnnoColors.softPink,
  );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final text = _textTheme(base.textTheme).apply(
    bodyColor: CnnoColors.text,
    displayColor: CnnoColors.text,
  );

  final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

  return base.copyWith(
    scaffoldBackgroundColor: CnnoColors.background,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: CnnoColors.background,
      foregroundColor: CnnoColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: rounded,
        textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: rounded,
        side: const BorderSide(color: CnnoColors.primary, width: 1.5),
        foregroundColor: CnnoColors.primary,
        textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: Color(0xFFB9A2A7)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: CnnoColors.softPink),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: CnnoColors.softPink),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: CnnoColors.primary, width: 1.5),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: CnnoColors.softPink,
      selectedColor: CnnoColors.primary,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: text.labelLarge?.copyWith(color: CnnoColors.text),
      secondaryLabelStyle: text.labelLarge?.copyWith(color: Colors.white),
      showCheckmark: false,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: CnnoColors.maroon,
    ),
  );
}
