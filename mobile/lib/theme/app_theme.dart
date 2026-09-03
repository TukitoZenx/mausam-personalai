import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'weather_palette.dart';

class AppTheme {
  // Re-export palette colors for backward compatibility
  static const Color navyPrimary = MausamPalette.bgPrimary;
  static const Color navyDark = MausamPalette.bgDeep;
  static const Color tealAccent = MausamPalette.accentGreen;
  static const Color tealLight = MausamPalette.accentCyan;
  static const Color backgroundLight = MausamPalette.bgPrimary;
  static const Color surfaceLight = MausamPalette.bgSurface;

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: MausamPalette.bgPrimary,
      primary: MausamPalette.bgPrimary,
      secondary: MausamPalette.accentBlue,
      surface: MausamPalette.bgSurface,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: MausamPalette.bgPrimary,
      canvasColor: MausamPalette.bgDeep,
      appBarTheme: AppBarTheme(
        backgroundColor: MausamPalette.bgDeep,
        foregroundColor: MausamPalette.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: MausamPalette.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: MausamPalette.drawerBg,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MausamPalette.accentBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: MausamPalette.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: MausamPalette.cardBorder, width: 1),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.inter(
          color: MausamPalette.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.inter(
          color: MausamPalette.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          color: MausamPalette.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.inter(
          color: MausamPalette.textSecondary,
          fontSize: 14,
        ),
      ),
    );
  }
}
