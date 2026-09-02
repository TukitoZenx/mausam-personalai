class HourlyForecastItem {
  final int dtUnix;
  final String hourLabel;
  final double temperatureCelsius;
  final String condition;
  final String? conditionIcon;
  final int rainProbabilityPercent;
  final double? rainMm;

  const HourlyForecastItem({
    required this.dtUnix,
    required this.hourLabel,
    required this.temperatureCelsius,
    required this.condition,
    this.conditionIcon,
    this.rainProbabilityPercent = 0,
    this.rainMm,
  });

  factory HourlyForecastItem.fromJson(Map<String, dynamic> json) {
    return HourlyForecastItem(
      dtUnix: (json['dt_unix'] as num?)?.toInt() ?? 0,
      hourLabel: (json['hour_label'] ?? '').toString(),
      temperatureCelsius: (json['temperature_celsius'] as num?)?.toDouble() ?? 0,
      condition: (json['condition'] ?? '').toString(),
      conditionIcon: json['condition_icon'] as String?,
      rainProbabilityPercent: (json['rain_probability_percent'] as num?)?.toInt() ?? 0,
      rainMm: (json['rain_mm'] as num?)?.toDouble(),
    );
  }
}

class DailyForecastItem {
  final String day;
  final String? weekday;
  final String? date;
  final double highCelsius;
  final double lowCelsius;
  final String condition;
  final String? conditionIcon;
  final int rainProbabilityPercent;
  final double? rainMm;
  final double? moonPhase;
  final int? moonriseUnix;
  final int? moonsetUnix;

  const DailyForecastItem({
    required this.day,
    required this.highCelsius,
    required this.lowCelsius,
    required this.condition,
    this.weekday,
    this.date,
    this.conditionIcon,
    this.rainProbabilityPercent = 0,
    this.rainMm,
    this.moonPhase,
    this.moonriseUnix,
    this.moonsetUnix,
  });

  factory DailyForecastItem.fromJson(Map<String, dynamic> json) {
    return DailyForecastItem(
      day: (json['day'] ?? '').toString(),
      weekday: json['weekday'] as String?,
      date: json['date'] as String?,
      highCelsius: (json['high_celsius'] as num?)?.toDouble() ?? 0,
      lowCelsius: (json['low_celsius'] as num?)?.toDouble() ?? 0,
      condition: (json['condition'] ?? '').toString(),
      conditionIcon: json['condition_icon'] as String?,
      rainProbabilityPercent: (json['rain_probability_percent'] as num?)?.toInt() ?? 0,
      rainMm: (json['rain_mm'] as num?)?.toDouble(),
      moonPhase: (json['moon_phase'] as num?)?.toDouble(),
      moonriseUnix: (json['moonrise_unix'] as num?)?.toInt(),
      moonsetUnix: (json['moonset_unix'] as num?)?.toInt(),
    );
  }
}

class CurrentConditions {
  final String location;
  final double temperatureCelsius;
  final String condition;
  final int humidityPercent;
  final double windSpeedKmh;
  final double uvIndex;
  final double? feelsLikeCelsius;
  final double? highCelsius;
  final double? lowCelsius;
  final String? conditionIcon;
  final double? dewPointCelsius;
  final double? windDirectionDeg;
  final double? pressureHpa;
  final double? visibilityKm;
  final double? rainMm1h;
  final int? sunriseUnix;
  final int? sunsetUnix;
  final int? timezoneOffsetSec;

  const CurrentConditions({
    required this.location,
    required this.temperatureCelsius,
    required this.condition,
    required this.humidityPercent,
    required this.windSpeedKmh,
    required this.uvIndex,
    this.feelsLikeCelsius,
    this.highCelsius,
    this.lowCelsius,
    this.conditionIcon,
    this.dewPointCelsius,
    this.windDirectionDeg,
    this.pressureHpa,
    this.visibilityKm,
    this.rainMm1h,
    this.sunriseUnix,
    this.sunsetUnix,
    this.timezoneOffsetSec,
  });

  factory CurrentConditions.fromJson(Map<String, dynamic> json) {
    return CurrentConditions(
      location: (json['location'] ?? '').toString(),
      temperatureCelsius: (json['temperature_celsius'] as num?)?.toDouble() ?? 0,
      condition: (json['condition'] ?? '').toString(),
      humidityPercent: (json['humidity_percent'] as num?)?.toInt() ?? 0,
      windSpeedKmh: (json['wind_speed_kmh'] as num?)?.toDouble() ?? 0,
      uvIndex: (json['uv_index'] as num?)?.toDouble() ?? 0,
      feelsLikeCelsius: (json['feels_like_celsius'] as num?)?.toDouble(),
      highCelsius: (json['high_celsius'] as num?)?.toDouble(),
      lowCelsius: (json['low_celsius'] as num?)?.toDouble(),
      conditionIcon: json['condition_icon'] as String?,
      dewPointCelsius: (json['dew_point_celsius'] as num?)?.toDouble(),
      windDirectionDeg: (json['wind_direction_deg'] as num?)?.toDouble(),
      pressureHpa: (json['pressure_hpa'] as num?)?.toDouble(),
      visibilityKm: (json['visibility_km'] as num?)?.toDouble(),
      rainMm1h: (json['rain_mm_1h'] as num?)?.toDouble(),
      sunriseUnix: (json['sunrise_unix'] as num?)?.toInt(),
      sunsetUnix: (json['sunset_unix'] as num?)?.toInt(),
      timezoneOffsetSec: (json['timezone_offset_sec'] as num?)?.toInt(),
    );
  }
}

