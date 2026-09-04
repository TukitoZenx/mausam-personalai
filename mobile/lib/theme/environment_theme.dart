import 'package:flutter/material.dart' show Color, Colors;

// ─────────────────────────────────────────────────────────────────────────────
// MAUSAM — Wallpaper & time-of-day atmosphere
//
// Three initial wallpapers, catalog-driven so more can be added later:
//   • dynamic     — Mausam Dynamic (default). Evolves Dawn → Night.
//   • wallpaper2  — Fixed. Never changes with time or weather.
//   • wallpaper3  — Fixed. Never changes with time or weather.
// ─────────────────────────────────────────────────────────────────────────────

/// Six distinct atmospheric time-of-day states.
enum TimeOfDayPeriod { dawn, morning, afternoon, goldenHour, dusk, night }

/// User-selectable home wallpapers.
/// Add a value here + a [WallpaperCatalog] entry to introduce a new wallpaper.
enum WallpaperTheme {
  dynamic,
  wallpaper2,
  wallpaper3;

  bool get isDynamic => this == WallpaperTheme.dynamic;

  static WallpaperTheme get defaultTheme => WallpaperTheme.dynamic;

  /// Parses persisted names, including legacy Auto/Horizon/Aurora/Clouds/Nightfall.
  static WallpaperTheme parse(String? name) {
    switch (name) {
      case 'wallpaper2':
        return WallpaperTheme.wallpaper2;
      case 'wallpaper3':
      case 'nightfall':
        return WallpaperTheme.wallpaper3;
      case 'dynamic':
      case 'auto':
      case 'horizon':
      case 'aurora':
      case 'clouds':
      default:
        return WallpaperTheme.dynamic;
    }
  }
}

/// Weather labels kept for existing condition mapping; wallpapers do not use them.
enum WeatherModifier { clear, cloudy, rainy, stormy, foggy, snowy }

/// Resolved gradient definition for a single atmosphere.
class EnvironmentGradient {
  final List<Color> linearColors;
  final List<double> linearStops;
  final bool hasGlow;
  final double glowX;
  final double glowY;
  final double glowRadius;
  final Color glowColor;
  final double glowOpacity;
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

  bool visuallyEquals(EnvironmentGradient other) {
    if (linearColors.length != other.linearColors.length) return false;
    for (var i = 0; i < linearColors.length; i++) {
      if (linearColors[i] != other.linearColors[i]) return false;
    }
    return glowOpacity == other.glowOpacity;
  }
}

/// Catalog entry. New wallpapers are added here without rewriting the resolver.
class WallpaperSpec {
  final WallpaperTheme id;
  final String title;
  final String subtitle;
  final bool isDynamic;
  final bool isDefault;
  final List<Color> previewColors;
  final EnvironmentGradient? fixed;
  final Map<TimeOfDayPeriod, EnvironmentGradient>? periods;

  const WallpaperSpec({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isDynamic,
    required this.previewColors,
    this.isDefault = false,
    this.fixed,
    this.periods,
  });

  EnvironmentGradient gradientFor(TimeOfDayPeriod period) {
    if (!isDynamic) return fixed!;
    return periods![period]!;
  }
}

class WallpaperCatalog {
  WallpaperCatalog._();

  static const List<double> _stops = [0.0, 0.25, 0.5, 0.75, 1.0];

  static List<WallpaperSpec> get all => const [_dynamic, _wallpaper2, _wallpaper3];

  static WallpaperSpec of(WallpaperTheme theme) {
    return all.firstWhere((s) => s.id == theme, orElse: () => _dynamic);
  }

  // ── Dynamic: brighter daytime, premium grayscale, smooth period lerp ──

