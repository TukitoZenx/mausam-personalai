import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/screens/insights_screen.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/widgets/ai/weather_intelligence_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockChatApiClient extends ApiClient {
  final Map<String, dynamic> responsePayload;

  MockChatApiClient(this.responsePayload);

  @override
  Future<Map<String, dynamic>> sendChatMessage({
    required String text,
    double? lat,
    double? lon,
    String? persona,
    List<String>? healthConcerns,
    String? activeLocationName,
    List<Map<String, dynamic>>? savedLocations,
    List<Map<String, String>>? history,
    String? language,
    required String idToken,
  }) async {
    return responsePayload;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  GoogleFonts.config.allowRuntimeFetching = false;

  group('SIH AI Weather Assistant UI & Intelligence Tests', () {
    testWidgets('renders structured WeatherIntelligenceCard from backend card_data', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockBackendResponse = {
        'reply': 'Tomorrow in Hyderabad will feature clear skies and a high of 31°C.',
        'intent': 'weather',
        'source': 'gemini',
        'suggested_actions': ['Hourly rain chance', 'What should I wear?'],
        'card_data': {
          'cardType': 'activityWindow',
          'category': 'OUTDOOR & CRICKET',
          'headline': 'Optimal 6:00 AM – 9:00 AM Window',
          'subtitle': 'Hyderabad · 24°C',
          'metrics': [
            {'label': 'Temp', 'value': '24°C'},
            {'label': 'Rain Chance', 'value': '5%'},
            {'label': 'Wind', 'value': '12 km/h'},
            {'label': 'AQI', 'value': '48'},
          ],
          'explanation': 'Dry conditions with light morning breeze.',
          'actionLabel': 'View 5-Day Forecast',
        },
      };

      final mockClient = MockChatApiClient(mockBackendResponse);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(mockClient),
          ],
          child: const MaterialApp(
            home: InsightsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Submit a query
      final inputFinder = find.byType(TextField);
      expect(inputFinder, findsOneWidget);

      await tester.enterText(inputFinder, 'Can I play cricket tomorrow morning?');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Wait for generation timer
      await tester.pump(const Duration(milliseconds: 100));

      // Pump streaming frames to completion
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      await tester.pumpAndSettle();

      // Verify text rendered
      expect(find.textContaining('Tomorrow in Hyderabad will feature clear skies'), findsOneWidget);

      // Verify Structured Weather Card rendered
      expect(find.byType(WeatherIntelligenceCard), findsOneWidget);
      expect(find.text('OUTDOOR & CRICKET'), findsOneWidget);
      expect(find.text('Optimal 6:00 AM – 9:00 AM Window'), findsOneWidget);
      expect(find.text('24°C'), findsWidgets);
      expect(find.text('Dry conditions with light morning breeze.'), findsOneWidget);

      // Verify follow-up chips
      expect(find.text('Hourly rain chance'), findsOneWidget);
      expect(find.text('What should I wear?'), findsOneWidget);

      // Verify Copy button is present
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);

      // Verify Clear Conversation button is present in header
      expect(find.text('New chat'), findsOneWidget);
    });

    testWidgets('tapping New Chat clears messages and resets to welcome state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockBackendResponse = {
        'reply': 'The current temperature in Hyderabad is 28°C.',
        'intent': 'weather',
        'source': 'template',
        'suggested_actions': ['Will it rain?'],
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(MockChatApiClient(mockBackendResponse)),
          ],
          child: const MaterialApp(
            home: InsightsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Send a message
      await tester.enterText(find.byType(TextField), 'Current weather');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      await tester.pumpAndSettle();

      expect(find.textContaining('current temperature in Hyderabad is 28°C'), findsOneWidget);
      expect(find.text('New chat'), findsOneWidget);

      // Tap New Chat
      await tester.tap(find.text('New chat'));
      await tester.pumpAndSettle();

      // Messages cleared, returned to initial state
      expect(find.textContaining('current temperature in Hyderabad is 28°C'), findsNothing);
      expect(find.text('New chat'), findsNothing);
      expect(find.text('Will it rain today?'), findsOneWidget);
    });
  });
}
