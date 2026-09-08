import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/routine_reminder.dart';
import '../router/app_router.dart';

class RoutineReminderScheduler {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static String _currentTimeZone = 'UTC';

  static String get currentTimeZone => _currentTimeZone;

  /// Initializes the local notification plugin and device local timezone data.
  static Future<void> init() async {
    if (_initialized) return;

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest || kIsWeb) {
      _initialized = true;
      return;
    }

    try {
      // 1. Initialize timezone database and detect device's actual IANA timezone
      tz.initializeTimeZones();
      try {
        final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
        final ianaName = timeZoneInfo.identifier;
        tz.setLocalLocation(tz.getLocation(ianaName));
        _currentTimeZone = ianaName;
        debugPrint('[MausamReminder] Timezone: $_currentTimeZone');
      } catch (e) {
        debugPrint('[MausamReminder] Timezone detection fallback: $e');
        _currentTimeZone = tz.local.name;
      }

      // 2. Platform initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open Routine Reminder',
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('[MausamReminder] Notification tapped. Payload: ${response.payload}');
          // Route user directly into Mausam AI insights screen
          try {
            appRouter.go('/insights');
          } catch (e) {
            debugPrint('[MausamReminder] Navigation on tap error: $e');
          }
        },
      );

      // 3. Create Android Notification Channel for Routines
      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.createNotificationChannel(
          const AndroidNotificationChannel(
            'mausam_routine_reminders',
            'Daily Routine & Activity Reminders',
            description: 'Personalized routine notifications calculated from real-time weather forecasts.',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
      }

      _initialized = true;
      debugPrint('[MausamReminder] RoutineReminderScheduler initialized successfully.');
    } catch (e) {
      debugPrint('[MausamReminder] Error initializing RoutineReminderScheduler: $e');
    }
  }

  /// Checks if notification permissions are currently enabled on the device.
  static Future<bool> checkPermissionStatus() async {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest || kIsWeb) return true;

    await init();
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final enabled = await androidImpl?.areNotificationsEnabled();
        return enabled ?? true;
      }
      return true;
    } catch (e) {
      debugPrint('[MausamReminder] Error checking notification permission: $e');
      return true;
    }
  }

  /// Requests notification permission on Android 13+ and iOS.
  static Future<bool> requestPermissions() async {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest || kIsWeb) return true;

    await init();
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidImpl?.requestNotificationsPermission();

        // Also check/request exact alarms permission if applicable on Android 12+
        try {
          final canExact = await androidImpl?.canScheduleExactNotifications();
          if (canExact == false) {
            await androidImpl?.requestExactAlarmsPermission();
          }
        } catch (_) {}

        debugPrint('[MausamReminder] Permission: ${granted == true ? "granted" : "denied"}');
        return granted ?? true;
      } else if (!kIsWeb && Platform.isIOS) {
        final iosImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('[MausamReminder] Permission: ${granted == true ? "granted" : "denied"}');
        return granted ?? true;
      }
      return true;
    } catch (e) {
      debugPrint('[MausamReminder] Error requesting notification permissions: $e');
      return true;
    }
  }

  /// Schedules a recurring daily reminder for the specified time.
  static Future<bool> scheduleDailyReminder(
    RoutineReminder reminder, {
    required String bodyText,
  }) async {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest || kIsWeb) {
      debugPrint('Test environment: Mocked scheduleDailyReminder for ${reminder.id}');
      return true;
    }

    await init();

    final notifId = _getNotificationId(reminder.id);
    final isPermitted = await checkPermissionStatus();

    debugPrint('[MausamReminder] Reminder created: ${reminder.activityTitle} — ${reminder.reminderTimeDisplay}');
    debugPrint('[MausamReminder] Permission: ${isPermitted ? "granted" : "denied"}');
    debugPrint('[MausamReminder] Timezone: $_currentTimeZone');
    debugPrint('[MausamReminder] Notification ID: $notifId');

    try {
      const androidDetails = AndroidNotificationDetails(
        'mausam_routine_reminders',
        'Daily Routine & Activity Reminders',
        channelDescription: 'Personalized routine notifications calculated from real-time weather forecasts.',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const linuxDetails = LinuxNotificationDetails(
        urgency: LinuxNotificationUrgency.critical,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
        linux: linuxDetails,
      );

      final nextScheduleTime = _calculateNextOccurrence(
        reminder.reminderHour,
        reminder.reminderMinute,
      );

      debugPrint('[MausamReminder] Next trigger: $nextScheduleTime');

      // Attempt exact alarm scheduling with safe fallback
      try {
        await _notificationsPlugin.zonedSchedule(
          notifId,
          reminder.activityTitle,
          bodyText,
          nextScheduleTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: reminder.id,
        );
      } catch (scheduleErr) {
        debugPrint('[MausamReminder] Exact alarm restricted, falling back to inexact: $scheduleErr');
        await _notificationsPlugin.zonedSchedule(
          notifId,
          reminder.activityTitle,
          bodyText,
          nextScheduleTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: reminder.id,
        );
      }

      debugPrint('[MausamReminder] Scheduling result: success');
      return true;
    } catch (e) {
      debugPrint('[MausamReminder] Scheduling result: failure (error: $e)');
      return false;
    }
  }

  /// Development-only test action: schedules an immediate notification approximately 10-15 seconds later.
  static Future<bool> scheduleTestNotification({
    int delaySeconds = 10,
    String activity = 'walking',
  }) async {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest || kIsWeb) {
      debugPrint('Test environment: Mocked scheduleTestNotification ($delaySeconds s)');
      return true;
    }

    await init();
    const notifId = 99999;
    final isPermitted = await checkPermissionStatus();

    debugPrint('[MausamReminder] Test notification requested');
    debugPrint('[MausamReminder] Permission: ${isPermitted ? "granted" : "denied"}');
    debugPrint('[MausamReminder] Timezone: $_currentTimeZone');
    debugPrint('[MausamReminder] Notification ID: $notifId');

    try {
      const androidDetails = AndroidNotificationDetails(
        'mausam_routine_reminders',
        'Daily Routine & Activity Reminders',
        channelDescription: 'Personalized routine notifications calculated from real-time weather forecasts.',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final triggerTime = tz.TZDateTime.now(tz.local).add(Duration(seconds: delaySeconds));
      debugPrint('[MausamReminder] Next trigger: $triggerTime');

      await _notificationsPlugin.zonedSchedule(
        notifId,
        'DAILY ${activity.toUpperCase()} CHECK',
        "Tomorrow's best $activity window is 6:15–7:15 AM (22° · AQI 38 · Low rain risk).",
        triggerTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'test_reminder_$notifId',
      );

      debugPrint('[MausamReminder] Scheduling result: success');
      return true;
    } catch (e) {
      debugPrint('[MausamReminder] Scheduling result: failure (error: $e)');
      return false;
    }
  }

  /// Cancels a previously scheduled reminder by its ID.
  static Future<void> cancelReminder(String reminderId) async {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest || kIsWeb) return;

    await init();
    try {
      final notifId = _getNotificationId(reminderId);
      await _notificationsPlugin.cancel(notifId);
      debugPrint('[MausamReminder] Cancelled routine reminder notification $notifId for $reminderId');
    } catch (e) {
      debugPrint('[MausamReminder] Error cancelling routine reminder: $e');
    }
  }

  /// Cancels all scheduled routine reminders.
  static Future<void> cancelAllReminders() async {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest || kIsWeb) return;

    await init();
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('[MausamReminder] Cancelled all reminders');
    } catch (e) {
      debugPrint('[MausamReminder] Error cancelling all reminders: $e');
    }
  }

  static int _getNotificationId(String reminderId) {
    return reminderId.hashCode.abs() % 100000;
  }

  static tz.TZDateTime _calculateNextOccurrence(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the scheduled time for today has already elapsed, schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}
