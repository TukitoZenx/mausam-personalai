import 'package:flutter/material.dart';

import '../models/routine_reminder.dart';
import '../models/weather_ai_card_data.dart';
import '../models/weather_dashboard.dart';
import '../providers/user_provider.dart';
import 'activity_recommendation_engine.dart';
import 'routine_intent_parser.dart';

class WeatherAiResponse {
  final String text;
  final WeatherAiCardData? cardData;
  final List<String> followUps;
  final RoutineIntentResult routineIntent;
  final ActivityRecommendation? recommendation;
  final RoutineReminder? reminder;

  const WeatherAiResponse({
    required this.text,
    this.cardData,
    this.followUps = const [],
    required this.routineIntent,
    this.recommendation,
    this.reminder,
  });
}

class WeatherAiEngine {
  /// Evaluates the user query against user profile context and live weather data.
  static WeatherAiResponse process({
    required String query,
    required UserState? userState,
    required WeatherDashboard? dashboard,
    required String locationName,
  }) {
    final lower = query.toLowerCase().trim();
    final routineIntent = RoutineIntentParser.parse(query);

    // 1. Routine / Activity Recommendation or Reminder Intent
    if (routineIntent.isRecommendationIntent || routineIntent.isReminderIntent) {
      return _handleActivityOrReminder(
        query: query,
        intent: routineIntent,
        userState: userState,
        dashboard: dashboard,
        locationName: locationName,
      );
    }

    // 2. Clothing & Wardrobe Intent
    if (_isClothingQuery(lower)) {
      return _handleClothingQuery(
        query: query,
        userState: userState,
        dashboard: dashboard,
        locationName: locationName,
        intent: routineIntent,
      );
    }

    // 3. Air Quality & Health Triggers Intent
    if (_isHealthOrAqiQuery(lower)) {
      return _handleHealthOrAqiQuery(
        query: query,
        userState: userState,
        dashboard: dashboard,
        locationName: locationName,
        intent: routineIntent,
      );
    }

    // 4. Travel & Destination Packing Intent
    if (_isTravelQuery(lower)) {
      return _handleTravelQuery(
        query: query,
        userState: userState,
        dashboard: dashboard,
        locationName: locationName,
        intent: routineIntent,
      );
    }

    // 5. Daily Plan Timeline Intent
    if (_isDailyPlanQuery(lower)) {
      return _handleDailyPlanQuery(
        query: query,
        userState: userState,
        dashboard: dashboard,
        locationName: locationName,
        intent: routineIntent,
      );
    }

    // 6. Rain or General Forecast Intent
    return _handleGeneralWeatherQuery(
      query: query,
      userState: userState,
      dashboard: dashboard,
      locationName: locationName,
      intent: routineIntent,
    );
  }

  // --- Helpers for query categorization ---

  static bool _isClothingQuery(String q) {
    return q.contains('wear') ||
        q.contains('jacket') ||
        q.contains('coat') ||
        q.contains('umbrella') ||
        q.contains('clothes') ||
        q.contains('outfit') ||
        q.contains('dress');
  }

  static bool _isHealthOrAqiQuery(String q) {
    return q.contains('aqi') ||
        q.contains('air quality') ||
        q.contains('pollution') ||
        q.contains('asthma') ||
        q.contains('allergy') ||
        q.contains('allergies') ||
        q.contains('dust') ||
        q.contains('smoke') ||
        q.contains('health') ||
        q.contains('breathe');
  }

  static bool _isTravelQuery(String q) {
    return q.contains('travelling') ||
        q.contains('traveling') ||
        q.contains('travel') ||
        q.contains('trip') ||
        q.contains('pack') ||
        q.contains('packing') ||
        q.contains('destination') ||
        q.contains('flying to') ||
        q.contains('going to');
  }

  static bool _isDailyPlanQuery(String q) {
    return q.contains('plan my day') ||
        q.contains('plan my morning') ||
        q.contains('daily plan') ||
        q.contains('timeline') ||
        q.contains('schedule my day') ||
        q.contains('plan tomorrow');
  }

