import 'package:flutter/material.dart' show Color, Colors;

// ─────────────────────────────────────────────────────────────────────────────
// MAUSAM — Environment Theme System
// Central source-of-truth for time-of-day background system & wallpaper themes.
//
// Provides:
//   • TimeOfDayPeriod enum (6 time periods)
//   • WallpaperTheme enum (Auto, Horizon, Aurora, Clouds, Nightfall)
//   • WeatherModifier enum (6 weather conditions)
//   • EnvironmentTheme — resolves (time, theme, condition) → interpolated gradient
// ─────────────────────────────────────────────────────────────────────────────

/// Six distinct atmospheric time-of-day states.
enum TimeOfDayPeriod { dawn, morning, afternoon, goldenHour, dusk, night }

/// Five user-selectable wallpaper themes.
enum WallpaperTheme {
  auto,       // Smart dynamic selection based on time & weather
  horizon,    // Minimal natural horizon, soft daylight, bright & readable (Default)
  aurora,     // Clean atmospheric sky with subtle blue/teal tones
  clouds,     // Elegant realistic cloud environment with spacious negative space
  nightfall,  // Darker evening/night environment with moody atmospheric lighting
}

/// Weather condition modifiers applied on top of the time gradient.
enum WeatherModifier { clear, cloudy, rainy, stormy, foggy, snowy }

/// Resolved gradient definition for a single environment state.
class EnvironmentGradient {
  /// Vertical linear gradient stops (top → bottom).
  final List<Color> linearColors;
  final List<double> linearStops;

  /// Optional radial glow: centre (0–1 coordinates), radius (0–1), color, opacity.
  final bool hasGlow;
  final double glowX;
  final double glowY;
  final double glowRadius;
  final Color glowColor;
  final double glowOpacity;

  /// Per-state readability overlay alphas [top, midUpper, midLower, bottom, base].
  final List<double> overlayAlphas;

  const EnvironmentGradient({
    required this.linearColors,
    required this.linearStops,
    this.hasGlow = false,
    this.glowX = 0.5,
    this.glowY = 0.5,
    this.glowRadius = 0.6,
    this.glowColor = Colors.white,
    this.glowOpacity = 0.0,
    required this.overlayAlphas,
  });

  /// Linearly interpolate between two [EnvironmentGradient]s.
  static EnvironmentGradient lerp(EnvironmentGradient a, EnvironmentGradient b, double t) {
    assert(a.linearColors.length == b.linearColors.length);
    assert(a.overlayAlphas.length == b.overlayAlphas.length);

    final colors = List<Color>.generate(
      a.linearColors.length,
      (i) => Color.lerp(a.linearColors[i], b.linearColors[i], t)!,
    );
    final overlays = List<double>.generate(
      a.overlayAlphas.length,
      (i) => a.overlayAlphas[i] + (b.overlayAlphas[i] - a.overlayAlphas[i]) * t,
    );

    return EnvironmentGradient(
      linearColors: colors,
      linearStops: a.linearStops,
      hasGlow: t < 0.5 ? a.hasGlow : b.hasGlow,
      glowX: a.glowX + (b.glowX - a.glowX) * t,
      glowY: a.glowY + (b.glowY - a.glowY) * t,
      glowRadius: a.glowRadius + (b.glowRadius - a.glowRadius) * t,
      glowColor: Color.lerp(a.glowColor, b.glowColor, t)!,
      glowOpacity: a.glowOpacity + (b.glowOpacity - a.glowOpacity) * t,
      overlayAlphas: overlays,
    );
  }
}

/// Central resolver for Mausam's environmental background system.
class EnvironmentTheme {
  EnvironmentTheme._();

  // ───────────────────────────── Time Mapping ───────────────────────────────

  static TimeOfDayPeriod periodForHour(int hour) {
    if (hour >= 5 && hour < 7) return TimeOfDayPeriod.dawn;
    if (hour >= 7 && hour < 11) return TimeOfDayPeriod.morning;
    if (hour >= 11 && hour < 16) return TimeOfDayPeriod.afternoon;
    if (hour >= 16 && hour < 19) return TimeOfDayPeriod.goldenHour;
    if (hour >= 19 && hour < 21) return TimeOfDayPeriod.dusk;
    return TimeOfDayPeriod.night; // 21–4
  }

