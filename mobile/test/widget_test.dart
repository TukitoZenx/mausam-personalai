import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/main.dart';
import 'package:mobile/providers/user_provider.dart';
import 'package:mobile/providers/location_provider.dart';
import 'package:mobile/providers/weather_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('App builds with ProviderScope and renders SplashScreen at root', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MausamApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('MAUSAM'), findsWidgets);
  });

  testWidgets('Riverpod providers initialize with default states', (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final userState = container.read(userProvider);
    final locationState = container.read(locationProvider);
    final weatherState = container.read(weatherProvider);

    expect(userState.isAuthenticated, isFalse);
    expect(locationState.isLoading, isFalse);
    expect(weatherState.isLoading, isFalse);
  });
}
