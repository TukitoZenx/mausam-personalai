import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/home_card.dart';
import 'package:mobile/models/personalized_home_response.dart';
import 'package:mobile/models/weather_dashboard.dart';
import 'package:mobile/providers/homepage_provider.dart';
import 'package:mobile/providers/location_provider.dart';
import 'package:mobile/providers/user_provider.dart';
import 'package:mobile/providers/weather_dashboard_provider.dart';
import 'package:mobile/screens/home_screen.dart';
import 'package:mobile/widgets/cards/personalized_context_card.dart';
import 'package:mobile/widgets/cards/recommended_section_widget.dart';
import 'package:mobile/widgets/weather/weather_sections.dart';

void main() {
  const sampleDashboard = WeatherDashboard(
    current: CurrentConditions(
      location: 'New Delhi',
      temperatureCelsius: 28.0,
      feelsLikeCelsius: 31.0,
      condition: 'Sunny',
      humidityPercent: 65,
      windSpeedKmh: 14.0,
      windDirectionDeg: 315.0,
      pressureHpa: 1012.0,
      uvIndex: 7.2,
      visibilityKm: 6.0,
      dewPointCelsius: 21.0,
      rainMm1h: 0.0,
      sunriseUnix: 1725582600,
      sunsetUnix: 1725627600,
    ),
    hourly: [
      HourlyForecastItem(
        dtUnix: 1725590000,
        hourLabel: '10 AM',
        temperatureCelsius: 28.0,
        condition: 'Sunny',
        rainProbabilityPercent: 10,
      ),
      HourlyForecastItem(
        dtUnix: 1725593600,
        hourLabel: '11 AM',
        temperatureCelsius: 29.0,
        condition: 'Sunny',
        rainProbabilityPercent: 10,
      ),
    ],
    daily: [
      DailyForecastItem(
        day: 'Today',
        weekday: 'Sun',
        date: '2026-09-06',
        condition: 'Sunny',
        highCelsius: 32.0,
        lowCelsius: 24.0,
        rainProbabilityPercent: 20,
        moonPhase: 0.25,
      ),
      DailyForecastItem(
        day: 'Tomorrow',
        weekday: 'Mon',
        date: '2026-09-07',
        condition: 'Partly Cloudy',
        highCelsius: 31.0,
        lowCelsius: 23.0,
        rainProbabilityPercent: 30,
        moonPhase: 0.28,
      ),
    ],
    aqi: AqiSnapshot(
      aqiValue: 85,
      category: 'Moderate',
      pollutants: {
        'pm2_5': 28.0,
        'pm10': 55.0,
        'no2': 20.0,
        'o3': 35.0,
        'so2': 12.0,
        'co': 450.0,
      },
    ),
    precipNext24hMm: 1.5,
  );

  group('TodaysMetricsGrid Widget Tests', () {
    testWidgets('renders 4 distinct metric cards with correct data', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TodaysMetricsGrid(
                  dashboard: sampleDashboard,
                  persona: 'Runner',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("TODAY'S METRICS"), findsOneWidget);

      // UV Index card
      expect(find.text('UV INDEX'), findsOneWidget);
      expect(find.text('7.2'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget);

      // Best Outdoor Time card
      expect(find.text('BEST OUTDOOR TIME'), findsOneWidget);
      expect(find.text('RUNNER'), findsOneWidget);

      // Rainfall Today card
      expect(find.text('RAINFALL TODAY'), findsOneWidget);
      expect(find.text('1.5 mm'), findsOneWidget);
      expect(find.text('20% PROB'), findsOneWidget);

      // Heat & Comfort card
      expect(find.text('HEAT & COMFORT'), findsOneWidget);
      expect(find.text('Feels 31°'), findsOneWidget);
    });

    testWidgets('renders AIR QUALITY card when persona is Health', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TodaysMetricsGrid(
                  dashboard: sampleDashboard,
                  persona: 'Health',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AIR QUALITY'), findsOneWidget);
      expect(find.text('AQI 85'), findsOneWidget);
      expect(find.text('MODERATE'), findsOneWidget);
    });
  });

  group('AdditionalConditionsSection Widget Tests', () {
    testWidgets('renders Sun & Moon card and secondary metric cards', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AdditionalConditionsSection(
                  dashboard: sampleDashboard,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ADDITIONAL CONDITIONS'), findsOneWidget);
      expect(find.text('SUN & MOON'), findsOneWidget);
      expect(find.text('WIND'), findsOneWidget);
      expect(find.text('PRESSURE'), findsOneWidget);
      expect(find.text('VISIBILITY'), findsOneWidget);
      expect(find.text('HUMIDITY'), findsOneWidget);
      expect(find.text('6.0 km'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
      expect(find.textContaining('Dew point 21°'), findsOneWidget);
    });
  });

  group('ConditionsAroundYouSection Widget Tests', () {
    testWidgets('renders commute card and 2-column outdoor & environment cards', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ConditionsAroundYouSection(
                  dashboard: sampleDashboard,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CONDITIONS AROUND YOU'), findsOneWidget);
      expect(find.textContaining('COMMUTE STATUS'), findsOneWidget);
      expect(find.text('Roads'), findsOneWidget);
      expect(find.text('Sight'), findsOneWidget);
      expect(find.text('Wind'), findsOneWidget);
      expect(find.text('OUTDOOR ACTIVITY'), findsOneWidget);
      expect(find.text('ENVIRONMENT & SOIL'), findsOneWidget);
    });
  });

  group('HomeScreen Content Flow Order', () {
    testWidgets('verifies exact 10-tier content sequence on HomeScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 4500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const testHomeResponse = PersonalizedHomeResponse(
        persona: 'Runner',
        greeting: 'Good morning',
        cards: [
          RankedHomeCard(
            id: 'card_1',
            cardType: 'hydration',
            rank: 1,
            score: 0.95,
            title: 'Hydration Strategy',
            subtitle: 'Take frequent water breaks outdoors today',
            category: 'Health',
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          weatherDashboardProvider.overrideWith(
            () => _MockDashboardNotifier(
              const WeatherDashboardState(data: sampleDashboard),
            ),
          ),
          userProvider.overrideWith(
            () => _MockUserNotifier(
              const UserState(displayName: 'Aarav Sharma', selectedPersona: 'Runner'),
            ),
          ),
          locationProvider.overrideWith(
            () => _MockLocationNotifier(
              const LocationState(activeCityName: 'New Delhi'),
            ),
          ),
          homepageProvider.overrideWith(
            () => _MockHomepageNotifier(
              const HomepageState(data: testHomeResponse),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all components exist in the tree
      expect(find.byType(PersonalizedContextCard), findsOneWidget);
      expect(find.byType(HeroCurrentCard), findsOneWidget);
      expect(find.byType(RecommendedSectionWidget), findsOneWidget);
      expect(find.byType(HourlyForecastStrip), findsOneWidget);
      expect(find.byType(DailyForecastPanel), findsOneWidget);
      expect(find.byType(AqiGaugeCard), findsOneWidget);
      expect(find.byType(TodaysMetricsGrid), findsOneWidget);
      expect(find.byType(AdditionalConditionsSection), findsOneWidget);
      expect(find.byType(ConditionsAroundYouSection), findsOneWidget);

      // Verify strict top-to-bottom layout sequence
      final greetingTop = tester.getTopLeft(find.byType(PersonalizedContextCard)).dy;
      final heroTop = tester.getTopLeft(find.byType(HeroCurrentCard)).dy;
      final recommendedTop = tester.getTopLeft(find.byType(RecommendedSectionWidget)).dy;
      final hourlyTop = tester.getTopLeft(find.byType(HourlyForecastStrip)).dy;
      final dailyTop = tester.getTopLeft(find.byType(DailyForecastPanel)).dy;
      final aqiTop = tester.getTopLeft(find.byType(AqiGaugeCard)).dy;
      final todayMetricsTop = tester.getTopLeft(find.byType(TodaysMetricsGrid)).dy;
      final additionalConditionsTop = tester.getTopLeft(find.byType(AdditionalConditionsSection)).dy;
      final conditionsAroundYouTop = tester.getTopLeft(find.byType(ConditionsAroundYouSection)).dy;

      expect(greetingTop, lessThan(heroTop), reason: 'Greeting above Hero');
      expect(heroTop, lessThan(recommendedTop), reason: 'Hero above Recommended');
      expect(recommendedTop, lessThan(hourlyTop), reason: 'Recommended above Hourly');
      expect(hourlyTop, lessThan(dailyTop), reason: 'Hourly above Daily');
      expect(dailyTop, lessThan(aqiTop), reason: 'Daily above AQI');
      expect(aqiTop, lessThan(todayMetricsTop), reason: 'AQI above TodaysMetrics');
      expect(todayMetricsTop, lessThan(additionalConditionsTop), reason: 'TodaysMetrics above AdditionalConditions');
      expect(additionalConditionsTop, lessThan(conditionsAroundYouTop), reason: 'AdditionalConditions above ConditionsAroundYou');
    });
  });

  group('Responsive Layout Zero Overflow Verification', () {
    for (final width in [320.0, 360.0, 393.0, 412.0]) {
      testWidgets('renders all added sections with ZERO overflow at width ${width}px', (tester) async {
        tester.view.physicalSize = Size(width, 3500);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      DailyForecastPanel(days: sampleDashboard.daily),
                      const TodaysMetricsGrid(dashboard: sampleDashboard),
                      const AdditionalConditionsSection(dashboard: sampleDashboard),
                      const ConditionsAroundYouSection(dashboard: sampleDashboard),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // tester.takeException() returns any FlutterError or overflow caught during layout
        expect(tester.takeException(), isNull, reason: 'Must not produce any overflow on width $width');
      });
    }
  });
}

class _MockDashboardNotifier extends WeatherDashboardNotifier {
  final WeatherDashboardState _state;
  _MockDashboardNotifier(this._state);

  @override
  WeatherDashboardState build() => _state;
}

class _MockUserNotifier extends UserNotifier {
  final UserState _state;
  _MockUserNotifier(this._state);

  @override
  UserState build() => _state;
}

class _MockLocationNotifier extends LocationNotifier {
  final LocationState _state;
  _MockLocationNotifier(this._state);

  @override
  LocationState build() => _state;
}

class _MockHomepageNotifier extends HomepageNotifier {
  final HomepageState _state;
  _MockHomepageNotifier(this._state);

  @override
  HomepageState build() => _state;
}