  static TimeOfDayPeriod nextPeriod(TimeOfDayPeriod period) {
    switch (period) {
      case TimeOfDayPeriod.dawn: return TimeOfDayPeriod.morning;
      case TimeOfDayPeriod.morning: return TimeOfDayPeriod.afternoon;
      case TimeOfDayPeriod.afternoon: return TimeOfDayPeriod.goldenHour;
      case TimeOfDayPeriod.goldenHour: return TimeOfDayPeriod.dusk;
      case TimeOfDayPeriod.dusk: return TimeOfDayPeriod.night;
      case TimeOfDayPeriod.night: return TimeOfDayPeriod.dawn;
    }
  }

  static int _startHour(TimeOfDayPeriod period) {
    switch (period) {
      case TimeOfDayPeriod.dawn: return 5;
      case TimeOfDayPeriod.morning: return 7;
      case TimeOfDayPeriod.afternoon: return 11;
      case TimeOfDayPeriod.goldenHour: return 16;
      case TimeOfDayPeriod.dusk: return 19;
      case TimeOfDayPeriod.night: return 21;
    }
  }

  static int _endHour(TimeOfDayPeriod period) {
    switch (period) {
      case TimeOfDayPeriod.dawn: return 7;
      case TimeOfDayPeriod.morning: return 11;
      case TimeOfDayPeriod.afternoon: return 16;
      case TimeOfDayPeriod.goldenHour: return 19;
      case TimeOfDayPeriod.dusk: return 21;
      case TimeOfDayPeriod.night: return 29; // wraps (21..5 next day = 8h)
    }
  }

  static double fractionThroughPeriod(DateTime now) {
    final period = periodForHour(now.hour);
    final startH = _startHour(period);
    final endH = _endHour(period);

    int elapsedMinutes = (now.hour - startH) * 60 + now.minute;
    if (elapsedMinutes < 0) elapsedMinutes += 24 * 60;
    final durationMinutes = (endH - startH) * 60;

    return (elapsedMinutes / durationMinutes).clamp(0.0, 1.0);
  }

  // ─────────────────────────── Condition Mapping ────────────────────────────

