import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/weather_dashboard.dart';
import 'package:mobile/providers/weather_dashboard_provider.dart';
import 'package:mobile/screens/forecast_screen.dart';
import 'package:mobile/screens/profile_screen.dart';

void main() {
  testForecastScreenOverflows();
  for (final width in [320.0, 360.0, 375.0, 390.0, 412.0]) {
    testWidgets('ProfileScreen zero overflow test on width ${width}px', (tester) async {
      final errors = <String>[];
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details.toString());
        oldOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldOnError);

      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProfileScreen(),
            ),
          ),
        ),
      );

      for (int i = 0; i < 15; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      for (final err in errors) {
        if (err.contains('overflowed by')) {
          // ignore: avoid_print
          print('--- OVERFLOW ON $width ---\n$err\n--------------------');
        }
      }

      final ex = tester.takeException();
      expect(ex, isNull, reason: 'ProfileScreen should have zero overflow on width $width');
    });
  }
}

class _MockForecastDashboardNotifier extends WeatherDashboardNotifier {
  final WeatherDashboard _data;
  _MockForecastDashboardNotifier(this._data);

  @override
  WeatherDashboardState build() {
    return WeatherDashboardState(data: _data);
  }
}

void testForecastScreenOverflows() {
  const current = CurrentConditions(
    location: 'Mumbai, India',
    temperatureCelsius: 30.0,
    condition: 'Heavy Thunderstorm and Rain',
    humidityPercent: 75,
    windSpeedKmh: 3.0,
    uvIndex: 7.2,
    feelsLikeCelsius: 36.0,
    highCelsius: 32.0,
    lowCelsius: 26.0,
    dewPointCelsius: 25.0,
    sunriseUnix: 1725755100,
    sunsetUnix: 1725800100,
    timezoneOffsetSec: 19800,
  );

  final daily = [
    const DailyForecastItem(
      day: 'Today',
      weekday: 'Monday',
      highCelsius: 32.0,
      lowCelsius: 26.0,
      condition: 'Scattered Showers',
      rainProbabilityPercent: 65,
      rainMm: 14.5,
      moonPhase: 0.78,
      moonriseUnix: 1725749040,
      moonsetUnix: 1725795600,
    ),
    const DailyForecastItem(
      day: 'Tomorrow',
      weekday: 'Tuesday',
      highCelsius: 31.0,
      lowCelsius: 25.0,
      condition: 'Thunderstorm',
      rainProbabilityPercent: 80,
      rainMm: 22.0,
      moonPhase: 0.81,
    ),
    const DailyForecastItem(
      day: 'Saturday',
      weekday: 'Saturday',
      highCelsius: 30.0,
      lowCelsius: 24.0,
      condition: 'Tropical Thunderstorm Rain',
      rainProbabilityPercent: 100,
      rainMm: 35.0,
      moonPhase: 0.85,
    ),
  ];

  final dashboard = WeatherDashboard(
    current: current,
    hourly: const [],
    daily: daily,
  );

  for (final width in [320.0, 360.0, 375.0, 390.0, 412.0]) {
    testWidgets('ForecastScreen zero overflow on width ${width}px', (tester) async {
      tester.view.physicalSize = Size(width, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weatherDashboardProvider.overrideWith(() => _MockForecastDashboardNotifier(dashboard)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ForecastScreen(),
            ),
          ),
        ),
      );

      for (int i = 0; i < 15; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -300));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      final ex = tester.takeException();
      expect(ex, isNull, reason: 'ForecastScreen should have zero overflow on width $width');
    });
  }
}
