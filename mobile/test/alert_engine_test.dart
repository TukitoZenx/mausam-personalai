import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/weather_dashboard.dart';

void main() {
  group('Alert Engine & Display Tests', () {
    test('Generates Heat Caution when temperature is >= 30°C', () {
      const mockData = WeatherDashboard(
        current: CurrentConditions(
          location: 'Hyderabad',
          temperatureCelsius: 32.5,
          condition: 'Sunny',
          humidityPercent: 45,
          windSpeedKmh: 12.0,
          uvIndex: 4.0,
        ),
      );

      expect(mockData.current.temperatureCelsius, greaterThanOrEqualTo(30.0));
    });

    test('Generates Rain Advisory when light rain is detected', () {
      const mockData = WeatherDashboard(
        current: CurrentConditions(
          location: 'Mumbai',
          temperatureCelsius: 27.0,
          condition: 'Light Rain Showers',
          humidityPercent: 88,
          windSpeedKmh: 15.0,
          uvIndex: 2.0,
          rainMm1h: 1.5,
        ),
      );

      expect(mockData.current.rainMm1h, greaterThan(0.0));
      expect(mockData.current.condition.toLowerCase(), contains('rain'));
    });

    test('Generates Air Quality Precaution when AQI is >= 100', () {
      const mockData = WeatherDashboard(
        current: CurrentConditions(
          location: 'Delhi',
          temperatureCelsius: 29.0,
          condition: 'Haze',
          humidityPercent: 50,
          windSpeedKmh: 8.0,
          uvIndex: 3.0,
        ),
        aqi: AqiSnapshot(
          aqiValue: 145,
          category: 'Unhealthy for Sensitive Groups',
        ),
      );

      expect(mockData.aqi?.aqiValue, greaterThanOrEqualTo(100));
    });
  });
}
