import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/widgets/animated_logo_container.dart';

import 'package:mobile/router/app_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final viewports = [
    const Size(320, 640),
    const Size(360, 800),
    const Size(412, 915),
    const Size(800, 1200),
  ];

  for (final size in viewports) {
    testWidgets('SplashScreen centers logo horizontally on ${size.width}x${size.height}', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final router = createRouter(initialLocation: '/splash');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Verify AnimatedLogoContainer is present
      final logoFinder = find.byType(AnimatedLogoContainer);
      expect(logoFinder, findsOneWidget);

      final logoRect = tester.getRect(logoFinder);
      final expectedCenterX = size.width / 2.0;

      // Allow 0.5px float tolerance
      expect(
        (logoRect.center.dx - expectedCenterX).abs(),
        lessThanOrEqualTo(0.5),
        reason: 'Logo should be centered horizontally on ${size.width} screen',
      );

      // Verify MAUSAM text is present
      expect(find.textContaining('MAUSAM'), findsOneWidget);

      // Verify no exceptions were thrown
      expect(tester.takeException(), isNull);
    });
  }
}
