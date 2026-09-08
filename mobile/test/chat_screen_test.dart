import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/router/app_router.dart';
import 'package:mobile/screens/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ChatScreen & Reminder UI Tests', () {
    testWidgets('ChatScreen renders correctly at /chat with chips and input bar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = createRouter(initialLocation: '/chat');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check ChatScreen is mounted
      expect(find.byType(ChatScreen), findsOneWidget);
      expect(find.text('Mausam Weather AI'), findsOneWidget);

      // Check Quick-reply chips
      expect(find.byKey(const Key('quick_chip_todays_weather')), findsOneWidget);
      expect(find.byKey(const Key('quick_chip_daily_reminder')), findsOneWidget);
      expect(find.byKey(const Key('quick_chip_aqi')), findsOneWidget);
      expect(find.byKey(const Key('quick_chip_set_reminder')), findsOneWidget);

      // Check input elements
      expect(find.byKey(const Key('chat_input_field')), findsOneWidget);
      expect(find.byKey(const Key('chat_send_button')), findsOneWidget);
      expect(find.byKey(const Key('chat_reminder_button')), findsOneWidget);
    });

    testWidgets('Tapping "Set a reminder ⏰" chip opens reminder setup modal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = createRouter(initialLocation: '/chat');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the set reminder button or chip
      final reminderBtn = find.byKey(const Key('chat_reminder_button'));
      await tester.tap(reminderBtn);
      await tester.pumpAndSettle();

      // Verify modal is displayed
      expect(find.byKey(const Key('set_reminder_dialog')), findsOneWidget);
      expect(find.text('Set Weather Reminder'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Once'), findsOneWidget);
      expect(find.byKey(const Key('confirm_reminder_button')), findsOneWidget);
    });
  });
}
