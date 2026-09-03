import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/theme/environment_theme.dart';

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

  group('EnvironmentTheme — WallpaperTheme variants', () {
    test('All 5 themes generate valid 5-stop gradients across all hours', () {
      for (final theme in WallpaperTheme.values) {
        for (final hour in [5, 8, 13, 17, 20, 23]) {
          final g = EnvironmentTheme.resolveForHour(hour, theme: theme);
          expect(g.linearColors.length, 5, reason: '${theme.name} at $hour should produce 5 colors');
          expect(g.linearStops.length, 5);
          expect(g.overlayAlphas.length, 5);
        }
      }
    });

    test('Horizon is brighter and crisp in morning than Nightfall', () {
      final horizon = EnvironmentTheme.resolveForHour(9, theme: WallpaperTheme.horizon);
      final nightfall = EnvironmentTheme.resolveForHour(9, theme: WallpaperTheme.nightfall);

      // Top color red component should be brighter in Horizon
      expect(horizon.linearColors.first.r, greaterThanOrEqualTo(nightfall.linearColors.first.r));
    });

    test('Aurora theme carries cyan/teal tones', () {
      final aurora = EnvironmentTheme.resolveForHour(12, theme: WallpaperTheme.aurora);
      // Teal tone has higher green/blue component than red
      final midColor = aurora.linearColors[2];
      expect(midColor.g, greaterThan(midColor.r));
      expect(midColor.b, greaterThan(midColor.r));
    });

    test('Auto theme resolves appropriately based on conditions', () {
      final autoClear = EnvironmentTheme.resolveForHour(12, theme: WallpaperTheme.auto, condition: 'clear sky');
      final autoCloudy = EnvironmentTheme.resolveForHour(12, theme: WallpaperTheme.auto, condition: 'overcast clouds');

      expect(autoClear.linearColors.length, 5);
      expect(autoCloudy.linearColors.length, 5);
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
