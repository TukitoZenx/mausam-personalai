import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Mausam PersonalAI — Purple/Lavender Visual System
///
/// Deep violet backgrounds, muted lavender card surfaces,
/// restrained accent colors reserved for weather condition icons only.
class MausamPalette {
  // ─── Background Spectrum ───
  static const Color bgDeep = Color(0xFF1A0E2E);       // Deepest background
  static const Color bgPrimary = Color(0xFF211539);     // Main scaffold bg
  static const Color bgSurface = Color(0xFF2D1B4E);    // Elevated surfaces

  // ─── Card Surfaces ───
  static const Color cardSurface = Color(0xFF362558);   // Primary card fill
  static const Color cardSurfaceLight = Color(0xFF3D2D62); // Lighter card variant
  static const Color cardBorder = Color(0xFF4A3670);    // Subtle card borders

  // ─── Soft Ambient Card Shadows (Craft Polish) ───
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x3D0D0720),
      blurRadius: 16,
      spreadRadius: -2,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> heroShadow = [
    BoxShadow(
      color: Color(0x541A0E2E),
      blurRadius: 24,
      spreadRadius: -4,
      offset: Offset(0, 12),
    ),
  ];

  // ─── Text ───
  static const Color textPrimary = Color(0xFFF0EBF8);   // High emphasis
  static const Color textSecondary = Color(0xFFB8A8D0);  // Medium emphasis
  static const Color textTertiary = Color(0xFF8A78A8);   // Low emphasis / labels
  static const Color textMuted = Color(0xFF6B5A88);      // Disabled / hint

  // ─── Accent (sparingly — icons & condition glyphs only) ───
  static const Color accentBlue = Color(0xFF5B9CF5);     // Clear sky
  static const Color accentCyan = Color(0xFF4DD0E1);     // Snow / ice
  static const Color accentOrange = Color(0xFFFF9E47);   // Sunrise / warm
  static const Color accentMagenta = Color(0xFFE066A0);  // Storm / alert
  static const Color accentGreen = Color(0xFF4ADE80);    // Good AQI / healthy

  // ─── Persona Brand (retained for persona badges only) ───
  static const Color personaFitness = Color(0xFF0D9488);
  static const Color personaHealth = Color(0xFFE066A0);
  static const Color personaTraveler = Color(0xFFFF9E47);

  // ─── Glass Effect ───
  static const Color glassWhite = Color(0x18FFFFFF);      // Glass overlay
  static const Color glassBorder = Color(0x25FFFFFF);     // Glass border

  // ─── Drawer ───
  static const Color drawerBg = Color(0xFF1A0E2E);
  static const Color drawerDivider = Color(0xFF362558);
  static const Color drawerActiveItem = Color(0xFF362558);

  // ─── Hero Gradients ───
  static LinearGradient heroGradient({required int hour, required String condition}) {
    final cond = condition.toLowerCase();
    final rainy = cond.contains('rain') || cond.contains('drizzle') ||
        cond.contains('thunder') || cond.contains('storm');
    final overcast = cond.contains('cloud') || cond.contains('mist') || cond.contains('fog');

    late List<Color> stops;
    if (hour >= 5 && hour < 8) {
      // Dawn
      stops = const [Color(0xFF3D1E6D), Color(0xFF8B3A62), Color(0xFFFF9E47)];
    } else if (hour >= 8 && hour < 17) {
      // Day
      stops = const [Color(0xFF2D1B4E), Color(0xFF3D5A99), Color(0xFF5B9CF5)];
    } else if (hour >= 17 && hour < 20) {
      // Dusk
      stops = const [Color(0xFF1A0E2E), Color(0xFF6B3A6D), Color(0xFFFF9E47)];
    } else {
      // Night
      stops = const [Color(0xFF0D0720), Color(0xFF1A0E2E), Color(0xFF2D1B4E)];
    }

    if (rainy) {
      stops = stops.map((c) => Color.lerp(c, const Color(0xFF0D0720), 0.35)!).toList();
    } else if (overcast) {
      stops = stops.map((c) => Color.lerp(c, const Color(0xFF2D1B4E), 0.25)!).toList();
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: stops,
    );
  }
}

/// Backward compatibility layer mapping legacy WeatherPalette fields to the new purple visual system.
class WeatherPalette {
  static const Color navy = MausamPalette.bgSurface;
  static const Color navyDeep = MausamPalette.bgDeep;
  static const Color teal = MausamPalette.accentCyan;
  static const Color sky = MausamPalette.accentBlue;
  static const Color amber = MausamPalette.accentOrange;
  static const Color background = MausamPalette.bgPrimary;
  static const Color card = MausamPalette.cardSurface;
  static const Color cardBorder = MausamPalette.cardBorder;

  static LinearGradient heroGradient({required int hour, required String condition}) {
    return MausamPalette.heroGradient(hour: hour, condition: condition);
  }
}

/// Typography scale matching the design system with tabular numbers support.
class MausamTypography {
  static const List<FontFeature> tabularFeatures = [FontFeature.tabularFigures()];

  static TextStyle largeTitle = GoogleFonts.inter(
    fontSize: 72,
    fontWeight: FontWeight.w700,
    color: MausamPalette.textPrimary,
    height: 1.0,
    letterSpacing: -2,
    fontFeatures: tabularFeatures,
  );

  static TextStyle sectionTitle = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: MausamPalette.textPrimary,
  );

  static TextStyle cardTitle = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: MausamPalette.textPrimary,
  );

  static TextStyle cardSubtitle = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: MausamPalette.textSecondary,
  );

  static TextStyle bodyRegular = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: MausamPalette.textSecondary,
  );

  static TextStyle bodyBold = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: MausamPalette.textPrimary,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: MausamPalette.textTertiary,
  );

  static TextStyle statValue = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: MausamPalette.textPrimary,
    fontFeatures: tabularFeatures,
  );

  static TextStyle statLabel = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: MausamPalette.textTertiary,
  );

  static TextStyle hourlyTemp = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: MausamPalette.textPrimary,
    fontFeatures: tabularFeatures,
  );

  static TextStyle hourlyTime = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: MausamPalette.textTertiary,
    fontFeatures: tabularFeatures,
  );

  /// Helper to apply tabular figures to any custom text style
  static TextStyle tabular(TextStyle base) {
    return base.copyWith(fontFeatures: [
      ...?base.fontFeatures,
      const FontFeature.tabularFigures(),
    ]);
  }
}
