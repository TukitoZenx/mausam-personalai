import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/screens/saved_locations_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SavedLocationsScreen renders luxury search bar and Current Location card below it', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SavedLocationsScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify search bar is present with hint text
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search any city or locality…'), findsOneWidget);

    // 2. Verify Current Location card is present below the search bar
    expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
    expect(find.text('GPS'), findsOneWidget);

    // 3. Verify Active or Use GPS badge
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && (widget.data == 'ACTIVE' || widget.data == 'USE GPS'),
      ),
      findsWidgets,
    );

    // 4. Verify search bar position is vertically above the Current Location card
    final searchBarFinder = find.byType(TextField);
    final gpsFinder = find.byIcon(Icons.my_location_rounded);

    final searchRect = tester.getRect(searchBarFinder);
    final gpsRect = tester.getRect(gpsFinder);

    expect(
      searchRect.bottom,
      lessThan(gpsRect.top),
      reason: 'Search bar must be vertically above the Current Location card',
    );
  });

  testWidgets('SavedLocationsScreen renders saved location cards with weather degrees and conditions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SavedLocationsScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify section title with count
    expect(find.textContaining('SAVED LOCATIONS'), findsOneWidget);

    // Verify default starter locations are visible
    expect(find.text('New Delhi'), findsOneWidget);
    expect(find.text('Mumbai'), findsOneWidget);
    expect(find.text('Bengaluru'), findsOneWidget);

    // Verify temperature degrees are rendered on cards
    expect(find.text('32°'), findsOneWidget); // New Delhi
    expect(find.text('29°'), findsOneWidget); // Mumbai
    expect(find.text('24°'), findsOneWidget); // Bengaluru

    // Verify weather conditions and high/low ranges
    expect(find.textContaining('Sunny & Solar Glow'), findsOneWidget);
    expect(find.textContaining('H:36° L:25°'), findsOneWidget);
  });
}
