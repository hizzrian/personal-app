import 'package:flutter/material.dart';

class AppTheme {
  // Shared colors
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF3525CD);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFE2DFFF);
  static const Color primaryContainerDark = Color(0xFF2E2670);

  static const Color secondary = Color(0xFF00687A);
  static const Color secondaryContainer = Color(0xFF57DFFE);
  static const Color tertiary = Color(0xFF7E3000);
  static const Color tertiaryContainer = Color(0xFFFFDBCC);

  static const Color error = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFEAB308);

  // Light theme colors
  static const Color background = Color(0xFFF9F9FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFE7EEFE);
  static const Color surfaceContainerLow = Color(0xFFF0F3FF);
  static const Color surfaceContainerHigh = Color(0xFFE2E8F8);
  static const Color onSurface = Color(0xFF151C27);
  static const Color onSurfaceVariant = Color(0xFF464555);
  static const Color outline = Color(0xFF777587);
  static const Color outlineVariant = Color(0xFFC7C4D8);

  // Dark theme colors
  static const Color backgroundDark = Color(0xFF0F0F1A);
  static const Color surfaceDark = Color(0xFF1A1A2E);
  static const Color surfaceContainerDark = Color(0xFF22223A);
  static const Color surfaceContainerLowDark = Color(0xFF16162A);
  static const Color surfaceContainerHighDark = Color(0xFF2A2A44);
  static const Color onSurfaceDark = Color(0xFFE8E8F0);
  static const Color onSurfaceVariantDark = Color(0xFFA0A0B8);
  static const Color outlineDark = Color(0xFF6E6E88);
  static const Color outlineVariantDark = Color(0xFF3A3A55);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryContainer,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: 'Inter', color: primary, fontSize: 20, fontWeight: FontWeight.w700),
        iconTheme: IconThemeData(color: onSurfaceVariant),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFF3F4F6))),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLow,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 1.5)),
        hintStyle: const TextStyle(color: outline, fontSize: 14, fontFamily: 'Inter'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Inter'),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary, textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Inter')),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerLow,
        selectedColor: primaryContainer,
        labelStyle: const TextStyle(color: onSurfaceVariant, fontSize: 12, fontFamily: 'Inter'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: outlineVariant.withValues(alpha: 0.3)),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFF3F4F6), thickness: 1, space: 0),
      dialogTheme: DialogThemeData(backgroundColor: surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: onSurface,
        contentTextStyle: const TextStyle(color: surface, fontSize: 13, fontFamily: 'Inter'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundDark,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.dark(
        primary: primary,
        primaryContainer: primaryContainerDark,
        surface: surfaceDark,
        onSurface: onSurfaceDark,
        onSurfaceVariant: onSurfaceVariantDark,
        outline: outlineDark,
        outlineVariant: outlineVariantDark,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: 'Inter', color: primary, fontSize: 20, fontWeight: FontWeight.w700),
        iconTheme: IconThemeData(color: onSurfaceVariantDark),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: outlineVariantDark)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLowDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 1.5)),
        hintStyle: const TextStyle(color: outlineDark, fontSize: 14, fontFamily: 'Inter'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Inter'),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary, textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Inter')),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerLowDark,
        selectedColor: primaryContainerDark,
        labelStyle: const TextStyle(color: onSurfaceVariantDark, fontSize: 12, fontFamily: 'Inter'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: outlineVariantDark),
      ),
      dividerTheme: const DividerThemeData(color: outlineVariantDark, thickness: 1, space: 0),
      dialogTheme: DialogThemeData(backgroundColor: surfaceDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: onSurfaceDark,
        contentTextStyle: const TextStyle(color: surfaceDark, fontSize: 13, fontFamily: 'Inter'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
