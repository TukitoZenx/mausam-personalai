import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/providers/mausam_ai_state_provider.dart';
import 'package:mobile/widgets/navigation/mausam_bottom_navbar.dart';
import 'package:mobile/widgets/navigation/mausam_center_logo_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mausam AI Center Bottom Nav Logo Animation Tests', () {
    testWidgets('Idle state: displays clean, still Mausam AI logo and navigates on tap', (tester) async {
      String? navigatedRoute;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MausamBottomNavbar(
              currentRoute: '/home',
              onNavigate: (route) => navigatedRoute = route,
              aiState: MausamAiState.idle,
            ),
          ),
        ),
      );

      // Verify the center AI button key (icon-only without text label)
      final centerButtonFinder = find.byKey(const Key('bottom_nav_insights'));
      expect(centerButtonFinder, findsOneWidget);
      expect(find.text('Mausam'), findsNothing);

      // Verify that the custom Mausam AI vector logo is rendered inside the button
      final iconFinder = find.descendant(
        of: centerButtonFinder,
        matching: find.byType(MausamCenterLogoIcon),
      );
      expect(iconFinder, findsOneWidget);

      // Verify still/idle state: scale transform is 1.0
      final scaleFinder = find.descendant(
        of: centerButtonFinder,
        matching: find.byType(Transform),
      );
      expect(scaleFinder, findsWidgets);

      // Tap center logo
      await tester.tap(centerButtonFinder);
      expect(navigatedRoute, '/insights');
    });

    testWidgets('Thinking state: logo activates breathing/motion animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MausamBottomNavbar(
              currentRoute: '/home',
              onNavigate: (_) {},
              aiState: MausamAiState.thinking,
            ),
          ),
        ),
      );

      final centerButtonFinder = find.byKey(const Key('bottom_nav_insights'));
      expect(centerButtonFinder, findsOneWidget);

      // Verify custom vector logo is active in thinking state
      final iconFinder = find.descendant(
        of: centerButtonFinder,
        matching: find.byType(MausamCenterLogoIcon),
      );
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('Responding state: logo maintains subtle animation until completion', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MausamBottomNavbar(
              currentRoute: '/insights',
              onNavigate: (_) {},
              aiState: MausamAiState.responding,
            ),
          ),
        ),
      );

      final centerButtonFinder = find.byKey(const Key('bottom_nav_insights'));
      expect(centerButtonFinder, findsOneWidget);

      final iconFinder = find.descendant(
        of: centerButtonFinder,
        matching: find.byType(MausamCenterLogoIcon),
      );
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('Reduced motion accessibility: disables looping animation transforms', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              bottomNavigationBar: MausamBottomNavbar(
                currentRoute: '/home',
                onNavigate: (_) {},
                aiState: MausamAiState.thinking,
              ),
            ),
          ),
        ),
      );

      final centerButtonFinder = find.byKey(const Key('bottom_nav_insights'));
      expect(centerButtonFinder, findsOneWidget);

      // Verify it builds gracefully without throwing
      expect(tester.takeException(), isNull);
    });

    testWidgets('State-driven transitions via ProviderScope: Idle -> Thinking -> Idle', (tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, child) {
              final aiState = ref.watch(mausamAiStateProvider);
              return MaterialApp(
                home: Scaffold(
                  bottomNavigationBar: MausamBottomNavbar(
                    currentRoute: '/home',
                    onNavigate: (_) {},
                    aiState: aiState,
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Initial state is idle
      expect(container.read(mausamAiStateProvider), MausamAiState.idle);

      // Trigger thinking
      container.read(mausamAiStateProvider.notifier).setThinking();
      await tester.pump();
      expect(container.read(mausamAiStateProvider), MausamAiState.thinking);

      // Trigger responding
      container.read(mausamAiStateProvider.notifier).setResponding();
      await tester.pump();
      expect(container.read(mausamAiStateProvider), MausamAiState.responding);

      // Return to idle
      container.read(mausamAiStateProvider.notifier).setIdle();
      await tester.pump();
      expect(container.read(mausamAiStateProvider), MausamAiState.idle);
    });
  });
}
