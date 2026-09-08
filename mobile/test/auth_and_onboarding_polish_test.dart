import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/providers/user_provider.dart';
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

        expect(find.text('About You'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'Zero layout overflow at ${width}px');
      });
    }

    testWidgets('renders About You slide with interactive sliders, 2x2 gender pills, and buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('STEP 1 / YOUR BASICS'), findsOneWidget);
      expect(find.textContaining('A little context'), findsOneWidget);
      expect(find.text('About You'), findsOneWidget);
      expect(find.byKey(const Key('about_you_age_slider')), findsOneWidget);
      expect(find.byKey(const Key('about_you_gender_female')), findsOneWidget);
      expect(find.byKey(const Key('about_you_gender_male')), findsOneWidget);
      expect(find.byKey(const Key('about_you_gender_non_binary')), findsOneWidget);
      expect(find.byKey(const Key('about_you_gender_prefer_not')), findsOneWidget);
      expect(find.byKey(const Key('about_you_height_slider')), findsOneWidget);
      expect(find.byKey(const Key('about_you_weight_slider')), findsOneWidget);
      expect(find.byKey(const Key('about_you_continue_button')), findsOneWidget);
      expect(find.byKey(const Key('about_you_skip_button')), findsOneWidget);
    });

    testWidgets('allows selecting gender from 2x2 grid', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );
      await tester.pump();

      // Tap Male
      await tester.tap(find.byKey(const Key('about_you_gender_male')));
      await tester.pump();

      expect(find.text('Male'), findsOneWidget);
    });

    testWidgets('transitions to Choose Your Persona on Skip for now', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('about_you_skip_button')));
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Persona'), findsOneWidget);
    });

    testWidgets('transitions to Choose Your Persona on Save & continue', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('about_you_gender_female')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('about_you_continue_button')));
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Persona'), findsOneWidget);
    });

    testWidgets('allows selecting multiple personas and advancing to Smart Alerts', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );
      await tester.pump();

      // Skip slide 0 to reach slide 1
      await tester.tap(find.byKey(const Key('about_you_skip_button')));
      await tester.pumpAndSettle();

      expect(find.text('Choose Your Persona'), findsOneWidget);

      // Tap Traveler as second persona
      await tester.tap(find.text('Traveler'));
      await tester.pump();

      // Tap Commuter as third persona
      await tester.tap(find.text('Commuter'));
      await tester.pump();

      // Tap Continue to reach Slide 2 (Smart Alerts)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.textContaining('What does the'), findsOneWidget);
      expect(find.text('WEATHER & AIR TRIGGERS'), findsOneWidget);
      expect(find.text('HEALTH CONCERNS'), findsOneWidget);
      expect(find.text('Tune my alerts'), findsOneWidget);
    });

    testWidgets('toggles triggers and concerns, configures rhythm, and completes to Location Access', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );
      await tester.pump();

      // Skip slide 0
      await tester.tap(find.byKey(const Key('about_you_skip_button')));
      await tester.pumpAndSettle();

      // Continue slide 1
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Toggle Humidity trigger
      await tester.tap(find.text('Humidity'));
      await tester.pump();

      // Toggle Asthma health concern
      await tester.tap(find.text('Asthma'));
      await tester.pump();

      // Tap Tune my alerts to reach Slide 3 (Your Rhythm)
      await tester.tap(find.byKey(const Key('tune_my_alerts_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('What should'), findsOneWidget);
      expect(find.text('WHAT MATTERS MOST'), findsOneWidget);
      expect(find.text('YOUR USUAL ACTIVITY'), findsOneWidget);
      expect(find.text('Your first insight'), findsOneWidget);
      expect(find.text('See my plan'), findsOneWidget);

      // Tap See my plan to reach Slide 4 (Location Access)
      await tester.tap(find.byKey(const Key('see_my_plan_button')));
      await tester.pumpAndSettle();

      expect(find.text('Location Access'), findsOneWidget);
    });

    testWidgets('interacts with rhythm preferences (matters most & activity level) and persists state', (tester) async {
      late final ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                home: OnboardingScreen(),
              );
            },
          ),
        ),
      );
      await tester.pump();

      // Skip slide 0
      await tester.tap(find.byKey(const Key('about_you_skip_button')));
      await tester.pumpAndSettle();

      // Continue slide 1
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Continue slide 2
      await tester.tap(find.byKey(const Key('tune_my_alerts_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('What should'), findsOneWidget);

      // Select 'Fitness' in What matters most
      await tester.tap(find.byKey(const Key('matter_Fitness')));
      await tester.pump();

      // Select 'Moderate' in Activity level
      await tester.tap(find.byKey(const Key('activity_Moderate')));
      await tester.pump();

      // Tap See my plan
      await tester.tap(find.byKey(const Key('see_my_plan_button')));
      await tester.pumpAndSettle();

      // Verify UserState updated
      final userState = container.read(userProvider);
      expect(userState.whatMattersMost, containsAll(['Daily energy', 'Fitness']));
      expect(userState.activityLevel, equals('Moderate'));

      expect(find.text('Location Access'), findsOneWidget);
    });
  });

  group('FloatingNavbar Polish Tests', () {
    testWidgets('renders with subtle border, integrated location text, and menu button (search removed)', (tester) async {
      final anim = AnimationController(vsync: const TestVSync());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingNavbar(
              locationName: 'Bengaluru, India',
              locationAnimation: anim,
              onLocationTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Bengaluru, India'), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsNothing);
    });
  });
}
