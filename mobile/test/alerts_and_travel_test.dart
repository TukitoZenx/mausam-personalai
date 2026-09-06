import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/weather_dashboard.dart';
import 'package:mobile/providers/weather_dashboard_provider.dart';
import 'package:mobile/screens/alerts_screen.dart';

void main() {
  const sampleDashboard = WeatherDashboard(
    current: CurrentConditions(
      location: 'Kolkata',
      temperatureCelsius: 28.0,
      feelsLikeCelsius: 32.0,
      condition: 'Heavy Rain',
      humidityPercent: 88,
      windSpeedKmh: 18.0,
      uvIndex: 7.0,
      rainMm1h: 6.5,
    ),
    hourly: [],
    daily: [
      DailyForecastItem(
        day: 'Today',
        condition: 'Rain',
        highCelsius: 32.0,
        lowCelsius: 26.0,
        rainProbabilityPercent: 78,
      ),
    ],
    aqi: AqiSnapshot(aqiValue: 80, category: 'Moderate'),
  );

  group('Alerts & Travel Screen Tests', () {
    testWidgets('renders all 4 sections matching reference layout', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weatherDashboardProvider.overrideWith(() => WeatherDashboardNotifierMock(sampleDashboard)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AlertsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title
      expect(find.text('ALERTS & TRAVEL'), findsOneWidget);

      // Section 1: ACTIVE ALERTS
      expect(find.textContaining('ACTIVE ALERTS'), findsOneWidget);
      expect(find.text('Heavy Rainfall Warning'), findsOneWidget);
      expect(find.text('Just now'), findsOneWidget);
      expect(find.textContaining('ORANGE ALERT'), findsOneWidget);

      // Section 2: SAVED LOCATIONS
      expect(find.text('SAVED LOCATIONS'), findsOneWidget);
      expect(find.text('Darjeeling'), findsOneWidget);
      expect(find.text('18°'), findsOneWidget);
      expect(find.text('600 km'), findsOneWidget);

      expect(find.text('Digha Beach'), findsOneWidget);
      expect(find.text('31°'), findsOneWidget);
      expect(find.text('180 km'), findsOneWidget);

      expect(find.text('Sundarbans'), findsOneWidget);
      expect(find.text('32°'), findsOneWidget);
      expect(find.text('130 km'), findsOneWidget);

      expect(find.text('Siliguri'), findsOneWidget);
      expect(find.text('27°'), findsOneWidget);
      expect(find.text('570 km'), findsOneWidget);

      // Section 3: TODAY'S PACKING LIST
      expect(find.text("TODAY'S PACKING LIST"), findsOneWidget);
      expect(find.text('Umbrella / rain protection'), findsOneWidget);
      expect(find.textContaining('78% rain chance'), findsOneWidget);
      expect(find.text('Waterproof footwear'), findsOneWidget);

      // Section 4: EVENT PLANNER
      expect(find.text('EVENT PLANNER'), findsOneWidget);
      expect(find.text('Weekend Outdoor Weather Outlook'), findsOneWidget);
      expect(find.text('Expected'), findsOneWidget);
      expect(find.text('Monsoon'), findsOneWidget);
      expect(find.text('33°C avg'), findsOneWidget);
      expect(find.text('Moderate Rain'), findsOneWidget);
      expect(find.textContaining('Some rain possible'), findsOneWidget);
    });

    for (final width in [320.0, 360.0, 393.0, 412.0]) {
      testWidgets('renders AlertsScreen without overflow at width ${width}px', (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              weatherDashboardProvider.overrideWith(() => WeatherDashboardNotifierMock(sampleDashboard)),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: AlertsScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Zero overflow at width ${width}px');
      });
    }
  });
}

class WeatherDashboardNotifierMock extends WeatherDashboardNotifier {
  final WeatherDashboard _dash;
  WeatherDashboardNotifierMock(this._dash);

  @override
  WeatherDashboardState build() {
    return WeatherDashboardState(data: _dash, isLoading: false);
  }
}
