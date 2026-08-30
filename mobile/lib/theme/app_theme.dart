import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors — Navy & Teal Palette
  static const Color navyPrimary = Color(0xFF0F172A);
  static const Color navyDark = Color(0xFF020617);
  static const Color tealAccent = Color(0xFF0D9488);
  static const Color tealLight = Color(0xFF14B8A6);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: navyPrimary,
      primary: navyPrimary,
      secondary: tealAccent,
      surface: surfaceLight,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: navyPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tealAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: navyPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: navyPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: navyPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF475569),
          fontSize: 14,
        ),
      ),
    );
  }
}