  // --- Handlers for each intent domain ---

  static WeatherAiResponse _handleActivityOrReminder({
    required String query,
    required RoutineIntentResult intent,
    required UserState? userState,
    required WeatherDashboard? dashboard,
    required String locationName,
  }) {
    final rec = ActivityRecommendationEngine.calculateRecommendation(
      dashboardData: dashboard,
      userState: userState ?? const UserState(),
      activity: intent.activity,
      targetPeriod: intent.targetPeriod,
    );

    final card = WeatherAiCardData(
      cardType: WeatherCardType.activityWindow,
      category: "TOMORROW'S BEST ${intent.activity.toUpperCase()} WINDOW",
      headline: rec.recommendedWindow,
      subtitle: '$locationName · ${intent.targetPeriod.toUpperCase()}',
      metrics: [
        WeatherAiMetricItem(
          icon: Icons.thermostat_rounded,
          label: 'TEMP',
          value: '${rec.temperatureCelsius}°C',
        ),
        WeatherAiMetricItem(
          icon: Icons.air_rounded,
          label: 'AQI',
          value: 'AQI ${rec.aqiValue} · ${rec.aqiCategory}',
          color: const Color(0xFF10B981),
        ),
        WeatherAiMetricItem(
          icon: Icons.water_drop_outlined,
          label: 'RAIN',
          value: rec.rainRiskLabel,
          color: rec.rainProbabilityPercent > 30 ? const Color(0xFF60A5FA) : null,
        ),
        WeatherAiMetricItem(
          icon: Icons.wind_power_rounded,
          label: 'WIND',
          value: rec.windLabel,
        ),
      ],
      explanation: rec.whyReason,
      actionLabel: intent.isReminderIntent
          ? 'Reminder scheduled for ${intent.reminderHour ?? 21}:00'
          : 'Remind me at 9 PM every day',
    );

    String text;
    if (intent.type == RoutineIntentType.reminderAndRecommendation) {
      text =
          'I\'ve scheduled your daily reminder for **${intent.reminderHour ?? 21}:${(intent.reminderMinute ?? 0).toString().padLeft(2, '0')}**.\n\n'
          'Here is tomorrow\'s optimal ${intent.activity} window derived from live radar:';
    } else if (intent.type == RoutineIntentType.createReminderOnly) {
      text = 'I\'ve scheduled your daily ${intent.activity} reminder. You\'ll receive an alert at that time with live forecast conditions.';
    } else {
      text = 'Based on your **${userState?.selectedPersona ?? "Fitness"}** profile and tomorrow\'s radar, here is the best window for your outdoor ${intent.activity}:';
    }

    return WeatherAiResponse(
      text: text,
      cardData: card,
      recommendation: rec,
      routineIntent: intent,
      followUps: [
        'What should I wear tomorrow?',
        'Hourly rain breakdown',
        'Check air quality',
      ],
    );
  }

