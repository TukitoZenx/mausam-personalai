import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/login_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/splash_screen.dart';
import '../theme/mausam_transitions.dart';
import '../widgets/navigation/app_shell.dart';

GoRouter createRouter({String initialLocation = '/splash'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
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
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => mausamFadePage(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      ShellRoute(
        pageBuilder: (context, state, child) {
          return mausamFadePage(
            key: const ValueKey('mausam-shell'),
            child: const AppShell(),
          );
        },
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
            path: '/alerts',
            name: 'alerts',
            pageBuilder: (context, state) => mausamNoMovePage(child: const SizedBox.shrink()),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => mausamNoMovePage(child: const SizedBox.shrink()),
          ),
        ],
      ),
    ],
  );
}

final GoRouter appRouter = createRouter();
