import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/navigation/floating_navbar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FloatingNavbar Scroll & Transparency Tests', () {
    testWidgets('Unscrolled state: transparent background, zero shadow, text and icons visible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingNavbar(
              locationName: 'DVC Research Center',
              isScrolled: false,
              onLocationTap: () {},
              onSearch: () {},
            ),
          ),
        ),
      );

      // Verify location text and icons are rendered
      expect(find.text('DVC Research Center'), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);

      // Verify that the background glass/shadow container has opacity 0.0 (transparent)
      final animatedOpacityFinder = find.byType(AnimatedOpacity);
      expect(animatedOpacityFinder, findsOneWidget);

      final animatedOpacity = tester.widget<AnimatedOpacity>(animatedOpacityFinder);
      expect(animatedOpacity.opacity, 0.0);
    });

    testWidgets('Scrolled state: activates subtle shadow & glass backdrop while keeping text pinned', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingNavbar(
              locationName: 'DVC Research Center',
              isScrolled: true,
              onLocationTap: () {},
              onSearch: () {},
            ),
          ),
        ),
      );

      // Verify text is still visible and pinned
      expect(find.text('DVC Research Center'), findsOneWidget);

      // Verify background glass/shadow container has opacity 1.0
      final animatedOpacity = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
      expect(animatedOpacity.opacity, 1.0);

      // Verify BoxShadow is present on the background container
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AnimatedOpacity),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNotEmpty);
      expect(decoration.boxShadow!.first.blurRadius, 16.0);
    });
  });
}
