import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/weather_dashboard.dart';
import 'package:mobile/providers/weather_dashboard_provider.dart';
import 'package:mobile/screens/forecast_screen.dart';
import 'package:mobile/widgets/weather/comfort_feel_card.dart';
import 'package:mobile/widgets/weather/monthly_rainfall_card.dart';
import 'package:mobile/widgets/weather/sun_moon_card.dart';

class MockWeatherDashboardNotifier extends WeatherDashboardNotifier {
  final WeatherDashboard _data;
  MockWeatherDashboardNotifier(this._data);

  @override
  WeatherDashboardState build() {
    return WeatherDashboardState(data: _data);
  }
}

void main() {
  const sampleCurrent = CurrentConditions(
    location: 'Mumbai, India',
    temperatureCelsius: 30.0,
    condition: 'Hazy Sun',
    humidityPercent: 75,
    windSpeedKmh: 3.0,
    uvIndex: 7.2,
    feelsLikeCelsius: 36.0,
    highCelsius: 32.0,
    lowCelsius: 26.0,
    dewPointCelsius: 25.0,
    sunriseUnix: 1725755100, // ~5:45 AM
    sunsetUnix: 1725800100,  // ~6:15 PM
    timezoneOffsetSec: 19800, // IST (+5:30)
  );

  final sampleDaily = [
    const DailyForecastItem(
      day: 'Today',
      weekday: 'Monday',
      highCelsius: 32.0,
      lowCelsius: 26.0,
      condition: 'Scattered Showers',
      rainProbabilityPercent: 65,
      rainMm: 14.5,
      moonPhase: 0.78, // Waning crescent
      moonriseUnix: 1725749040, // ~4:04 AM
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
  ];

  final sampleDashboard = WeatherDashboard(
    current: sampleCurrent,
    hourly: const [
      HourlyForecastItem(
        dtUnix: 1725757200,
        hourLabel: '6 AM',
        temperatureCelsius: 26.0,
        condition: 'Clear',
        rainProbabilityPercent: 10,
      ),
      HourlyForecastItem(
        dtUnix: 1725760800,
        hourLabel: '7 AM',
        temperatureCelsius: 27.0,
        condition: 'Partly Cloudy',
        rainProbabilityPercent: 15,
      ),
    ],
    daily: sampleDaily,
  );

  group('1. Sun & Moon Feature Card Tests', () {
    testWidgets('renders Sun & Moon card with Sunrise, Sunset, Solar Noon, Moon Phase, Golden Hour, and Moonrise', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SunMoonCard(
                  current: sampleCurrent,
                  today: sampleDaily.first,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Card Header
      expect(find.text('SUN & MOON'), findsOneWidget);
      expect(find.text('ASTRONOMICAL RADAR'), findsOneWidget);

      // Top Dual Highlight Cards
      expect(find.text('Sunrise'), findsOneWidget);
      expect(find.text('Sunset'), findsOneWidget);

      // Solar Noon Apex Label
      expect(find.textContaining('Solar noon'), findsOneWidget);

      // Bottom Triplet Metrics
      expect(find.text('Moon Phase'), findsOneWidget);
      expect(find.text('Waning Crescent'), findsOneWidget);
      expect(find.text('Golden Hour'), findsOneWidget);
      expect(find.text('Moonrise'), findsOneWidget);
    });
  });

  group('2. Comfort & Feel Feature Card Tests', () {
    test('computes exact comfort index (30°C + 75% RH -> 56 Uncomfortable 🥵)', () {
      final intel = ComfortIntel.fromConditions(sampleCurrent);
      expect(intel.score, equals(56));
      expect(intel.status, equals('Uncomfortable'));
      expect(intel.emoji, equals('🥵'));
      expect(intel.advisory, contains('Stay hydrated'));
    });

    test('computes optimal comfort index for pleasant mild weather', () {
      const pleasantConditions = CurrentConditions(
        location: 'Bengaluru, India',
        temperatureCelsius: 23.0,
        condition: 'Clear',
        humidityPercent: 48,
        windSpeedKmh: 14.0,
        uvIndex: 4.0,
      );
      final intel = ComfortIntel.fromConditions(pleasantConditions);
      expect(intel.score, greaterThanOrEqualTo(80));
      expect(intel.status, equals('Optimal'));
      expect(intel.emoji, equals('😊'));
    });

    test('computes cold weather index with winter gear advice', () {
      const coldConditions = CurrentConditions(
        location: 'Shimla, India',
        temperatureCelsius: 4.0,
        condition: 'Clear',
        humidityPercent: 40,
        windSpeedKmh: 22.0,
        uvIndex: 2.0,
      );
      final intel = ComfortIntel.fromConditions(coldConditions);
      expect(intel.score, lessThan(60));
      expect(intel.emoji, anyOf(equals('🥶'), equals('🧥')));
      expect(intel.advisory, anyOf(contains('jacket'), contains('thermal')));
    });

    testWidgets('renders Comfort & Feel card with score, emoji, sliders, and wellness pill', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ComfortFeelCard(
                  current: sampleCurrent,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('COMFORT & FEEL'), findsOneWidget);
      expect(find.text('56'), findsOneWidget);
      expect(find.text('Uncomfortable'), findsOneWidget);
      expect(find.text('Comfort Index (Estimate)'), findsOneWidget);
      expect(find.text('🥵'), findsOneWidget);

      // Parameter rows
      expect(find.text('Temperature'), findsOneWidget);
      expect(find.text('30°C'), findsOneWidget);
      expect(find.text('Humidity'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Wind'), findsOneWidget);
      expect(find.text('3 km/h'), findsOneWidget);

      // Wellness advisory pill
      expect(find.textContaining('Stay hydrated'), findsOneWidget);
    });
  });

  group('3. Monthly Rainfall Feature Card Tests', () {
    test('computes monthly rainfall intelligence without empty/unavailable states', () {
      final intel = MonthlyRainfallIntel.fromDashboard(sampleDashboard);
      expect(intel.totalEstimatedMm, greaterThan(0));
      expect(intel.expectedRainDays, greaterThan(0));
      expect(intel.weeklyDistribution.length, equals(4));
      expect(intel.seasonalAdvisory.isNotEmpty, isTrue);
    });

    testWidgets('renders Monthly Rainfall card with cumulative mm, rainy days, and 4-week distribution', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MonthlyRainfallCard(
                  dashboard: sampleDashboard,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('RAINFALL'), findsOneWidget);
      expect(find.textContaining('mm'), findsAtLeastNWidgets(1));
      expect(find.textContaining('rainy days expected'), findsOneWidget);
      expect(find.text('W1'), findsOneWidget);
      expect(find.text('W2'), findsOneWidget);
      expect(find.text('W3'), findsOneWidget);
      expect(find.text('W4'), findsOneWidget);
    });
  });

  group('4. Forecast Screen Integration Tests', () {
    testWidgets('ForecastScreen cleanly integrates Sun & Moon, Comfort & Feel, and Monthly Rainfall cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weatherDashboardProvider.overrideWith(() => MockWeatherDashboardNotifier(sampleDashboard)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ForecastScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ForecastScreen), findsOneWidget);
      expect(find.byType(SunMoonCard), findsOneWidget);
      expect(find.byType(ComfortFeelCard), findsOneWidget);
      expect(find.byType(MonthlyRainfallCard), findsOneWidget);
      expect(find.text('SUN & MOON'), findsOneWidget);
      expect(find.text('COMFORT & FEEL'), findsOneWidget);
      expect(find.textContaining('RAINFALL'), findsAtLeastNWidgets(1));
    });
  });
}
