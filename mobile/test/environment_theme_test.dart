import 'dart:math' as math;
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

  group('EnvironmentTheme — modifierForCondition', () {
    test('Empty string → clear', () => expect(EnvironmentTheme.modifierForCondition(''), WeatherModifier.clear));
    test('clear sky → clear', () => expect(EnvironmentTheme.modifierForCondition('clear sky'), WeatherModifier.clear));
    test('few clouds → cloudy', () => expect(EnvironmentTheme.modifierForCondition('few clouds'), WeatherModifier.cloudy));
    test('heavy rain → rainy', () => expect(EnvironmentTheme.modifierForCondition('heavy rain'), WeatherModifier.rainy));
    test('thunderstorm → stormy', () => expect(EnvironmentTheme.modifierForCondition('thunderstorm'), WeatherModifier.stormy));
    test('mist → foggy', () => expect(EnvironmentTheme.modifierForCondition('mist'), WeatherModifier.foggy));
    test('light snow → snowy', () => expect(EnvironmentTheme.modifierForCondition('light snow'), WeatherModifier.snowy));
  });

  group('EnvironmentTheme — resolve returns correct gradient shape', () {
    test('All time states produce 5-color gradients', () {
      for (final hour in [5, 7, 11, 16, 19, 21]) {
        final g = EnvironmentTheme.resolveForHour(hour);
        expect(g.linearColors.length, 5, reason: 'Hour $hour should produce 5 color stops');
        expect(g.linearStops.length, 5, reason: 'Hour $hour should produce 5 stops');
        expect(g.overlayAlphas.length, 5, reason: 'Hour $hour should produce 5 overlay alphas');
      }
    });

    test('Colors are fully opaque (alpha = 1.0)', () {
      final g = EnvironmentTheme.resolveForHour(14);
      for (final color in g.linearColors) {
        expect(color.a, closeTo(1.0, 0.01), reason: 'Background linear colors should be fully opaque');
      }
    });

    test('Overlay alphas are in valid range 0.0–1.0', () {
      for (final hour in [5, 9, 13, 17, 20, 23]) {
        final g = EnvironmentTheme.resolveForHour(hour);
        for (final alpha in g.overlayAlphas) {
          expect(alpha, greaterThanOrEqualTo(0.0));
          expect(alpha, lessThanOrEqualTo(1.0));
        }
      }
    });

    test('Glow opacity is in valid range 0.0–1.0', () {
      for (final hour in [5, 9, 13, 17, 20, 23]) {
        final g = EnvironmentTheme.resolveForHour(hour);
        expect(g.glowOpacity, greaterThanOrEqualTo(0.0));
        expect(g.glowOpacity, lessThanOrEqualTo(1.0));
      }
    });
  });

  group('EnvironmentTheme — weather modifiers darken appropriately', () {
    test('Clear is brighter than stormy at same hour', () {
      final clear = EnvironmentTheme.resolveForHour(12, condition: 'clear sky');
      final stormy = EnvironmentTheme.resolveForHour(12, condition: 'thunderstorm');
      // Upper sky color should be darker in stormy (lower red component)
      final clearTop = clear.linearColors.first;
      final stormyTop = stormy.linearColors.first;
      expect(stormyTop.r, lessThanOrEqualTo(clearTop.r + 0.01));
    });

    test('Rain reduces glow opacity to zero', () {
      final g = EnvironmentTheme.resolveForHour(16, condition: 'heavy rain');
      expect(g.glowOpacity, equals(0.0));
      expect(g.hasGlow, isFalse);
    });

    test('Storm reduces glow opacity to zero', () {
      final g = EnvironmentTheme.resolveForHour(10, condition: 'thunderstorm');
      expect(g.glowOpacity, equals(0.0));
    });
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

    test('t=0.5 is between a and b', () {
      final a = EnvironmentTheme.resolveForHour(5);  // dawn — warm
      final b = EnvironmentTheme.resolveForHour(19); // dusk — cool-purple
      final mid = EnvironmentGradient.lerp(a, b, 0.5);
      // Mid glow opacity should be between a and b
      expect(mid.glowOpacity, greaterThanOrEqualTo(math.min(a.glowOpacity, b.glowOpacity) - 0.001));
      expect(mid.glowOpacity, lessThanOrEqualTo(math.max(a.glowOpacity, b.glowOpacity) + 0.001));
    });
  });

  group('EnvironmentTheme — fractionThroughPeriod', () {
    test('Midpoint through morning gives ~0.5', () {
      // Morning = 7:00–11:00 (4h). Midpoint = 9:00 = 2h in → 0.50
      final t = EnvironmentTheme.fractionThroughPeriod(DateTime(2024, 1, 1, 9, 0));
      expect(t, closeTo(0.5, 0.01));
    });

    test('Start of period gives ~0.0', () {
      final t = EnvironmentTheme.fractionThroughPeriod(DateTime(2024, 1, 1, 7, 0));
      expect(t, closeTo(0.0, 0.01));
    });

    test('Near end of period gives close to 1.0', () {
      final t = EnvironmentTheme.fractionThroughPeriod(DateTime(2024, 1, 1, 10, 59));
      expect(t, greaterThan(0.98));
    });
  });
}
