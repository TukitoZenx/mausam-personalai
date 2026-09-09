import 'package:flutter/material.dart';

enum WeatherCardType {
  activityWindow,
  clothingWardrobe,
  healthEnvironment,
  travelPacking,
  dailyPlan,
  forecastSummary,
  travelRoute,
}

class WeatherAiMetricItem {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const WeatherAiMetricItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });
}

class DailyPlanPeriodItem {
  final String period; // 'Morning', 'Afternoon', 'Evening', 'Night'
  final String timeRange; // '6:00 AM – 11:00 AM'
  final String temp; // '22°C'
  final String condition; // 'Clear'
  final String advice; // 'Optimal walking window'
  final IconData icon;

  const DailyPlanPeriodItem({
    required this.period,
    required this.timeRange,
    required this.temp,
    required this.condition,
    required this.advice,
    required this.icon,
  });
}

class TravelRoutePoint {
  final String name;
  final String role; // 'origin', 'intermediate', 'destination'
  final double lat;
  final double lon;
  final Map<String, dynamic>? weather;

  const TravelRoutePoint({
    required this.name,
    required this.role,
    required this.lat,
    required this.lon,
    this.weather,
  });

  bool get isOrigin => role == 'origin';
  bool get isIntermediate => role == 'intermediate';
  bool get isDestination => role == 'destination';

  int? get temperature {
    if (weather == null) return null;
    final t = weather!['temperature'] ?? weather!['temperature_celsius'];
    if (t is num) return t.round();
    return null;
  }

  String? get condition => weather?['condition']?.toString();
  String? get icon => weather?['icon']?.toString();

  int? get aqi {
    if (weather == null) return null;
    final a = weather!['aqi'];
    if (a is num) return a.round();
    return null;
  }

  String? get aqiCategory =>
      weather?['aqiCategory']?.toString() ?? weather?['aqi_category']?.toString();

  factory TravelRoutePoint.fromJson(Map<String, dynamic> json) {
    final rawWeather = json['weather'];
    Map<String, dynamic>? w;
    if (rawWeather is Map<String, dynamic>) {
      w = rawWeather;
    } else if (rawWeather is Map) {
      w = Map<String, dynamic>.from(rawWeather);
    }

    return TravelRoutePoint(
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'intermediate',
      lat: (json['lat'] ?? json['latitude'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] ?? json['longitude'] as num?)?.toDouble() ?? 0.0,
      weather: w,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'role': role,
        'lat': lat,
        'lon': lon,
        'weather': weather,
      };
}

class WeatherAiCardData {
  final WeatherCardType cardType;
  final String category;
  final String headline;
  final String? subtitle;
  final List<WeatherAiMetricItem> metrics;
  final String? explanation;
  final String? actionLabel;
  final String? actionRoute;
  final List<DailyPlanPeriodItem>? dailyPlanPeriods;
  final List<String>? checklistItems;
  final String? origin;
  final String? destination;
  final int? distanceKm;
  final String? durationText;
  final bool isEstimate;
  final bool isEstimated;
  final String? routeSource;
  final Map<String, double>? originCoords;
  final Map<String, double>? destCoords;
  final Map<String, dynamic>? destinationWeather;
  final List<TravelRoutePoint>? routePoints;
  final List<Map<String, double>>? routeGeometry;

  const WeatherAiCardData({
    required this.cardType,
    required this.category,
    required this.headline,
    this.subtitle,
    this.metrics = const [],
    this.explanation,
    this.actionLabel,
    this.actionRoute,
    this.dailyPlanPeriods,
    this.checklistItems,
    this.origin,
    this.destination,
    this.distanceKm,
    this.durationText,
    this.isEstimate = true,
    this.isEstimated = true,
    this.routeSource,
    this.originCoords,
    this.destCoords,
    this.destinationWeather,
    this.routePoints,
    this.routeGeometry,
  });

