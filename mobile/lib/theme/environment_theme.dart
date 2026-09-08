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

  // ── Dynamic Live Wallpaper Atmospheres (Dawn, Morning, Afternoon, Golden Hour, Dusk, Night) ──

  /// Dawn (05:00 - 06:59): Deep cosmic obsidian zenith with subtle rose-gold/apricot horizon glow
  static const _liveDawn = EnvironmentGradient(
    linearColors: [
      Color(0xFF080B14),
      Color(0xFF0E121E),
      Color(0xFF171526),
      Color(0xFF241824),
      Color(0xFF352026),
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.42,
    glowY: 0.14,
    glowRadius: 0.65,
    glowColor: Color(0xFFF59E0B),
    glowOpacity: 0.10,
    overlayAlphas: [0.26, 0.12, 0.06, 0.20, 0.40],
  );

  /// Morning (07:00 - 10:59): Pristine deep navy-obsidian charcoal with quiet daylight solar halo
  static const _liveMorning = EnvironmentGradient(
    linearColors: [
      Color(0xFF090E18),
      Color(0xFF0E1726),
      Color(0xFF142034),
      Color(0xFF1A2B45),
      Color(0xFF223758),
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.38,
    glowY: 0.10,
    glowRadius: 0.70,
    glowColor: Color(0xFFFDE68A),
    glowOpacity: 0.12,
    overlayAlphas: [0.28, 0.14, 0.08, 0.22, 0.42],
  );

  /// Afternoon (11:00 - 15:59): Crisp obsidian sapphire-slate with pure solar daylight radiance
  static const _liveAfternoon = EnvironmentGradient(
    linearColors: [
      Color(0xFF0A101C),
      Color(0xFF101B2E),
      Color(0xFF172640),
      Color(0xFF1E3254),
      Color(0xFF263F68),
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.35,
    glowY: 0.08,
    glowRadius: 0.72,
    glowColor: Color(0xFFFFFFFF),
    glowOpacity: 0.14,
    overlayAlphas: [0.28, 0.14, 0.08, 0.22, 0.42],
  );

  /// Golden Hour (16:00 - 18:59): Velvety obsidian dusk with warm burnished bronze/copper horizon whisper
  static const _liveGoldenHour = EnvironmentGradient(
    linearColors: [
      Color(0xFF0A0912),
      Color(0xFF120E1C),
      Color(0xFF1C1324),
      Color(0xFF271724),
      Color(0xFF361F26),
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.42,
    glowY: 0.12,
    glowRadius: 0.68,
    glowColor: Color(0xFFF59E0B),
    glowOpacity: 0.12,
    overlayAlphas: [0.26, 0.12, 0.06, 0.20, 0.40],
  );

  /// Dusk (19:00 - 20:59): Royal obsidian-indigo with quiet twilight violet horizon
  static const _liveDusk = EnvironmentGradient(
    linearColors: [
      Color(0xFF060710),
      Color(0xFF0A0B18),
      Color(0xFF0F1022),
      Color(0xFF15152C),
      Color(0xFF1B1834),
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.45,
    glowY: 0.15,
    glowRadius: 0.62,
    glowColor: Color(0xFFA855F7),
    glowOpacity: 0.08,
    overlayAlphas: [0.24, 0.10, 0.05, 0.18, 0.38],
  );

  /// Night (21:00 - 04:59): Abyssal obsidian midnight cosmos with delicate silver-blue lunar starlight
  static const _liveNight = EnvironmentGradient(
    linearColors: [
      Color(0xFF030408),
      Color(0xFF05070E),
      Color(0xFF070A14),
      Color(0xFF0A0D1B),
      Color(0xFF070A14),
    ],
    linearStops: _stops,
    hasGlow: true,
    glowX: 0.46,
    glowY: 0.13,
    glowRadius: 0.60,
    glowColor: Color(0xFF93C5FD),
    glowOpacity: 0.08,
    overlayAlphas: [0.22, 0.08, 0.04, 0.16, 0.36],
  );

  static const WallpaperSpec _dynamic = WallpaperSpec(
    id: WallpaperTheme.dynamic,
    title: 'Dynamic Live Wallpaper',
    subtitle: 'Changes live across Morning, Afternoon, Evening & Night',
    isDynamic: true,
    isDefault: true,
    previewColors: [
      Color(0xFF0E1726),
      Color(0xFF172640),
      Color(0xFF271724),
      Color(0xFF05070E),
    ],
    periods: {
      TimeOfDayPeriod.dawn: _liveDawn,
      TimeOfDayPeriod.morning: _liveMorning,
      TimeOfDayPeriod.afternoon: _liveAfternoon,
      TimeOfDayPeriod.goldenHour: _liveGoldenHour,
      TimeOfDayPeriod.dusk: _liveDusk,
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
