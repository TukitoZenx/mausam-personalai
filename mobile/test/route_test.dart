import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/router/app_router.dart';
import 'package:mobile/screens/chat_screen.dart';
import 'package:mobile/screens/home_screen.dart';
import 'package:mobile/screens/insights_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeUser extends Fake implements User {
  @override
  String get uid => 'fake_uid';
  @override
  String get email => 'test@mausam.ai';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

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
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('MAUSAM'), findsWidgets);
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

  testWidgets('App renders HomeScreen at /home', (WidgetTester tester) async {
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
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('App renders OnboardingScreen at /onboarding', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = createRouter(initialLocation: '/onboarding');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('About You'), findsOneWidget);
  });

  testWidgets('App renders ForecastScreen at /forecast', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = createRouter(initialLocation: '/forecast');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('FORECAST'), findsWidgets);
  });

  testWidgets('App renders InsightsScreen at /insights', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = createRouter(initialLocation: '/insights');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(InsightsScreen), findsOneWidget);
  });

  testWidgets('App renders ChatScreen at /chat', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = createRouter(initialLocation: '/chat');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ChatScreen), findsOneWidget);
  });

  testWidgets('App renders AlertsScreen at /alerts', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = createRouter(initialLocation: '/alerts');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('ALERTS'), findsWidgets);
  });

  testWidgets('App renders ProfileScreen at /profile', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = createRouter(initialLocation: '/profile');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('PROFILE'), findsWidgets);
  });

  testWidgets('App renders ContextDetailScreen at /context-detail', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = createRouter(initialLocation: '/context-detail');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Persona Context'), findsOneWidget);
  });

  testWidgets('App renders HealthMetricsScreen as new blank page at /health-metrics', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = createRouter(initialLocation: '/health-metrics');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('health_metrics_blank_page')), findsOneWidget);
    expect(find.text('Health & Metrics'), findsOneWidget);
  });
}

