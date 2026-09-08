import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/appearance_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/weather_dashboard_provider.dart';
import '../../screens/alerts_screen.dart';
import '../../screens/chat_screen.dart';
import '../../screens/context_detail_screen.dart';
import '../../screens/forecast_screen.dart';
import '../../screens/health_metrics_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/insights_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/saved_locations_screen.dart';
import '../weather_environment_background.dart';
import 'app_drawer.dart';
import 'fading_indexed_stack.dart';
import 'floating_navbar.dart';
import 'mausam_bottom_navbar.dart';

const _shellRoutes = [
  '/home',
  '/saved-locations',
  '/forecast',
  '/insights',
  '/chat',
  '/alerts',
  '/profile',
  '/context-detail',
  '/health-metrics',
];

int shellIndexForPath(String path) {
  final index = _shellRoutes.indexWhere((r) => path == r || path.startsWith('$r/'));
  return index < 0 ? 0 : index;
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with SingleTickerProviderStateMixin {
  late final AnimationController _locationAnim;
  double _lastOffset = 0;
  bool _locationCollapsed = false;

  static const _spring = SpringDescription(mass: 0.85, stiffness: 220, damping: 18);

  @override
  void initState() {
    super.initState();
    _locationAnim = AnimationController.unbounded(vsync: this);
  }

  @override
  void dispose() {
    _locationAnim.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification) return false;
    final offset = notification.metrics.pixels;
    final delta = offset - _lastOffset;
    _lastOffset = offset;
    if (offset <= 2) {
      _setLocationCollapsed(false);
      return false;
    }
    if (delta > 1.6 && offset > 10) {
      _setLocationCollapsed(true);
    } else if (delta < -1.6) {
      _setLocationCollapsed(false);
    }
    return false;
  }

  void _setLocationCollapsed(bool collapsed) {
    if (_locationCollapsed == collapsed) return;
    _locationCollapsed = collapsed;
    _locationAnim.animateWith(
      SpringSimulation(_spring, _locationAnim.value, collapsed ? 1.0 : 0.0, _locationAnim.velocity),
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final index = shellIndexForPath(path);
    final locState = ref.watch(locationProvider);
    final dash = ref.watch(weatherDashboardProvider);
    final appearance = ref.watch(appearanceProvider);
    final rawLocation = locState.cityName.isNotEmpty
        ? locState.cityName
        : (dash.data?.current.location ?? 'Active Location');
    final locationName = rawLocation.split(',').first.trim().isNotEmpty
        ? rawLocation.split(',').first.trim()
        : rawLocation;

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: MausamAppDrawer(currentRoute: path),
      body: WeatherEnvironmentBackground(
        wallpaperTheme: appearance.wallpaperTheme,
        hourOverride: appearance.previewHour,
        child: SafeArea(
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: Colors.transparent),
                ),
                Positioned.fill(
                  child: FadingIndexedStack(
                    index: index,
                    children: const [
                      HomeScreen(),
                      SavedLocationsScreen(),
                      ForecastScreen(),
                      InsightsScreen(),
                      ChatScreen(),
                      AlertsScreen(),
                      ProfileScreen(),
                      ContextDetailScreen(),
                      HealthMetricsScreen(),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 14,
                  right: 14,
                  child: FloatingNavbar(
                    locationName: locationName,
                    locationAnimation: _locationAnim,
                    onLocationTap: () => context.go('/saved-locations'),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: MediaQuery.viewInsetsOf(context).bottom > 0 ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: IgnorePointer(
                      ignoring: MediaQuery.viewInsetsOf(context).bottom > 0,
                      child: MausamBottomNavbar(
                        currentRoute: path,
                        onNavigate: (route) => context.go(route),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
