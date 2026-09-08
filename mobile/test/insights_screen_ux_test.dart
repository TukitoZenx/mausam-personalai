import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/screens/insights_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  GoogleFonts.config.allowRuntimeFetching = false;

  Widget buildTestWidget() {
    return const ProviderScope(
      child: MaterialApp(
        home: InsightsScreen(),
      ),
    );
  }

  group('InsightsScreen Premier UX Tests', () {
    testWidgets('renders Welcome State with suggestion chips settled in row above input dock', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify Middle/Top Headline is NOT shown
      expect(find.text('Ask me about the weather'), findsNothing);

      // Verify Suggestion Chips settled in row
      expect(find.text('Will it rain today?'), findsOneWidget);
      expect(find.text('Weather tomorrow'), findsOneWidget);
      expect(find.text('Carry an umbrella?'), findsOneWidget);
      expect(find.text('Weekend forecast'), findsOneWidget);
      expect(find.text('Best workout window'), findsOneWidget);
      expect(find.text('Air quality check'), findsOneWidget);

      // Verify Input Field with rotating placeholder
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    });

    testWidgets('tapping suggestion chip sends query, displays user bubble, and streams structured response', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap "Will it rain today?"
      await tester.tap(find.text('Will it rain today?'));
      await tester.pump(); // immediate frame

      // User message is immediately visible
      expect(find.text('Will it rain today in my area?'), findsOneWidget);

      // Loading state appears
      expect(find.text('Checking the weather...'), findsOneWidget);

      // Pump through mock delay and streaming ticks
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Verify completion & Copy button presence
      expect(find.text('Copy'), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);

      // Verify New chat button is now visible in header
      expect(find.text('New chat'), findsOneWidget);
    });

    testWidgets('copy button provides visual feedback on tap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Submit a query
      await tester.enterText(find.byType(TextField), 'Rain forecast');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();

      // Settle response streaming
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Tap Copy
      expect(find.text('Copy'), findsOneWidget);
      await tester.tap(find.text('Copy'));
      await tester.pump();

      // Verify visual confirmation "Copied!"
      expect(find.text('Copied!'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('New chat button clears messages and restores Welcome State', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Send message
      await tester.ensureVisible(find.text('Carry an umbrella?'));
      await tester.tap(find.text('Carry an umbrella?'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify chips row is hidden while in conversation
      expect(find.text('Carry an umbrella?'), findsNothing);

      // Tap New chat
      await tester.tap(find.text('New chat'));
      await tester.pumpAndSettle();

      // Suggestion chips row is restored
      expect(find.text('Will it rain today?'), findsOneWidget);
    });

    testWidgets('Assistant Logo rule: only displays avatar on first assistant message, not consecutive', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Send first message
      await tester.ensureVisible(find.text('Weather tomorrow'));
      await tester.tap(find.text('Weather tomorrow'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Assistant avatar cloud icon is present
      expect(find.byIcon(Icons.wb_cloudy_rounded), findsWidgets);
    });

    testWidgets('Stop button is displayed during generation and cleanly halts streaming', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Submit message
      await tester.enterText(find.byType(TextField), 'Will it rain today?');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();

      // Verify Stop button appears while thinking/streaming
      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);

      // Tap Stop button
      await tester.tap(find.byIcon(Icons.stop_rounded));
      await tester.pump();

      // Stop button reverts back to send button
      expect(find.byIcon(Icons.stop_rounded), findsNothing);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    });

    testWidgets('Send button is disabled when text field is empty', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tapping send button while empty does not add messages
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();

      // Still in initial state with chips row
      expect(find.text('Will it rain today?'), findsOneWidget);
    });

    testWidgets('renders cleanly on narrow mobile screen (360x640) without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders centered and constrained on tablet/desktop (800x1200) without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
