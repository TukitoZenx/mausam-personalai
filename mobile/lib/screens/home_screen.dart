import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../providers/homepage_provider.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';
import '../providers/weather_dashboard_provider.dart';
import '../theme/weather_palette.dart';
import '../widgets/app_drawer.dart';
import '../widgets/staggered_item_wrapper.dart';
import '../widgets/weather/location_switcher_sheet.dart';
import '../widgets/weather/weather_sections.dart';
import '../widgets/weather_skeleton_loader.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocationAndFetchData();
    });
  }

  Future<void> _initLocationAndFetchData() async {
    final userState = ref.read(userProvider);
    final apiClient = ref.read(apiClientProvider);
    final idToken = userState.idToken ?? 'test_token';

    // Start fetching dashboard and feed immediately with default/active coordinates
    ref.read(homepageProvider.notifier).fetchHomeFeed();
    ref.read(weatherDashboardProvider.notifier).fetchDashboard();

    // Detect device location in background and fetch saved locations
    ref.read(locationProvider.notifier).detectDeviceLocation(apiClient, idToken);

    try {
      final savedRaw = await apiClient.fetchSavedLocations(idToken: idToken);
      if (!mounted) return;
      final items = savedRaw.map((e) {
        final itemMap = e as Map<String, dynamic>;
        return LocationItem(
          id: itemMap['id'] as String,
          name: itemMap['name'] as String,
          latitude: (itemMap['latitude'] as num).toDouble(),
          longitude: (itemMap['longitude'] as num).toDouble(),
          placeName: itemMap['place_name'] as String?,
        );
      }).toList();
      ref.read(locationProvider.notifier).setSavedLocations(items);
    } catch (_) {}
  }

  Future<void> _openSwitcher() {
    return showLocationSwitcherSheet(context: context, ref: ref);
  }

  @override
  Widget build(BuildContext context) {
    final locState = ref.watch(locationProvider);
    final dash = ref.watch(weatherDashboardProvider);
    final data = dash.data;

    return Scaffold(
      backgroundColor: MausamPalette.bgPrimary,
      drawer: const AppDrawer(currentRoute: '/home'),
      body: SafeArea(
        child: RefreshIndicator(
          color: MausamPalette.accentBlue,
          backgroundColor: MausamPalette.cardSurface,
          onRefresh: () async {
            await ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
            await ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true);
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: dash.isLoading && data == null
                ? const WeatherSkeletonLoader(key: ValueKey('skeleton_loader'))
                : dash.errorMessage != null && data == null
                    ? ListView(
                        key: const ValueKey('error_view'),
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        children: [
                          const SizedBox(height: 80),
                          const Icon(Icons.cloud_off_rounded, color: MausamPalette.accentOrange, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Could not load live weather.\n${dash.errorMessage}',
                            style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MausamPalette.accentBlue,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        key: ValueKey('data_view_${locState.activeLatitude}_${locState.activeLongitude}'),
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
                        children: [
                          if (data != null) ...[
                            StaggeredItemWrapper(
                              index: 0,
                              child: HeroCurrentCard(
                                current: data.current,
                                hourly: data.hourly,
                                locationName: locState.cityName.isNotEmpty ? locState.cityName : data.current.location,
                                onLocationTap: _openSwitcher,
                                onSearchTap: _openSwitcher,
                              ),
                            ),
                            const SizedBox(height: 12),
                            StaggeredItemWrapper(
                              index: 1,
                              child: HourlyForecastStrip(
                                hourly: data.hourly,
                                onMore: () => context.go('/forecast'),
                              ),
                            ),
                            StaggeredItemWrapper(
                              index: 2,
                              child: DailyForecastPanel(days: data.daily),
                            ),
                            if (data.aqi != null)
                              StaggeredItemWrapper(
                                index: 3,
                                child: AqiGaugeCard(aqi: data.aqi!),
                              ),
                            StaggeredItemWrapper(
                              index: 4,
                              child: StatGrid(dashboard: data),
                            ),
                            const SizedBox(height: 10),
                            StaggeredItemWrapper(
                              index: 5,
                              child: SunMoonCard(
                                current: data.current,
                                today: data.daily.isEmpty ? null : data.daily.first,
                              ),
                            ),
                          ],
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}
