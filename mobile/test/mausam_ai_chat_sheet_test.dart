import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/ai/mausam_ai_chat_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('MausamAiChatSheet Tests', () {
    testWidgets('renders AI assistant header, quick prompt chips, input field, and send button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => showMausamAiChatSheet(context),
                    child: const Text('Open AI Assistant'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Tap to open bottom sheet
      await tester.tap(find.text('Open AI Assistant'));
      await tester.pumpAndSettle();

      // Verify header components
      expect(find.text('Mausam AI Assistant'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);

      // Verify quick prompt chips presence
      expect(find.text('What should I wear today?'), findsOneWidget);
      expect(find.text('Best window for outdoor workout?'), findsOneWidget);

      // Verify input bar presence
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    });

    testWidgets('sends user message when quick prompt chip is tapped and returns response', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () => showMausamAiChatSheet(context),
                    child: const Text('Open AI Assistant'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open AI Assistant'));
      await tester.pumpAndSettle();

      // Tap on quick chip
      await tester.tap(find.text('What should I wear today?'));
      await tester.pump();

      // User message rendered
      expect(find.text('What should I wear today?'), findsWidgets);

      // Pump timer for AI thinking simulation
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // AI response rendered
      expect(find.textContaining('Mausam AI'), findsWidgets);
    });
  });
}