  factory WeatherAiCardData.fromJson(Map<String, dynamic> json) {
    final typeStr = json['cardType'] as String? ?? 'forecastSummary';
    final cardType = WeatherCardType.values.firstWhere(
      (e) => e.name.toLowerCase() == typeStr.toLowerCase(),
      orElse: () => WeatherCardType.forecastSummary,
    );

    final rawMetrics = json['metrics'];
    final metrics = <WeatherAiMetricItem>[];
    if (rawMetrics is List) {
      for (final m in rawMetrics) {
        if (m is Map) {
          final label = m['label']?.toString() ?? '';
          final value = m['value']?.toString() ?? '';
          metrics.add(
            WeatherAiMetricItem(
              label: label,
              value: value,
              icon: _iconForMetric(label),
            ),
          );
        }
      }
    }

    Map<String, double>? parseCoords(dynamic raw) {
      if (raw is Map) {
        final lat = (raw['latitude'] ?? raw['lat']);
        final lon = (raw['longitude'] ?? raw['lon']);
        if (lat is num && lon is num) {
          return {'latitude': lat.toDouble(), 'longitude': lon.toDouble()};
        }
      }
      return null;
    }

    final originCoords = parseCoords(json['originCoords']);
    final destCoords = parseCoords(json['destCoords']);
    final destinationWeather = json['destinationWeather'] is Map<String, dynamic>
        ? json['destinationWeather'] as Map<String, dynamic>
        : (json['destinationWeather'] is Map
            ? Map<String, dynamic>.from(json['destinationWeather'] as Map)
            : null);

    final isEstimateVal =
        json['isEstimated'] as bool? ?? json['isEstimate'] as bool? ?? true;
    final routeSource = json['routeSource'] as String?;

    final rawPoints = json['routePoints'];
    final routePoints = <TravelRoutePoint>[];
    if (rawPoints is List) {
      for (final rp in rawPoints) {
        if (rp is Map) {
          routePoints.add(
              TravelRoutePoint.fromJson(Map<String, dynamic>.from(rp)));
        }
      }
    }

    final rawGeometry = json['routeGeometry'];
    final routeGeometry = <Map<String, double>>[];
    if (rawGeometry is List) {
      for (final g in rawGeometry) {
        if (g is Map) {
          final lat = (g['lat'] ?? g['latitude']);
          final lon = (g['lon'] ?? g['longitude']);
          if (lat is num && lon is num) {
            routeGeometry.add({'lat': lat.toDouble(), 'lon': lon.toDouble()});
          }
        }
      }
    }

    return WeatherAiCardData(
      cardType: cardType,
      category: json['category'] as String? ?? 'WEATHER INTELLIGENCE',
      headline: json['headline'] as String? ?? 'Weather Analysis',
      subtitle: json['subtitle'] as String?,
      metrics: metrics,
      explanation: json['explanation'] as String?,
      actionLabel: json['actionLabel'] as String?,
      actionRoute: json['actionRoute'] as String?,
      origin: json['origin'] as String?,
      destination: json['destination'] as String?,
      distanceKm: json['distanceKm'] is num ? (json['distanceKm'] as num).toInt() : null,
      durationText: json['durationText'] as String?,
      isEstimate: isEstimateVal,
      isEstimated: isEstimateVal,
      routeSource: routeSource,
      originCoords: originCoords,
      destCoords: destCoords,
      destinationWeather: destinationWeather,
      routePoints: routePoints.isNotEmpty ? routePoints : null,
      routeGeometry: routeGeometry.isNotEmpty ? routeGeometry : null,
    );
  }

  static IconData _iconForMetric(String? label) {
    if (label == null) return Icons.info_outline;
    final l = label.toLowerCase();
    if (l.contains('temp') || l.contains('heat') || l.contains('feels')) return Icons.thermostat;
    if (l.contains('rain') || l.contains('precip') || l.contains('shower')) return Icons.water_drop;
    if (l.contains('wind') || l.contains('speed')) return Icons.air;
    if (l.contains('aqi') || l.contains('air') || l.contains('pollut')) return Icons.bubble_chart;
    if (l.contains('uv') || l.contains('sun')) return Icons.wb_sunny;
    if (l.contains('humid') || l.contains('dew')) return Icons.water;
    if (l.contains('visib')) return Icons.visibility;
    return Icons.insights;
  }
}
