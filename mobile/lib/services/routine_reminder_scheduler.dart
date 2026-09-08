import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/routine_reminder.dart';
import 'notification_service.dart';

/// Legacy adapter maintaining seamless backward compatibility while delegating
/// to the unified [NotificationService].
class RoutineReminderScheduler {
  static String get currentTimeZone => NotificationService.currentTimeZone;

  static Future<void> init() async {
    await NotificationService.init();
  }

  static Future<bool> checkPermissionStatus() async {
    return await NotificationService.checkPermissionStatus();
  }

  static Future<bool> requestPermissions() async {
    return await NotificationService.requestPermissions();
  }

  static Future<bool> scheduleDailyReminder(
    RoutineReminder reminder, {
    required String bodyText,
  }) async {
    return await NotificationService.scheduleDailyRoutineReminder(
      reminder,
      bodyText: bodyText,
    );
  }

  static Future<bool> scheduleTestNotification({
    int delaySeconds = 12,
    String activity = 'walking',
  }) async {
    return await NotificationService.scheduleTestNotification(
      delaySeconds: delaySeconds,
    );
  }

  static Future<void> cancelReminder(String reminderId) async {
    await NotificationService.cancelReminder(reminderId);
  }

  static Future<void> cancelAllReminders() async {
    await NotificationService.cancelAll();
  }

  static int getNotificationId(String reminderId) {
    return NotificationService.getNotificationId(reminderId);
  }

  static tz.TZDateTime calculateNextOccurrence(int hour, int minute) {
    return NotificationService.calculateNextOccurrence(hour, minute);
  }

  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await NotificationService.getPendingNotifications();
  }
}
