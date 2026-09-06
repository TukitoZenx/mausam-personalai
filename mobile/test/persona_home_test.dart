import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/weather_dashboard.dart';
import 'package:mobile/widgets/weather/persona_home.dart';

WeatherDashboard _dash() {
  return const WeatherDashboard(
    current: CurrentConditions(
      location: 'Test City',
      temperatureCelsius: 29,
      condition: 'Clear',
      humidityPercent: 55,
      windSpeedKmh: 10,
      uvIndex: 6,
      feelsLikeCelsius: 31,
      visibilityKm: 9,
      rainMm1h: 0,
    ),
    hourly: [],
    daily: [
      DailyForecastItem(
        day: 'Today',
        highCelsius: 33,
        lowCelsius: 24,
        condition: 'Clear',
        rainProbabilityPercent: 10,
      ),
    ],
    aqi: AqiSnapshot(aqiValue: 70, category: 'Fair'),
  );
}

void main() {
  test('Health persona prefers Air Quality and UV, not commute', () {
    final d = _dash();
    final today = PersonaHome.todayMetrics('Health', d);
    expect(today.map((e) => e.title), ['AIR QUALITY', 'UV INDEX']);
    expect(PersonaHome.showCommute('Health'), isFalse);
    expect(PersonaHome.contextual('Health', d).length, lessThanOrEqualTo(3));
  });

  test('Commuter persona surfaces commute context', () {
    final d = _dash();
    expect(PersonaHome.showCommute('Commuter'), isTrue);
    final ctx = PersonaHome.contextual('Commuter', d);
    expect(ctx.any((e) => e.wide), isTrue);
  });

  test('Garden persona uses rainfall and frost, never invented soil moisture', () {
    final today = PersonaHome.todayMetrics('Garden', _dash());
    expect(today.map((e) => e.title).toList(), containsAll(['RAINFALL', 'FROST RISK']));
    expect(today.any((e) => e.title.contains('SOIL')), isFalse);
  });
}
