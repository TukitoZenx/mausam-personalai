import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/models/weather_ai_card_data.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/screens/insights_screen.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/widgets/ai/weather_intelligence_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockTravelApiClient extends ApiClient {
  final Map<String, dynamic> Function(String text) responseGenerator;

  MockTravelApiClient(this.responseGenerator);

  @override
  Future<Map<String, dynamic>> sendChatMessage({
    required String text,
    double? lat,
    double? lon,
    String? persona,
    List<String>? healthConcerns,
    List<String>? weatherTriggers,
    List<String>? whatMattersMost,
    String? activityLevel,
    String? userName,
    String? activeLocationName,
    List<Map<String, dynamic>>? savedLocations,
    List<Map<String, String>>? history,
    String? language,
    required String idToken,
  }) async {
    return responseGenerator(text);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Travel Route Intent & Compact Premium Card Tests', () {
    test('WeatherAiCardData parses travelRoute JSON properly with routePoints and routeSource', () {
      final json = {
        'cardType': 'travelRoute',
        'category': 'TRAVEL ROUTE INTELLIGENCE',
        'headline': 'Chennai → Vijayawada',
        'subtitle': '454 km · 5h 54m (via highway)',
        'origin': 'Chennai',
        'destination': 'Vijayawada',
        'distanceKm': 454,
        'durationText': '5h 54m',
        'isEstimate': false,
        'isEstimated': false,
        'routeSource': 'osrm',
        'originCoords': {'latitude': 13.0827, 'longitude': 80.2707},
        'destCoords': {'latitude': 16.5062, 'longitude': 80.6480},
        'destinationWeather': {
          'temperature': 32,
          'condition': 'Partly Cloudy',
          'aqi': 68,
          'aqiCategory': 'Moderate',
        },
        'routePoints': [
          {
            'name': 'Chennai',
            'role': 'origin',
            'lat': 13.0827,
            'lon': 80.2707,
            'weather': {'temperature': 31, 'condition': 'Partly Cloudy', 'aqi': 55},
          },
          {
            'name': 'Nellore',
            'role': 'intermediate',
            'lat': 14.4426,
            'lon': 79.9865,
            'weather': {'temperature': 32, 'condition': 'Clear', 'aqi': 62},
          },
          {
            'name': 'Ongole',
            'role': 'intermediate',
            'lat': 15.5057,
            'lon': 80.0499,
            'weather': {'temperature': 30, 'condition': 'Clear', 'aqi': 58},
          },
          {
            'name': 'Vijayawada',
            'role': 'destination',
            'lat': 16.5062,
            'lon': 80.6480,
            'weather': {'temperature': 32, 'condition': 'Partly Cloudy', 'aqi': 68},
          },
        ],
        'metrics': [
          {'label': 'Distance', 'value': '454 km'},
          {'label': 'Duration', 'value': '5h 54m'},
          {'label': 'Vijayawada Temp', 'value': '32°C'},
          {'label': 'Vijayawada AQI', 'value': '68 (Moderate)'},
        ],
        'explanation': 'Favorable highway driving conditions.',
        'actionLabel': 'View route on map',
        'actionRoute': 'https://www.google.com/maps/dir/?api=1&origin=Chennai&destination=Vijayawada',
      };

      final card = WeatherAiCardData.fromJson(json);

      expect(card.cardType, WeatherCardType.travelRoute);
      expect(card.origin, 'Chennai');
      expect(card.destination, 'Vijayawada');
      expect(card.distanceKm, 454);
      expect(card.durationText, '5h 54m');
      expect(card.isEstimate, isFalse);
      expect(card.isEstimated, isFalse);
      expect(card.routeSource, 'osrm');
      expect(card.originCoords!['latitude'], 13.0827);
      expect(card.destCoords!['latitude'], 16.5062);
      expect(card.destinationWeather!['temperature'], 32);
      expect(card.destinationWeather!['aqi'], 68);
      expect(card.actionLabel, 'View route on map');

      expect(card.routePoints, isNotNull);
      expect(card.routePoints!.length, 4);
      expect(card.routePoints![0].role, 'origin');
      expect(card.routePoints![0].name, 'Chennai');
      expect(card.routePoints![1].role, 'intermediate');
      expect(card.routePoints![1].name, 'Nellore');
      expect(card.routePoints![1].temperature, 32);
      expect(card.routePoints![2].name, 'Ongole');
      expect(card.routePoints![3].role, 'destination');
      expect(card.routePoints![3].name, 'Vijayawada');
    });

    testWidgets('renders WeatherIntelligenceCard with along-route stations strip and interactive node selection', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool actionTapped = false;

      const cardData = WeatherAiCardData(
        cardType: WeatherCardType.travelRoute,
        category: 'TRAVEL ROUTE INTELLIGENCE',
        headline: 'Chennai → Vijayawada',
        subtitle: '~467 km (est.) · ~7h 45m (est. drive)',
        origin: 'Chennai',
        destination: 'Vijayawada',
        distanceKm: 467,
        durationText: '7h 45m',
        isEstimate: true,
        isEstimated: true,
        routeSource: 'estimated',
        originCoords: {'latitude': 13.0827, 'longitude': 80.2707},
        destCoords: {'latitude': 16.5062, 'longitude': 80.6480},
        destinationWeather: {
          'temperature': 32,
          'condition': 'Partly Cloudy',
          'aqi': 68,
          'aqiCategory': 'Moderate',
        },
        routePoints: [
          TravelRoutePoint(
            name: 'Chennai',
            role: 'origin',
            lat: 13.0827,
            lon: 80.2707,
            weather: {'temperature': 31, 'condition': 'Partly Cloudy', 'aqi': 55},
          ),
          TravelRoutePoint(
            name: 'Nellore',
            role: 'intermediate',
            lat: 14.4426,
            lon: 79.9865,
            weather: {'temperature': 32, 'condition': 'Clear', 'aqi': 62},
          ),
          TravelRoutePoint(
            name: 'Ongole',
            role: 'intermediate',
            lat: 15.5057,
            lon: 80.0499,
            weather: {'temperature': 30, 'condition': 'Clear', 'aqi': 58},
          ),
          TravelRoutePoint(
            name: 'Vijayawada',
            role: 'destination',
            lat: 16.5062,
            lon: 80.6480,
            weather: {'temperature': 32, 'condition': 'Partly Cloudy', 'aqi': 68},
          ),
        ],
        metrics: [
          WeatherAiMetricItem(
            icon: Icons.navigation_rounded,
            label: 'Est. Distance',
            value: '~467 km',
          ),
          WeatherAiMetricItem(
            icon: Icons.schedule_rounded,
            label: 'Est. Duration',
            value: '7h 45m',
          ),
          WeatherAiMetricItem(
            icon: Icons.thermostat_rounded,
            label: 'Vijayawada Temp',
            value: '32°C',
          ),
          WeatherAiMetricItem(
            icon: Icons.bubble_chart_rounded,
            label: 'Vijayawada AQI',
            value: '68 (Moderate)',
          ),
        ],
        explanation: 'Favorable highway driving conditions.',
        actionLabel: 'View route on map',
        actionRoute: 'https://www.google.com/maps/dir/?api=1&origin=Chennai&destination=Vijayawada',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeatherIntelligenceCard(
              cardData: cardData,
              onActionTap: () {
                actionTapped = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify category and headline
      expect(find.text('TRAVEL ROUTE INTELLIGENCE'), findsOneWidget);
      expect(find.text('Chennai → Vijayawada'), findsOneWidget);
      expect(find.text('~467 km (est.) · ~7h 45m (est. drive)'), findsOneWidget);

      // Verify metrics
      expect(find.text('~467 km'), findsOneWidget);
      expect(find.text('7h 45m'), findsOneWidget);
      expect(find.text('32°C'), findsWidgets);
      expect(find.text('68 (Moderate)'), findsOneWidget);

      // Verify route preview map labels
      expect(find.text('ESTIMATED ROUTE'), findsOneWidget);
      expect(find.text('Interactive preview'), findsOneWidget);
      expect(find.text('Chennai'), findsWidgets);
      expect(find.text('Vijayawada'), findsWidgets);

      // Verify along-route horizontal strip
      expect(find.text('ALONG YOUR ROUTE'), findsOneWidget);
      expect(find.text('4 STOPS'), findsOneWidget);
      expect(find.text('Nellore'), findsOneWidget);
      expect(find.text('Ongole'), findsOneWidget);

      // Tap on Nellore in the strip to trigger selection tooltip
      await tester.tap(find.text('Nellore'));
      await tester.pumpAndSettle();

      // Verify tooltip appeared with station weather
      expect(find.byType(StationTooltip), findsOneWidget);

      // Verify action button and tap trigger
      expect(find.text('View route on map'), findsOneWidget);
      await tester.tap(find.text('View route on map'));
      expect(actionTapped, isTrue);
    });

    testWidgets('InsightsScreen processes travel query with dynamic loading state and renders travel card', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockClient = MockTravelApiClient((text) {
        if (text.toLowerCase().contains('vijayawada')) {
          return {
            'reply': 'Got it! You’re planning to travel from Chennai to Vijayawada. Here’s your route overview.',
            'intent': 'TRAVEL',
            'source': 'template',
            'suggested_actions': ['Weather in Vijayawada', 'Weather in Chennai'],
            'card_data': {
              'cardType': 'travelRoute',
              'category': 'TRAVEL ROUTE INTELLIGENCE',
              'headline': 'Chennai → Vijayawada',
              'subtitle': '~467 km (est.) · ~7h 45m (est. drive)',
              'origin': 'Chennai',
              'destination': 'Vijayawada',
              'distanceKm': 467,
              'durationText': '7h 45m',
              'isEstimate': true,
              'originCoords': {'latitude': 13.0827, 'longitude': 80.2707},
              'destCoords': {'latitude': 16.5062, 'longitude': 80.6480},
              'destinationWeather': {
                'temperature': 32,
                'condition': 'Partly Cloudy',
                'aqi': 68,
              },
              'metrics': [
                {'label': 'Est. Distance', 'value': '~467 km'},
                {'label': 'Est. Duration', 'value': '7h 45m'},
              ],
              'actionLabel': 'View route on map',
            },
          };
        }
        return {
          'reply': 'Hello! 👋 How can I help you today?',
          'intent': 'GENERAL_CHAT',
          'source': 'template',
          'suggested_actions': ["Today's weather", 'Will it rain today?'],
        };
      });

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

      // 1. Submit travel query
      final input = find.byType(TextField);
      await tester.enterText(input, 'I will go to Vijayawada from Chennai');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // 2. Verify dynamic loading state shows travel-specific task text
      expect(find.text('Understanding your trip…'), findsOneWidget);

      // Finish generation & streaming
      await tester.pump(const Duration(milliseconds: 100));
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 35));
      }
      await tester.pumpAndSettle();

      // 3. Loading state disappeared automatically
      expect(find.text('Understanding your trip…'), findsNothing);
      expect(find.text('Checking the route from Chennai to Vijayawada…'), findsNothing);

      // 4. Conversational assistant response rendered
      expect(find.textContaining('Got it! You’re planning to travel from Chennai to Vijayawada'), findsOneWidget);

      // 5. Travel route card rendered with preview map & action
      expect(find.byType(WeatherIntelligenceCard), findsOneWidget);
      expect(find.text('Chennai → Vijayawada'), findsOneWidget);
      expect(find.text('View route on map'), findsOneWidget);

      // 6. Test general chat isolation: Send "hi"
      await tester.enterText(input, 'hi');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 30));
      }
      await tester.pumpAndSettle();

      expect(find.textContaining('Hello! 👋 How can I help you today?'), findsOneWidget);
    });
  });
}
