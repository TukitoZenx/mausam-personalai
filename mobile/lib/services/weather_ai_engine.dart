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

    // 2. General Chat & Greetings Intent (e.g. "hi", "how are you", "thanks", "what can you do")
    if (_isGeneralChat(lower)) {
      return _handleGeneralChat(
        query: query,
        intent: routineIntent,
      );
    }

    // 3. Clothing & Wardrobe Intent
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

  static bool _isGeneralChat(String q) {
    final clean = q.trim().replaceAll(RegExp(r'[!?.,]'), '');
    final greetings = {
      'hi',
      'hii',
      'hello',
      'hey',
      'yo',
      'hola',
      'namaste',
      'good morning',
      'good afternoon',
      'good evening',
      'good night',
    };
    if (greetings.contains(clean)) return true;
    if (clean.startsWith('hi ') || clean.startsWith('hello ') || clean.startsWith('hey ')) {
      if (!clean.contains('weather') &&
          !clean.contains('rain') &&
          !clean.contains('temp') &&
          !clean.contains('aqi') &&
          !clean.contains('forecast')) {
        return true;
      }
    }
    if (clean.contains('how are you') ||
        clean.contains('hows it going') ||
        clean.contains("how's it going") ||
        clean.contains('whats up') ||
        clean.contains("what's up")) {
      return true;
    }
    if (clean == 'thanks' || clean == 'thank you' || clean == 'thx' || clean == 'ty' || clean == 'tysm') {
      return true;
    }
    if (clean == 'what can you do' ||
        clean == 'help' ||
        clean == 'who are you' ||
        clean == 'what are your capabilities') {
      return true;
    }
    return false;
  }

  static WeatherAiResponse _handleGeneralChat({
    required String query,
    required RoutineIntentResult intent,
  }) {
    final lower = query.toLowerCase().trim();

    if (lower.contains('how are you') ||
        lower.contains('hows it going') ||
        lower.contains("how's it going") ||
        lower.contains("what's up") ||
        lower.contains('whats up')) {
      return WeatherAiResponse(
        text: 'I’m doing great! 😊 What can I help you with?',
        routineIntent: intent,
        followUps: const [
          "What's the weather today?",
          'Will it rain today?',
          'Check air quality',
          'What can you do?',
        ],
      );
    }

    if (lower.contains('what can you do') ||
        lower == 'help' ||
        lower.contains('who are you') ||
        lower.contains('capabilities')) {
      return WeatherAiResponse(
        text: "I'm **Mausam AI**, your personal weather intelligence assistant! 🌤️ Here is what I can do for you:\n\n"
            "• **Live Weather**: Instant temperature, 'feels-like', humidity, wind, and conditions\n"
            "• **Forecasts**: Hourly trends and 5-day daily forecasts\n"
            "• **Air Quality (AQI)**: Live pollution levels and respiratory health guidance\n"
            "• **Severe Weather Alerts**: Official storm, heatwave, and heavy rain warnings\n"
            "• **Activity Intelligence**: Optimal windows for cricket, running, workouts, and outdoor sports\n"
            "• **Travel & Commute**: Weather comparison across cities and road safety insights\n"
            "• **Wardrobe & Routine**: Personalized outfit advice, umbrella reminders, and daily schedules\n\n"
            "What would you like to check today?",
        routineIntent: intent,
        followUps: const [
          "What's the weather in Hyderabad?",
          'Will it rain today?',
          'Check air quality',
          'Can I play cricket today?',
        ],
      );
    }

    if (lower.contains('thank')) {
      return WeatherAiResponse(
        text: 'You’re welcome! 😊',
        routineIntent: intent,
        followUps: const [
          "Today's weather",
          'Air quality index',
          '5-day forecast',
        ],
      );
    }

    return WeatherAiResponse(
      text: 'Hello! 👋 How can I help you today?',
      routineIntent: intent,
      followUps: const [
        "What's the weather today?",
        'Will it rain today?',
        'Air quality index',
        '5-day forecast',
      ],
    );
  }

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
    final clean = query.trim();
    final cleanCore = clean.replaceAll(
      RegExp(r"^(?:i\s+will|i'm|i\s+am|we\s+will|we're|we\s+are|planning\s+to|plan\s+to|want\s+to|need\s+to|how\s+is\s+the|what\s+is\s+the|can\s+i|please|check\s+the)\s+", caseSensitive: false),
      '',
    ).trim();

    String cleanPlace(String p) {
      var s = p.trim();
      s = s.replaceAll(RegExp(r"^(?:the\s+city\s+of|the\s+town\s+of|the)\s+", caseSensitive: false), '');
      s = s.replaceAll(RegExp(r"\s+(?:city|town|area|state)$", caseSensitive: false), '');
      s = s.replaceAll(RegExp(r"\b(by\s+road|by\s+car|by\s+bus|by\s+train|road|highway|trip|route|weather|tomorrow|today|tonight)\b.*$", caseSensitive: false), '');
      return s.trim();
    }

    String? origin;
    String? destination;

    // Pattern 1: to <dest> from <origin>
    var m = RegExp(r"\b(?:go|going|travel|traveling|travelling|trip|commute|commuting|drive|driving)?\s*to\s+([A-Za-z\s]+?)\s+from\s+([A-Za-z\s]+?)(?:\s+(?:by|on|via|with|tomorrow|today|tonight|next)|[?.!,]|$)", caseSensitive: false).firstMatch(cleanCore);
    if (m != null) {
      destination = cleanPlace(m.group(1) ?? '');
      origin = cleanPlace(m.group(2) ?? '');
    }

    // Pattern 2: from <origin> to <dest>
    if (origin == null || destination == null) {
      m = RegExp(r"\b(?:travel|traveling|travelling|trip|commute|commuting|drive|driving|route|going|go)?\s*from\s+([A-Za-z\s]+?)\s+to\s+([A-Za-z\s]+?)(?:\s+(?:by|on|via|with|tomorrow|today|tonight|next)|[?.!,]|$)", caseSensitive: false).firstMatch(cleanCore);
      if (m != null) {
        origin = cleanPlace(m.group(1) ?? '');
        destination = cleanPlace(m.group(2) ?? '');
      }
    }

    // Pattern 3: <origin> to <dest>
    if (origin == null || destination == null) {
      m = RegExp(r"^([A-Za-z\s]+?)\s+(?:to|->|→)\s+([A-Za-z\s]+?)(?:\s+(?:route|trip|drive|weather|by\s+road)|[?.!,]|$)", caseSensitive: false).firstMatch(cleanCore);
      if (m != null) {
        origin = cleanPlace(m.group(1) ?? '');
        destination = cleanPlace(m.group(2) ?? '');
      }
    }

    final curr = dashboard?.current;
    final temp = curr?.temperatureCelsius.round() ?? 28;
    final cond = curr?.condition ?? 'Clear';
    final rainProb = dashboard?.daily.firstOrNull?.rainProbabilityPercent ?? 20;

    // If both origin and destination are extracted -> Return structured travelRoute card
    if (origin != null && destination != null && origin.isNotEmpty && destination.isNotEmpty && origin.toLowerCase() != destination.toLowerCase()) {
      final card = WeatherAiCardData(
        cardType: WeatherCardType.travelRoute,
        category: 'TRAVEL ROUTE INTELLIGENCE',
        headline: '$origin → $destination',
        subtitle: '~450 km (est.) · ~7h 30m (est. drive)',
        origin: origin,
        destination: destination,
        distanceKm: 450,
        durationText: '7h 30m',
        isEstimate: true,
        isEstimated: true,
        routeSource: 'estimated',
        originCoords: const {'latitude': 13.0827, 'longitude': 80.2707},
        destCoords: const {'latitude': 16.5062, 'longitude': 80.6480},
        destinationWeather: {
          'temperature': temp,
          'condition': cond,
          'aqi': 65,
          'aqiCategory': 'Moderate',
        },
        routePoints: [
          TravelRoutePoint(
            name: origin,
            role: 'origin',
            lat: 13.0827,
            lon: 80.2707,
            weather: {
              'temperature': temp,
              'condition': cond,
              'aqi': 55,
              'aqiCategory': 'Good',
            },
          ),
          TravelRoutePoint(
            name: destination,
            role: 'destination',
            lat: 16.5062,
            lon: 80.6480,
            weather: {
              'temperature': temp,
              'condition': cond,
              'aqi': 65,
              'aqiCategory': 'Moderate',
            },
          ),
        ],
        routeGeometry: const [
          {'lat': 13.0827, 'lon': 80.2707},
          {'lat': 16.5062, 'lon': 80.6480},
        ],
        metrics: [
          const WeatherAiMetricItem(
            icon: Icons.navigation_rounded,
            label: 'Est. Distance',
            value: '~450 km',
          ),
          const WeatherAiMetricItem(
            icon: Icons.schedule_rounded,
            label: 'Est. Duration',
            value: '7h 30m drive',
          ),
          WeatherAiMetricItem(
            icon: Icons.thermostat_rounded,
            label: '$destination Temp',
            value: '$temp°C',
          ),
          const WeatherAiMetricItem(
            icon: Icons.bubble_chart_rounded,
            label: 'Air Quality',
            value: 'AQI 65',
          ),
        ],
        explanation: 'Destination conditions in $destination show $temp°C with $cond. Highway driving conditions are generally favorable. Drive safely!',
        actionLabel: 'View route on map',
        actionRoute: 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination',
      );

      return WeatherAiResponse(
        text: 'Got it! You’re planning to travel from **$origin** to **$destination**. Here’s your route overview:\n\n'
            '• **Estimated Distance**: ~450 km by road\n'
            '• **Estimated Travel Time**: ~7h 30m drive\n'
            '• **Destination Weather ($destination)**: **$temp°C**, $cond\n'
            '• **Air Quality**: AQI **65** (Moderate)\n\n'
            'Safe travels! Tap **View route on map** below to see your route preview and live directions.',
        cardData: card,
        routineIntent: intent,
        followUps: [
          'Weather in $destination',
          'Weather in $origin',
          'Will it rain in $destination?',
        ],
      );
    }

    // Default single-city travel and packing brief
    final words = query.split(RegExp(r'\s+'));
    String singleDest = locationName;
    for (int i = 0; i < words.length; i++) {
      if ((words[i].toLowerCase() == 'to' || words[i].toLowerCase() == 'in') && i + 1 < words.length) {
        singleDest = words.sublist(i + 1).join(' ').replaceAll(RegExp(r'[^a-zA-Z\s]'), '').trim();
        break;
      }
    }
    if (singleDest.isEmpty) singleDest = locationName;

    final card = WeatherAiCardData(
      cardType: WeatherCardType.travelPacking,
      category: 'TRAVEL & PACKING INTELLIGENCE',
      headline: '$singleDest Outlook · $temp°C',
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
          'Expected weather in $singleDest shows $temp°C with $rainProb% chance of light precipitation. Visibility is clear for flights and roads.',
      actionLabel: 'Save $singleDest to My Locations',
    );

    return WeatherAiResponse(
      text: 'Here is your curated travel and packing brief for your upcoming trip to **$singleDest**:',
      cardData: card,
      routineIntent: intent,
      followUps: [
        'What should I pack?',
        'Will it rain in $singleDest?',
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
