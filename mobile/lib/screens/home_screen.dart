import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/appearance_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/homepage_provider.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';
import '../providers/weather_dashboard_provider.dart';
import '../theme/weather_palette.dart';
import '../widgets/cards/recommended_section_widget.dart';
import '../widgets/navigation/app_drawer.dart';
import '../widgets/navigation/search_overlay.dart';
import '../widgets/staggered_item_wrapper.dart';
import '../widgets/weather/location_switcher_sheet.dart';
import '../widgets/weather/weather_sections.dart';
import '../widgets/weather_environment_background.dart';
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

    ref.read(homepageProvider.notifier).fetchHomeFeed();
    ref.read(weatherDashboardProvider.notifier).fetchDashboard();
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
    final homeState = ref.watch(homepageProvider);
    final appearance = ref.watch(appearanceProvider);
    final data = dash.data;
    final topCard = homeState.data?.cards.firstOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const MausamAppDrawer(currentRoute: '/home'),
      body: WeatherEnvironmentBackground(
        wallpaperTheme: appearance.wallpaperTheme,
        condition: data?.current.condition,
        child: SafeArea(
          child: Column(
            children: [
              // 1. Floating Glass Control Header Bar: [ ☰   📍 Location   ⌕ ]
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: MausamPalette.cardSurface.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: MausamPalette.cardBorder),
                    boxShadow: MausamPalette.cardShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: ☰ Menu Drawer Button
                      Builder(
                        builder: (drawerContext) => IconButton(
                          icon: const Icon(Icons.menu_rounded, color: MausamPalette.textPrimary, size: 22),
                          tooltip: 'Open Menu',
                          onPressed: () => Scaffold.of(drawerContext).openDrawer(),
                        ),
                      ),

                      // Center: 📍 Location Selector Pill
                      GestureDetector(
                        onTap: _openSwitcher,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: MausamPalette.bgDeep.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: MausamPalette.cardBorderSubtle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_outlined, color: MausamPalette.accentBlue, size: 14),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 140),
                                child: Text(
                                  locState.cityName.isNotEmpty
                                      ? locState.cityName
                                      : (data?.current.location ?? 'Active Location'),
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: MausamPalette.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.keyboard_arrow_down_rounded, color: MausamPalette.textTertiary, size: 16),
                            ],
                          ),
                        ),
                      ),

                      // Right: 🔍 Search Control Modal
                      IconButton(
                        icon: const Icon(Icons.search_rounded, color: MausamPalette.textPrimary, size: 22),
                        tooltip: 'Search City',
                        onPressed: () => showSearchOverlay(context: context, ref: ref),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Main Content Body
              Expanded(
                child: RefreshIndicator(
                  color: MausamPalette.accentBlue,
                  backgroundColor: MausamPalette.cardSurface,
                  onRefresh: () async {
                    await ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
                    await ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true);
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: dash.isLoading && data == null
                        ? const WeatherSkeletonLoader(key: ValueKey('skeleton_loader'))
                        : dash.errorMessage != null && data == null
                            ? ListView(
                                key: const ValueKey('error_view'),
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(24),
                                children: [
                                  const SizedBox(height: 80),
                                  const Icon(Icons.cloud_off_rounded, color: MausamPalette.accentAmber, size: 44),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Weather Unavailable',
                                    style: GoogleFonts.inter(
                                      color: MausamPalette.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Unable to retrieve live weather data right now.',
                                    style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  Center(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: MausamPalette.textPrimary,
                                        foregroundColor: MausamPalette.bgDeep,
                                      ),
                                      onPressed: () {
                                        ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
                                        ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true);
                                      },
                                      icon: const Icon(Icons.refresh_rounded, size: 18),
                                      label: const Text('Try Again'),
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
                                    // 1. Weather Hero
                                    StaggeredItemWrapper(
                                      index: 0,
                                      child: HeroCurrentCard(
                                        current: data.current,
                                        hourly: data.hourly,
                                        locationName: locState.cityName.isNotEmpty ? locState.cityName : data.current.location,
                                        onLocationTap: _openSwitcher,
                                        onSearchTap: () => showSearchOverlay(context: context, ref: ref),
                                        onProfileTap: () => context.push('/profile'),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // 2. FOR YOU Recommendation Section (Clean monochrome surface, no left green line)
                                    if (topCard != null)
                                      StaggeredItemWrapper(
                                        index: 1,
                                        child: RecommendedSectionWidget(
                                          card: topCard,
                                          onTap: () => context.push('/insights'),
                                        ),
                                      ),

                                    // 3. Hourly Forecast Strip
                                    StaggeredItemWrapper(
                                      index: 2,
                                      child: HourlyForecastStrip(
                                        hourly: data.hourly,
                                        onMore: () => context.push('/forecast'),
                                      ),
                                    ),

                                    // 4. AQI Card
                                    if (data.aqi != null)
                                      StaggeredItemWrapper(
                                        index: 3,
                                        child: AqiGaugeCard(aqi: data.aqi!),
                                      ),

                                    // 5. Stat Grid
                                    StaggeredItemWrapper(
                                      index: 4,
                                      child: StatGrid(dashboard: data),
                                    ),
                                  ],
                                ],
                              ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
