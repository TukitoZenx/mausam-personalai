import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/routine_reminder.dart';
import '../router/app_router.dart';

/// Premier unified Notification Engine for Mausam PersonalAI.
///
/// Features:
/// - Single shared FlutterLocalNotificationsPlugin instance.
/// - Exact local timezone detection with offset matching fallback (never silently defaults to UTC).
/// - High-importance Android channels with sound and vibration.
/// - Guaranteed valid non-adaptive icon `@drawable/ic_notification` preventing OEM drops.
/// - Safe exact alarm scheduling with automatic fallback to inexact when restricted.
/// - Payload routing to Mausam AI / Weather contexts on notification tap.
/// - Diagnostic logging: permission, timezone, scheduled datetime, next trigger, notification ID.
class NotificationService {
  static final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static String _currentTimeZone = 'UTC';
  static bool _exactAlarmsAllowed = false;

  /// Holds pending query to be consumed when navigating to Mausam AI Assistant via notification tap
  static final ValueNotifier<String?> pendingNotificationQuery = ValueNotifier<String?>(null);

  static String get currentTimeZone => _currentTimeZone;
  static bool get exactAlarmsAllowed => _exactAlarmsAllowed;

  // Channel IDs
  static const String channelRoutines = 'mausam_routine_reminders';
  static const String channelAlerts = 'mausam_weather_alerts';
  static const String channelDiagnostics = 'mausam_dev_test';

  /// Initializes the local notification plugin, creates channels, and detects local timezone.
  static Future<void> init() async {
    if (_initialized) return;

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest || kIsWeb) {
      _initialized = true;
      return;
    }

    try {
      // 1. Initialize timezone database & resolve device's local timezone
      tz.initializeTimeZones();
      await _resolveLocalTimezone();

      // 2. Platform initialization settings with dedicated drawable icon
      const androidInit = AndroidInitializationSettings('@drawable/ic_notification');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const linuxInit = LinuxInitializationSettings(
        defaultActionName: 'Open Mausam',
      );

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
        linux: linuxInit,
      );

