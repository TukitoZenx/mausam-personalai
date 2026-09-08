import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/routine_reminder.dart';
import '../services/routine_reminder_scheduler.dart';

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
      }
      _isHydrated = true;
    } catch (_) {
      _isHydrated = true;
    }
  }

  Future<void> _saveToPrefs(List<RoutineReminder> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = RoutineReminder.listToJsonString(list);
      await prefs.setString(_kRoutineRemindersKey, jsonStr);
    } catch (_) {
      // Graceful fallback
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
    // Check if an existing reminder exists for this activity
    final index = state.indexWhere((r) => r.activity.toLowerCase() == activity.toLowerCase());

    RoutineReminder reminder;
    if (index != -1) {
      reminder = state[index].copyWith(
        reminderHour: reminderHour,
        reminderMinute: reminderMinute,
        targetPeriod: targetPeriod,
        isActive: true,
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
        isDaily: true,
        isActive: true,
        createdAt: DateTime.now(),
      );
      state = [reminder, ...state];
    }

    await _saveToPrefs(state);

    // Schedule notification
    final body = notificationBody ??
        "Tomorrow's best $activity window has been calculated from the latest weather radar.";
    await RoutineReminderScheduler.scheduleDailyReminder(reminder, bodyText: body);

    return reminder;
  }

  /// Toggles the active status of a reminder (Pause / Resume).
  Future<void> togglePauseResume(String id, {String? notificationBody}) async {
    _isHydrated = true;
    final index = state.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final current = state[index];
    final updated = current.copyWith(isActive: !current.isActive);

    final updatedList = List<RoutineReminder>.from(state);
    updatedList[index] = updated;
    state = updatedList;

    await _saveToPrefs(state);

    if (updated.isActive) {
      final body = notificationBody ??
          "Tomorrow's best ${updated.activity} window has been calculated from the latest weather radar.";
      await RoutineReminderScheduler.scheduleDailyReminder(updated, bodyText: body);
    } else {
      await RoutineReminderScheduler.cancelReminder(id);
    }
  }

  /// Deletes a reminder and cancels its scheduled alarm.
  Future<void> deleteReminder(String id) async {
    _isHydrated = true;
    await RoutineReminderScheduler.cancelReminder(id);
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
