import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Mausam PersonalAI — Obsidian Monochrome Visual System
///
/// Black-and-white first, minimal developer-product aesthetic.
/// Deep obsidian base (`#09090B`), elevated cards (`#18181B`), crisp 1px borders (`#27272A`),
/// and high-contrast typography (`#FAFAFA`) with restrained, meaningful semantic accents.
class MausamPalette {
  // ─── Background Spectrum ───
  static const Color bgDeep = Color(0xFF09090B);       // Deepest obsidian background
  static const Color bgPrimary = Color(0xFF0C0C0E);     // Main scaffold bg
  static const Color bgSurface = Color(0xFF141417);    // Elevated surfaces

  // ─── Card Surfaces & Borders ───
  static const Color cardSurface = Color(0xFF18181B);   // Primary card fill
  static const Color cardSurfaceLight = Color(0xFF202024); // Hover/active card variant
  static const Color cardBorder = Color(0xFF27272A);    // Subtle 1px card borders
  static const Color cardBorderSubtle = Color(0xFF1F1F23); // Extremely subtle divider

  // ─── Soft Ambient Card Shadows ───
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 12,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> heroShadow = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 20,
      spreadRadius: -2,
      offset: Offset(0, 8),
    ),
  ];

  /// Soft, wide elevation under the floating navbar. Reads on both light and dark content.
  static const List<BoxShadow> navbarShadow = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 32,
      spreadRadius: 0,
      offset: Offset(0, 14),
    ),
    BoxShadow(
      color: Color(0x3D000000),
      blurRadius: 12,
      spreadRadius: -2,
      offset: Offset(0, 4),
    ),
  ];

  // ─── Typography & Contrast ───
  static const Color textPrimary = Color(0xFFFAFAFA);   // High emphasis white
  static const Color textSecondary = Color(0xFFA1A1AA);  // Medium emphasis muted gray
  static const Color textTertiary = Color(0xFF71717A);   // Low emphasis labels / metadata
  static const Color textMuted = Color(0xFF52525B);      // Disabled / hint text

  // ─── Semantic tokens remapped to grayscale (no decorative RGB) ───
  static const Color accentBlue = Color(0xFFD4D4D8);
  static const Color accentCyan = Color(0xFFE4E4E7);
  static const Color accentOrange = Color(0xFFFAFAFA);
  static const Color accentAmber = Color(0xFFA1A1AA);
  static const Color accentRed = Color(0xFFE4E4E7);
  static const Color accentGreen = Color(0xFFD4D4D8);
  static const Color accentMagenta = Color(0xFFA1A1AA);

  // ─── Persona tokens (monochrome hierarchy, not hue) ───
  static const Color personaFitness = Color(0xFFFAFAFA);
  static const Color personaHealth = Color(0xFFD4D4D8);
  static const Color personaTraveler = Color(0xFFA1A1AA);

  // ─── Glass & Overlay Effects ───
  static const Color glassWhite = Color(0x0CFFFFFF);      // Subtle overlay
  static const Color glassBorder = Color(0x1AFFFFFF);     // Subtle border

  // ─── Drawer & Menu Navigation ───
  static const Color drawerBg = Color(0xFF09090B);
  static const Color drawerDivider = Color(0xFF27272A);
  static const Color drawerActiveItem = Color(0xFF18181B);

  // ─── Hero Gradients (Minimal Atmospheric Dark) ───
  static LinearGradient heroGradient({required int hour, required String condition}) {
    final cond = condition.toLowerCase();
    final rainy = cond.contains('rain') || cond.contains('drizzle') ||
        cond.contains('thunder') || cond.contains('storm');
    final overcast = cond.contains('cloud') || cond.contains('mist') || cond.contains('fog');

    late List<Color> stops;
    if (hour >= 5 && hour < 8) {
      stops = const [Color(0xFF18181B), Color(0xFF1C1C1F), Color(0xFF222226)];
    } else if (hour >= 8 && hour < 17) {
      stops = const [Color(0xFF141417), Color(0xFF18181B), Color(0xFF1F1F23)];
    } else if (hour >= 17 && hour < 20) {
      stops = const [Color(0xFF121214), Color(0xFF18181B), Color(0xFF1C1C1F)];
    } else {
      stops = const [Color(0xFF09090B), Color(0xFF0F0F12), Color(0xFF141417)];
    }

    if (rainy) {
      stops = stops.map((c) => Color.lerp(c, const Color(0xFF0A0A0C), 0.5)!).toList();
    } else if (overcast) {
      stops = stops.map((c) => Color.lerp(c, const Color(0xFF121215), 0.4)!).toList();
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: stops,
    );
  }
}

/// Backward compatibility layer mapping legacy WeatherPalette fields.
class WeatherPalette {
  static const Color navy = MausamPalette.bgSurface;
  static const Color navyDeep = MausamPalette.bgDeep;
  static const Color teal = MausamPalette.accentCyan;
  static const Color sky = MausamPalette.accentBlue;
  static const Color amber = MausamPalette.accentAmber;
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
    fontSize: 68,
    fontWeight: FontWeight.w700,
    color: MausamPalette.textPrimary,
    height: 1.0,
    letterSpacing: -2,
    fontFeatures: tabularFeatures,
  );

  static TextStyle sectionTitle = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: MausamPalette.textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle cardTitle = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: MausamPalette.textPrimary,
    letterSpacing: -0.2,
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
    fontSize: 22,
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
    fontSize: 14,
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
