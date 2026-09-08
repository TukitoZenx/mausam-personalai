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
}
