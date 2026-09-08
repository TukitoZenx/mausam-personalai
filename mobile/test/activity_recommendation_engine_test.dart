import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/weather_dashboard.dart';
import 'package:mobile/providers/user_provider.dart';
import 'package:mobile/services/activity_recommendation_engine.dart';

void main() {
  group('ActivityRecommendationEngine', () {
    const mockCurrent = CurrentConditions(
      location: 'Bengaluru',
      temperatureCelsius: 24.0,
      condition: 'Partly Cloudy',
      humidityPercent: 65,
      windSpeedKmh: 10.0,
      uvIndex: 4.5,
      feelsLikeCelsius: 24.0,
    );

    final mockHourly = [
      const HourlyForecastItem(dtUnix: 100, hourLabel: '5 AM', temperatureCelsius: 19.0, condition: 'Clear', rainProbabilityPercent: 5),
      const HourlyForecastItem(dtUnix: 101, hourLabel: '6 AM', temperatureCelsius: 20.0, condition: 'Clear', rainProbabilityPercent: 5),
      const HourlyForecastItem(dtUnix: 102, hourLabel: '7 AM', temperatureCelsius: 22.0, condition: 'Clear', rainProbabilityPercent: 10),
      const HourlyForecastItem(dtUnix: 103, hourLabel: '8 AM', temperatureCelsius: 25.0, condition: 'Partly Cloudy', rainProbabilityPercent: 10),
      const HourlyForecastItem(dtUnix: 104, hourLabel: '9 AM', temperatureCelsius: 28.0, condition: 'Partly Cloudy', rainProbabilityPercent: 15),
      const HourlyForecastItem(dtUnix: 105, hourLabel: '5 PM', temperatureCelsius: 27.0, condition: 'Partly Cloudy', rainProbabilityPercent: 10),
      const HourlyForecastItem(dtUnix: 106, hourLabel: '6 PM', temperatureCelsius: 25.0, condition: 'Clear', rainProbabilityPercent: 10),
      const HourlyForecastItem(dtUnix: 107, hourLabel: '7 PM', temperatureCelsius: 23.0, condition: 'Clear', rainProbabilityPercent: 5),
    ];

    const mockAqi = AqiSnapshot(
      aqiValue: 45,
      category: 'Good',
    );

    final mockDashboard = WeatherDashboard(
      current: mockCurrent,
      hourly: mockHourly,
      daily: const [],
      aqi: mockAqi,
    );

    test('calculates optimal morning walking window using profile sensitivities', () {
      const userState = UserState(
        age: 32,
        gender: 'Female',
        selectedPersona: 'Fitness',
        weatherTriggers: ['Heat'],
      );

      final rec = ActivityRecommendationEngine.calculateRecommendation(
        dashboardData: mockDashboard,
        userState: userState,
        activity: 'walking',
        targetPeriod: 'morning',
      );

      expect(rec.activity, equals('walking'));
      expect(rec.recommendedWindow, contains('AM'));
      expect(rec.temperatureCelsius, lessThanOrEqualTo(24));
      expect(rec.aqiValue, equals(45));
      expect(rec.isIdeal, isTrue);
      expect(rec.whyReason, isNotEmpty);
      expect(rec.notificationBody, contains("Tomorrow's best walking window"));
    });

    test('prioritizes cool window when user has heat sensitivity and senior age', () {
      const userState = UserState(
        age: 65,
        gender: 'Male',
        selectedPersona: 'Health & Wellness',
        weatherTriggers: ['Heat'],
        healthConcerns: ['Asthma'],
      );

      final rec = ActivityRecommendationEngine.calculateRecommendation(
        dashboardData: mockDashboard,
        userState: userState,
        activity: 'walking',
        targetPeriod: 'morning',
      );

      // Should choose early cool hour (e.g. 5-7 AM)
      expect(rec.temperatureCelsius, lessThanOrEqualTo(22));
      expect(rec.whyReason, contains('temperature'));
    });

    test('suggests alternative window when morning has high rain probability', () {
      final rainyHourly = [
        const HourlyForecastItem(dtUnix: 201, hourLabel: '6 AM', temperatureCelsius: 21.0, condition: 'Rain', rainProbabilityPercent: 80),
        const HourlyForecastItem(dtUnix: 202, hourLabel: '7 AM', temperatureCelsius: 22.0, condition: 'Rain', rainProbabilityPercent: 75),
        const HourlyForecastItem(dtUnix: 203, hourLabel: '8 AM', temperatureCelsius: 23.0, condition: 'Rain', rainProbabilityPercent: 70),
        const HourlyForecastItem(dtUnix: 204, hourLabel: '5 PM', temperatureCelsius: 25.0, condition: 'Clear', rainProbabilityPercent: 10),
        const HourlyForecastItem(dtUnix: 205, hourLabel: '6 PM', temperatureCelsius: 24.0, condition: 'Clear', rainProbabilityPercent: 10),
      ];

      final rainyDashboard = WeatherDashboard(
        current: mockCurrent,
        hourly: rainyHourly,
        daily: const [],
        aqi: mockAqi,
      );

      const userState = UserState(
        age: 28,
        weatherTriggers: ['Rain'],
      );

      final rec = ActivityRecommendationEngine.calculateRecommendation(
        dashboardData: rainyDashboard,
        userState: userState,
        activity: 'walking',
        targetPeriod: 'morning',
      );

      expect(rec.isIdeal, isFalse);
      expect(rec.rainProbabilityPercent, greaterThanOrEqualTo(70));
      expect(rec.alternativeWindow, isNotNull);
    });

    test('returns sensible fallback when dashboard data is null', () {
      const userState = UserState();
      final rec = ActivityRecommendationEngine.calculateRecommendation(
        dashboardData: null,
        userState: userState,
        activity: 'walking',
        targetPeriod: 'morning',
      );

      expect(rec.activity, equals('walking'));
      expect(rec.recommendedWindow, equals('6:30–7:30 AM'));
      expect(rec.isIdeal, isTrue);
    });
  });
}
