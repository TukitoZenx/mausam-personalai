import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/routine_reminder.dart';
import '../services/notification_service.dart';

const _kRoutineRemindersKey = 'mausam_routine_reminders_v1';

class RoutineReminderNotifier extends Notifier<List<RoutineReminder>> {
  bool _isHydrated = false;

  @override
  List<RoutineReminder> build() {
    _loadFromPrefs();
    return const [];
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_kRoutineRemindersKey);
      if (!_isHydrated && jsonStr != null && jsonStr.isNotEmpty) {
        final list = RoutineReminder.listFromJsonString(jsonStr);
        state = list;
        _isHydrated = true;
        // Re-synchronize OS alarms on startup
        _rescheduleActiveReminders(list);
        return;
      }
      _isHydrated = true;
    } catch (e) {
      debugPrint('[RoutineReminderNotifier] Error loading reminders: $e');
      _isHydrated = true;
    }
  }

  Future<void> _rescheduleActiveReminders(List<RoutineReminder> list) async {
    try {
      for (final reminder in list) {
        if (reminder.isActive) {
          final body = "Tomorrow's best ${reminder.activity} window is ready based on live weather.";
          await NotificationService.scheduleDailyRoutineReminder(
            reminder,
            bodyText: body,
          );
        }
      }
    } catch (e) {
      debugPrint('[RoutineReminderNotifier] Reschedule error: $e');
    }
  }

  Future<void> _saveToPrefs(List<RoutineReminder> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = RoutineReminder.listToJsonString(list);
      await prefs.setString(_kRoutineRemindersKey, jsonStr);
    } catch (e) {
      debugPrint('[RoutineReminderNotifier] Error saving to prefs: $e');
    }
  }

  /// Creates a new routine reminder or updates an existing reminder for the same activity.
  Future<RoutineReminder> createOrUpdateReminder({
    required String activity,
    required int reminderHour,
    required int reminderMinute,
    String targetPeriod = 'morning',
    String? notificationBody,
  }) async {
    _isHydrated = true;
    final currentTz = NotificationService.currentTimeZone;

    // Check if an existing reminder exists for this activity
    final index = state.indexWhere(
      (r) => r.activity.toLowerCase() == activity.toLowerCase(),
    );

    RoutineReminder reminder;
    if (index != -1) {
      // Cancel previous notification schedule to prevent duplicates
      await NotificationService.cancelReminder(state[index].id);

      reminder = state[index].copyWith(
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
        targetPeriod: targetPeriod,
        timezone: currentTz,
        isActive: true,
        updatedAt: DateTime.now(),
      );
      final updatedList = List<RoutineReminder>.from(state);
      updatedList[index] = reminder;
      state = updatedList;
    } else {
      reminder = RoutineReminder(
        id: 'rem_${DateTime.now().millisecondsSinceEpoch}',
        activity: activity,
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
        targetPeriod: targetPeriod,
        timezone: currentTz,
        isDaily: true,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      state = [reminder, ...state];
    }

    await _saveToPrefs(state);

    // Schedule real OS device notification
    final body = notificationBody ??
        "Tomorrow's best $activity window is ready. Open Mausam for your dynamic forecast.";
    await NotificationService.scheduleDailyRoutineReminder(
      reminder,
      bodyText: body,
    );

    return reminder;
  }

  /// Edits reminder schedule time and cancels/reschedules the OS alarm.
  Future<RoutineReminder?> editReminderTime(
    String id, {
    required int newHour,
    required int newMinute,
    String? notificationBody,
  }) async {
    _isHydrated = true;
    final index = state.indexWhere((r) => r.id == id);
    if (index == -1) return null;

    final current = state[index];
    // 1. Cancel previous schedule
    await NotificationService.cancelReminder(id);

    // 2. Update model
    final updated = current.copyWith(
      reminderHour: newHour,
      reminderMinute: newMinute,
      timezone: NotificationService.currentTimeZone,
      updatedAt: DateTime.now(),
    );

    final updatedList = List<RoutineReminder>.from(state);
    updatedList[index] = updated;
    state = updatedList;
    await _saveToPrefs(state);

    // 3. Schedule fresh notification if active
    if (updated.isActive) {
      final body = notificationBody ??
          "Tomorrow's best ${updated.activity} window is ready based on live weather.";
      await NotificationService.scheduleDailyRoutineReminder(
        updated,
        bodyText: body,
      );
    }

    return updated;
  }

  /// Toggles the active status of a reminder (Pause / Resume).
  Future<void> togglePauseResume(String id, {String? notificationBody}) async {
    _isHydrated = true;
    final index = state.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final current = state[index];
    final willBeActive = !current.isActive;

    final updated = current.copyWith(
      isActive: willBeActive,
      updatedAt: DateTime.now(),
    );

    final updatedList = List<RoutineReminder>.from(state);
    updatedList[index] = updated;
    state = updatedList;

    await _saveToPrefs(state);

    if (willBeActive) {
      final body = notificationBody ??
          "Tomorrow's best ${updated.activity} window is ready based on live weather.";
      await NotificationService.scheduleDailyRoutineReminder(
        updated,
        bodyText: body,
      );
    } else {
      await NotificationService.cancelReminder(id);
    }
  }

  /// Deletes a reminder and cancels its scheduled alarm.
  Future<void> deleteReminder(String id) async {
    _isHydrated = true;
    await NotificationService.cancelReminder(id);
    final updatedList = state.where((r) => r.id != id).toList();
    state = updatedList;
    await _saveToPrefs(state);
  }

  /// Returns the most recently created or updated active reminder.
  RoutineReminder? getLatestActiveReminder() {
    for (final r in state) {
      if (r.isActive) return r;
    }
    return state.isNotEmpty ? state.first : null;
  }
}

final routineReminderProvider =
    NotifierProvider<RoutineReminderNotifier, List<RoutineReminder>>(() {
  return RoutineReminderNotifier();
});