  static WeatherModifier modifierForCondition(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('thunder') || c.contains('storm')) return WeatherModifier.stormy;
    if (c.contains('rain') || c.contains('drizzle') || c.contains('shower')) return WeatherModifier.rainy;
    if (c.contains('snow') || c.contains('sleet') || c.contains('ice') || c.contains('blizzard')) return WeatherModifier.snowy;
    if (c.contains('fog') || c.contains('mist') || c.contains('haze') || c.contains('smoke')) return WeatherModifier.foggy;
    if (c.contains('cloud') || c.contains('overcast')) return WeatherModifier.cloudy;
    return WeatherModifier.clear;
  }

  // ────────────────────── 5-Stop Shared Helper ──────────────────────────────
  static const List<double> _stops = [0.0, 0.25, 0.5, 0.75, 1.0];

  // ───────────────────────────────────────────────────────────────────────────
  // THEME 1: HORIZON (Default Baseline — Brighter, Clean, Natural, Spacious)
  // ───────────────────────────────────────────────────────────────────────────

  static const EnvironmentGradient _horizonDawn = EnvironmentGradient(
    linearColors: [
      Color(0xFF141936), // Deep Slate Violet
      Color(0xFF26254E), // Soft Lavender Indigo
      Color(0xFF482D4B), // Warm Mauve
      Color(0xFF703B45), // Peach Blush Horizon
      Color(0xFF8E4C3D), // Radiant Dawn Horizon Light
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.5,
    glowY: 0.94,
    glowRadius: 0.70,
    glowColor: Color(0xFFF59E0B),
    glowOpacity: 0.28,
    overlayAlphas: [0.28, 0.12, 0.05, 0.20, 0.40],
  );

  static const EnvironmentGradient _horizonMorning = EnvironmentGradient(
    linearColors: [
      Color(0xFF162B4C), // Clean Sky Slate
      Color(0xFF1C3A66), // Cool Sky Blue
      Color(0xFF244D88), // Fresh Daylight Atmosphere
      Color(0xFF2A599B), // Bright Horizon Blue
      Color(0xFF224A84), // Natural Ground Horizon
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.78,
    glowY: 0.16,
    glowRadius: 0.60,
    glowColor: Color(0xFFBAE6FD),
    glowOpacity: 0.26,
    overlayAlphas: [0.22, 0.08, 0.04, 0.15, 0.35],
  );

  static const EnvironmentGradient _horizonAfternoon = EnvironmentGradient(
    linearColors: [
      Color(0xFF142D52), // Deep Daylight Blue
      Color(0xFF1E3E72), // Rich Sky Navy
      Color(0xFF265296), // Vibrant Ocean Blue
      Color(0xFF2A5CB4), // High Daylight Atmosphere
      Color(0xFF204892), // Horizon Blue
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.70,
    glowY: 0.12,
    glowRadius: 0.65,
    glowColor: Color(0xFFE0F2FE),
    glowOpacity: 0.28,
    overlayAlphas: [0.20, 0.06, 0.03, 0.12, 0.32],
  );

  static const EnvironmentGradient _horizonGoldenHour = EnvironmentGradient(
    linearColors: [
      Color(0xFF1C1434), // Twilight Upper Sky
      Color(0xFF341F3C), // Soft Plum Violet
      Color(0xFF642A32), // Deep Crimson Terracotta
      Color(0xFF964424), // Warm Sunset Gold
      Color(0xFFB85E1E), // Horizon Sunset Gold
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.82,
    glowY: 0.80,
    glowRadius: 0.75,
    glowColor: Color(0xFFF97316),
    glowOpacity: 0.38,
    overlayAlphas: [0.25, 0.10, 0.05, 0.18, 0.38],
  );

  static const EnvironmentGradient _horizonDusk = EnvironmentGradient(
    linearColors: [
      Color(0xFF100F26), // Deep Night Slate
      Color(0xFF1E1A40), // Dusk Violet Indigo
      Color(0xFF32234D), // Muted Purple Dusk
      Color(0xFF40274B), // Twilight Rose Plum
      Color(0xFF2F1D38), // Dark Horizon Dusk
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.65,
    glowY: 0.90,
    glowRadius: 0.60,
    glowColor: Color(0xFFF43F5E),
    glowOpacity: 0.22,
    overlayAlphas: [0.28, 0.12, 0.06, 0.22, 0.42],
  );

  static const EnvironmentGradient _horizonNight = EnvironmentGradient(
    linearColors: [
      Color(0xFF080B1C), // Deep Night Sky
      Color(0xFF101634), // Dark Navy Indigo
      Color(0xFF182046), // Obsidian Blue Atmosphere
      Color(0xFF151C3E), // Deep Steel Navy
      Color(0xFF0D122B), // Horizon Midnight Slate
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.35,
    glowY: 0.12,
    glowRadius: 0.65,
    glowColor: Color(0xFF93C5FD),
    glowOpacity: 0.22,
    overlayAlphas: [0.32, 0.14, 0.08, 0.24, 0.46],
  );

  // ───────────────────────────────────────────────────────────────────────────
  // THEME 2: AURORA (Atmospheric Sky with Subtle Blue / Teal Tones)
  // ───────────────────────────────────────────────────────────────────────────

  static const EnvironmentGradient _auroraDawn = EnvironmentGradient(
    linearColors: [
      Color(0xFF0A1B28), // Deep Teal Navy
      Color(0xFF122C3D), // Emerald Indigo
      Color(0xFF1C4252), // Atmospheric Teal
      Color(0xFF265868), // Crisp Teal Haze
      Color(0xFF2D6E7E), // Radiant Emerald Dawn
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.5,
    glowY: 0.94,
    glowRadius: 0.70,
    glowColor: Color(0xFF2DD4BF),
    glowOpacity: 0.30,
    overlayAlphas: [0.28, 0.12, 0.05, 0.20, 0.40],
  );

  static const EnvironmentGradient _auroraMorning = EnvironmentGradient(
    linearColors: [
      Color(0xFF0E2838), // Deep Electric Slate
      Color(0xFF14384C), // Cool Teal Blue
      Color(0xFF1C4D66), // Bright Cyan Atmosphere
      Color(0xFF225F7C), // Sky Cyan Haze
      Color(0xFF1E526D), // Horizon Teal
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.78,
    glowY: 0.16,
    glowRadius: 0.60,
    glowColor: Color(0xFF67E8F9),
    glowOpacity: 0.26,
    overlayAlphas: [0.22, 0.08, 0.04, 0.15, 0.35],
  );

  static const EnvironmentGradient _auroraAfternoon = EnvironmentGradient(
    linearColors: [
      Color(0xFF0B2A3E), // Ocean Teal Slate
      Color(0xFF123B54), // Rich Cyan Navy
      Color(0xFF1A5070), // Vibrant Emerald Teal
      Color(0xFF206288), // High Cyan Atmosphere
      Color(0xFF185072), // Horizon Teal Blue
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.70,
    glowY: 0.12,
    glowRadius: 0.65,
    glowColor: Color(0xFFA5F3FC),
    glowOpacity: 0.28,
    overlayAlphas: [0.20, 0.06, 0.03, 0.12, 0.32],
  );

  static const EnvironmentGradient _auroraGoldenHour = EnvironmentGradient(
    linearColors: [
      Color(0xFF141C30), // Deep Teal Twilight
      Color(0xFF22263C), // Muted Violet Cyan
      Color(0xFF3B2A42), // Emerald Amber Plum
      Color(0xFF5E3A3F), // Warm Copper Haze
      Color(0xFF7E4A35), // Horizon Aurora Sunset
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.82,
    glowY: 0.80,
    glowRadius: 0.75,
    glowColor: Color(0xFF2DD4BF),
    glowOpacity: 0.35,
    overlayAlphas: [0.25, 0.10, 0.05, 0.18, 0.38],
  );

  static const EnvironmentGradient _auroraDusk = EnvironmentGradient(
    linearColors: [
      Color(0xFF0D1426), // Deep Night Teal
      Color(0xFF142038), // Dusk Emerald Navy
      Color(0xFF1E2E4A), // Cyan Dusk Violet
      Color(0xFF283B59), // Muted Aurora Dusk
      Color(0xFF1E2D47), // Dark Horizon Teal
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.65,
    glowY: 0.90,
    glowRadius: 0.60,
    glowColor: Color(0xFF38BDF8),
    glowOpacity: 0.22,
    overlayAlphas: [0.28, 0.12, 0.06, 0.22, 0.42],
  );

  static const EnvironmentGradient _auroraNight = EnvironmentGradient(
    linearColors: [
      Color(0xFF060F1A), // Deep Emerald Midnight
      Color(0xFF0D1C2C), // Deep Cyan Midnight
      Color(0xFF142A3E), // Obsidian Teal Atmosphere
      Color(0xFF102336), // Dark Teal Navy
      Color(0xFF0A1624), // Horizon Midnight Slate
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.35,
    glowY: 0.12,
    glowRadius: 0.65,
    glowColor: Color(0xFF5EEAD4),
    glowOpacity: 0.22,
    overlayAlphas: [0.32, 0.14, 0.08, 0.24, 0.46],
  );

  // ───────────────────────────────────────────────────────────────────────────
  // THEME 3: CLOUDS (Realistic Cloud Environment, Soft Overcast Haze, Spacious)
  // ───────────────────────────────────────────────────────────────────────────

  static const EnvironmentGradient _cloudsDawn = EnvironmentGradient(
    linearColors: [
      Color(0xFF1C1F32), // Soft Charcoal Lavender
      Color(0xFF2A2C44), // Cool Silver Cloud Sky
      Color(0xFF3D3B54), // Muted Cloud Mauve
      Color(0xFF564758), // Peach Cloud Haze
      Color(0xFF70525C), // Warm Rose Cloud Horizon
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.5,
    glowY: 0.94,
    glowRadius: 0.70,
    glowColor: Color(0xFFFDBA74),
    glowOpacity: 0.24,
    overlayAlphas: [0.26, 0.10, 0.04, 0.18, 0.38],
  );

  static const EnvironmentGradient _cloudsMorning = EnvironmentGradient(
    linearColors: [
      Color(0xFF1E2838), // Soft Slate Cloud Sky
      Color(0xFF283448), // Crisp Silver Cloud Layer
      Color(0xFF34445C), // Spacious Blue Cloud Haze
      Color(0xFF3D506C), // High Cloud Daylight
      Color(0xFF32425B), // Horizon Cloud Haze
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.78,
    glowY: 0.16,
    glowRadius: 0.60,
    glowColor: Color(0xFFE2E8F0),
    glowOpacity: 0.24,
    overlayAlphas: [0.20, 0.06, 0.03, 0.12, 0.32],
  );

  static const EnvironmentGradient _cloudsAfternoon = EnvironmentGradient(
    linearColors: [
      Color(0xFF1B2E46), // Deep Slate Cloud Navy
      Color(0xFF243B58), // Cool Silver Blue Cloud
      Color(0xFF2E4A6E), // Spacious Blue Cloud Layer
      Color(0xFF36557D), // Bright Cloud Atmosphere
      Color(0xFF2C466A), // Horizon Cloud Navy
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.70,
    glowY: 0.12,
    glowRadius: 0.65,
    glowColor: Color(0xFFF1F5F9),
    glowOpacity: 0.26,
    overlayAlphas: [0.18, 0.05, 0.02, 0.10, 0.30],
  );

  static const EnvironmentGradient _cloudsGoldenHour = EnvironmentGradient(
    linearColors: [
      Color(0xFF221A30), // Soft Violet Cloud Sky
      Color(0xFF34263B), // Plum Cloud Haze
      Color(0xFF523640), // Warm Amber Cloud Layer
      Color(0xFF76473E), // Sunset Cloud Gold
      Color(0xFF90523C), // Horizon Cloud Sunset
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.82,
    glowY: 0.80,
    glowRadius: 0.75,
    glowColor: Color(0xFFFB923C),
    glowOpacity: 0.34,
    overlayAlphas: [0.22, 0.08, 0.04, 0.15, 0.35],
  );

  static const EnvironmentGradient _cloudsDusk = EnvironmentGradient(
    linearColors: [
      Color(0xFF161528), // Muted Dusk Cloud Sky
      Color(0xFF222036), // Slate Purple Cloud
      Color(0xFF302B48), // Cool Dusk Lavender
      Color(0xFF3B3352), // Fading Cloud Rose
      Color(0xFF2C263F), // Dark Horizon Cloud Slate
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.65,
    glowY: 0.90,
    glowRadius: 0.60,
    glowColor: Color(0xFFFDA4AF),
    glowOpacity: 0.20,
    overlayAlphas: [0.25, 0.10, 0.05, 0.18, 0.38],
  );

  static const EnvironmentGradient _cloudsNight = EnvironmentGradient(
    linearColors: [
      Color(0xFF0C101D), // Deep Charcoal Midnight
      Color(0xFF14192A), // Slate Cloud Midnight
      Color(0xFF1D2438), // Obsidian Cloud Haze
      Color(0xFF181F30), // Dark Navy Cloud Layer
      Color(0xFF101424), // Horizon Cloud Midnight
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.35,
    glowY: 0.12,
    glowRadius: 0.65,
    glowColor: Color(0xFFCBD5E1),
    glowOpacity: 0.20,
    overlayAlphas: [0.28, 0.12, 0.06, 0.20, 0.42],
  );

  // ───────────────────────────────────────────────────────────────────────────
  // THEME 4: NIGHTFALL (Darker Evening/Night Focused, Subtle Atmospheric Light)
  // ───────────────────────────────────────────────────────────────────────────

  static const EnvironmentGradient _nightfallDawn = EnvironmentGradient(
    linearColors: [
      Color(0xFF080A1A), // Deep Midnight Sky
      Color(0xFF12142B), // Dark Violet Indigo
      Color(0xFF221A33), // Mauve Nightfall Haze
      Color(0xFF352033), // Dark Rose Blush Horizon
      Color(0xFF462531), // Fading Nightfall Dawn
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.5,
    glowY: 0.94,
    glowRadius: 0.70,
    glowColor: Color(0xFFD97706),
    glowOpacity: 0.22,
    overlayAlphas: [0.35, 0.16, 0.10, 0.25, 0.48],
  );

  static const EnvironmentGradient _nightfallMorning = EnvironmentGradient(
    linearColors: [
      Color(0xFF0A1424), // Slate Navy Midnight
      Color(0xFF101F34), // Atmospheric Deep Blue
      Color(0xFF162B46), // Cool Slate Steel
      Color(0xFF1A3352), // Deep Steel Navy
      Color(0xFF142740), // Horizon Midnight Slate
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.78,
    glowY: 0.16,
    glowRadius: 0.60,
    glowColor: Color(0xFF7DD3FC),
    glowOpacity: 0.20,
    overlayAlphas: [0.30, 0.12, 0.06, 0.20, 0.42],
  );

  static const EnvironmentGradient _nightfallAfternoon = EnvironmentGradient(
    linearColors: [
      Color(0xFF08162A), // Deep Midnight Ocean
      Color(0xFF0E203A), // Dark Ocean Navy
      Color(0xFF142B4E), // Moody Blue Atmosphere
      Color(0xFF18335C), // Deep High Blue
      Color(0xFF122746), // Horizon Navy
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.70,
    glowY: 0.12,
    glowRadius: 0.65,
    glowColor: Color(0xFF38BDF8),
    glowOpacity: 0.22,
    overlayAlphas: [0.28, 0.10, 0.05, 0.18, 0.38],
  );

  static const EnvironmentGradient _nightfallGoldenHour = EnvironmentGradient(
    linearColors: [
      Color(0xFF0F0B1E), // Deep Nightfall Upper Sky
      Color(0xFF1E1325), // Moody Plum Violet
      Color(0xFF3A1B24), // Dark Crimson Amber
      Color(0xFF56261E), // Deep Sunset Gold
      Color(0xFF6E311A), // Horizon Nightfall Gold
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.82,
    glowY: 0.80,
    glowRadius: 0.75,
    glowColor: Color(0xFFEA580C),
    glowOpacity: 0.30,
    overlayAlphas: [0.32, 0.14, 0.08, 0.22, 0.44],
  );

  static const EnvironmentGradient _nightfallDusk = EnvironmentGradient(
    linearColors: [
      Color(0xFF080718), // Pure Obsidian Upper Sky
      Color(0xFF0F0E24), // Deep Midnight Dusk
      Color(0xFF191433), // Dark Purple Twilight
      Color(0xFF221938), // Moody Dusk Plum
      Color(0xFF191228), // Dark Horizon Violet
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.65,
    glowY: 0.90,
    glowRadius: 0.60,
    glowColor: Color(0xFFE11D48),
    glowOpacity: 0.18,
    overlayAlphas: [0.35, 0.16, 0.10, 0.26, 0.48],
  );

  static const EnvironmentGradient _nightfallNight = EnvironmentGradient(
    linearColors: [
      Color(0xFF03040C), // Pure Obsidian Black
      Color(0xFF070918), // Deepest Midnight Indigo
      Color(0xFF0C1024), // Obsidian Blue Atmosphere
      Color(0xFF0A0D1E), // Dark Navy Nightfall
      Color(0xFF050712), // Horizon Obsidian Black
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.35,
    glowY: 0.12,
    glowRadius: 0.65,
    glowColor: Color(0xFF60A5FA),
    glowOpacity: 0.16,
    overlayAlphas: [0.38, 0.18, 0.12, 0.28, 0.50],
  );

  // ────────────────────────────── Resolver Map ───────────────────────────────

  static EnvironmentGradient _baseFor(TimeOfDayPeriod period, WallpaperTheme theme, WeatherModifier modifier) {
    // 1. Resolve effective theme if set to 'auto'
    final effectiveTheme = theme == WallpaperTheme.auto
        ? _autoThemeFor(period, modifier)
        : theme;

    switch (effectiveTheme) {
      case WallpaperTheme.auto:
      case WallpaperTheme.horizon:
        switch (period) {
          case TimeOfDayPeriod.dawn: return _horizonDawn;
          case TimeOfDayPeriod.morning: return _horizonMorning;
          case TimeOfDayPeriod.afternoon: return _horizonAfternoon;
          case TimeOfDayPeriod.goldenHour: return _horizonGoldenHour;
          case TimeOfDayPeriod.dusk: return _horizonDusk;
          case TimeOfDayPeriod.night: return _horizonNight;
        }

      case WallpaperTheme.aurora:
        switch (period) {
          case TimeOfDayPeriod.dawn: return _auroraDawn;
          case TimeOfDayPeriod.morning: return _auroraMorning;
          case TimeOfDayPeriod.afternoon: return _auroraAfternoon;
          case TimeOfDayPeriod.goldenHour: return _auroraGoldenHour;
          case TimeOfDayPeriod.dusk: return _auroraDusk;
          case TimeOfDayPeriod.night: return _auroraNight;
        }

      case WallpaperTheme.clouds:
        switch (period) {
          case TimeOfDayPeriod.dawn: return _cloudsDawn;
          case TimeOfDayPeriod.morning: return _cloudsMorning;
          case TimeOfDayPeriod.afternoon: return _cloudsAfternoon;
          case TimeOfDayPeriod.goldenHour: return _cloudsGoldenHour;
          case TimeOfDayPeriod.dusk: return _cloudsDusk;
          case TimeOfDayPeriod.night: return _cloudsNight;
        }

      case WallpaperTheme.nightfall:
        switch (period) {
          case TimeOfDayPeriod.dawn: return _nightfallDawn;
          case TimeOfDayPeriod.morning: return _nightfallMorning;
          case TimeOfDayPeriod.afternoon: return _nightfallAfternoon;
          case TimeOfDayPeriod.goldenHour: return _nightfallGoldenHour;
          case TimeOfDayPeriod.dusk: return _nightfallDusk;
          case TimeOfDayPeriod.night: return _nightfallNight;
        }
    }
  }

  /// Automatically picks the ideal visual theme based on condition and time period.
  static WallpaperTheme _autoThemeFor(TimeOfDayPeriod period, WeatherModifier modifier) {
    if (modifier == WeatherModifier.cloudy || modifier == WeatherModifier.foggy) {
      return WallpaperTheme.clouds;
    }
    if (modifier == WeatherModifier.rainy || modifier == WeatherModifier.stormy) {
      return WallpaperTheme.nightfall;
    }
    if (period == TimeOfDayPeriod.dusk || period == TimeOfDayPeriod.goldenHour) {
      return WallpaperTheme.horizon;
    }
    return WallpaperTheme.horizon; // Baseline
  }

  // ─────────────────────── Weather Condition Modifiers ──────────────────────

  static EnvironmentGradient _applyModifier(EnvironmentGradient g, WeatherModifier mod) {
    switch (mod) {
      case WeatherModifier.clear:
        return g;

      case WeatherModifier.cloudy:
        const tint = Color(0xFF1E2430);
        return EnvironmentGradient(
          linearColors: g.linearColors.map((c) => Color.lerp(c, tint, 0.22)!).toList(),
          linearStops: g.linearStops,
          hasGlow: g.hasGlow,
          glowX: g.glowX, glowY: g.glowY, glowRadius: g.glowRadius,
          glowColor: g.glowColor,
          glowOpacity: g.glowOpacity * 0.50,
          overlayAlphas: g.overlayAlphas,
        );

      case WeatherModifier.rainy:
        const tint = Color(0xFF141C2B);
        return EnvironmentGradient(
          linearColors: g.linearColors.map((c) => Color.lerp(c, tint, 0.40)!).toList(),
          linearStops: g.linearStops,
          hasGlow: false,
          glowX: g.glowX, glowY: g.glowY, glowRadius: g.glowRadius,
          glowColor: g.glowColor, glowOpacity: 0,
          overlayAlphas: g.overlayAlphas.map((a) => (a + 0.05).clamp(0.0, 0.85)).toList(),
        );

      case WeatherModifier.stormy:
        const tint = Color(0xFF0D121F);
        return EnvironmentGradient(
          linearColors: g.linearColors.map((c) => Color.lerp(c, tint, 0.60)!).toList(),
          linearStops: g.linearStops,
          hasGlow: false,
          glowX: g.glowX, glowY: g.glowY, glowRadius: g.glowRadius,
          glowColor: g.glowColor, glowOpacity: 0,
          overlayAlphas: g.overlayAlphas.map((a) => (a + 0.10).clamp(0.0, 0.88)).toList(),
        );

      case WeatherModifier.foggy:
        const fogTint = Color(0xFF1D2432);
        final flatColors = g.linearColors.map((c) => Color.lerp(c, fogTint, 0.38)!).toList();
        return EnvironmentGradient(
          linearColors: flatColors,
          linearStops: g.linearStops,
          hasGlow: g.hasGlow,
          glowX: g.glowX, glowY: g.glowY, glowRadius: g.glowRadius * 1.4,
          glowColor: const Color(0xFFCBD5E1),
          glowOpacity: g.glowOpacity * 0.40,
          overlayAlphas: g.overlayAlphas.map((a) => (a * 0.90).clamp(0.0, 0.85)).toList(),
        );

      case WeatherModifier.snowy:
        const snowTint = Color(0xFF1A2A42);
        return EnvironmentGradient(
          linearColors: g.linearColors.map((c) => Color.lerp(c, snowTint, 0.30)!).toList(),
          linearStops: g.linearStops,
          hasGlow: g.hasGlow,
          glowX: g.glowX, glowY: g.glowY, glowRadius: g.glowRadius,
          glowColor: const Color(0xFFE2E8F0),
          glowOpacity: g.glowOpacity * 0.60,
          overlayAlphas: g.overlayAlphas.map((a) => (a * 0.90).clamp(0.0, 0.85)).toList(),
        );
    }
  }

  // ──────────────────────── Main Public API ─────────────────────────────────

  /// Returns a fully interpolated, weather-modified [EnvironmentGradient]
  /// for the given [now] timestamp, selected [theme], and [condition] string.
  static EnvironmentGradient resolve({
    required DateTime now,
    WallpaperTheme theme = WallpaperTheme.auto,
    String condition = '',
  }) {
    final period = periodForHour(now.hour);
    final next = nextPeriod(period);
    final t = fractionThroughPeriod(now);
    final modifier = modifierForCondition(condition);

    // Interpolate between current and next base gradients for the given theme
    final baseA = _baseFor(period, theme, modifier);
    final baseB = _baseFor(next, theme, modifier);
    final interpolated = EnvironmentGradient.lerp(baseA, baseB, t);

    // Apply weather modifier
    return _applyModifier(interpolated, modifier);
  }

  /// Convenience: resolve for a specific hour (ignores minutes, uses now.minute).
  static EnvironmentGradient resolveForHour(
    int hour, {
    WallpaperTheme theme = WallpaperTheme.auto,
    String condition = '',
  }) {
    final now = DateTime.now();
    final fake = DateTime(now.year, now.month, now.day, hour, now.minute);
    return resolve(now: fake, theme: theme, condition: condition);
  }
}