  static const _dynamicDawn = EnvironmentGradient(
    linearColors: [
      Color(0xFF2A2A30),
      Color(0xFF3C3C44),
      Color(0xFF55555E),
      Color(0xFF6E6E76),
      Color(0xFF7A7A82),
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.5,
    glowY: 0.90,
    glowRadius: 0.72,
    glowColor: Color(0xFFE4E4E7),
    glowOpacity: 0.28,
    overlayAlphas: [0.14, 0.04, 0.0, 0.12, 0.26],
  );

  static const _dynamicMorning = EnvironmentGradient(
    linearColors: [
      Color(0xFF4A4A52),
      Color(0xFF63636C),
      Color(0xFF7C7C86),
      Color(0xFF95959E),
      Color(0xFF82828A),
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.78,
    glowY: 0.16,
    glowRadius: 0.62,
    glowColor: Color(0xFFF4F4F5),
    glowOpacity: 0.32,
    overlayAlphas: [0.08, 0.02, 0.0, 0.10, 0.22],
  );

  static const _dynamicAfternoon = EnvironmentGradient(
    linearColors: [
      Color(0xFF5A5A62),
      Color(0xFF73737C),
      Color(0xFF8C8C94),
      Color(0xFFA3A3AA),
      Color(0xFF8A8A92),
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.70,
    glowY: 0.12,
    glowRadius: 0.68,
    glowColor: Color(0xFFFAFAFA),
    glowOpacity: 0.34,
    overlayAlphas: [0.06, 0.0, 0.0, 0.08, 0.20],
  );

  static const _dynamicEvening = EnvironmentGradient(
    linearColors: [
      Color(0xFF222226),
      Color(0xFF2E2E32),
      Color(0xFF3C3C42),
      Color(0xFF4E4E54),
      Color(0xFF3A3A40),
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.82,
    glowY: 0.80,
    glowRadius: 0.70,
    glowColor: Color(0xFFD4D4D8),
    glowOpacity: 0.22,
    overlayAlphas: [0.16, 0.06, 0.02, 0.16, 0.32],
  );

  static const _dynamicDusk = EnvironmentGradient(
    linearColors: [
      Color(0xFF121214),
      Color(0xFF18181B),
      Color(0xFF202024),
      Color(0xFF2A2A30),
      Color(0xFF1C1C20),
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.65,
    glowY: 0.88,
    glowRadius: 0.55,
    glowColor: Color(0xFFA1A1AA),
    glowOpacity: 0.14,
    overlayAlphas: [0.22, 0.10, 0.04, 0.20, 0.38],
  );

  static const _dynamicNight = EnvironmentGradient(
    linearColors: [
      Color(0xFF050506),
      Color(0xFF09090B),
      Color(0xFF0E0E10),
      Color(0xFF121214),
      Color(0xFF0A0A0C),
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.32,
    glowY: 0.12,
    glowRadius: 0.55,
    glowColor: Color(0xFFD4D4D8),
    glowOpacity: 0.10,
    overlayAlphas: [0.28, 0.12, 0.06, 0.24, 0.44],
  );

  static const WallpaperSpec _dynamic = WallpaperSpec(
    id: WallpaperTheme.dynamic,
    title: 'Mausam Dynamic',
    subtitle: 'Changes with the time of day',
    isDynamic: true,
    isDefault: true,
    previewColors: [
      Color(0xFFA3A3AA),
      Color(0xFF7C7C86),
      Color(0xFF3C3C42),
      Color(0xFF09090B),
    ],
    periods: {
      TimeOfDayPeriod.dawn: _dynamicDawn,
      TimeOfDayPeriod.morning: _dynamicMorning,
      TimeOfDayPeriod.afternoon: _dynamicAfternoon,
      TimeOfDayPeriod.goldenHour: _dynamicEvening,
      TimeOfDayPeriod.dusk: _dynamicDusk,
      TimeOfDayPeriod.night: _dynamicNight,
    },
  );

  // ── Wallpaper 2: fixed mid-slate. Independent of hour and weather. ──

  static const _fixed2 = EnvironmentGradient(
    linearColors: [
      Color(0xFF2A2A30),
      Color(0xFF34343A),
      Color(0xFF3E3E44),
      Color(0xFF48484E),
      Color(0xFF38383E),
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.5,
    glowY: 0.18,
    glowRadius: 0.70,
    glowColor: Color(0xFFD4D4D8),
    glowOpacity: 0.12,
    overlayAlphas: [0.16, 0.06, 0.02, 0.16, 0.30],
  );

  static const WallpaperSpec _wallpaper2 = WallpaperSpec(
    id: WallpaperTheme.wallpaper2,
    title: 'Wallpaper 2',
    subtitle: 'Fixed wallpaper',
    isDynamic: false,
    previewColors: [
      Color(0xFF2A2A30),
      Color(0xFF3E3E44),
      Color(0xFF48484E),
    ],
    fixed: _fixed2,
  );

  // ── Wallpaper 3: fixed deep obsidian. Independent of hour and weather. ──

  static const _fixed3 = EnvironmentGradient(
    linearColors: [
      Color(0xFF070708),
      Color(0xFF0C0C0E),
      Color(0xFF121214),
      Color(0xFF18181B),
      Color(0xFF0E0E10),
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.28,
    glowY: 0.10,
    glowRadius: 0.50,
    glowColor: Color(0xFFA1A1AA),
    glowOpacity: 0.08,
    overlayAlphas: [0.30, 0.14, 0.08, 0.26, 0.46],
  );

  static const WallpaperSpec _wallpaper3 = WallpaperSpec(
    id: WallpaperTheme.wallpaper3,
    title: 'Wallpaper 3',
    subtitle: 'Fixed wallpaper',
    isDynamic: false,
    previewColors: [
      Color(0xFF070708),
      Color(0xFF121214),
      Color(0xFF18181B),
    ],
    fixed: _fixed3,
  );
}

/// Central resolver for Mausam's home wallpaper.
class EnvironmentTheme {
  EnvironmentTheme._();

  static TimeOfDayPeriod periodForHour(int hour) {
    if (hour >= 5 && hour < 7) return TimeOfDayPeriod.dawn;
    if (hour >= 7 && hour < 11) return TimeOfDayPeriod.morning;
    if (hour >= 11 && hour < 16) return TimeOfDayPeriod.afternoon;
    if (hour >= 16 && hour < 19) return TimeOfDayPeriod.goldenHour;
    if (hour >= 19 && hour < 21) return TimeOfDayPeriod.dusk;
    return TimeOfDayPeriod.night;
  }

  static TimeOfDayPeriod nextPeriod(TimeOfDayPeriod period) {
    switch (period) {
      case TimeOfDayPeriod.dawn:
        return TimeOfDayPeriod.morning;
      case TimeOfDayPeriod.morning:
        return TimeOfDayPeriod.afternoon;
      case TimeOfDayPeriod.afternoon:
        return TimeOfDayPeriod.goldenHour;
      case TimeOfDayPeriod.goldenHour:
        return TimeOfDayPeriod.dusk;
      case TimeOfDayPeriod.dusk:
        return TimeOfDayPeriod.night;
      case TimeOfDayPeriod.night:
        return TimeOfDayPeriod.dawn;
    }
  }

  static int _startHour(TimeOfDayPeriod period) {
    switch (period) {
      case TimeOfDayPeriod.dawn:
        return 5;
      case TimeOfDayPeriod.morning:
        return 7;
      case TimeOfDayPeriod.afternoon:
        return 11;
      case TimeOfDayPeriod.goldenHour:
        return 16;
      case TimeOfDayPeriod.dusk:
        return 19;
      case TimeOfDayPeriod.night:
        return 21;
    }
  }

  static int _endHour(TimeOfDayPeriod period) {
    switch (period) {
      case TimeOfDayPeriod.dawn:
        return 7;
      case TimeOfDayPeriod.morning:
        return 11;
      case TimeOfDayPeriod.afternoon:
        return 16;
      case TimeOfDayPeriod.goldenHour:
        return 19;
      case TimeOfDayPeriod.dusk:
        return 21;
      case TimeOfDayPeriod.night:
        return 29;
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

  static WeatherModifier modifierForCondition(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('thunder') || c.contains('storm')) return WeatherModifier.stormy;
    if (c.contains('rain') || c.contains('drizzle') || c.contains('shower')) return WeatherModifier.rainy;
    if (c.contains('snow') || c.contains('sleet') || c.contains('ice') || c.contains('blizzard')) return WeatherModifier.snowy;
    if (c.contains('fog') || c.contains('mist') || c.contains('haze') || c.contains('smoke')) return WeatherModifier.foggy;
    if (c.contains('cloud') || c.contains('overcast')) return WeatherModifier.cloudy;
    return WeatherModifier.clear;
  }

  /// Resolves the wallpaper. Dynamic lerps across local time.
  /// Fixed wallpapers ignore [now] and [condition].
  static EnvironmentGradient resolve({
    required DateTime now,
    WallpaperTheme theme = WallpaperTheme.dynamic,
    String condition = '',
  }) {
    final spec = WallpaperCatalog.of(theme);
    if (!spec.isDynamic) {
      return spec.fixed!;
    }

    final period = periodForHour(now.hour);
    final next = nextPeriod(period);
    final t = fractionThroughPeriod(now);
    return EnvironmentGradient.lerp(spec.gradientFor(period), spec.gradientFor(next), t);
  }

  static EnvironmentGradient resolveForHour(
    int hour, {
    WallpaperTheme theme = WallpaperTheme.dynamic,
    String condition = '',
  }) {
    final now = DateTime.now();
    final fake = DateTime(now.year, now.month, now.day, hour, now.minute);
    return resolve(now: fake, theme: theme, condition: condition);
  }
}