class AqiSnapshot {
  final int aqiValue;
  final String category;
  final Map<String, double> pollutants;

  const AqiSnapshot({
    required this.aqiValue,
    required this.category,
    this.pollutants = const {},
  });

  factory AqiSnapshot.fromJson(Map<String, dynamic> json) {
    final raw = json['pollutants'];
    final map = <String, double>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is num) map[k.toString()] = v.toDouble();
      });
    }
    return AqiSnapshot(
      aqiValue: (json['aqi_value'] as num?)?.toInt() ?? 0,
      category: (json['category'] ?? 'Unknown').toString(),
      pollutants: map,
    );
  }

  static const _guidelines = <String, double>{
    'pm2_5': 15,
    'pm10': 45,
    'no2': 25,
    'o3': 100,
    'so2': 40,
    'co': 4000,
  };

  static const _labels = <String, String>{
    'pm2_5': 'PM2.5',
    'pm10': 'PM10',
    'no2': 'NO₂',
    'o3': 'O₃',
    'so2': 'SO₂',
    'co': 'CO',
  };

  String get mainPollutantLabel {
    String best = 'PM2.5';
    var bestRatio = -1.0;
    pollutants.forEach((key, value) {
      final ref = _guidelines[key] ?? 1;
      final ratio = value / ref;
      if (ratio > bestRatio) {
        bestRatio = ratio;
        best = _labels[key] ?? key.toUpperCase();
      }
    });
    return best;
  }
}

class WeatherDashboard {
  final CurrentConditions current;
  final List<HourlyForecastItem> hourly;
  final List<DailyForecastItem> daily;
  final double? precipNext24hMm;
  final AqiSnapshot? aqi;
  final bool stale;

  const WeatherDashboard({
    required this.current,
    this.hourly = const [],
    this.daily = const [],
    this.precipNext24hMm,
    this.aqi,
    this.stale = false,
  });

  factory WeatherDashboard.fromForecastJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? aqiJson,
  }) {
    final currentMap = (json['current'] as Map?)?.cast<String, dynamic>() ?? json;
    return WeatherDashboard(
      current: CurrentConditions.fromJson(currentMap),
      hourly: ((json['hourly'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => HourlyForecastItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
      daily: ((json['forecast'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => DailyForecastItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
      precipNext24hMm: (json['precip_next_24h_mm'] as num?)?.toDouble(),
      aqi: aqiJson == null ? null : AqiSnapshot.fromJson(aqiJson),
      stale: json['stale'] == true,
    );
  }
}

String moonPhaseName(double? phase) {
  if (phase == null) {
    return 'Unknown';
  }
  final p = phase;
  if (p < 0.03 || p >= 0.97) return 'New Moon';
  if (p < 0.22) return 'Waxing Crescent';
  if (p < 0.28) return 'First Quarter';
  if (p < 0.47) return 'Waxing Gibbous';
  if (p < 0.53) return 'Full Moon';
  if (p < 0.72) return 'Waning Gibbous';
  if (p < 0.78) return 'Last Quarter';
  return 'Waning Crescent';
}

String uvCategory(double uv) {
  if (uv >= 11) return 'Extreme';
  if (uv >= 8) return 'Very High';
  if (uv >= 6) return 'High';
  if (uv >= 3) return 'Moderate';
  return 'Low';
}

String uvGuidance(double uv) {
  if (uv >= 11) return 'Avoid midday sun. Seek shade and cover up.';
  if (uv >= 8) return 'Extra protection required. Limit time outdoors.';
  if (uv >= 6) return 'Pay attention to sun protection.';
  if (uv >= 3) return 'Sunscreen recommended for longer outdoor time.';
  return 'Low UV — sun protection is optional.';
}

String visibilityLine(double? km) {
  if (km == null) return 'Visibility unavailable';
  if (km >= 10) return 'Excellent visibility';
  if (km >= 5) return 'Good visibility';
  if (km >= 2) return 'Hazy — reduced visibility';
  return 'Poor visibility';
}

String dailyHeadline(List<DailyForecastItem> days) {
  for (final day in days) {
    final cond = day.condition.toLowerCase();
    if (day.rainProbabilityPercent >= 50 ||
        cond.contains('rain') ||
        cond.contains('thunder')) {
      return 'Rain expected ${day.day}';
    }
  }
  for (final day in days) {
    if (day.condition.toLowerCase().contains('storm')) {
      return 'Stormy stretch ${day.day}';
    }
  }
  if (days.isEmpty) return 'Forecast updating';
  return 'Clear skies ahead';
}

String precipBannerText({
  required CurrentConditions current,
  required List<HourlyForecastItem> hourly,
}) {
  if ((current.rainMm1h ?? 0) > 0) {
    return 'Rain in the area now';
  }
  for (final slot in hourly.take(8)) {
    if (slot.rainProbabilityPercent >= 40 || (slot.rainMm ?? 0) > 0) {
      final mins = ((slot.dtUnix * 1000) - DateTime.now().millisecondsSinceEpoch) ~/ 60000;
      if (mins <= 0) return 'Rain expected around ${slot.hourLabel}';
      if (mins < 120) return 'Rain expected in $mins min';
      return 'Rain expected around ${slot.hourLabel}';
    }
  }
  if (hourly.isEmpty) return 'No precipitation signal in the near-term forecast';
  final hours = hourly.length >= 8 ? 24 : hourly.length * 3;
  return 'No precipitation for the next $hours hr';
}
