import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/open_meteo_weather_service.dart';

void main() {
  test('maps Open-Meteo forecast JSON into Mausam dashboard shape', () {
    final mapped = OpenMeteoWeatherService.mapForecast({
      'utc_offset_seconds': 19800,
      'current': {
        'temperature_2m': 31.2,
        'relative_humidity_2m': 58,
        'apparent_temperature': 34.0,
        'precipitation': 0.0,
        'weather_code': 1,
        'wind_speed_10m': 12.4,
        'wind_direction_10m': 220,
        'uv_index': 7.1,
        'dew_point_2m': 21.0,
        'surface_pressure': 1008.0,
        'visibility': 10000.0,
      },
      'hourly': {
        'time': ['2099-01-01T10:00', '2099-01-01T11:00'],
        'temperature_2m': [31.0, 32.0],
        'precipitation_probability': [10, 20],
        'precipitation': [0.0, 0.2],
        'weather_code': [1, 2],
      },
      'daily': {
        'time': ['2099-01-01', '2099-01-02'],
        'temperature_2m_max': [33.0, 34.0],
        'temperature_2m_min': [24.0, 25.0],
        'weather_code': [1, 61],
        'sunrise': ['2099-01-01T06:12'],
        'sunset': ['2099-01-01T18:04'],
        'precipitation_sum': [0.0, 4.2],
        'precipitation_probability_max': [10, 70],
      },
    }, locationName: 'Hyderabad');

    final current = mapped['current'] as Map;
    expect(current['location'], 'Hyderabad');
    expect(current['temperature_celsius'], 31.2);
    expect(current['condition'], 'Clouds');
    expect(current['humidity_percent'], 58);
    expect(current['uv_index'], 7.1);
    expect(current['visibility_km'], 10.0);
    expect((mapped['forecast'] as List).length, 2);
    expect((mapped['forecast'] as List).last['condition'], 'Rain');
  });

  test('maps Open-Meteo AQI JSON', () {
    final mapped = OpenMeteoWeatherService.mapAqi({
      'current': {
        'us_aqi': 82,
        'pm2_5': 22.0,
        'pm10': 40.0,
        'nitrogen_dioxide': 12.0,
        'ozone': 60.0,
        'sulphur_dioxide': 3.0,
        'carbon_monoxide': 180.0,
      },
    });
    expect(mapped['aqi_value'], 82);
    expect(mapped['category'], 'Fair');
    expect((mapped['pollutants'] as Map)['pm2_5'], 22.0);
  });
}
