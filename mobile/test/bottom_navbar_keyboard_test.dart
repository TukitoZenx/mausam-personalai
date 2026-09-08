import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/router/app_router.dart';
import 'package:mobile/widgets/navigation/mausam_bottom_navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Bottom Navbar Keyboard Inset & Typing State Tests', () {
    testWidgets('Bottom navbar slides away when keyboard insets appear', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = createRouter(initialLocation: '/insights');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially keyboard is closed, bottom navbar is visible at opacity 1.0
      expect(find.byType(MausamBottomNavbar), findsOneWidget);
      final initialOpacity = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.byType(MausamBottomNavbar),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(initialOpacity.opacity, equals(1.0));

      // Simulate keyboard opening by setting viewInsets.bottom
      tester.view.viewInsets = const FakeViewPadding(bottom: 350);
      await tester.pump(const Duration(milliseconds: 200));

      // Bottom navbar is now hidden (opacity 0.0)
      final keyboardOpacity = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.byType(MausamBottomNavbar),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(keyboardOpacity.opacity, equals(0.0));

      // Simulate keyboard closing
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pump(const Duration(milliseconds: 250));

      // Bottom navbar returns (opacity 1.0)
      final restoredOpacity = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.byType(MausamBottomNavbar),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(restoredOpacity.opacity, equals(1.0));
    });
  });
}
