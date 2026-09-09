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

  testWidgets('SavedLocationsScreen renders empty state for new users when saved list is empty', (tester) async {
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

    // Verify section title with count (0 for new users)
    expect(find.textContaining('SAVED LOCATIONS (0)'), findsOneWidget);

    // Verify empty state is rendered
    expect(find.text('No Saved Locations'), findsOneWidget);
    expect(find.byIcon(Icons.location_city_rounded), findsOneWidget);
  });
}
