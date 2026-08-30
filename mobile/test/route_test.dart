import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/main.dart';
import 'package:mobile/router/app_router.dart';

void main() {
  testWidgets('Navigate through all 6 routes without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MausamApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Home Screen
    expect(find.text('Home Screen'), findsOneWidget);

    // 2. Onboarding Screen
    appRouter.go('/onboarding');
    await tester.pumpAndSettle();
    expect(find.text('Onboarding Screen'), findsOneWidget);

    // 3. Login Screen
    appRouter.go('/login');
    await tester.pumpAndSettle();
    expect(find.text('Login Screen'), findsOneWidget);

    // 4. Forecast Screen
    appRouter.go('/forecast');
    await tester.pumpAndSettle();
    expect(find.text('Forecast Screen'), findsOneWidget);

    // 5. Saved Locations Screen
    appRouter.go('/saved-locations');
    await tester.pumpAndSettle();
    expect(find.text('Saved Locations Screen'), findsOneWidget);

    // 6. Profile Screen
    appRouter.go('/profile');
    await tester.pumpAndSettle();
    expect(find.text('Profile Screen'), findsOneWidget);
  });
}
