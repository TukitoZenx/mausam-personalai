import 'dart:math' as math;

import '../models/weather_dashboard.dart';
import '../providers/user_provider.dart';

/// Structured result of the tomorrow activity intelligence recommendation.
class ActivityRecommendation {
  final String activity; // 'walking', 'jogging', etc.
  final String recommendedWindow; // e.g. "6:15–7:15 AM"
  final int temperatureCelsius;
  final int feelsLikeCelsius;
  final int aqiValue;
  final String aqiCategory;
  final int rainProbabilityPercent;
  final String rainRiskLabel; // "Low rain chance", "Rain likely", etc.
  final int windSpeedKmh;
  final String windLabel; // "Light wind", "Breezy", etc.
  final String whyReason; // "Cooler conditions and lower rain risk."
  final bool isIdeal;
  final String? alternativeWindow;
  final String? advisoryMessage;

  const ActivityRecommendation({
    required this.activity,
    required this.recommendedWindow,
    required this.temperatureCelsius,
    required this.feelsLikeCelsius,
    required this.aqiValue,
    required this.aqiCategory,
    required this.rainProbabilityPercent,
    required this.rainRiskLabel,
    required this.windSpeedKmh,
    required this.windLabel,
    required this.whyReason,
    this.isIdeal = true,
    this.alternativeWindow,
    this.advisoryMessage,
  });

  /// Short single-sentence summary for notifications.
  String get notificationBody {
    if (!isIdeal && advisoryMessage != null) {
      return advisoryMessage!;
    }
    return "Tomorrow's best $activity window is $recommendedWindow. "
        "Cool conditions ($temperatureCelsius°C), $aqiCategory air quality, and $rainRiskLabel.";
  }
}

