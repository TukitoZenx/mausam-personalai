import 'dart:convert';

/// Represents a user's scheduled personal routine reminder.
class RoutineReminder {
  final String id;
  final String? userId;
  final String activity; // 'walking', 'jogging', 'running', 'cycling', 'workout'
  final String reminderType; // 'activity_forecast', 'routine_check'
  final String recurrence; // 'daily', 'weekdays', 'once'
  final int reminderHour; // 0-23
  final int reminderMinute; // 0-59
  final String targetPeriod; // 'morning', 'evening', 'afternoon'
  final String timezone; // IANA timezone e.g. 'Asia/Kolkata'
  final bool isDaily;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastTriggeredAt;
  final String? customTitle;

  const RoutineReminder({
    required this.id,
    this.userId,
    required this.activity,
    this.reminderType = 'activity_forecast',
    this.recurrence = 'daily',
    required this.reminderHour,
    required this.reminderMinute,
    this.targetPeriod = 'morning',
    this.timezone = 'UTC',
    this.isDaily = true,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.lastTriggeredAt,
    this.customTitle,
  });

  /// Displays the reminder time in 12-hour format, e.g. "9:00 PM".
  String get reminderTimeDisplay {
    final hour12 = reminderHour % 12 == 0 ? 12 : reminderHour % 12;
    final period = reminderHour < 12 ? 'AM' : 'PM';
    final minuteStr = reminderMinute.toString().padLeft(2, '0');
    return '$hour12:$minuteStr $period';
  }

  /// Displays the uppercase header label, e.g. "DAILY WALKING CHECK".
  String get activityTitle {
    if (customTitle != null && customTitle!.isNotEmpty) {
      return customTitle!.toUpperCase();
    }
    final act = activity.trim().isEmpty ? 'ACTIVITY' : activity.trim().toUpperCase();
    return 'DAILY $act CHECK';
  }

  /// Display string for the schedule, e.g. "Every day · 9:00 PM".
  String get scheduleDisplay {
    final frequency = isDaily ? 'Every day' : 'Scheduled';
    return '$frequency · $reminderTimeDisplay';
  }

  RoutineReminder copyWith({
    String? id,
    String? userId,
    String? activity,
    String? reminderType,
    String? recurrence,
    int? reminderHour,
    int? reminderMinute,
    String? targetPeriod,
    String? timezone,
    bool? isDaily,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastTriggeredAt,
    String? customTitle,
  }) {
    return RoutineReminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      activity: activity ?? this.activity,
      reminderType: reminderType ?? this.reminderType,
      recurrence: recurrence ?? this.recurrence,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      targetPeriod: targetPeriod ?? this.targetPeriod,
      timezone: timezone ?? this.timezone,
      isDaily: isDaily ?? this.isDaily,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
      customTitle: customTitle ?? this.customTitle,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'activity': activity,
      'reminder_type': reminderType,
      'recurrence': recurrence,
      'reminder_hour': reminderHour,
      'reminder_minute': reminderMinute,
      'target_period': targetPeriod,
      'timezone': timezone,
      'is_daily': isDaily,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_triggered_at': lastTriggeredAt?.toIso8601String(),
      'custom_title': customTitle,
    };
  }

  factory RoutineReminder.fromJson(Map<String, dynamic> json) {
    return RoutineReminder(
      id: json['id'] as String? ?? 'rem_${DateTime.now().millisecondsSinceEpoch}',
      userId: json['user_id'] as String?,
      activity: json['activity'] as String? ?? 'walking',
      reminderType: json['reminder_type'] as String? ?? 'activity_forecast',
      recurrence: json['recurrence'] as String? ?? 'daily',
      reminderHour: (json['reminder_hour'] as num?)?.toInt() ?? 21,
      reminderMinute: (json['reminder_minute'] as num?)?.toInt() ?? 0,
      targetPeriod: json['target_period'] as String? ?? 'morning',
      timezone: json['timezone'] as String? ?? 'UTC',
      isDaily: json['is_daily'] as bool? ?? true,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      lastTriggeredAt: json['last_triggered_at'] != null
          ? DateTime.tryParse(json['last_triggered_at'] as String)
          : null,
      customTitle: json['custom_title'] as String?,
    );
  }

  static List<RoutineReminder> listFromJsonString(String jsonStr) {
    try {
      final decoded = json.decode(jsonStr) as List<dynamic>;
      return decoded.map((e) => RoutineReminder.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJsonString(List<RoutineReminder> list) {
    return json.encode(list.map((e) => e.toJson()).toList());
  }
}
