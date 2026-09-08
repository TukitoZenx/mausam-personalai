import 'package:flutter/material.dart' show Color, Colors;

// ─────────────────────────────────────────────────────────────────────────────
// MAUSAM — Wallpaper & time-of-day atmosphere
//
// Three initial wallpapers, catalog-driven so more can be added later:
//   • dynamic     — Mausam Dynamic (default). Evolves Dawn → Night.
//   • wallpaper2  — Fixed. Never changes with time or weather.
//   • wallpaper3  — Fixed. Never changes with time or weather.
// ─────────────────────────────────────────────────────────────────────────────

/// Live wallpaper periods. Dynamic wallpaper follows local time.
enum TimeOfDayPeriod { morning, afternoon, evening, night }

/// User-selectable home wallpapers.
/// Add a value here + a [WallpaperCatalog] entry to introduce a new wallpaper.
enum WallpaperTheme {
  dynamic,
  wallpaper2,
  wallpaper3;

  bool get isDynamic => this == WallpaperTheme.dynamic;
  bool get isFixedBlack => this == WallpaperTheme.wallpaper2 || this == WallpaperTheme.wallpaper3;

  static WallpaperTheme get defaultTheme => WallpaperTheme.dynamic;

  /// Parses persisted names, including legacy Auto/Horizon/Aurora/Clouds/Nightfall and Fixed Black.
  static WallpaperTheme parse(String? name) {
    switch (name) {
      case 'wallpaper2':
      case 'fixed':
      case 'black':
      case 'fixedBlack':
      case 'obsidian':
        return WallpaperTheme.wallpaper2;
      case 'wallpaper3':
      case 'nightfall':
        return WallpaperTheme.wallpaper3;
      case 'dynamic':
      case 'live':
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
  final bool starfield;
  final double discRadius;

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
    this.starfield = false,
    this.discRadius = 0.038,
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
      starfield: t < 0.5 ? a.starfield : b.starfield,
      discRadius: a.discRadius + (b.discRadius - a.discRadius) * t,
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

  // ── Fixed Obsidian Black Atmosphere (Pure OLED Black) ──
  static const _obsidianNight = EnvironmentGradient(
    linearColors: [
      Color(0xFF030304),
      Color(0xFF050506),
      Color(0xFF070709),
      Color(0xFF0A0A0C),
      Color(0xFF050506),
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.45,
    glowY: 0.14,
    glowRadius: 0.60,
    glowColor: Color(0xFFA1A1AA),
    glowOpacity: 0.08,
    overlayAlphas: [0.28, 0.14, 0.08, 0.24, 0.44],
  );

  static const _obsidianNebula = EnvironmentGradient(
    linearColors: [
      Color(0xFF070709),
      Color(0xFF0A0A0E),
      Color(0xFF0E0E14),
      Color(0xFF13131A),
      Color(0xFF08080C),
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.35,
    glowY: 0.10,
    glowRadius: 0.65,
    glowColor: Color(0xFFD4D4D8),
    glowOpacity: 0.10,
    overlayAlphas: [0.24, 0.10, 0.05, 0.20, 0.40],
  );

  // ── Dynamic live wallpaper: cinematic dark sky, sun path by period ──

  /// Morning 05:00–11:59 — cool ink sky, sun rising left.
  static const _liveMorning = EnvironmentGradient(
    linearColors: [
      Color(0xFF0C121C),
      Color(0xFF141C28),
      Color(0xFF1C2634),
      Color(0xFF161E2A),
      Color(0xFF0E141C),
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.20,
    glowY: 0.18,
    glowRadius: 0.72,
    glowColor: Color(0xFFE8E2D6),
    glowOpacity: 0.20,
    overlayAlphas: [0.16, 0.02, 0.0, 0.08, 0.30],
    discRadius: 0.042,
  );

  /// Afternoon 12:00–16:59 — cleaner navy, sun high.
  static const _liveAfternoon = EnvironmentGradient(
    linearColors: [
      Color(0xFF101820),
      Color(0xFF1A2430),
      Color(0xFF243040),
      Color(0xFF1C2836),
      Color(0xFF121820),
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.50,
    glowY: 0.10,
    glowRadius: 0.80,
    glowColor: Color(0xFFF4F1EA),
    glowOpacity: 0.24,
    overlayAlphas: [0.12, 0.0, 0.0, 0.08, 0.28],
    discRadius: 0.050,
  );

  /// Evening 17:00–20:59 — warm low sun, cool zenith.
  static const _liveEvening = EnvironmentGradient(
    linearColors: [
      Color(0xFF0A090F),
      Color(0xFF141018),
      Color(0xFF1C161C),
      Color(0xFF241C1A),
      Color(0xFF120E10),
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.82,
    glowY: 0.32,
    glowRadius: 0.68,
    glowColor: Color(0xFFD9C2AE),
    glowOpacity: 0.22,
    overlayAlphas: [0.20, 0.04, 0.0, 0.10, 0.34],
    discRadius: 0.040,
  );

  /// Night 21:00–04:59 — abyss, moon, stars.
  static const _liveNight = EnvironmentGradient(
    linearColors: [
      Color(0xFF020204),
      Color(0xFF040508),
      Color(0xFF07080E),
      Color(0xFF090B12),
      Color(0xFF030406),
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.78,
    glowY: 0.14,
    glowRadius: 0.48,
    glowColor: Color(0xFFC5CDD8),
    glowOpacity: 0.14,
    overlayAlphas: [0.10, 0.0, 0.0, 0.10, 0.36],
    starfield: true,
    discRadius: 0.026,
  );

  static const WallpaperSpec _dynamic = WallpaperSpec(
    id: WallpaperTheme.dynamic,
    title: 'Dynamic Live Wallpaper',
    subtitle: 'Sky follows morning, afternoon, evening, and night',
    isDynamic: true,
    isDefault: true,
    previewColors: [
      Color(0xFF1C2634),
      Color(0xFF243040),
      Color(0xFF241C1A),
      Color(0xFF040508),
    ],
    periods: {
      TimeOfDayPeriod.morning: _liveMorning,
      TimeOfDayPeriod.afternoon: _liveAfternoon,
      TimeOfDayPeriod.evening: _liveEvening,
      TimeOfDayPeriod.night: _liveNight,
    },
  );

  static const WallpaperSpec _wallpaper2 = WallpaperSpec(
    id: WallpaperTheme.wallpaper2,
    title: 'Fixed Obsidian Black',
    subtitle: 'Permanent deep OLED black — never changes with time',
    isDynamic: false,
    previewColors: [
      Color(0xFF030304),
      Color(0xFF050506),
      Color(0xFF070709),
    ],
    fixed: _obsidianNight,
  );

  static const WallpaperSpec _wallpaper3 = WallpaperSpec(
    id: WallpaperTheme.wallpaper3,
    title: 'Obsidian Nebula',
    subtitle: 'Subtle celestial radiance',
    isDynamic: false,
    previewColors: [
      Color(0xFF070709),
      Color(0xFF0E0E12),
      Color(0xFF141418),
    ],
    fixed: _obsidianNebula,
  );
}

/// Central resolver for Mausam's home wallpaper.
class EnvironmentTheme {
  EnvironmentTheme._();

  static TimeOfDayPeriod periodForHour(int hour) {
    if (hour >= 5 && hour < 12) return TimeOfDayPeriod.morning;
    if (hour >= 12 && hour < 17) return TimeOfDayPeriod.afternoon;
    if (hour >= 17 && hour < 21) return TimeOfDayPeriod.evening;
    return TimeOfDayPeriod.night;
  }

  static TimeOfDayPeriod nextPeriod(TimeOfDayPeriod period) {
    switch (period) {
      case TimeOfDayPeriod.morning:
        return TimeOfDayPeriod.afternoon;
      case TimeOfDayPeriod.afternoon:
        return TimeOfDayPeriod.evening;
      case TimeOfDayPeriod.evening:
        return TimeOfDayPeriod.night;
      case TimeOfDayPeriod.night:
        return TimeOfDayPeriod.morning;
    }
  }

  static int _startHour(TimeOfDayPeriod period) {
    switch (period) {
      case TimeOfDayPeriod.morning:
        return 5;
      case TimeOfDayPeriod.afternoon:
        return 12;
      case TimeOfDayPeriod.evening:
        return 17;
      case TimeOfDayPeriod.night:
        return 21;
    }
  }

  static int _endHour(TimeOfDayPeriod period) {
    switch (period) {
      case TimeOfDayPeriod.morning:
        return 12;
      case TimeOfDayPeriod.afternoon:
        return 17;
      case TimeOfDayPeriod.evening:
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
