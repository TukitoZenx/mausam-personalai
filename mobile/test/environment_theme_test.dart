import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/theme/environment_theme.dart';

double _meanLuma(EnvironmentGradient g) {
  var sum = 0.0;
  for (final c in g.linearColors) {
    sum += 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
  }
  return sum / g.linearColors.length;
}

void main() {
  group('EnvironmentTheme — periodForHour', () {
    test('Hour 5 → dawn', () => expect(EnvironmentTheme.periodForHour(5), TimeOfDayPeriod.dawn));
    test('Hour 6 → dawn', () => expect(EnvironmentTheme.periodForHour(6), TimeOfDayPeriod.dawn));
    test('Hour 7 → morning', () => expect(EnvironmentTheme.periodForHour(7), TimeOfDayPeriod.morning));
    test('Hour 10 → morning', () => expect(EnvironmentTheme.periodForHour(10), TimeOfDayPeriod.morning));
    test('Hour 11 → afternoon', () => expect(EnvironmentTheme.periodForHour(11), TimeOfDayPeriod.afternoon));
    test('Hour 15 → afternoon', () => expect(EnvironmentTheme.periodForHour(15), TimeOfDayPeriod.afternoon));
    test('Hour 16 → goldenHour', () => expect(EnvironmentTheme.periodForHour(16), TimeOfDayPeriod.goldenHour));
    test('Hour 18 → goldenHour', () => expect(EnvironmentTheme.periodForHour(18), TimeOfDayPeriod.goldenHour));
    test('Hour 19 → dusk', () => expect(EnvironmentTheme.periodForHour(19), TimeOfDayPeriod.dusk));
    test('Hour 20 → dusk', () => expect(EnvironmentTheme.periodForHour(20), TimeOfDayPeriod.dusk));
    test('Hour 21 → night', () => expect(EnvironmentTheme.periodForHour(21), TimeOfDayPeriod.night));
    test('Hour 0 → night', () => expect(EnvironmentTheme.periodForHour(0), TimeOfDayPeriod.night));
    test('Hour 4 → night', () => expect(EnvironmentTheme.periodForHour(4), TimeOfDayPeriod.night));
  });

  group('Wallpaper catalog', () {
    test('exposes exactly 3 wallpapers and Dynamic is default', () {
      expect(WallpaperCatalog.all.length, 3);
      expect(WallpaperCatalog.all.first.id, WallpaperTheme.dynamic);
      expect(WallpaperCatalog.of(WallpaperTheme.dynamic).isDefault, isTrue);
      expect(WallpaperCatalog.of(WallpaperTheme.dynamic).isDynamic, isTrue);
      expect(WallpaperCatalog.of(WallpaperTheme.wallpaper2).isDynamic, isFalse);
      expect(WallpaperCatalog.of(WallpaperTheme.wallpaper3).isDynamic, isFalse);
    });

    test('legacy persisted names map onto the new catalog', () {
      expect(WallpaperTheme.parse(null), WallpaperTheme.dynamic);
      expect(WallpaperTheme.parse('auto'), WallpaperTheme.dynamic);
      expect(WallpaperTheme.parse('horizon'), WallpaperTheme.dynamic);
      expect(WallpaperTheme.parse('aurora'), WallpaperTheme.dynamic);
      expect(WallpaperTheme.parse('clouds'), WallpaperTheme.dynamic);
      expect(WallpaperTheme.parse('nightfall'), WallpaperTheme.wallpaper3);
      expect(WallpaperTheme.parse('wallpaper2'), WallpaperTheme.wallpaper2);
      expect(WallpaperTheme.parse('dynamic'), WallpaperTheme.dynamic);
    });
  });

  group('Mausam Dynamic — time of day', () {
    test('all hours produce a 5-stop gradient', () {
      for (final hour in [5, 8, 13, 17, 20, 23]) {
        final g = EnvironmentTheme.resolveForHour(hour, theme: WallpaperTheme.dynamic);
        expect(g.linearColors.length, 5, reason: 'dynamic at $hour');
        expect(g.linearStops.length, 5);
        expect(g.overlayAlphas.length, 5);
      }
    });

    test('9 AM morning is brighter than 10 PM night', () {
      final morning = EnvironmentTheme.resolveForHour(9, theme: WallpaperTheme.dynamic);
      final night = EnvironmentTheme.resolveForHour(22, theme: WallpaperTheme.dynamic);
      expect(_meanLuma(morning), greaterThan(_meanLuma(night)));
    });

    test('2 PM afternoon is brighter than 6 PM evening', () {
      final afternoon = EnvironmentTheme.resolveForHour(14, theme: WallpaperTheme.dynamic);
      final evening = EnvironmentTheme.resolveForHour(18, theme: WallpaperTheme.dynamic);
      expect(_meanLuma(afternoon), greaterThan(_meanLuma(evening)));
    });

    test('ignores weather so rain does not swap the atmosphere', () {
      final clear = EnvironmentTheme.resolveForHour(12, theme: WallpaperTheme.dynamic, condition: 'clear sky');
      final rain = EnvironmentTheme.resolveForHour(12, theme: WallpaperTheme.dynamic, condition: 'heavy rain');
      expect(clear.visuallyEquals(rain), isTrue);
    });
  });

  group('Fixed wallpapers', () {
    test('Wallpaper 2 is identical at 9 AM and 10 PM', () {
      final day = EnvironmentTheme.resolveForHour(9, theme: WallpaperTheme.wallpaper2);
      final night = EnvironmentTheme.resolveForHour(22, theme: WallpaperTheme.wallpaper2);
      expect(day.visuallyEquals(night), isTrue);
    });

    test('Wallpaper 3 is identical at 9 AM and 10 PM', () {
      final day = EnvironmentTheme.resolveForHour(9, theme: WallpaperTheme.wallpaper3);
      final night = EnvironmentTheme.resolveForHour(22, theme: WallpaperTheme.wallpaper3);
      expect(day.visuallyEquals(night), isTrue);
    });

    test('fixed wallpapers ignore weather', () {
      final a = EnvironmentTheme.resolveForHour(12, theme: WallpaperTheme.wallpaper2, condition: 'clear sky');
      final b = EnvironmentTheme.resolveForHour(12, theme: WallpaperTheme.wallpaper2, condition: 'thunderstorm');
      expect(a.visuallyEquals(b), isTrue);
    });

    test('Wallpaper 2 and Wallpaper 3 are visually distinct', () {
      final a = EnvironmentTheme.resolveForHour(12, theme: WallpaperTheme.wallpaper2);
      final b = EnvironmentTheme.resolveForHour(12, theme: WallpaperTheme.wallpaper3);
      expect(a.visuallyEquals(b), isFalse);
    });
  });

  group('EnvironmentTheme — modifierForCondition', () {
    test('Empty string → clear', () => expect(EnvironmentTheme.modifierForCondition(''), WeatherModifier.clear));
    test('clear sky → clear', () => expect(EnvironmentTheme.modifierForCondition('clear sky'), WeatherModifier.clear));
    test('few clouds → cloudy', () => expect(EnvironmentTheme.modifierForCondition('few clouds'), WeatherModifier.cloudy));
    test('heavy rain → rainy', () => expect(EnvironmentTheme.modifierForCondition('heavy rain'), WeatherModifier.rainy));
    test('thunderstorm → stormy', () => expect(EnvironmentTheme.modifierForCondition('thunderstorm'), WeatherModifier.stormy));
    test('mist → foggy', () => expect(EnvironmentTheme.modifierForCondition('mist'), WeatherModifier.foggy));
    test('light snow → snowy', () => expect(EnvironmentTheme.modifierForCondition('light snow'), WeatherModifier.snowy));
  });

  group('EnvironmentGradient.lerp — interpolation sanity', () {
    test('t=0 returns first gradient', () {
      final a = EnvironmentTheme.resolveForHour(7);
      final b = EnvironmentTheme.resolveForHour(12);
      final result = EnvironmentGradient.lerp(a, b, 0.0);
      for (int i = 0; i < a.linearColors.length; i++) {
        expect(result.linearColors[i].r, closeTo(a.linearColors[i].r, 0.01));
      }
    });

    test('t=1 returns second gradient', () {
      final a = EnvironmentTheme.resolveForHour(7);
      final b = EnvironmentTheme.resolveForHour(12);
      final result = EnvironmentGradient.lerp(a, b, 1.0);
      for (int i = 0; i < b.linearColors.length; i++) {
        expect(result.linearColors[i].r, closeTo(b.linearColors[i].r, 0.01));
      }
    });
  });
}
