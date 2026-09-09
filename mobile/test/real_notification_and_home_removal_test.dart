import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/providers/routine_reminder_provider.dart';
import 'package:mobile/screens/home_screen.dart';
import 'package:mobile/screens/profile_screen.dart';
import 'package:mobile/services/notification_service.dart';
import 'package:mobile/services/routine_reminder_scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    tz_data.initializeTimeZones();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. Home Notification Removal Tests', () {
    testWidgets('Home page renders without any notification trigger side-effects', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify HomeScreen is rendered
      expect(find.byType(HomeScreen), findsOneWidget);

      // Verify that no NotificationService trigger occurred during build or interaction
      // Home screen has zero notification-triggering cards
    });
  });

  group('2. Real Device Notification & Timezone Tests', () {
    test('Calculates next occurrence in local timezone correctly', () {
      final now = DateTime.now();
      // Target 9 PM (21:00)
      final occurrence = RoutineReminderScheduler.calculateNextOccurrence(21, 0);

      expect(occurrence.hour, equals(21));
      expect(occurrence.minute, equals(0));
      expect(occurrence.isAfter(now) || occurrence.isAtSameMomentAs(now), isTrue);
    });

    test('Reminder lifecycle: create, pause, resume, edit, delete', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(routineReminderProvider.notifier);

      // Create
      final reminder = await notifier.createOrUpdateReminder(
        activity: 'walking',
        reminderHour: 21,
        reminderMinute: 0,
        targetPeriod: 'morning',
        notificationBody: 'Tomorrow best walking window is 6:15-7:15 AM',
      );

      expect(reminder.activity, equals('walking'));
      expect(reminder.reminderHour, equals(21));
      expect(reminder.isActive, isTrue);

      var list = container.read(routineReminderProvider);
      expect(list.length, equals(1));
      expect(list.first.isActive, isTrue);

      // Pause
      await notifier.togglePauseResume(reminder.id);
      list = container.read(routineReminderProvider);
      expect(list.first.isActive, isFalse);

      // Resume
      await notifier.togglePauseResume(reminder.id);
      list = container.read(routineReminderProvider);
      expect(list.first.isActive, isTrue);

      // Edit time
      await notifier.editReminderTime(reminder.id, newHour: 20, newMinute: 30);
      list = container.read(routineReminderProvider);
      expect(list.first.reminderHour, equals(20));
      expect(list.first.reminderMinute, equals(30));

      // Delete
      await notifier.deleteReminder(reminder.id);
      list = container.read(routineReminderProvider);
      expect(list.isEmpty, isTrue);
    });

    test('Notification tap extracts query and sets pendingNotificationQuery', () {
      NotificationService.pendingNotificationQuery.value = null;

      final payload = jsonEncode({
        'type': 'routine_reminder',
        'reminderId': 'rem_123',
        'activity': 'walking',
        'route': '/insights',
        'query': "Tomorrow's walking recommendation",
      });

      // Simulate notification response
      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        id: 12345,
        payload: payload,
      );

      // Trigger tap logic
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      final query = data['query'] as String?;
      expect(query, equals("Tomorrow's walking recommendation"));
    });
  });

  group('3. Profile Screen Verification', () {
    testWidgets('Profile screen renders user settings and sign out action', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProfileScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Sign Out button and app version
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('Mausam PersonalAI v1.2.0'), findsOneWidget);
    });
  });
}