  static WeatherAiResponse _handleClothingQuery({
    required String query,
    required UserState? userState,
    required WeatherDashboard? dashboard,
    required String locationName,
    required RoutineIntentResult intent,
  }) {
    final curr = dashboard?.current;
    final temp = curr?.temperatureCelsius.round() ?? 24;
    final rainProb = dashboard?.daily.firstOrNull?.rainProbabilityPercent ?? 0;
    final rainMm = curr?.rainMm1h ?? 0.0;
    final wind = curr?.windSpeedKmh.round() ?? 10;
    final uv = curr?.uvIndex ?? 4.0;

    String recommendation;
    String layering;
    final bool needUmbrella = rainProb >= 35 || rainMm > 0;

    if (temp < 14) {
      recommendation = 'Warm insulating layers and an outer jacket.';
      layering = 'Thermal/sweater + heavy jacket';
    } else if (temp < 20) {
      recommendation = 'Light jacket, cardigan, or hoodie over cottons.';
      layering = 'Breathable mid-layer';
    } else if (temp < 28) {
      recommendation = 'Light, breathable cotton t-shirt and comfortable trousers.';
      layering = 'Single light layer';
    } else {
      recommendation = 'Loose, moisture-wicking summer wear and hydration gear.';
      layering = 'Ultra-light breathable';
    }

    final card = WeatherAiCardData(
      cardType: WeatherCardType.clothingWardrobe,
      category: 'WARDROBE & GEAR RECOMMENDATION',
      headline: needUmbrella ? 'Light layers + Carry Umbrella' : recommendation,
      subtitle: '$locationName · $temp°C Feels like ${(curr?.feelsLikeCelsius ?? temp).round()}°C',
      metrics: [
        WeatherAiMetricItem(
          icon: Icons.umbrella_rounded,
          label: 'UMBRELLA',
          value: needUmbrella ? 'Required ($rainProb%)' : 'Not needed',
          color: needUmbrella ? const Color(0xFF60A5FA) : const Color(0xFF10B981),
        ),
        WeatherAiMetricItem(
          icon: Icons.checkroom_rounded,
          label: 'LAYERING',
          value: layering,
        ),
        WeatherAiMetricItem(
          icon: Icons.wb_sunny_rounded,
          label: 'SUN',
          value: uv >= 6 ? 'Sunglasses & SPF' : 'Normal UV',
          color: uv >= 6 ? const Color(0xFFFBBF24) : null,
        ),
        WeatherAiMetricItem(
          icon: Icons.wind_power_rounded,
          label: 'WIND',
          value: wind > 20 ? 'Breezy ($wind km/h)' : 'Calm ($wind km/h)',
        ),
      ],
      explanation:
          'Temperature is $temp°C with $rainProb% rain probability. ${needUmbrella ? "Rain is likely today; keep rain protection handy." : "Dry conditions make lightweight layers comfortable."}',
      actionLabel: 'View hourly temperature',
    );

    return WeatherAiResponse(
      text: 'Here is your personalized wardrobe advice for **$locationName** based on temperature, rain risk, and wind:',
      cardData: card,
      routineIntent: intent,
      followUps: [
        'Will it rain today?',
        'Best time to walk tomorrow',
        'Plan my day',
      ],
    );
  }

  static WeatherAiResponse _handleHealthOrAqiQuery({
    required String query,
    required UserState? userState,
    required WeatherDashboard? dashboard,
    required String locationName,
    required RoutineIntentResult intent,
  }) {
    final aqi = dashboard?.aqi;
    final aqiVal = aqi?.aqiValue ?? 42;
    final aqiCat = aqi?.category ?? 'Good';
    final concerns = userState?.healthConcerns ?? [];

    final isHighAqi = aqiVal > 80;
    final hasRespiratoryConcern =
        concerns.contains('Asthma') || concerns.contains('Dust') || concerns.contains('Allergies');

    String advice;
    if (isHighAqi && hasRespiratoryConcern) {
      advice = 'Air quality is elevated ($aqiVal). Because you noted sensitive respiratory triggers, wear an N95 mask and limit prolonged strenuous outdoor exposure.';
    } else if (isHighAqi) {
      advice = 'Air quality is moderately elevated ($aqiVal). Sensitive groups should reduce extended outdoor exertion during afternoon peaks.';
    } else {
      advice = 'Air quality is clean and healthy ($aqiVal · $aqiCat). Ideal for open-window ventilation and outdoor workouts.';
    }

    final card = WeatherAiCardData(
      cardType: WeatherCardType.healthEnvironment,
      category: 'AIR QUALITY & HEALTH ADVISORY',
      headline: 'AQI $aqiVal · $aqiCat',
      subtitle: '$locationName · Tailored for ${concerns.isNotEmpty ? concerns.join(", ") : "General Health"}',
      metrics: [
        WeatherAiMetricItem(
          icon: Icons.air_rounded,
          label: 'AQI',
          value: '$aqiVal ($aqiCat)',
          color: isHighAqi ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
        ),
        WeatherAiMetricItem(
          icon: Icons.masks_rounded,
          label: 'MASK',
          value: (isHighAqi && hasRespiratoryConcern) ? 'N95 Recommended' : 'Optional',
          color: (isHighAqi && hasRespiratoryConcern) ? const Color(0xFFFB7185) : null,
        ),
        WeatherAiMetricItem(
          icon: Icons.directions_run_rounded,
          label: 'OUTDOOR EXERTION',
          value: isHighAqi ? 'Limit to morning' : 'Safe all day',
        ),
      ],
      explanation: advice,
      actionLabel: 'Check Health & Metrics details',
    );

    return WeatherAiResponse(
      text: 'Here is your current health & environmental assessment for **$locationName**:',
      cardData: card,
      routineIntent: intent,
      followUps: [
        'Best time for outdoor exercise',
        'What should I wear today?',
        'Plan my morning',
      ],
    );
  }