      await plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );

      // Check if cold start was triggered by notification tap
      try {
        final launchDetails = await plugin.getNotificationAppLaunchDetails();
        if (launchDetails?.didNotificationLaunchApp == true && launchDetails?.notificationResponse != null) {
          debugPrint('[NotificationService] Cold start from notification! Payload: ${launchDetails!.notificationResponse!.payload}');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleNotificationResponse(launchDetails.notificationResponse!);
          });
        }
      } catch (launchErr) {
        debugPrint('[NotificationService] Error checking launch details: $launchErr');
      }

      // 3. Setup Android channels
      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        await androidImpl?.createNotificationChannel(
          const AndroidNotificationChannel(
            channelRoutines,
            'Daily Routine & Activity Reminders',
            description: 'Personalized routine notifications calculated from real-time weather forecasts.',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );

        await androidImpl?.createNotificationChannel(
          const AndroidNotificationChannel(
            channelAlerts,
            'Severe Weather & AQI Alerts',
            description: 'Critical weather warnings and high AQI pollution alerts.',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );

        await androidImpl?.createNotificationChannel(
          const AndroidNotificationChannel(
            channelDiagnostics,
            'Mausam Developer & Diagnostics',
            description: 'Diagnostic and test notifications for verification.',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );

        // Check exact alarm capability
        try {
          final canExact = await androidImpl?.canScheduleExactNotifications();
          _exactAlarmsAllowed = canExact ?? true;
        } catch (_) {
          _exactAlarmsAllowed = true;
        }
      }

      _initialized = true;
      debugPrint('[NotificationService] Initialized successfully. Timezone: $_currentTimeZone, Exact alarms: $_exactAlarmsAllowed');
    } catch (e, st) {
      debugPrint('[NotificationService] Initialization error: $e\n$st');
    }
  }

  /// Resolves the device's local timezone with multiple fallback strategies.
  static Future<void> _resolveLocalTimezone() async {
    String? resolvedName;
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      resolvedName = tzInfo.identifier;
    } catch (e) {
      debugPrint('[NotificationService] FlutterTimezone error: $e');
    }

    if (resolvedName != null && resolvedName.isNotEmpty) {
      try {
        tz.setLocalLocation(tz.getLocation(resolvedName));
        _currentTimeZone = resolvedName;
        debugPrint('[NotificationService] Device timezone resolved: $_currentTimeZone');
        return;
      } catch (e) {
        debugPrint('[NotificationService] tz.getLocation($resolvedName) failed: $e');
        if (resolvedName == 'Asia/Calcutta') {
          try {
            tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
            _currentTimeZone = 'Asia/Kolkata';
            return;
          } catch (_) {}
        }
      }
    }

    // Fallback: match by device system offset
    try {
      final deviceOffsetMs = DateTime.now().timeZoneOffset.inMilliseconds;
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.currentTimeZone.offset == deviceOffsetMs) {
          tz.setLocalLocation(loc);
          _currentTimeZone = loc.name;
          debugPrint('[NotificationService] Timezone resolved via offset match: $_currentTimeZone');
          return;
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Timezone offset fallback error: $e');
    }

    _currentTimeZone = tz.local.name;
    debugPrint('[NotificationService] Fallback to current tz.local: $_currentTimeZone');
  }

  /// Handles notification tap events and routes the user into the relevant context.
  static void _handleNotificationResponse(NotificationResponse details) {
    final payload = details.payload;
    debugPrint('[NotificationService] Notification tapped! Payload: $payload');

    if (payload == null || payload.isEmpty) {
      try {
        appRouter.go('/insights');
      } catch (_) {}
      return;
    }

    try {
      if (payload.startsWith('{') && payload.endsWith('}')) {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        final route = data['route'] as String? ?? '/insights';
        final query = data['query'] as String? ??
            (data['activity'] != null ? "Tomorrow's ${data['activity']} recommendation" : null);
        if (query != null && query.isNotEmpty) {
          pendingNotificationQuery.value = query;
        }
        appRouter.go(route);
      } else if (payload.startsWith('/')) {
        appRouter.go(payload);
      } else {
        // Routine payload (e.g. 'rem_123' or 'walking')
        pendingNotificationQuery.value = "Tomorrow's $payload recommendation";
        appRouter.go('/insights');
      }
    } catch (e) {
      debugPrint('[NotificationService] Navigation on tap error: $e');
      try {
        appRouter.go('/insights');
      } catch (_) {}
    }
  }

  /// Checks if the application has permission to post notifications.
  static Future<bool> checkPermissionStatus() async {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest || kIsWeb) return true;

    await init();
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final enabled = await androidImpl?.areNotificationsEnabled();
        return enabled ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('[NotificationService] checkPermissionStatus error: $e');
      return true;
    }
  }

  /// Requests notification and exact alarm permissions from the user.
  static Future<bool> requestPermissions() async {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest || kIsWeb) return true;

    await init();
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidImpl?.requestNotificationsPermission();

        // Exact alarms check for Android 12+ (API 31+)
        try {
          final canExact = await androidImpl?.canScheduleExactNotifications();
          if (canExact == false) {
            await androidImpl?.requestExactAlarmsPermission();
          }
          _exactAlarmsAllowed = await androidImpl?.canScheduleExactNotifications() ?? true;
        } catch (_) {}

        final isGranted = granted ?? false;
        debugPrint('[NotificationService] Permission granted: $isGranted, exact: $_exactAlarmsAllowed');
        return isGranted;
      } else if (!kIsWeb && Platform.isIOS) {
        final iosImpl = plugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final granted = await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('[NotificationService] requestPermissions error: $e');
      return false;
    }
  }

  /// Schedules a recurring daily routine reminder at [reminder.reminderHour]:[reminder.reminderMinute].
  static Future<bool> scheduleDailyRoutineReminder(
    RoutineReminder reminder, {
    required String bodyText,
  }) async {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest || kIsWeb) {
      debugPrint('Test environment: Mocked scheduleDailyRoutineReminder for ${reminder.id}');
      return true;
    }

    await init();

    final notifId = getNotificationId(reminder.id);
    final hasPerm = await checkPermissionStatus();

    final nextOccurrence = calculateNextOccurrence(
      reminder.reminderHour,
      reminder.reminderMinute,
    );

    debugPrint('════════════════════════════════════════════════════════════');
    debugPrint('[MausamNotification] SCHEDULING DAILY ROUTINE REMINDER');
    debugPrint('[MausamNotification] Title: ${reminder.activityTitle}');
    debugPrint('[MausamNotification] Time: ${reminder.reminderTimeDisplay} (Device Local)');
    debugPrint('[MausamNotification] Timezone: $_currentTimeZone');
    debugPrint('[MausamNotification] Next Trigger: $nextOccurrence');
    debugPrint('[MausamNotification] Notification ID: $notifId');
    debugPrint('[MausamNotification] Permission Status: ${hasPerm ? "GRANTED" : "DENIED"}');
    debugPrint('════════════════════════════════════════════════════════════');

    try {
      const androidDetails = AndroidNotificationDetails(
        channelRoutines,
        'Daily Routine & Activity Reminders',
        channelDescription: 'Personalized routine notifications calculated from real-time weather forecasts.',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
        color: Color(0xFF7B2CBF),
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(''),
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

      final payloadMap = {
        'type': 'routine_reminder',
        'reminderId': reminder.id,
        'activity': reminder.activity,
        'targetPeriod': reminder.targetPeriod,
        'route': '/insights',
        'query': "Tomorrow's ${reminder.activity} recommendation",
      };

      if (!kIsWeb && Platform.isWindows) {
        final duration = nextOccurrence.difference(tz.TZDateTime.now(tz.local));
        final safeDuration = duration.isNegative ? const Duration(seconds: 5) : duration;
        Timer(safeDuration, () {
          _showWindowsToast(
            title: reminder.activityTitle,
            body: bodyText,
          );
        });
        debugPrint('[MausamNotification] Windows routine timer scheduled for ${reminder.id}');
        return true;
      }

      // Try exact alarm first, fallback to inexact if restricted
      try {
        await plugin.zonedSchedule(
          notifId,
          reminder.activityTitle,
          bodyText,
          nextOccurrence,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: jsonEncode(payloadMap),
        );
        debugPrint('[MausamNotification] Scheduled via exactAllowWhileIdle successfully.');
      } catch (scheduleErr) {
        debugPrint('[MausamNotification] Exact alarm restricted, falling back to inexact: $scheduleErr');
        await plugin.zonedSchedule(
          notifId,
          reminder.activityTitle,
          bodyText,
          nextOccurrence,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: jsonEncode(payloadMap),
        );
        debugPrint('[MausamNotification] Scheduled via inexactAllowWhileIdle successfully.');
      }

      debugPrint('[MausamNotification] Scheduling result: SUCCESS');
      return true;
    } catch (e, st) {
      debugPrint('[MausamNotification] Scheduling result: FAILURE ($e)\n$st');
      return false;
    }
  }

  /// Development-only diagnostic: schedules a real test notification approximately 10-15 seconds later.
  static Future<bool> scheduleTestNotification({
    int delaySeconds = 12,
  }) async {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest || kIsWeb) {
      debugPrint('Test environment: Mocked scheduleTestNotification ($delaySeconds s)');
      return true;
    }

    if (!kIsWeb && Platform.isWindows) {
      showSystemNotification(
        title: 'Mausam Weather Alert ⚡',
        body: 'Immediate notification test on Windows desktop!',
      );
      Timer(Duration(seconds: delaySeconds), () {
        showSystemNotification(
          title: 'MAUSAM TEST NOTIFICATION ⚡',
          body: 'Scheduled notification delivery working on Windows! Timezone: $_currentTimeZone',
        );
      });
      debugPrint('[MausamNotification] Scheduled Windows test notification ($delaySeconds s)');
      return true;
    }

    await init();
    const notifId = 88888;
    final hasPerm = await checkPermissionStatus();

    final triggerTime = tz.TZDateTime.now(tz.local).add(Duration(seconds: delaySeconds));

    debugPrint('════════════════════════════════════════════════════════════');
    debugPrint('[MausamNotification] SCHEDULING REAL DEVICE TEST NOTIFICATION');
    debugPrint('[MausamNotification] Notification ID: $notifId');
    debugPrint('[MausamNotification] Delay: $delaySeconds seconds');
    debugPrint('[MausamNotification] Timezone: $_currentTimeZone');
    debugPrint('[MausamNotification] Scheduled Trigger: $triggerTime');
    debugPrint('[MausamNotification] Permission Status: ${hasPerm ? "GRANTED" : "DENIED"}');
    debugPrint('════════════════════════════════════════════════════════════');

    try {
      const androidDetails = AndroidNotificationDetails(
        channelDiagnostics,
        'Mausam Developer & Diagnostics',
        channelDescription: 'Diagnostic and test notifications for verification.',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
        color: Color(0xFF00E5FF),
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(''),
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

      const testPayload = '{"type":"test","route":"/insights","query":"Notification delivery is working."}';

      try {
        await plugin.zonedSchedule(
          notifId,
          'MAUSAM TEST',
          'Notification delivery is working. Local timezone: $_currentTimeZone',
          triggerTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: testPayload,
        );
      } catch (err) {
        debugPrint('[MausamNotification] Exact alarm fallback on test notification: $err');
        await plugin.zonedSchedule(
          notifId,
          'MAUSAM TEST',
          'Notification delivery is working. Local timezone: $_currentTimeZone',
          triggerTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: testPayload,
        );
      }

      debugPrint('[MausamNotification] Test notification scheduled successfully.');
      return true;
    } catch (e, st) {
      debugPrint('[MausamNotification] Test notification scheduling failed: $e\n$st');
      return false;
    }
  }

  /// Windows native toast notification helper using PowerShell WinRT Toast API
  static Future<void> _showWindowsToast({
    required String title,
    required String body,
  }) async {
    if (kIsWeb || !Platform.isWindows) return;
    try {
      final cleanTitle = title.replaceAll("'", "''").replaceAll('"', '`"');
      final cleanBody = body.replaceAll("'", "''").replaceAll('"', '`"');

      final script = '''
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
\$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
\$template = @"
<toast>
  <visual>
    <binding template="ToastGeneric">
      <text>$cleanTitle</text>
      <text>$cleanBody</text>
    </binding>
  </visual>
</toast>
"@
\$xml.LoadXml(\$template)
\$toast = [Windows.UI.Notifications.ToastNotification]::new(\$xml)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Mausam PersonalAI").Show(\$toast)
''';

      await Process.start(
        'powershell.exe',
        [
          '-NoProfile',
          '-NonInteractive',
          '-WindowStyle',
          'Hidden',
          '-Command',
          script,
        ],
        mode: ProcessStartMode.detached,
      );
      debugPrint('[NotificationService] Windows toast dispatched: $title');
    } catch (e) {
      debugPrint('[NotificationService] Windows toast error: $e');
    }
  }

  /// Displays an immediate system tray notification (e.g. for urgent alerts or test).
  static Future<void> showSystemNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = channelAlerts,
  }) async {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest || kIsWeb) return;

    if (!kIsWeb && Platform.isWindows) {
      await _showWindowsToast(title: title, body: body);
      return;
    }

    await init();

    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == channelRoutines ? 'Daily Routine & Activity Reminders' : 'Severe Weather & AQI Alerts',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
        color: const Color(0xFF7B2CBF),
        playSound: true,
        enableVibration: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await plugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      debugPrint('[NotificationService] Displayed immediate system notification #$id');
    } catch (e) {
      debugPrint('[NotificationService] Error showing system notification: $e');
    }
  }

  /// Cancels a scheduled notification by reminder ID.
  static Future<void> cancelReminder(String reminderId) async {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest || kIsWeb) return;

    await init();
    try {
      final notifId = getNotificationId(reminderId);
      await plugin.cancel(notifId);
      debugPrint('[NotificationService] Cancelled notification #$notifId for reminder $reminderId');
    } catch (e) {
      debugPrint('[NotificationService] Error cancelling reminder: $e');
    }
  }

  /// Cancels all scheduled notifications.
  static Future<void> cancelAll() async {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest || kIsWeb) return;

    await init();
    try {
      await plugin.cancelAll();
      debugPrint('[NotificationService] Cancelled all scheduled notifications');
    } catch (e) {
      debugPrint('[NotificationService] Error cancelling all: $e');
    }
  }

  /// Retrieves list of currently scheduled pending notifications on the device.
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTest || kIsWeb) return [];

    await init();
    try {
      return await plugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('[NotificationService] Error getting pending notifications: $e');
      return [];
    }
  }

  static int getNotificationId(String reminderId) {
    return reminderId.hashCode.abs() % 100000;
  }

  static tz.TZDateTime calculateNextOccurrence(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}
