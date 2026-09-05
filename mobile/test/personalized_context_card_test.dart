import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/weather_dashboard.dart';
import 'package:mobile/providers/location_provider.dart';
import 'package:mobile/providers/user_provider.dart';
import 'package:mobile/providers/weather_dashboard_provider.dart';
import 'package:mobile/screens/home_screen.dart';
import 'package:mobile/widgets/cards/personalized_context_card.dart';
import 'package:mobile/widgets/weather/weather_sections.dart';

void main() {
  group('PersonalizedContextCard Logic Tests', () {
    test('greetingForHour correctly categorizes all 24 hours', () {
      // Morning: 05:00 - 11:59
      expect(PersonalizedContextCard.greetingForHour(5), equals('Good morning'));
      expect(PersonalizedContextCard.greetingForHour(9), equals('Good morning'));
      expect(PersonalizedContextCard.greetingForHour(11), equals('Good morning'));

      // Afternoon: 12:00 - 16:59
      expect(PersonalizedContextCard.greetingForHour(12), equals('Good afternoon'));
      expect(PersonalizedContextCard.greetingForHour(14), equals('Good afternoon'));
      expect(PersonalizedContextCard.greetingForHour(16), equals('Good afternoon'));

      // Evening: 17:00 - 21:59
      expect(PersonalizedContextCard.greetingForHour(17), equals('Good evening'));
      expect(PersonalizedContextCard.greetingForHour(19), equals('Good evening'));
      expect(PersonalizedContextCard.greetingForHour(21), equals('Good evening'));

      // Night: 22:00 - 04:59
      expect(PersonalizedContextCard.greetingForHour(22), equals('Good night'));
      expect(PersonalizedContextCard.greetingForHour(23), equals('Good night'));
      expect(PersonalizedContextCard.greetingForHour(0), equals('Good night'));
      expect(PersonalizedContextCard.greetingForHour(4), equals('Good night'));
    });

    test('resolveUserName extracts clean first names and falls back gracefully', () {
      // With display name
      expect(
        PersonalizedContextCard.resolveUserName(
          const UserState(displayName: 'Hari Kumar', email: 'hari@test.com'),
        ),
        equals('Hari'),
      );

      // With email prefix
      expect(
        PersonalizedContextCard.resolveUserName(
          const UserState(email: 'rahul.verma@example.com'),
        ),
        equals('Rahul'),
      );

      // With hyphen/underscore in email
      expect(
        PersonalizedContextCard.resolveUserName(
          const UserState(email: 'priya_sharma@test.com'),
        ),
        equals('Priya'),
      );

      // Guest session
      expect(
        PersonalizedContextCard.resolveUserName(
          const UserState(isGuest: true, email: 'guest@mausam.ai'),
        ),
        equals('Guest'),
      );

      // Unauthenticated fallback
      expect(
        PersonalizedContextCard.resolveUserName(null),
        equals('User'),
      );
    });

    test('resolveWatchingConditions dynamically derives conditions from weather state', () {
      // 1. Morning Rain + AQI
      const rainAndAqiDashboard = WeatherDashboard(
        current: CurrentConditions(
          location: 'Bengaluru',
          temperatureCelsius: 24.0,
          condition: 'Light Rain',
          humidityPercent: 82,
          windSpeedKmh: 12.0,
          uvIndex: 2.0,
          rainMm1h: 1.8,
        ),
        aqi: AqiSnapshot(aqiValue: 95, category: 'Moderate'),
      );

      final morningWatching = PersonalizedContextCard.resolveWatchingConditions(
        dashboard: rainAndAqiDashboard,
        persona: 'Fitness',
        hour: 8,
      );
      expect(morningWatching, equals('Rain + AQI'));

      // 2. Afternoon Heat + UV
      const heatAndUvDashboard = WeatherDashboard(
        current: CurrentConditions(
          location: 'Bengaluru',
          temperatureCelsius: 35.5,
          condition: 'Sunny',
          humidityPercent: 40,
          windSpeedKmh: 10.0,
          uvIndex: 8.5,
        ),
        aqi: AqiSnapshot(aqiValue: 42, category: 'Good'),
      );

      final afternoonWatching = PersonalizedContextCard.resolveWatchingConditions(
        dashboard: heatAndUvDashboard,
        persona: 'Fitness',
        hour: 14,
      );
      expect(afternoonWatching, equals('Heat + UV'));

      // 3. Evening Rain
      const eveningRainDashboard = WeatherDashboard(
        current: CurrentConditions(
          location: 'Bengaluru',
          temperatureCelsius: 23.0,
          condition: 'Drizzle',
          humidityPercent: 88,
          windSpeedKmh: 8.0,
          uvIndex: 0.0,
          rainMm1h: 0.5,
        ),
        aqi: AqiSnapshot(aqiValue: 35, category: 'Good'),
      );

      final eveningWatching = PersonalizedContextCard.resolveWatchingConditions(
        dashboard: eveningRainDashboard,
        persona: 'Fitness',
        hour: 19,
      );
      expect(eveningWatching, equals('Rain'));

      // 4. Night Air Quality
      const nightAqiDashboard = WeatherDashboard(
        current: CurrentConditions(
          location: 'Bengaluru',
          temperatureCelsius: 21.0,
          condition: 'Clear',
          humidityPercent: 65,
          windSpeedKmh: 6.0,
          uvIndex: 0.0,
        ),
        aqi: AqiSnapshot(aqiValue: 110, category: 'Unhealthy for Sensitive Groups'),
      );

      final nightWatching = PersonalizedContextCard.resolveWatchingConditions(
        dashboard: nightAqiDashboard,
        persona: 'Health',
        hour: 23,
      );
      expect(nightWatching, equals('Air Quality'));
    });
  });

  group('PersonalizedContextCard Widget Tests', () {
    testWidgets('renders all required elements with monochrome styling', (tester) async {
      bool tapped = false;

      const testDashboard = WeatherDashboard(
        current: CurrentConditions(
          location: 'Bengaluru, Karnataka',
          temperatureCelsius: 22.0,
          condition: 'Rain',
          humidityPercent: 85,
          windSpeedKmh: 10.0,
          uvIndex: 1.0,
          rainMm1h: 2.0,
        ),
        aqi: AqiSnapshot(aqiValue: 88, category: 'Moderate'),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PersonalizedContextCard(
                locationName: 'Bengaluru, Karnataka',
                dashboard: testDashboard,
                hourOverride: 9,
                userNameOverride: 'Hari',
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      // Verify Greeting and Name
      expect(find.text('Good morning, Hari'), findsOneWidget);

      // Verify Clean Location
      expect(find.text('Personalised for Bengaluru'), findsOneWidget);

      // Verify Dynamic Watching status
      expect(find.text('Watching Rain + AQI'), findsOneWidget);

      // Verify Icons (sparkle and chevron)
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      // Verify Tap Interaction
      await tester.tap(find.byType(PersonalizedContextCard));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('renders evening greeting and single condition correctly', (tester) async {
      const testDashboard = WeatherDashboard(
        current: CurrentConditions(
          location: 'Delhi',
          temperatureCelsius: 26.0,
          condition: 'Rain',
          humidityPercent: 70,
          windSpeedKmh: 14.0,
          uvIndex: 0.0,
          rainMm1h: 3.5,
        ),
        aqi: AqiSnapshot(aqiValue: 40, category: 'Good'),
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PersonalizedContextCard(
                locationName: 'Delhi',
                dashboard: testDashboard,
                hourOverride: 18,
                userNameOverride: 'Hari',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Good evening, Hari'), findsOneWidget);
      expect(find.text('Personalised for Delhi'), findsOneWidget);
      expect(find.text('Watching Rain'), findsOneWidget);
    });

    testWidgets('HomeScreen integrates PersonalizedContextCard directly above HeroCurrentCard', (tester) async {
      const mockData = WeatherDashboard(
        current: CurrentConditions(
          location: 'Bengaluru',
          temperatureCelsius: 25.0,
          condition: 'Cloudy',
          humidityPercent: 60,
          windSpeedKmh: 15.0,
          uvIndex: 4.0,
        ),
        aqi: AqiSnapshot(aqiValue: 45, category: 'Good'),
      );

      final container = ProviderContainer(
        overrides: [
          weatherDashboardProvider.overrideWith(() => _MockDashboardNotifier(
            const WeatherDashboardState(data: mockData),
          )),
          userProvider.overrideWith(() => _MockUserNotifier(
            const UserState(displayName: 'Hari', selectedPersona: 'Fitness'),
          )),
          locationProvider.overrideWith(() => _MockLocationNotifier(
            const LocationState(activeCityName: 'Bengaluru'),
          )),
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

      // Verify PersonalizedContextCard is rendered
      expect(find.byType(PersonalizedContextCard), findsOneWidget);
      expect(find.text('Personalised for Bengaluru'), findsOneWidget);
      expect(find.textContaining('Good'), findsOneWidget);
      expect(find.textContaining('Hari'), findsOneWidget);

      // Verify HeroCurrentCard is also rendered
      expect(find.byType(HeroCurrentCard), findsOneWidget);

      // Verify HourlyForecastStrip is rendered directly below HeroCurrentCard
      expect(find.byType(HourlyForecastStrip), findsOneWidget);

      // Verify relative vertical positioning: PersonalizedContextCard is ABOVE HeroCurrentCard,
      // and HeroCurrentCard is ABOVE HourlyForecastStrip (For You card removed).
      final cardTop = tester.getTopLeft(find.byType(PersonalizedContextCard)).dy;
      final heroTop = tester.getTopLeft(find.byType(HeroCurrentCard)).dy;
      final hourlyTop = tester.getTopLeft(find.byType(HourlyForecastStrip)).dy;
      expect(cardTop, lessThan(heroTop));
      expect(heroTop, lessThan(hourlyTop));
    });
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

