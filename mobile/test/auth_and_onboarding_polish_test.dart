import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/login_screen.dart';
import 'package:mobile/screens/onboarding_screen.dart';
import 'package:mobile/widgets/navigation/floating_navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('LoginScreen Polish & Mode Switch Tests', () {
    testWidgets('renders in Sign In mode by default with all expected keys', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('MAUSAM'), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.byKey(const Key('continue_with_email_button')), findsOneWidget);
      expect(find.byKey(const Key('google_sign_in_button')), findsOneWidget);
      expect(find.byKey(const Key('continue_as_guest_button')), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Create an account'), findsOneWidget);
    });

    testWidgets('switches smoothly to Create Account mode and back to Sign In', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pump();

      // Tap 'Create an account'
      await tester.tap(find.text('Create an account'));
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Create an account'), findsWidgets);
      expect(find.text('Full name (optional)'), findsOneWidget);
      expect(find.text('Confirm password'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);

      // Tap 'Sign in' link
      await tester.tap(find.text('Sign in'));
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Create an account'), findsOneWidget);
    });

    for (final width in [320.0, 360.0, 393.0, 412.0]) {
      testWidgets('renders LoginScreen without overflow at width ${width}px', (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: LoginScreen(),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull, reason: 'Zero layout overflow at ${width}px');
      });
    }
  });

  group('OnboardingScreen Polish & Responsive Tests', () {
    for (final width in [320.0, 360.0, 393.0, 412.0]) {
      testWidgets('renders OnboardingScreen without overflow at width ${width}px', (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: OnboardingScreen(),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Choose Your Persona'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Zero layout overflow at ${width}px');
      });
    }
  });

  group('FloatingNavbar Polish Tests', () {
    testWidgets('renders with subtle border, integrated location text, and menu/search buttons', (tester) async {
      final anim = AnimationController(vsync: const TestVSync());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingNavbar(
              locationName: 'Bengaluru, India',
              locationAnimation: anim,
              onLocationTap: () {},
              onSearch: () {},
            ),
          ),
        ),
      );

      expect(find.text('Bengaluru, India'), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });
  });
}
