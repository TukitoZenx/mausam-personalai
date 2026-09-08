import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/models/weather_dashboard.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/user_provider.dart';
import 'package:mobile/providers/weather_dashboard_provider.dart';
import 'package:mobile/router/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeUser extends Fake implements User {
  @override
  String get uid => 'fake_uid';
  @override
  String get email => 'test@mausam.ai';
}

class MockWeatherDashboardNotifier extends WeatherDashboardNotifier {
  final WeatherDashboard _data;
  MockWeatherDashboardNotifier(this._data);

  @override
  WeatherDashboardState build() {
    return WeatherDashboardState(data: _data);
  }
}

class MockUserNotifier extends UserNotifier {
  final UserState _userState;
  MockUserNotifier(this._userState);

  @override
  UserState build() {
    return _userState;
  }

  @override
  Future<void> setTriggersAndConcerns({
    required List<String> triggers,
    required List<String> concerns,
  }) async {
    state = state.copyWith(weatherTriggers: triggers, healthConcerns: concerns);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const mockDashboard = WeatherDashboard(
    current: CurrentConditions(
      location: 'New Delhi',
      temperatureCelsius: 32.0,
      condition: 'Sunny',
      humidityPercent: 60,
      windSpeedKmh: 12.0,
      uvIndex: 7.2,
      feelsLikeCelsius: 36.0,
      dewPointCelsius: 22.0,
    ),
    hourly: [],
    daily: [],
    aqi: AqiSnapshot(
      aqiValue: 165,
      category: 'Moderate',
      pollutants: {
        'pm2_5': 85.0,
        'pm10': 140.0,
        'no2': 45.0,
        'so2': 18.0,
        'co': 25.0,
        'o3': 30.0,
      },
    ),
  );

  testWidgets('HealthMetricsScreen toggles Detailed Analysis and shows clinical breakdown', (tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final userNotifier = MockUserNotifier(
      const UserState(
        selectedPersona: 'Fitness',
        healthConcerns: ['Asthma'],
        weatherTriggers: ['Heat'],
      ),
    );

    final router = createRouter(initialLocation: '/health-metrics');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(FakeUser())),
          weatherDashboardProvider.overrideWith(() => MockWeatherDashboardNotifier(mockDashboard)),
          userProvider.overrideWith(() => userNotifier),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial state: Detailed analysis is off
    expect(find.text('Detailed Analysis'), findsOneWidget);
    expect(find.text('CLINICAL PULMONARY & EXPOSURE ANALYSIS'), findsNothing);

    // Tap Detailed Analysis button to activate
    await tester.tap(find.text('Detailed Analysis'));
    await tester.pumpAndSettle();

    // Verify clinical analysis sections appear
    expect(find.text('Detailed: ON'), findsOneWidget);
    expect(find.text('CLINICAL PULMONARY & EXPOSURE ANALYSIS'), findsOneWidget);
    expect(find.text('FITZPATRICK PHOTOTYPE & DERMAL PROTOCOL'), findsOneWidget);
    expect(find.text('ALLERGEN PHENOLOGY & BIO-AEROSOL DISPERSAL'), findsOneWidget);
    expect(find.text('THERMAL STRAIN & OSMOREGULATION MODEL'), findsOneWidget);

    // Toggle active health focus chip
    expect(find.text('UV & Skin Care'), findsOneWidget);
    await tester.tap(find.text('UV & Skin Care'));
    await tester.pumpAndSettle();

    // Verify userState received new health concern
    expect(userNotifier.state.healthConcerns.contains('Skin sensitivity'), isTrue);
  });
}