  static WeatherAiResponse _handleTravelQuery({
    required String query,
    required UserState? userState,
    required WeatherDashboard? dashboard,
    required String locationName,
    required RoutineIntentResult intent,
  }) {
    // Extract destination if specified
    final words = query.split(RegExp(r'\s+'));
    String destination = locationName;
    for (int i = 0; i < words.length; i++) {
      if ((words[i].toLowerCase() == 'to' || words[i].toLowerCase() == 'in') && i + 1 < words.length) {
        destination = words.sublist(i + 1).join(' ').replaceAll(RegExp(r'[^a-zA-Z\s]'), '').trim();
        break;
      }
    }
    if (destination.isEmpty) destination = locationName;

    final curr = dashboard?.current;
    final temp = curr?.temperatureCelsius.round() ?? 28;
    final rainProb = dashboard?.daily.firstOrNull?.rainProbabilityPercent ?? 20;

    final card = WeatherAiCardData(
      cardType: WeatherCardType.travelPacking,
      category: 'TRAVEL & PACKING INTELLIGENCE',
      headline: '$destination Outlook · $temp°C',
      subtitle: 'Rain risk: $rainProb% · Travel comfort optimal',
      metrics: [
        WeatherAiMetricItem(
          icon: Icons.thermostat_rounded,
          label: 'TEMP',
          value: '$temp°C',
        ),
        WeatherAiMetricItem(
          icon: Icons.water_drop_outlined,
          label: 'RAIN',
          value: '$rainProb% chance',
          color: rainProb > 30 ? const Color(0xFF60A5FA) : null,
        ),
        const WeatherAiMetricItem(
          icon: Icons.luggage_rounded,
          label: 'TRAVEL COMFORT',
          value: 'Favorable',
          color: Color(0xFF10B981),
        ),
      ],
      checklistItems: [
        'Compact travel umbrella (for unexpected showers)',
        'Breathable cotton layers & light cardigan for transit',
        'Sun protection & SPF 30+ sunglasses',
        'Universal portable battery pack & travel hydration bottle',
      ],
      explanation:
          'Expected weather in $destination shows $temp°C with $rainProb% chance of light precipitation. Visibility is clear for flights and roads.',
      actionLabel: 'Save $destination to My Locations',
    );

    return WeatherAiResponse(
      text: 'Here is your curated travel and packing brief for your upcoming trip to **$destination**:',
      cardData: card,
      routineIntent: intent,
      followUps: [
        'What should I pack?',
        'Will it rain in $destination?',
        'Best time to walk tomorrow',
      ],
    );
  }

