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
import '../widgets/weather/location_switcher_sheet.dart';
import '../widgets/weather/weather_sections.dart';

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
          color: WeatherPalette.sky,
          backgroundColor: WeatherPalette.card,
          onRefresh: () async {
            await ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
            await ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
            children: [
              if (dash.isLoading && data == null)
                const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: WeatherPalette.sky),
                        SizedBox(height: 16),
                        Text(
                          'Loading live weather data...',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else if (dash.errorMessage != null && data == null)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_off_rounded, color: Colors.orangeAccent, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Could not load live weather.\n${dash.errorMessage}',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WeatherPalette.sky,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else ...[
                if (data != null) ...[
                  HeroCurrentCard(
                    current: data.current,
                    hourly: data.hourly,
                    locationName: locState.cityName.isNotEmpty ? locState.cityName : data.current.location,
                    onLocationTap: _openSwitcher,
                    onSearchTap: _openSwitcher,
                  ),
                  const SizedBox(height: 12),
                  HourlyForecastStrip(
                    hourly: data.hourly,
                    onMore: () => context.go('/forecast'),
                  ),
                  DailyForecastPanel(days: data.daily),
                  if (data.aqi != null) AqiGaugeCard(aqi: data.aqi!),
                  StatGrid(dashboard: data),
                  const SizedBox(height: 10),
                  SunMoonCard(
                    current: data.current,
                    today: data.daily.isEmpty ? null : data.daily.first,
                  ),
                ]
              ],
            ],
          ),
        ),
      ),
    );
  }
}