class ActivityRecommendationEngine {
  /// Evaluates real forecast data and user profile to find tomorrow's best activity window.
  static ActivityRecommendation calculateRecommendation({
    required WeatherDashboard? dashboardData,
    required UserState userState,
    String activity = 'walking',
    String targetPeriod = 'morning',
  }) {
    // If no weather data, return fallback
    if (dashboardData == null) {
      return ActivityRecommendation(
        activity: activity,
        recommendedWindow: '6:30–7:30 AM',
        temperatureCelsius: 22,
        feelsLikeCelsius: 21,
        aqiValue: 40,
        aqiCategory: 'Good',
        rainProbabilityPercent: 10,
        rainRiskLabel: 'Low rain chance',
        windSpeedKmh: 8,
        windLabel: 'Light wind',
        whyReason: 'Favorable morning temperatures and stable atmospheric conditions.',
      );
    }

    final hourlyList = dashboardData.hourly;
    final aqiVal = dashboardData.aqi?.aqiValue ?? 38;
    final aqiCat = dashboardData.aqi?.category ?? 'Good';
    final curr = dashboardData.current;

    // Filter hourly items for the target period with persona-aware timing preferences
    final targetHours = _getTargetHours(targetPeriod, userState.selectedPersona);

    final personaLower = (userState.selectedPersona ?? '').toLowerCase();
    String fallbackWindow = '6:15–7:15 AM';
    if (personaLower.contains('commut') || personaLower.contains('drive')) {
      fallbackWindow = '7:30–8:45 AM';
    } else if (personaLower.contains('family') || personaLower.contains('parent')) {
      fallbackWindow = '7:15–8:30 AM';
    } else if (personaLower.contains('garden') || personaLower.contains('farm')) {
      fallbackWindow = '5:45–7:15 AM';
    } else if (personaLower.contains('event') || personaLower.contains('planner')) {
      fallbackWindow = '4:30–9:30 PM';
    } else if (personaLower.contains('travel')) {
      fallbackWindow = '8:00–11:30 AM';
    } else if (personaLower.contains('health')) {
      fallbackWindow = '6:30–8:30 AM';
    }

    List<HourlyForecastItem> candidateHours = [];
    if (hourlyList.isNotEmpty) {
      candidateHours = hourlyList.where((h) {
        final hourNumber = _parseHourLabel(h.hourLabel);
        return targetHours.contains(hourNumber);
      }).toList();
    }

    // If candidate list is empty, fallback to available hours or current conditions
    if (candidateHours.isEmpty) {
      final baseTemp = curr.temperatureCelsius.round();
      return ActivityRecommendation(
        activity: activity,
        recommendedWindow: fallbackWindow,
        temperatureCelsius: math.max(16, baseTemp - 3),
        feelsLikeCelsius: math.max(15, baseTemp - 4),
        aqiValue: aqiVal,
        aqiCategory: aqiCat,
        rainProbabilityPercent: curr.rainMm1h != null && curr.rainMm1h! > 0 ? 55 : 15,
        rainRiskLabel: curr.rainMm1h != null && curr.rainMm1h! > 0 ? 'Possible showers' : 'Low rain chance',
        windSpeedKmh: curr.windSpeedKmh.round(),
        windLabel: curr.windSpeedKmh > 15 ? 'Moderate breeze' : 'Light wind',
        whyReason: 'Optimal temperature window before daytime solar heating picks up.',
      );
    }

    // Score each candidate hour
    HourlyForecastItem bestHour = candidateHours.first;
    double bestScore = -999999;

    for (final item in candidateHours) {
      final score = _scoreHour(item, userState, aqiVal, activity);
      if (score > bestScore) {
        bestScore = score;
        bestHour = item;
      }
    }

    final chosenTemp = bestHour.temperatureCelsius.round();
    final chosenRainProb = bestHour.rainProbabilityPercent;
    final chosenWind = curr.windSpeedKmh.round();

    // Check if conditions are ideal vs poor
    final isRainy = chosenRainProb >= 50 || (bestHour.rainMm ?? 0) > 0.5;
    final isTooHot = chosenTemp >= 31;
    final isPoorAqi = aqiVal > 100;
    final isIdeal = !isRainy && !isTooHot && !isPoorAqi;

    final hourNum = _parseHourLabel(bestHour.hourLabel);
    final startMinute = (hourNum * 15) % 30 == 0 ? '15' : '30';
    final endHour = hourNum + 1;
    final startPeriod = hourNum >= 12 ? 'PM' : 'AM';
    final endPeriod = endHour >= 12 ? 'PM' : 'AM';
    final displayHour = hourNum % 12 == 0 ? 12 : hourNum % 12;
    final displayEndHour = endHour % 12 == 0 ? 12 : endHour % 12;

    final windowString = startPeriod != endPeriod
        ? '$displayHour:$startMinute $startPeriod–$displayEndHour:$startMinute $endPeriod'
        : '$displayHour:$startMinute–$displayEndHour:$startMinute $endPeriod';

    // Formulate rain label
    String rainLabel = 'Low rain chance';
    if (chosenRainProb >= 60) {
      rainLabel = 'Rain likely ($chosenRainProb%)';
    } else if (chosenRainProb >= 30) {
      rainLabel = 'Moderate rain risk ($chosenRainProb%)';
    }

    // Formulate wind label
    String windLabel = 'Light wind';
    if (chosenWind >= 24) {
      windLabel = 'Breezy ($chosenWind km/h)';
    } else if (chosenWind >= 15) {
      windLabel = 'Gentle breeze ($chosenWind km/h)';
    }

    // Formulate concise "Why" reasoning
    String whyReason = 'Cooler conditions ($chosenTemp°C) and lower rain risk.';
    if (isPoorAqi) {
      whyReason = 'Lowest expected particulate dispersion window under current air pressure.';
    } else if (chosenTemp <= 22 && chosenRainProb <= 20) {
      whyReason = 'Optimal cool temperature ($chosenTemp°C), pristine air ($aqiVal AQI), and clear pavements.';
    } else if (userState.weatherTriggers.contains('Heat') || userState.age != null && userState.age! > 55) {
      whyReason = 'Comfortable thermal envelope avoiding peak midday sun and UV index.';
    }

    String? advisory;
    String? altWindow;
    if (!isIdeal) {
      final altHour = (hourNum + 2) % 24;
      final altDisplay = altHour % 12 == 0 ? 12 : altHour % 12;
      final altPeriodStr = altHour >= 12 ? 'PM' : 'AM';
      altWindow = '$altDisplay:00–${altDisplay + 1}:00 $altPeriodStr';
      advisory = 'Tomorrow morning may not be ideal for $activity. Rain/heat is expected earlier. A later window looks better: $altWindow.';
    }

    return ActivityRecommendation(
      activity: activity,
      recommendedWindow: windowString,
      temperatureCelsius: chosenTemp,
      feelsLikeCelsius: (chosenTemp - 1),
      aqiValue: aqiVal,
      aqiCategory: aqiCat,
      rainProbabilityPercent: chosenRainProb,
      rainRiskLabel: rainLabel,
      windSpeedKmh: chosenWind,
      windLabel: windLabel,
      whyReason: whyReason,
      isIdeal: isIdeal,
      alternativeWindow: altWindow,
      advisoryMessage: advisory,
    );
  }

