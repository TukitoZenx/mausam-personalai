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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const mockDashboard = WeatherDashboard(
    current: CurrentConditions(
      location: 'Bengaluru',
      temperatureCelsius: 28.0,
      condition: 'Clear',
      humidityPercent: 55,
      windSpeedKmh: 8.0,
      uvIndex: 4.5,
      feelsLikeCelsius: 29.0,
    ),
    hourly: [],
    daily: [],
    aqi: AqiSnapshot(
      aqiValue: 42,
      category: 'Good',
    ),
  );

  const mockUserState = UserState(
    age: 28,
    gender: 'Male',
    height: 175,
    weight: 70,
    selectedPersona: 'Fitness',
    weatherTriggers: ['Heat', 'High UV'],
    healthConcerns: ['Asthma'],
  );

  testWidgets('ContextDetailScreen renders 2 tabs (Persona & Health) and switches between them', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = createRouter(initialLocation: '/context-detail');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(FakeUser())),
          weatherDashboardProvider.overrideWith(() => MockWeatherDashboardNotifier(mockDashboard)),
          userProvider.overrideWith(() => MockUserNotifier(mockUserState)),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify both tabs exist on Persona Context page
    expect(find.text('Persona Context'), findsOneWidget);
    expect(find.text('Health & Metrics'), findsOneWidget);
    expect(find.byKey(const Key('context_detail_back_button')), findsOneWidget);

    // Persona Context is active
    expect(find.text('ACTIVE PERSONA'), findsOneWidget);
    expect(find.text('Fitness'), findsWidgets);
    expect(find.text('Profile & Physical Context'), findsOneWidget);
    expect(find.text('28 yrs'), findsOneWidget);

    // Tap Health & Metrics tab -> navigates to /health-metrics
    await tester.tap(find.text('Health & Metrics'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, equals('/health-metrics'));
    expect(find.byKey(const Key('health_metrics_blank_page')), findsOneWidget);

    // Tap Persona Context tab -> navigates back to /context-detail
    await tester.tap(find.text('Persona Context'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, equals('/context-detail'));

    // Tap back button -> navigates to /home
    await tester.tap(find.byKey(const Key('context_detail_back_button')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, equals('/home'));
  });

  testWidgets('HealthMetricsScreen renders 2 tabs (Persona & Health) and blank canvas', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = createRouter(initialLocation: '/health-metrics');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(FakeUser())),
          weatherDashboardProvider.overrideWith(() => MockWeatherDashboardNotifier(mockDashboard)),
          userProvider.overrideWith(() => MockUserNotifier(mockUserState)),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify both tabs exist on Health & Metrics page
    expect(find.text('Persona Context'), findsOneWidget);
    expect(find.text('Health & Metrics'), findsOneWidget);
    expect(find.byKey(const Key('health_metrics_back_button')), findsOneWidget);
    expect(find.byKey(const Key('health_metrics_blank_page')), findsOneWidget);

    // Verify 4 reference cards & tailored health intelligence
    expect(find.textContaining('INDIA NATIONAL AQI'), findsOneWidget);
    expect(find.text('UV INDEX'), findsOneWidget);
    expect(find.text('POLLEN OUTLOOK (SEASONAL ESTIMATE)'), findsOneWidget);
    expect(find.text('HEAT & HYDRATION'), findsOneWidget);

    // Verify pollutants & tailored health advisories
    expect(find.text('PM2.5'), findsOneWidget);
    expect(find.text('O₃'), findsOneWidget);
    expect(find.text('Tree Pollen'), findsOneWidget);
    expect(find.text('Peak Hours'), findsOneWidget);
    expect(find.text('Heat Index (Approx.)'), findsOneWidget);
    expect(find.textContaining('Asthma & Air Advisory'), findsOneWidget);

    // Tap back button -> navigates to /home
    await tester.tap(find.byKey(const Key('health_metrics_back_button')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, equals('/home'));
  });
}
