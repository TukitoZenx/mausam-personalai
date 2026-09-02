import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/router/app_router.dart';
import 'package:mobile/screens/home_screen.dart';

class FakeUser extends Fake implements User {
  @override
  String get uid => 'fake_uid';
  @override
  String get email => 'test@mausam.ai';
}

void main() {
  testWidgets('App renders SplashScreen at root', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = createRouter(initialLocation: '/splash');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Mausam'), findsWidgets);
  });

  testWidgets('App renders LoginScreen with Google & Email buttons', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = createRouter(initialLocation: '/login');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('google_sign_in_button')), findsOneWidget);
    expect(find.byKey(const Key('continue_with_email_button')), findsOneWidget);
  });

  testWidgets('App navigates through feature routes without errors', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = createRouter(initialLocation: '/home');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(FakeUser())),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    // Onboarding
    router.go('/onboarding');
    await tester.pumpAndSettle();
    expect(find.text('Choose Your Persona'), findsOneWidget);

    // Forecast
    router.go('/forecast');
    await tester.pumpAndSettle();
    expect(find.text('Forecast'), findsWidgets);

    // Saved Locations
    router.go('/saved-locations');
    await tester.pumpAndSettle();
    expect(find.text('Saved Locations Screen'), findsOneWidget);

    // Profile
    router.go('/profile');
    await tester.pumpAndSettle();
    expect(find.textContaining('Profile'), findsWidgets);
  });
}
