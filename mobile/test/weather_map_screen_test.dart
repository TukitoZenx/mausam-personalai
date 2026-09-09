import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:mobile/models/weather_ai_card_data.dart';
import 'package:mobile/screens/weather_map_screen.dart';
import 'package:mobile/widgets/ai/weather_intelligence_card.dart';

void main() {
  group('WeatherMapScreen & Route Navigation Tests', () {
    const sampleRouteData = WeatherAiCardData(
      cardType: WeatherCardType.travelRoute,
      category: 'TRAVEL ROUTE INTELLIGENCE',
      headline: 'Chennai → Vijayawada',
      subtitle: '454 km · 5h 54m (via highway)',
      origin: 'Chennai',
      destination: 'Vijayawada',
      distanceKm: 454,
      durationText: '5h 54m',
      isEstimate: false,
      isEstimated: false,
      routeSource: 'osrm',
      originCoords: {'latitude': 13.0827, 'longitude': 80.2707},
      destCoords: {'latitude': 16.5062, 'longitude': 80.6480},
      destinationWeather: {
        'temperature': 33,
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
          weather: {'temperature': 33, 'condition': 'Partly Cloudy', 'aqi': 68},
        ),
      ],
      routeGeometry: [
        {'lat': 13.0827, 'lon': 80.2707},
        {'lat': 14.4426, 'lon': 79.9865},
        {'lat': 15.5057, 'lon': 80.0499},
        {'lat': 16.5062, 'lon': 80.6480},
      ],
      metrics: [
        WeatherAiMetricItem(
          icon: Icons.navigation_rounded,
          label: 'Distance',
          value: '454 km',
        ),
        WeatherAiMetricItem(
          icon: Icons.schedule_rounded,
          label: 'Duration',
          value: '5h 54m',
        ),
      ],
      explanation: 'Driving route passes through Nellore and Ongole.',
      actionLabel: 'View route on map',
      actionRoute: 'https://www.google.com/maps/dir/?api=1&origin=Chennai&destination=Vijayawada',
    );

    testWidgets('renders WeatherMapScreen in Route Mode with fitted route & station strip', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WeatherMapScreen(routeData: sampleRouteData),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top Bar Elements
      expect(find.text('Weather Map'), findsOneWidget);
      expect(find.text('ROUTE MODE'), findsOneWidget);
      expect(find.textContaining('Chennai → Vijayawada'), findsWidgets);

      // Factual Telemetry Banner
      expect(find.text('Real station weather active along your travel route.'), findsOneWidget);

      // Layer Controls (Weather, Rain, Temperature, AQI, Wind, Alerts)
      expect(find.text('Weather'), findsOneWidget);
      expect(find.text('Rain'), findsOneWidget);
      expect(find.text('Temperature'), findsOneWidget);
      expect(find.text('AQI'), findsOneWidget);
      expect(find.text('Wind'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);

      // Synchronized Route Strip at bottom
      expect(find.text('Nellore'), findsOneWidget);
      expect(find.text('Ongole'), findsOneWidget);
      expect(find.text('Vijayawada'), findsWidgets);
    });

    testWidgets('tapping station in route strip opens compact station popup card', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WeatherMapScreen(routeData: sampleRouteData),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Nellore' in the route strip
      await tester.tap(find.text('Nellore'));
      await tester.pumpAndSettle();

      // Verify Popup Card displays station details
      expect(find.text('INTERMEDIATE STOP'), findsOneWidget);
      expect(find.text('32°C'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('AQI 62 (Moderate)'), findsOneWidget);

      // Close popup
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('INTERMEDIATE STOP'), findsNothing);
    });

    testWidgets('layer switcher changes active layer and displays honest factual state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WeatherMapScreen(routeData: sampleRouteData),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Switch to Rain Layer
      await tester.tap(find.text('Rain'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Station precipitation active · Nationwide radar grid unavailable'), findsOneWidget);

      // 2. Switch to Temperature Layer
      await tester.tap(find.text('Temperature'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Station temperatures active · Spatial raster interpolation unavailable'), findsOneWidget);

      // 3. Switch to AQI Layer
      await tester.ensureVisible(find.text('AQI'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('AQI'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Station AQI sensors active · Nationwide pollution heatmap unavailable'), findsOneWidget);

      // 4. Switch to Wind Layer
      await tester.ensureVisible(find.text('Wind'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wind'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Station anemometers active · Nationwide vector field unavailable'), findsOneWidget);

      // 5. Switch to Alerts Layer
      await tester.ensureVisible(find.text('Alerts'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alerts'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Official IMD alerts · 0 active nationwide severe advisories'), findsOneWidget);

      // Ensure Route is still functional and visible
      expect(find.text('Nellore'), findsOneWidget);
    });

    testWidgets('renders WeatherMapScreen in India Overview Mode when routeData is null', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: WeatherMapScreen(routeData: null),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top Bar Elements for India Overview
      expect(find.text('Weather Map'), findsOneWidget);
      expect(find.text('INDIA OVERVIEW'), findsOneWidget);
      expect(find.text('Live weather telemetry across India'), findsOneWidget);

      // No route strip present in overview mode
      expect(find.text('ORIGIN STATION'), findsNothing);

      // Telemetry Banner for Overview
      expect(find.text('Live regional weather stations reporting telemetry.'), findsOneWidget);

      // All layer buttons active
      expect(find.text('Weather'), findsOneWidget);
      expect(find.text('Rain'), findsOneWidget);
      expect(find.text('AQI'), findsOneWidget);
    });

    testWidgets('AI Chat WeatherIntelligenceCard View route on map triggers navigation with intact route data', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      WeatherAiCardData? passedData;

      final router = GoRouter(
        initialLocation: '/chat',
        routes: [
          GoRoute(
            path: '/chat',
            builder: (context, state) => Scaffold(
              body: Center(
                child: WeatherIntelligenceCard(
                  cardData: sampleRouteData,
                  onActionTap: () {
                    passedData = sampleRouteData;
                    context.push('/weather-map', extra: sampleRouteData);
                  },
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/weather-map',
            builder: (context, state) {
              final data = state.extra as WeatherAiCardData?;
              return WeatherMapScreen(routeData: data);
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify travel card is rendered
      expect(find.text('TRAVEL ROUTE INTELLIGENCE'), findsOneWidget);
      expect(find.text('View route on map'), findsOneWidget);

      // Tap 'View route on map'
      await tester.tap(find.text('View route on map'));
      await tester.pumpAndSettle();

      // Verify navigation occurred to WeatherMapScreen with intact data
      expect(passedData, isNotNull);
      expect(passedData!.origin, 'Chennai');
      expect(passedData!.destination, 'Vijayawada');
      expect(passedData!.routePoints!.length, 4);
      expect(passedData!.routeGeometry!.length, 4);

      // Verify WeatherMapScreen is now displayed on top
      expect(find.text('ROUTE MODE'), findsOneWidget);
      expect(find.text('Nellore'), findsWidgets);
    });
  });
}
