import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/onboarding_screen.dart';

GoRouter createRouter({String initialLocation = '/splash'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const MainNavigationScreen(initialIndex: 0),
      ),
      GoRoute(
        path: '/',
        name: 'root',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/forecast',
        name: 'forecast',
        builder: (context, state) => const MainNavigationScreen(initialIndex: 1),
      ),
      GoRoute(
        path: '/saved-locations',
        name: 'saved_locations',
        builder: (context, state) => const MainNavigationScreen(initialIndex: 2),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const MainNavigationScreen(initialIndex: 3),
      ),
    ],
  );
}

final GoRouter appRouter = createRouter();
