enum RoutineIntentType {
  reminderAndRecommendation,
  createReminderOnly,
  recommendationOnly,
  listReminders,
  deleteReminder,
  none,
}

class RoutineIntentResult {
  final RoutineIntentType type;
  final String activity; // 'walking', 'jogging', 'running', 'cycling', 'workout'
  final int? reminderHour; // 0-23
  final int? reminderMinute; // 0-59
  final String targetPeriod; // 'morning', 'evening', 'afternoon'
  final bool isDaily;
  final String rawQuery;

  const RoutineIntentResult({
    required this.type,
    required this.activity,
    this.reminderHour,
    this.reminderMinute,
    this.targetPeriod = 'morning',
    this.isDaily = true,
    required this.rawQuery,
  });

  bool get hasReminderTime => reminderHour != null;
  bool get isReminderIntent =>
      type == RoutineIntentType.reminderAndRecommendation ||
      type == RoutineIntentType.createReminderOnly;
  bool get isRecommendationIntent =>
      type == RoutineIntentType.reminderAndRecommendation ||
      type == RoutineIntentType.recommendationOnly;
}

class RoutineIntentParser {
  /// Parses natural user queries into routine and activity intents.
  static RoutineIntentResult parse(String query) {
    final lower = query.toLowerCase().trim();

    // 1. Detect Activity
    String activity = 'walking';
    if (lower.contains('jogging') || lower.contains('jog')) {
      activity = 'jogging';
    } else if (lower.contains('running') || lower.contains('run')) {
      activity = 'running';
    } else if (lower.contains('cycling') || lower.contains('cycle') || lower.contains('bike')) {
      activity = 'cycling';
    } else if (lower.contains('workout') || lower.contains('exercise') || lower.contains('fitness')) {
      activity = 'outdoor workout';
    } else if (lower.contains('walk')) {
      activity = 'walking';
    }

    // 2. Detect Target Period for Activity
    String targetPeriod = 'morning';
    if (lower.contains('evening') || lower.contains('dusk') || lower.contains('sunset')) {
      targetPeriod = 'evening';
    } else if (lower.contains('afternoon') || lower.contains('midday') || lower.contains('noon')) {
      targetPeriod = 'afternoon';
    } else if (lower.contains('morning') || lower.contains('dawn') || lower.contains('sunrise')) {
      targetPeriod = 'morning';
    }

    // 3. Detect Reminder Keywords
    final hasReminderKeyword = lower.contains('remind') ||
        lower.contains('reminder') ||
        lower.contains('alarm') ||
        lower.contains('alert me') ||
        lower.contains('notify me') ||
        lower.contains('schedule');

    // 3b. Quick match: List / Show reminders
    if ((lower.contains('my reminder') ||
            lower.contains('show reminder') ||
            lower.contains('list reminder') ||
            lower.contains('view reminder') ||
            lower.contains('active reminder')) &&
        !lower.contains('set') &&
        !lower.contains('create')) {
      return RoutineIntentResult(
        type: RoutineIntentType.listReminders,
        activity: activity,
        rawQuery: query,
      );
    }

    // 3c. Quick match: Delete / Cancel reminder
    if ((lower.contains('delete') || lower.contains('cancel') || lower.contains('remove')) &&
        hasReminderKeyword) {
      return RoutineIntentResult(
        type: RoutineIntentType.deleteReminder,
        activity: activity,
        rawQuery: query,
      );
    }

    // 4. Detect Recommendation Keywords
    final hasRecommendationKeyword = lower.contains('what time') ||
        lower.contains('best time') ||
        lower.contains('when should') ||
        lower.contains('best window') ||
        lower.contains('good time') ||
        lower.contains('ideal time') ||
        lower.contains('timing') ||
        lower.contains('window');

    final hasTomorrow = lower.contains('tomorrow');

    // 5. Extract Reminder Time
    final timeResult = _extractTime(lower);

    // 6. Determine Intent Type
    if (hasReminderKeyword && (hasRecommendationKeyword || hasTomorrow) && timeResult != null) {
      return RoutineIntentResult(
        type: RoutineIntentType.reminderAndRecommendation,
        activity: activity,
        reminderHour: timeResult.hour,
        reminderMinute: timeResult.minute,
        targetPeriod: targetPeriod,
        isDaily: _isDaily(lower),
        rawQuery: query,
      );
    } else if (hasReminderKeyword && timeResult != null) {
      return RoutineIntentResult(
        type: RoutineIntentType.createReminderOnly,
        activity: activity,
        reminderHour: timeResult.hour,
        reminderMinute: timeResult.minute,
        targetPeriod: targetPeriod,
        isDaily: _isDaily(lower),
        rawQuery: query,
      );
    } else if (hasRecommendationKeyword || (hasTomorrow && (lower.contains('walk') || lower.contains('run') || lower.contains('jog') || lower.contains('cycl')))) {
      return RoutineIntentResult(
        type: RoutineIntentType.recommendationOnly,
        activity: activity,
        reminderHour: null,
        reminderMinute: null,
        targetPeriod: targetPeriod,
        isDaily: false,
        rawQuery: query,
      );
    }

    return RoutineIntentResult(
      type: RoutineIntentType.none,
      activity: activity,
      rawQuery: query,
    );
  }

  static bool _isDaily(String text) {
    return text.contains('every day') ||
        text.contains('daily') ||
        text.contains('every night') ||
        text.contains('every morning') ||
        text.contains('every evening') ||
        text.contains('each day');
  }

  /// Extracts hour (0-23) and minute (0-59) from natural strings.
  /// Supports: "9:00 PM", "9 PM", "9pm", "9:30 am", "9 at night", "21:00", "at 9"
  static ({int hour, int minute})? _extractTime(String text) {
    // Pattern 1: HH:MM AM/PM or HH:MM
    final regexTimeColon = RegExp(r'(\d{1,2}):(\d{2})\s*(am|pm)?', caseSensitive: false);
    final matchColon = regexTimeColon.firstMatch(text);
    if (matchColon != null) {
      int hour = int.parse(matchColon.group(1)!);
      final int minute = int.parse(matchColon.group(2)!);
      final String? period = matchColon.group(3)?.toLowerCase();

      if (period == 'pm' && hour < 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;
      if (period == null) {
        // Look for contextual clues like "at night" / "evening"
        if ((text.contains('night') || text.contains('evening')) && hour < 12) {
          hour += 12;
        }
      }
      return (hour: hour, minute: minute);
    }

    // Pattern 2: "9 PM" or "9pm" or "9 AM"
    final regexHourPeriod = RegExp(r'(?:at\s+)?(\d{1,2})\s*(am|pm)', caseSensitive: false);
    final matchHour = regexHourPeriod.firstMatch(text);
    if (matchHour != null) {
      int hour = int.parse(matchHour.group(1)!);
      final String period = matchHour.group(2)!.toLowerCase();
      if (period == 'pm' && hour < 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;
      return (hour: hour, minute: 0);
    }

    // Pattern 3: "at 9" or "every night at 9" or "at 9 in the night"
    final regexAtNight = RegExp(r'(?:at|night at|evening at)\s+(\d{1,2})(?:\s+at night|\s+in the evening|\s+tonight)?', caseSensitive: false);
    final matchAt = regexAtNight.firstMatch(text);
    if (matchAt != null) {
      int hour = int.parse(matchAt.group(1)!);
      if (hour >= 1 && hour <= 12) {
        if (text.contains('night') || text.contains('evening') || text.contains('pm')) {
          if (hour < 12) hour += 12;
        }
      }
      return (hour: hour, minute: 0);
    }

    return null;
  }
}
