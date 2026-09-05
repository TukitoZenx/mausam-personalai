import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/navigation/app_drawer.dart';
import 'package:mobile/widgets/navigation/mausam_bottom_navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('MausamBottomNavbar 3-Destination Tests', () {
    testWidgets('renders exactly 3 primary destinations: Home, raised center Mausam AI, Settings', (tester) async {
      String? navigatedRoute;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  bottom: 12,
                  left: 20,
                  right: 20,
                  child: MausamBottomNavbar(
                    currentRoute: '/home',
                    onNavigate: (route) => navigatedRoute = route,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify presence of keys
      expect(find.byKey(const Key('bottom_nav_home')), findsOneWidget);
      expect(find.byKey(const Key('bottom_nav_insights')), findsOneWidget);
      expect(find.byKey(const Key('bottom_nav_settings')), findsOneWidget);

      // Verify labels
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Mausam'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Tap center action
      await tester.tap(find.byKey(const Key('bottom_nav_insights')));
      expect(navigatedRoute, '/insights');

      // Tap settings action
      await tester.tap(find.byKey(const Key('bottom_nav_settings')));
      expect(navigatedRoute, '/profile');

      // Tap home action
      await tester.tap(find.byKey(const Key('bottom_nav_home')));
      expect(navigatedRoute, '/home');
    });

    testWidgets('zero horizontal overflow across narrow and standard phone widths', (tester) async {
      final widths = [320.0, 360.0, 393.0, 412.0];

      for (final width in widths) {
        await tester.binding.setSurfaceSize(Size(width, 800));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    bottom: 12,
                    left: width < 360 ? 12 : 20,
                    right: width < 360 ? 12 : 20,
                    child: MausamBottomNavbar(
                      currentRoute: '/insights',
                      onNavigate: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'Overflow occurred at width $width');
      }
      await tester.binding.setSurfaceSize(null);
    });
  });

  group('MausamAppDrawer Destination Tests', () {
    testWidgets('renders all required drawer secondary destinations including Extended Forecast and Health', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              drawer: MausamAppDrawer(currentRoute: '/home'),
              body: Center(child: Text('Drawer Test')),
            ),
          ),
        ),
      );

      // Open drawer
      final scaffoldState = tester.firstState<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Check destinations
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('My Locations'), findsOneWidget);
      expect(find.text('Extended Forecast'), findsOneWidget);
      expect(find.text('Health Metrics'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
      expect(find.text('Travel & Commute'), findsOneWidget);
      expect(find.text('Profile & Settings'), findsOneWidget);
      expect(find.textContaining('MAUSAM'), findsWidgets);
    });
  });
}
