import 'dart:convert';

import 'package:http/http.dart' as http;

/// Live Open-Meteo forecast + air quality. Used when the Mausam API is unreachable.
class OpenMeteoWeatherService {
  OpenMeteoWeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _forecastHost = 'https://api.open-meteo.com/v1/forecast';
  static const _airHost = 'https://air-quality-api.open-meteo.com/v1/air-quality';

  Future<Map<String, dynamic>> fetchForecast({
    required double lat,
    required double lon,
    String locationName = 'Active Location',
  }) async {
    final uri = Uri.parse(_forecastHost).replace(queryParameters: {
      'latitude': lat.toString(),
      'longitude': lon.toString(),
      'current': [
        'temperature_2m',
        'relative_humidity_2m',
        'apparent_temperature',
        'precipitation',
        'weather_code',
        'wind_speed_10m',
        'wind_direction_10m',
        'uv_index',
        'dew_point_2m',
        'surface_pressure',
        'visibility',
      ].join(','),
      'hourly': [
        'temperature_2m',
        'precipitation_probability',
        'precipitation',
        'weather_code',
        'uv_index',
        'wind_speed_10m',
      ].join(','),
      'daily': [
        'weather_code',
        'temperature_2m_max',
        'temperature_2m_min',
        'sunrise',
        'sunset',
        'uv_index_max',
        'precipitation_sum',
        'precipitation_probability_max',
      ].join(','),
      'timezone': 'auto',
      'forecast_days': '7',
      'wind_speed_unit': 'kmh',
    });

    final response = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Open-Meteo forecast HTTP ${response.statusCode}');
    }
    final raw = jsonDecode(response.body);
    if (raw is! Map) throw Exception('Open-Meteo forecast malformed');
    return mapForecast(Map<String, dynamic>.from(raw), locationName: locationName);
  }

  Future<Map<String, dynamic>?> fetchAqi({
    required double lat,
    required double lon,
  }) async {
    try {
      final uri = Uri.parse(_airHost).replace(queryParameters: {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'current': [
          'us_aqi',
          'pm10',
          'pm2_5',
          'carbon_monoxide',
          'nitrogen_dioxide',
          'sulphur_dioxide',
          'ozone',
        ].join(','),
        'timezone': 'auto',
      });
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final raw = jsonDecode(response.body);
      if (raw is! Map) return null;
      return mapAqi(Map<String, dynamic>.from(raw));
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> mapForecast(
    Map<String, dynamic> raw, {
    required String locationName,
  }) {
    final current = (raw['current'] as Map?)?.cast<String, dynamic>() ?? {};
    final daily = (raw['daily'] as Map?)?.cast<String, dynamic>() ?? {};
    final hourly = (raw['hourly'] as Map?)?.cast<String, dynamic>() ?? {};
    final offset = (raw['utc_offset_seconds'] as num?)?.toInt() ?? 0;

    final weatherCode = (current['weather_code'] as num?)?.toInt() ?? 0;
    final visM = (current['visibility'] as num?)?.toDouble();
    final highs = _numList(daily['temperature_2m_max']);
    final lows = _numList(daily['temperature_2m_min']);
    final sunrises = _strList(daily['sunrise']);
    final sunsets = _strList(daily['sunset']);

    final sunriseUnix = _isoToUnix(sunrises.isNotEmpty ? sunrises.first : null);
    final sunsetUnix = _isoToUnix(sunsets.isNotEmpty ? sunsets.first : null);

    final currentJson = {
      'location': locationName,
      'temperature_celsius': (current['temperature_2m'] as num?)?.toDouble() ?? 0,
      'condition': conditionFromWmo(weatherCode),
      'humidity_percent': (current['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      'wind_speed_kmh': (current['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      'uv_index': (current['uv_index'] as num?)?.toDouble() ?? 0,
      'feels_like_celsius': (current['apparent_temperature'] as num?)?.toDouble(),
      'high_celsius': highs.isNotEmpty ? highs.first : null,
      'low_celsius': lows.isNotEmpty ? lows.first : null,
      'dew_point_celsius': (current['dew_point_2m'] as num?)?.toDouble(),
      'wind_direction_deg': (current['wind_direction_10m'] as num?)?.toDouble(),
      'pressure_hpa': (current['surface_pressure'] as num?)?.toDouble(),
      'visibility_km': visM == null ? null : visM / 1000.0,
      'rain_mm_1h': (current['precipitation'] as num?)?.toDouble(),
      'sunrise_unix': sunriseUnix,
      'sunset_unix': sunsetUnix,
      'timezone_offset_sec': offset,
    };

    final times = _strList(hourly['time']);
    final temps = _numList(hourly['temperature_2m']);
    final rainP = _numList(hourly['precipitation_probability']);
    final rainMm = _numList(hourly['precipitation']);
    final codes = _numList(hourly['weather_code']);
    final hourlyItems = <Map<String, dynamic>>[];
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    for (var i = 0; i < times.length && hourlyItems.length < 16; i++) {
      final dt = _isoToUnix(times[i]);
      if (dt == null || dt + 1800 < now) continue;
      final local = DateTime.parse(times[i]);
      hourlyItems.add({
        'dt_unix': dt,
        'hour_label': '${local.hour.toString().padLeft(2, '0')}:00',
        'temperature_celsius': i < temps.length ? temps[i] : 0,
        'condition': conditionFromWmo(i < codes.length ? codes[i].round() : weatherCode),
        'rain_probability_percent': i < rainP.length ? rainP[i].round() : 0,
        'rain_mm': i < rainMm.length ? rainMm[i] : null,
      });
    }

    final days = _strList(daily['time']);
    final dayCodes = _numList(daily['weather_code']);
    final dayRain = _numList(daily['precipitation_sum']);
    final dayRainP = _numList(daily['precipitation_probability_max']);
    final forecast = <Map<String, dynamic>>[];
    for (var i = 0; i < days.length && i < 7; i++) {
      final date = DateTime.tryParse(days[i]);
      forecast.add({
        'day': i == 0 ? 'Today' : (date == null ? days[i] : _weekday(date.weekday)),
        'weekday': date == null ? null : _weekday(date.weekday),
        'date': days[i],
        'high_celsius': i < highs.length ? highs[i] : 0,
        'low_celsius': i < lows.length ? lows[i] : 0,
        'condition': conditionFromWmo(i < dayCodes.length ? dayCodes[i].round() : weatherCode),
        'rain_probability_percent': i < dayRainP.length ? dayRainP[i].round() : 0,
        'rain_mm': i < dayRain.length ? dayRain[i] : null,
      });
    }

    var precip24 = 0.0;
    for (final item in hourlyItems.take(24)) {
      precip24 += (item['rain_mm'] as num?)?.toDouble() ?? 0;
    }

    return {
      'location': locationName,
      'current': currentJson,
      'hourly': hourlyItems,
      'forecast': forecast,
      'precip_next_24h_mm': precip24,
      'stale': false,
    };
  }

  static Map<String, dynamic> mapAqi(Map<String, dynamic> raw) {
    final current = (raw['current'] as Map?)?.cast<String, dynamic>() ?? {};
    final value = (current['us_aqi'] as num?)?.toInt() ?? 0;
    return {
      'aqi_value': value,
      'category': _aqiCategory(value),
      'pollutants': {
        'pm2_5': (current['pm2_5'] as num?)?.toDouble() ?? 0,
        'pm10': (current['pm10'] as num?)?.toDouble() ?? 0,
        'no2': (current['nitrogen_dioxide'] as num?)?.toDouble() ?? 0,
        'o3': (current['ozone'] as num?)?.toDouble() ?? 0,
        'so2': (current['sulphur_dioxide'] as num?)?.toDouble() ?? 0,
        'co': (current['carbon_monoxide'] as num?)?.toDouble() ?? 0,
      },
    };
  }

  static String conditionFromWmo(int code) {
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Clouds';
    if (code <= 48) return 'Fog';
    if (code <= 57) return 'Drizzle';
    if (code <= 67) return 'Rain';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Rain';
    if (code <= 86) return 'Snow';
    if (code >= 95) return 'Thunderstorm';
    return 'Clouds';
  }

  static String _aqiCategory(int v) {
    if (v <= 50) return 'Good';
    if (v <= 100) return 'Fair';
    if (v <= 150) return 'Moderate';
    if (v <= 200) return 'Poor';
    return 'Severe';
  }

  static String _weekday(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(weekday - 1).clamp(0, 6)];
  }

  static int? _isoToUnix(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    return dt.toUtc().millisecondsSinceEpoch ~/ 1000;
  }

  static List<double> _numList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e is num ? e.toDouble() : 0.0).toList();
  }

  static List<String> _strList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e?.toString() ?? '').toList();
  }
}