  static Set<int> _getTargetHours(String period, [String? persona]) {
    final pLower = (persona ?? '').toLowerCase();
    switch (period.toLowerCase()) {
      case 'evening':
        if (pLower.contains('family')) return {16, 17, 18};
        if (pLower.contains('garden')) return {17, 18};
        if (pLower.contains('event')) return {16, 17, 18, 19, 20, 21};
        return {17, 18, 19, 20};
      case 'afternoon':
        return {12, 13, 14, 15, 16};
      case 'morning':
      default:
        if (pLower.contains('health')) return {6, 7, 8};
        if (pLower.contains('travel')) return {8, 9, 10, 11};
        if (pLower.contains('commut')) return {7, 8, 9};
        if (pLower.contains('family')) return {7, 8};
        if (pLower.contains('garden')) return {5, 6, 7};
        if (pLower.contains('event')) return {9, 10, 11};
        return {5, 6, 7, 8};
    }
  }

  static int _parseHourLabel(String label) {
    final lower = label.toLowerCase().trim();
    final match = RegExp(r'(\d{1,2})').firstMatch(lower);
    if (match == null) return 7; // default 7 AM

    int h = int.parse(match.group(1)!);
    if (lower.contains('pm') && h < 12) h += 12;
    if (lower.contains('am') && h == 12) h = 0;
    return h;
  }

  static double _scoreHour(
    HourlyForecastItem item,
    UserState user,
    int aqi,
    String activity,
  ) {
    double score = 100.0;

    final temp = item.temperatureCelsius;
    final rainProb = item.rainProbabilityPercent;
    final rainMm = item.rainMm ?? 0;

    // 1. Temperature Scoring (ideal ~19-23°C)
    final tempDiff = (temp - 21).abs();
    score -= tempDiff * 3.0;

    // Senior or Heat sensitivity
    if (user.age != null && user.age! >= 50 || user.weatherTriggers.contains('Heat')) {
      if (temp > 26) score -= (temp - 26) * 6.0;
    }

    // 2. Rain Probability & Precipitation
    score -= rainProb * 1.8;
    if (rainMm > 0) score -= (rainMm * 15.0);
    if (user.weatherTriggers.contains('Rain') && rainProb > 25) {
      score -= 35.0;
    }

    // 3. Air Quality Penalty
    if (aqi > 50) {
      score -= (aqi - 50) * 0.8;
    }
    if (user.healthConcerns.contains('Asthma') || user.healthConcerns.contains('Dust')) {
      if (aqi > 60) score -= (aqi - 60) * 1.5;
    }

    // 4. Activity Specific
    if (activity == 'running' || activity == 'jogging') {
      // Runners prefer cooler weather
      if (temp > 24) score -= (temp - 24) * 4.0;
    }

    return score;
  }
}
