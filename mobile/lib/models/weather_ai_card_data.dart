import 'package:flutter/material.dart';

enum WeatherCardType {
  activityWindow,
  clothingWardrobe,
  healthEnvironment,
  travelPacking,
  dailyPlan,
  forecastSummary,
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

    return WeatherAiCardData(
      cardType: cardType,
      category: json['category'] as String? ?? 'WEATHER INTELLIGENCE',
      headline: json['headline'] as String? ?? 'Weather Analysis',
      subtitle: json['subtitle'] as String?,
      metrics: metrics,
      explanation: json['explanation'] as String?,
      actionLabel: json['actionLabel'] as String?,
      actionRoute: json['actionRoute'] as String?,
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
