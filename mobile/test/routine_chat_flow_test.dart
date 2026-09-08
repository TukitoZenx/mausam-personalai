import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/models/weather_dashboard.dart';
import 'package:mobile/providers/user_provider.dart';
import 'package:mobile/providers/weather_dashboard_provider.dart';
import 'package:mobile/screens/insights_screen.dart';
import 'package:mobile/widgets/ai/active_routine_reminder_card.dart';
import 'package:mobile/widgets/ai/routine_recommendation_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      temperatureCelsius: 22.0,
      condition: 'Clear',
      humidityPercent: 55,
      windSpeedKmh: 8.0,
      uvIndex: 3.0,
      feelsLikeCelsius: 22.0,
    ),
    hourly: [
      HourlyForecastItem(dtUnix: 101, hourLabel: '6 AM', temperatureCelsius: 19.0, condition: 'Clear', rainProbabilityPercent: 5),
      HourlyForecastItem(dtUnix: 102, hourLabel: '7 AM', temperatureCelsius: 20.0, condition: 'Clear', rainProbabilityPercent: 5),
      HourlyForecastItem(dtUnix: 103, hourLabel: '8 AM', temperatureCelsius: 22.0, condition: 'Clear', rainProbabilityPercent: 5),
    ],
    daily: [],
    aqi: AqiSnapshot(
      aqiValue: 38,
      category: 'Good',
    ),
  );

  Widget buildChatApp({UserState? userState}) {
    final state = userState ?? const UserState(age: 30, selectedPersona: 'Fitness');
    return ProviderScope(
      overrides: [
        weatherDashboardProvider.overrideWith(() => MockWeatherDashboardNotifier(mockDashboard)),
        userProvider.overrideWith(() => MockUserNotifier(state)),
      ],
      child: const MaterialApp(
        home: InsightsScreen(),
      ),
    );
  }

  group('Mausam AI Routine Reminder & Activity Intelligence Flow', () {
    testWidgets('Full flow: sets daily 9:00 PM reminder and renders recommendation card', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildChatApp());
      await tester.pumpAndSettle();

      // Verify the new Daily walking reminder suggestion chip is present
      expect(find.text('Daily walking reminder'), findsOneWidget);

      // Enter user query
      final inputField = find.byType(TextField);
      expect(inputField, findsOneWidget);

      await tester.enterText(
        inputField,
        'Every day at 9:00 PM, remind me what time I should go walking tomorrow.',
      );
      await tester.pump();

      // Tap Send message button
      final sendBtn = find.byTooltip('Send message');
      expect(sendBtn, findsOneWidget);
      await tester.tap(sendBtn);

      // Advance clock for generation delay timer (60ms in test) and async futures
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Pump streaming responses
      for (int i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 30));
      }
      await tester.pumpAndSettle();

      // Check assistant response confirmation text
      expect(find.textContaining('9:00 PM'), findsWidgets);

      // Check RoutineRecommendationCard is displayed
      expect(find.byType(RoutineRecommendationCard), findsOneWidget);
      expect(find.textContaining("TOMORROW'S BEST WALKING WINDOW"), findsOneWidget);
      expect(find.textContaining('AQI 38'), findsOneWidget);
      expect(find.text('WHY'), findsOneWidget);

      // Check ActiveRoutineReminderCard is displayed
      expect(find.byType(ActiveRoutineReminderCard), findsOneWidget);
      expect(find.text('DAILY WALKING CHECK'), findsOneWidget);
      expect(find.text('Status: Active'), findsOneWidget);
      expect(find.text('Every day · 9:00 PM'), findsOneWidget);

      // Tap Pause button
      final pauseBtn = find.text('Pause');
      expect(pauseBtn, findsOneWidget);
      await tester.tap(pauseBtn);
      await tester.pumpAndSettle();

      // Status should now be Paused
      expect(find.text('Status: Paused'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);

      // Tap Resume button
      final resumeBtn = find.text('Resume');
      await tester.tap(resumeBtn);
      await tester.pumpAndSettle();

      expect(find.text('Status: Active'), findsOneWidget);

      // Tap Delete button
      final deleteBtn = find.text('Delete');
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Status should show Reminder deleted
      expect(find.text('Reminder deleted'), findsOneWidget);
    });

    testWidgets('Tapping the suggestion chip submits the routine prompt directly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildChatApp());
      await tester.pumpAndSettle();

      final chip = find.text('Daily walking reminder');
      expect(chip, findsOneWidget);

      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      for (int i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 30));
      }
      await tester.pumpAndSettle();

      expect(find.byType(RoutineRecommendationCard), findsOneWidget);
      expect(find.byType(ActiveRoutineReminderCard), findsOneWidget);
    });
  });
}
