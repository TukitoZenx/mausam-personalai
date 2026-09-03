import 'package:flutter/material.dart' show Color, Colors;

// ─────────────────────────────────────────────────────────────────────────────
// MAUSAM — Environment Theme
// Central source-of-truth for time-of-day background system.
//
// Provides:
//   • TimeOfDayPeriod enum (6 states)
//   • WeatherModifier enum (6 conditions)
//   • EnvironmentTheme — resolves time → period, condition → modifier,
//     and computes interpolated EnvironmentGradient for any DateTime
// ─────────────────────────────────────────────────────────────────────────────

/// Six distinct atmospheric time-of-day states.
enum TimeOfDayPeriod { dawn, morning, afternoon, goldenHour, dusk, night }

/// Weather condition modifiers applied on top of the time gradient.
enum WeatherModifier { clear, cloudy, rainy, stormy, foggy, snowy }

/// Resolved gradient definition for a single environment state.
/// Carries all the data needed to paint the background.
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

  /// Per-state readability overlay alphas [top, midUpper, midLower, bottom].
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
      linearStops: a.linearStops, // stops are the same for all states
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

  /// Maps a local [hour] (0–23) to a [TimeOfDayPeriod].
  static TimeOfDayPeriod periodForHour(int hour) {
    if (hour >= 5 && hour < 7) return TimeOfDayPeriod.dawn;
    if (hour >= 7 && hour < 11) return TimeOfDayPeriod.morning;
    if (hour >= 11 && hour < 16) return TimeOfDayPeriod.afternoon;
    if (hour >= 16 && hour < 19) return TimeOfDayPeriod.goldenHour;
    if (hour >= 19 && hour < 21) return TimeOfDayPeriod.dusk;
    return TimeOfDayPeriod.night; // 21–4
  }

  /// The next [TimeOfDayPeriod] in the cycle after [period].
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

  /// Start hour (inclusive) for each period.
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

  /// End hour (exclusive) for each period.
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

  /// Fractional progress (0.0–1.0) through the current period, given actual minutes.
  /// Used for smooth continuous interpolation.
  static double fractionThroughPeriod(DateTime now) {
    final period = periodForHour(now.hour);
    final startH = _startHour(period);
    final endH = _endHour(period);

    // Minutes elapsed since period start
    int elapsedMinutes = (now.hour - startH) * 60 + now.minute;
    // Clamp negative (shouldn't happen but night wraps)
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

  // ─────────────────────── Base Gradient Definitions ────────────────────────
  // All gradients share the same 5-stop structure (top → bottom) so they can
  // be linearly interpolated at matching indices.
  //
  // Color rationale:
  //   • Always deep/dark — content sits on top and must be readable
  //   • Subtle hue shifts convey time, not brightness levels
  //   • Radial glow is separate and composited on top at low opacity

  static const List<double> _stops = [0.0, 0.25, 0.5, 0.75, 1.0];

  static const EnvironmentGradient _dawn = EnvironmentGradient(
    linearColors: [
      Color(0xFF0C0E26), // Deep night sky (upper)
      Color(0xFF1B1838), // Indigo-violet
      Color(0xFF341A2E), // Mauve-purple
      Color(0xFF54222B), // Warm horizon blush
      Color(0xFF6E2D28), // First dawn horizon light
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.5,
    glowY: 0.95,       // Horizon sun rise
    glowRadius: 0.65,
    glowColor: Color(0xFFF59E0B), // Warm golden-amber
    glowOpacity: 0.25,
    overlayAlphas: [0.35, 0.15, 0.08, 0.25, 0.45],
  );

  static const EnvironmentGradient _morning = EnvironmentGradient(
    linearColors: [
      Color(0xFF0F1E36), // Deep morning slate
      Color(0xFF142B4E), // Cool sky blue-navy
      Color(0xFF1A3B69), // Crisp atmospheric blue
      Color(0xFF173258), // Deep steel
      Color(0xFF10223E), // Horizon slate
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.78,
    glowY: 0.18,       // High morning sun
    glowRadius: 0.55,
    glowColor: Color(0xFFBAE6FD), // Crisp cool sunlight
    glowOpacity: 0.20,
    overlayAlphas: [0.30, 0.12, 0.05, 0.20, 0.40],
  );

  static const EnvironmentGradient _afternoon = EnvironmentGradient(
    linearColors: [
      Color(0xFF0D1C3A), // High blue-navy
      Color(0xFF122C5A), // Deep atmospheric navy
      Color(0xFF173E7C), // Rich ocean blue
      Color(0xFF15356C), // Deep clear blue
      Color(0xFF10234A), // Horizon blue
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.70,
    glowY: 0.12,       // High afternoon sun
    glowRadius: 0.60,
    glowColor: Color(0xFFE0F2FE), // Bright daylight glow
    glowOpacity: 0.22,
    overlayAlphas: [0.28, 0.10, 0.05, 0.18, 0.38],
  );

  static const EnvironmentGradient _goldenHour = EnvironmentGradient(
    linearColors: [
      Color(0xFF140F24), // Twilight upper sky
      Color(0xFF261628), // Dark violet-plum
      Color(0xFF4A2022), // Deep amber-crimson
      Color(0xFF73321B), // Warm golden terracotta
      Color(0xFF8E4515), // Horizon sunset gold
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.82,
    glowY: 0.80,       // Setting sun
    glowRadius: 0.70,
    glowColor: Color(0xFFF97316), // Radiant amber-sunset
    glowOpacity: 0.35, // Rich golden glow
    overlayAlphas: [0.35, 0.18, 0.10, 0.25, 0.45],
  );

  static const EnvironmentGradient _dusk = EnvironmentGradient(
    linearColors: [
      Color(0xFF0B0A1C), // Deep night upper sky
      Color(0xFF161330), // Cool indigo-purple
      Color(0xFF261A40), // Rich twilight violet
      Color(0xFF331F40), // Muted dusk plum
      Color(0xFF241630), // Dark horizon violet
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.65,
    glowY: 0.90,       // Fading horizon light
    glowRadius: 0.55,
    glowColor: Color(0xFFF43F5E), // Fading magenta-rose glow
    glowOpacity: 0.20,
    overlayAlphas: [0.35, 0.15, 0.10, 0.28, 0.48],
  );

  static const EnvironmentGradient _night = EnvironmentGradient(
    linearColors: [
      Color(0xFF04060E), // Deep midnight black
      Color(0xFF0A0F24), // Deep indigo midnight
      Color(0xFF101736), // Obsidian blue atmosphere
      Color(0xFF0E142D), // Deep navy
      Color(0xFF070A18), // Dark horizon
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.35,
    glowY: 0.12,       // Silver moonlight upper left
    glowRadius: 0.65,
    glowColor: Color(0xFF93C5FD), // Soft silver-blue moonlight
    glowOpacity: 0.18,
    overlayAlphas: [0.38, 0.18, 0.12, 0.28, 0.50],
  );

  static EnvironmentGradient _baseFor(TimeOfDayPeriod period) {
    switch (period) {
      case TimeOfDayPeriod.dawn: return _dawn;
      case TimeOfDayPeriod.morning: return _morning;
      case TimeOfDayPeriod.afternoon: return _afternoon;
      case TimeOfDayPeriod.goldenHour: return _goldenHour;
      case TimeOfDayPeriod.dusk: return _dusk;
      case TimeOfDayPeriod.night: return _night;
    }
  }

  // ─────────────────────── Weather Condition Modifiers ──────────────────────
  // All modifiers shift the gradient toward a target tint color at a fraction.
  // Radial glow opacity is also reduced to reflect covered sky.

  static EnvironmentGradient _applyModifier(EnvironmentGradient g, WeatherModifier mod) {
    switch (mod) {
      case WeatherModifier.clear:
        return g; // no modification

      case WeatherModifier.cloudy:
        // Desaturate 25%, shift toward cool mid-gray
        const tint = Color(0xFF12141A);
        return EnvironmentGradient(
          linearColors: g.linearColors.map((c) => Color.lerp(c, tint, 0.28)!).toList(),
          linearStops: g.linearStops,
          hasGlow: g.hasGlow,
          glowX: g.glowX, glowY: g.glowY, glowRadius: g.glowRadius,
          glowColor: g.glowColor,
          glowOpacity: g.glowOpacity * 0.40, // glow reduced — sky covered
          overlayAlphas: g.overlayAlphas,
        );

      case WeatherModifier.rainy:
        const tint = Color(0xFF0C1018);
        return EnvironmentGradient(
          linearColors: g.linearColors.map((c) => Color.lerp(c, tint, 0.52)!).toList(),
          linearStops: g.linearStops,
          hasGlow: false,
          glowX: g.glowX, glowY: g.glowY, glowRadius: g.glowRadius,
          glowColor: g.glowColor, glowOpacity: 0,
          overlayAlphas: g.overlayAlphas.map((a) => (a + 0.08).clamp(0.0, 0.85)).toList(),
        );

      case WeatherModifier.stormy:
        const tint = Color(0xFF070A0F);
        return EnvironmentGradient(
          linearColors: g.linearColors.map((c) => Color.lerp(c, tint, 0.72)!).toList(),
          linearStops: g.linearStops,
          hasGlow: false,
          glowX: g.glowX, glowY: g.glowY, glowRadius: g.glowRadius,
          glowColor: g.glowColor, glowOpacity: 0,
          overlayAlphas: g.overlayAlphas.map((a) => (a + 0.14).clamp(0.0, 0.88)).toList(),
        );

      case WeatherModifier.foggy:
        // Flatten contrast — pull all stops toward a single mid-gray value
        const fogTint = Color(0xFF10121A);
        final flatColors = g.linearColors.map((c) => Color.lerp(c, fogTint, 0.48)!).toList();
        return EnvironmentGradient(
          linearColors: flatColors,
          linearStops: g.linearStops,
          hasGlow: g.hasGlow,
          glowX: g.glowX, glowY: g.glowY, glowRadius: g.glowRadius * 1.4,
          glowColor: const Color(0xFFCCDDEE),
          glowOpacity: g.glowOpacity * 0.30,
          overlayAlphas: g.overlayAlphas.map((a) => (a * 0.85).clamp(0.0, 0.85)).toList(),
        );

      case WeatherModifier.snowy:
        const snowTint = Color(0xFF0E1525);
        return EnvironmentGradient(
          linearColors: g.linearColors.map((c) => Color.lerp(c, snowTint, 0.35)!).toList(),
          linearStops: g.linearStops,
          hasGlow: g.hasGlow,
          glowX: g.glowX, glowY: g.glowY, glowRadius: g.glowRadius,
          glowColor: const Color(0xFFD8EEFF),
          glowOpacity: g.glowOpacity * 0.5,
          overlayAlphas: g.overlayAlphas.map((a) => (a * 0.90).clamp(0.0, 0.85)).toList(),
        );
    }
  }

  // ──────────────────────── Main Public API ─────────────────────────────────

  /// Returns a fully interpolated, weather-modified [EnvironmentGradient]
  /// for the given [now] timestamp and [condition] string.
  ///
  /// The gradient is continuously interpolated between the current period
  /// and the next, based on how far through the current period [now] is.
  /// This provides perfectly smooth, imperceptible transitions.
  static EnvironmentGradient resolve({
    required DateTime now,
    String condition = '',
  }) {
    final period = periodForHour(now.hour);
    final next = nextPeriod(period);
    final t = fractionThroughPeriod(now);

    // Interpolate between current and next base gradients
    final baseA = _baseFor(period);
    final baseB = _baseFor(next);
    final interpolated = EnvironmentGradient.lerp(baseA, baseB, t);

    // Apply weather modifier
    final modifier = modifierForCondition(condition);
    return _applyModifier(interpolated, modifier);
  }

  /// Convenience: resolve for a specific hour (ignores minutes, uses now.minute).
  static EnvironmentGradient resolveForHour(int hour, {String condition = ''}) {
    final now = DateTime.now();
    final fake = DateTime(now.year, now.month, now.day, hour, now.minute);
    return resolve(now: fake, condition: condition);
  }
}
