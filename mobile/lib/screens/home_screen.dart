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
import '../services/notification_service.dart';
import '../widgets/cards/recommended_section_widget.dart';
import '../widgets/navigation/app_drawer.dart';
import '../widgets/navigation/search_overlay.dart';
import '../widgets/staggered_item_wrapper.dart';
import '../widgets/weather/weather_sections.dart';
import '../widgets/weather_environment_background.dart';
import '../widgets/weather_skeleton_loader.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _locationCollapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocationAndFetchData();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    if (offset > 45 && !_locationCollapsed) {
      setState(() => _locationCollapsed = true);
    } else if (offset <= 15 && _locationCollapsed) {
      setState(() => _locationCollapsed = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final locState = ref.watch(locationProvider);
    final dash = ref.watch(weatherDashboardProvider);
    final homeState = ref.watch(homepageProvider);
    final appearance = ref.watch(appearanceProvider);
    final data = dash.data;
    final topCard = homeState.data?.cards.firstOrNull;

    final activeLocationName = locState.cityName.isNotEmpty
        ? locState.cityName
        : (data?.current.location ?? 'Active Location');

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const MausamAppDrawer(currentRoute: '/home'),
      body: WeatherEnvironmentBackground(
        wallpaperTheme: appearance.wallpaperTheme,
        condition: data?.current.condition,
        child: SafeArea(
          child: Column(
            children: [
              // 1. Floating Glass Control Header Bar: [ ☰   📍 Location Text   ⌕ ]
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

                      // Center: Plain Interactive Location Text (No pill, no border, no fill)
                      // Dynamic scroll bounce return animation
                      Expanded(
                        child: Center(
                          child: AnimatedSlide(
                            offset: _locationCollapsed ? const Offset(0, -0.6) : Offset.zero,
                            duration: const Duration(milliseconds: 350),
                            curve: _locationCollapsed ? Curves.easeOutCubic : Curves.easeOutBack,
                            child: AnimatedOpacity(
                              opacity: _locationCollapsed ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 250),
                              child: InkWell(
                                onTap: () => context.push('/saved-locations'),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        color: MausamPalette.accentBlue,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 5),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 160),
                                        child: Text(
                                          activeLocationName,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: MausamPalette.textPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
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
                    if (!mounted) return;
                    await ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
                    if (!mounted) return;
                    await ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true);
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: dash.isLoading && data == null
                        ? const WeatherSkeletonLoader(key: ValueKey('skeleton_loader'))
                        : dash.errorMessage != null && data == null
                            ? ListView(
                                key: const ValueKey('error_view'),
                                controller: _scrollController,
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
                                controller: _scrollController,
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
                                        locationName: activeLocationName,
                                        onLocationTap: () => context.push('/saved-locations'),
                                        onSearchTap: () => showSearchOverlay(context: context, ref: ref),
                                        onProfileTap: () => context.push('/profile'),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // 1b. Active Weather Alert Banner
                                    if (_computeHomeAlert(data) != null) ...[
                                      StaggeredItemWrapper(
                                        index: 1,
                                        child: _HomeAlertBanner(
                                          alert: _computeHomeAlert(data)!,
                                          onTap: () => context.push('/alerts'),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],

                                    // 2. FOR YOU Recommendation Section
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

  _AlertItemData? _computeHomeAlert(data) {
    if (data == null) return null;
    final current = data.current;
    final temp = current.temperatureCelsius;
    final precip = current.rainMm1h ?? 0.0;
    final cond = (current.condition ?? '').toLowerCase();
    final aqi = data.aqi?.aqiValue ?? 0;
    final wind = current.windSpeedKmh;

    if (temp >= 36) {
      return _AlertItemData(
        title: 'EXTREME HEAT WARNING',
        message: 'High temperature of ${temp.round()}°C. Avoid peak sun & stay hydrated.',
        isSevere: true,
        icon: Icons.thermostat_rounded,
      );
    }
    if (precip >= 5.0 || cond.contains('thunder') || cond.contains('heavy rain')) {
      return _AlertItemData(
        title: 'HEAVY RAINFALL WARNING',
        message: 'Active heavy rain or thunderstorm. Plan travel carefully.',
        isSevere: true,
        icon: Icons.thunderstorm_rounded,
      );
    }
    if (aqi >= 200) {
      return _AlertItemData(
        title: 'SEVERE AIR POLLUTION',
        message: 'AQI reached $aqi (${data.aqi?.category}). Limit outdoor exposure.',
        isSevere: true,
        icon: Icons.air_rounded,
      );
    }
    if (temp >= 30) {
      return _AlertItemData(
        title: 'WARM WEATHER CAUTION',
        message: 'Temperature is ${temp.round()}°C. Drink extra fluids during outdoor activity.',
        isSevere: false,
        icon: Icons.wb_sunny_rounded,
      );
    }
    if (precip > 0.0 || anyWordIn(cond, ['rain', 'drizzle', 'shower'])) {
      return _AlertItemData(
        title: 'RAINFALL ADVISORY',
        message: '${current.condition ?? "Light rain"} reported. Carry an umbrella outside.',
        isSevere: false,
        icon: Icons.water_drop_rounded,
      );
    }
    if (aqi >= 80) {
      return _AlertItemData(
        title: 'MODERATE AQI ADVISORY',
        message: 'Air Quality Index is $aqi (${data.aqi?.category}).',
        isSevere: false,
        icon: Icons.air_rounded,
      );
    }
    if (wind >= 25.0) {
      return _AlertItemData(
        title: 'GUSTY WIND ADVISORY',
        message: 'Wind speed reaching ${wind.round()} km/h.',
        isSevere: false,
        icon: Icons.air_rounded,
      );
    }
    return null;
  }
}

bool anyWordIn(String text, List<String> words) {
  return words.any((w) => text.contains(w));
}

class _AlertItemData {
  final String title;
  final String message;
  final bool isSevere;
  final IconData icon;

  _AlertItemData({
    required this.title,
    required this.message,
    required this.isSevere,
    required this.icon,
  });
}

class _HomeAlertBanner extends StatelessWidget {
  final _AlertItemData alert;
  final VoidCallback onTap;

  const _HomeAlertBanner({
    required this.alert,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        NotificationService.showAlertNotification(
          context,
          title: alert.title,
          message: alert.message,
          isSevere: alert.isSevere,
          onViewAlerts: onTap,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: MausamPalette.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: alert.isSevere ? MausamPalette.accentRed.withValues(alpha: 0.7) : MausamPalette.accentAmber.withValues(alpha: 0.5),
            width: 1.0,
          ),
          boxShadow: MausamPalette.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: alert.isSevere ? MausamPalette.accentRed.withValues(alpha: 0.15) : MausamPalette.accentAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                alert.icon,
                color: alert.isSevere ? MausamPalette.accentRed : MausamPalette.accentAmber,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        alert.title,
                        style: GoogleFonts.inter(
                          color: alert.isSevere ? MausamPalette.accentRed : MausamPalette.accentAmber,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: MausamPalette.textTertiary, size: 12),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: MausamPalette.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
