import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/weather_ai_card_data.dart';
import '../screens/login_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/weather_map_screen.dart';
import '../theme/mausam_transitions.dart';
import '../widgets/navigation/app_shell.dart';

GoRouter createRouter({String initialLocation = '/splash'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/weather-map',
        name: 'weather_map',
        pageBuilder: (context, state) {
          final routeData = state.extra as WeatherAiCardData?;
          return mausamFadePage(
            key: state.pageKey,
            child: WeatherMapScreen(routeData: routeData),
          );
        },
      ),
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => mausamFadePage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/',
        name: 'root',
        pageBuilder: (context, state) => mausamFadePage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => mausamFadePage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/create-account',
        name: 'create_account',
        pageBuilder: (context, state) => mausamFadePage(
          key: state.pageKey,
          child: const LoginScreen(initialMode: AuthViewMode.createAccount),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => mausamFadePage(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => const AppShell(),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => mausamNoMovePage(child: const SizedBox.shrink()),
          ),
          GoRoute(
            path: '/forecast',
            name: 'forecast',
            pageBuilder: (context, state) => mausamNoMovePage(child: const SizedBox.shrink()),
          ),
          GoRoute(
            path: '/saved-locations',
            name: 'saved_locations',
            pageBuilder: (context, state) => mausamNoMovePage(child: const SizedBox.shrink()),
          ),
          GoRoute(
            path: '/insights',
            name: 'insights',
            pageBuilder: (context, state) => mausamNoMovePage(child: const SizedBox.shrink()),
          ),
          GoRoute(
            path: '/chat',
            name: 'chat',
            pageBuilder: (context, state) => mausamNoMovePage(child: const SizedBox.shrink()),
          ),
          GoRoute(
            path: '/alerts',
            name: 'alerts',
            pageBuilder: (context, state) => mausamNoMovePage(child: const SizedBox.shrink()),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => mausamNoMovePage(child: const SizedBox.shrink()),
          ),
          GoRoute(
            path: '/context-detail',
            name: 'context_detail',
            pageBuilder: (context, state) => mausamNoMovePage(child: const SizedBox.shrink()),
          ),
          GoRoute(
            path: '/health-metrics',
            name: 'health_metrics',
            pageBuilder: (context, state) => mausamNoMovePage(child: const SizedBox.shrink()),
          ),
        ],
      ),
    ],
  );
}

final GoRouter appRouter = createRouter();