  static WeatherAiResponse _handleDailyPlanQuery({
    required String query,
    required UserState? userState,
    required WeatherDashboard? dashboard,
    required String locationName,
    required RoutineIntentResult intent,
  }) {
    final curr = dashboard?.current;
    final temp = curr?.temperatureCelsius.round() ?? 26;

    final card = WeatherAiCardData(
      cardType: WeatherCardType.dailyPlan,
      category: 'WEATHER-ADAPTIVE DAILY PLAN',
      headline: 'Today\'s 4-Stage Activity Rhythm',
      subtitle: '$locationName · Balanced for ${userState?.selectedPersona ?? "Active"} Lifestyle',
      dailyPlanPeriods: [
        DailyPlanPeriodItem(
          period: 'Morning',
          timeRange: '6:15 – 9:00 AM',
          temp: '${temp - 3}°C',
          condition: 'Cool & Clear',
          advice: 'Best window for outdoor walk or run',
          icon: Icons.wb_sunny_outlined,
        ),
        DailyPlanPeriodItem(
          period: 'Afternoon',
          timeRange: '12:00 – 3:30 PM',
          temp: '${temp + 3}°C',
          condition: 'Peak Heat & UV',
          advice: 'Stay hydrated, prefer indoor or shaded tasks',
          icon: Icons.thermostat_rounded,
        ),
        DailyPlanPeriodItem(
          period: 'Evening',
          timeRange: '5:30 – 7:45 PM',
          temp: '$temp°C',
          condition: 'Pleasant Breeze',
          advice: 'Great outdoor comfort for commute & errands',
          icon: Icons.park_outlined,
        ),
        DailyPlanPeriodItem(
          period: 'Night',
          timeRange: '9:00 PM onwards',
          temp: '${temp - 2}°C',
          condition: 'Calm & Cool',
          advice: 'Prepare for tomorrow morning routine',
          icon: Icons.bedtime_outlined,
        ),
      ],
      explanation: 'Conditions are favorable today with cool morning air and a mild evening. Afternoon features peak temperatures; schedule strenuous activities outside 12–3 PM.',
      actionLabel: 'Remind me at 9 PM every day',
    );

    return WeatherAiResponse(
      text: 'I\'ve organized your day into 4 weather-optimized periods for **$locationName**:',
      cardData: card,
      routineIntent: intent,
      followUps: [
        'What should I wear today?',
        'Will it rain this afternoon?',
        'Remind me at 9 PM to walk tomorrow',
      ],
    );
  }

  static WeatherAiResponse _handleGeneralWeatherQuery({
    required String query,
    required UserState? userState,
    required WeatherDashboard? dashboard,
    required String locationName,
    required RoutineIntentResult intent,
  }) {
    final curr = dashboard?.current;
    final temp = curr?.temperatureCelsius.round() ?? 25;
    final condition = curr?.condition ?? 'Partly cloudy';
    final rainProb = dashboard?.daily.firstOrNull?.rainProbabilityPercent ?? 10;
    final aqi = dashboard?.aqi?.aqiValue ?? 38;

    final card = WeatherAiCardData(
      cardType: WeatherCardType.forecastSummary,
      category: 'CURRENT CONDITIONS & RADAR',
      headline: '$temp°C · $condition',
      subtitle: '$locationName · Real-time satellite & sensor feed',
      metrics: [
        WeatherAiMetricItem(
          icon: Icons.water_drop_outlined,
          label: 'RAIN CHANCE',
          value: '$rainProb%',
          color: rainProb > 30 ? const Color(0xFF60A5FA) : null,
        ),
        WeatherAiMetricItem(
          icon: Icons.air_rounded,
          label: 'AQI',
          value: 'AQI $aqi',
          color: const Color(0xFF10B981),
        ),
        WeatherAiMetricItem(
          icon: Icons.thermostat_rounded,
          label: 'FEELS LIKE',
          value: '${(curr?.feelsLikeCelsius ?? temp).round()}°C',
        ),
      ],
      explanation: rainProb > 30
          ? 'Isolated showers are possible today with a $rainProb% probability. Keep rain gear accessible.'
          : 'Stable conditions with low rain probability ($rainProb%). Ideal for outdoor plans.',
      actionLabel: 'View full 7-day forecast',
    );

    return WeatherAiResponse(
      text: 'Here is the current weather radar summary for **$locationName**:',
      cardData: card,
      routineIntent: intent,
      followUps: [
        'Best time to walk tomorrow',
        'What should I wear?',
        'Plan my day based on weather',
      ],
    );
  }
}
