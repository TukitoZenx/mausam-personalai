import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
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

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _locationAnim;
  double _lastOffset = 0;
  bool _locationCollapsed = false;

  static const _spring = SpringDescription(mass: 0.85, stiffness: 220, damping: 18);

  @override
  void initState() {
    super.initState();
    _locationAnim = AnimationController.unbounded(vsync: this);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocationAndFetchData();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _locationAnim.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    final delta = offset - _lastOffset;
    _lastOffset = offset;

    if (offset <= 2) {
      _setLocationCollapsed(false);
      return;
    }
    if (delta > 1.6 && offset > 10) {
      _setLocationCollapsed(true);
    } else if (delta < -1.6) {
      _setLocationCollapsed(false);
    }
  }

  void _setLocationCollapsed(bool collapsed) {
    if (_locationCollapsed == collapsed) return;
    _locationCollapsed = collapsed;
    final sim = SpringSimulation(
      _spring,
      _locationAnim.value,
      collapsed ? 1.0 : 0.0,
      _locationAnim.velocity,
    );
    _locationAnim.animateWith(sim);
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
          id: itemMap['id'].toString(),
          name: itemMap['name'].toString(),
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
          child: Stack(
            children: [
              Positioned.fill(
                child: RefreshIndicator(
                  color: MausamPalette.textPrimary,
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
                                padding: const EdgeInsets.fromLTRB(24, 78, 24, 24),
                                children: [
                                  const SizedBox(height: 80),
                                  const Icon(Icons.cloud_off_rounded, color: MausamPalette.textSecondary, size: 44),
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
                                padding: const EdgeInsets.fromLTRB(14, 78, 14, 28),
                                children: [
                                  if (data != null) ...[
                                    StaggeredItemWrapper(
                                      index: 0,
                                      child: HeroCurrentCard(
                                        current: data.current,
                                        hourly: data.hourly,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (topCard != null)
                                      StaggeredItemWrapper(
                                        index: 1,
                                        child: RecommendedSectionWidget(
                                          card: topCard,
                                          onTap: () => context.push('/insights'),
                                        ),
                                      ),
                                    StaggeredItemWrapper(
                                      index: 2,
                                      child: HourlyForecastStrip(
                                        hourly: data.hourly,
                                        onMore: () => context.push('/forecast'),
                                      ),
                                    ),
                                    if (data.aqi != null)
                                      StaggeredItemWrapper(
                                        index: 3,
                                        child: AqiGaugeCard(aqi: data.aqi!),
                                      ),
                                    if (_computeHomeAlert(data) != null) ...[
                                      StaggeredItemWrapper(
                                        index: 4,
                                        child: _HomeAlertBanner(
                                          alert: _computeHomeAlert(data)!,
                                          onTap: () => context.push('/alerts'),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    StaggeredItemWrapper(
                                      index: 5,
                                      child: StatGrid(dashboard: data),
                                    ),
                                  ],
                                ],
                              ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 14,
                right: 14,
                child: _FloatingNavbar(
                  locationName: activeLocationName,
                  locationAnimation: _locationAnim,
                  onLocationTap: () => context.push('/saved-locations'),
                  onSearch: () => showSearchOverlay(context: context, ref: ref),
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

class _FloatingNavbar extends StatelessWidget {
  final String locationName;
  final Animation<double> locationAnimation;
  final VoidCallback onLocationTap;
  final VoidCallback onSearch;

  const _FloatingNavbar({
    required this.locationName,
    required this.locationAnimation,
    required this.onLocationTap,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: MausamPalette.navbarShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: MausamPalette.cardSurface.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Builder(
                  builder: (drawerContext) => IconButton(
                    icon: const Icon(Icons.menu_rounded, color: MausamPalette.textPrimary, size: 22),
                    tooltip: 'Open Menu',
                    onPressed: () => Scaffold.of(drawerContext).openDrawer(),
                  ),
                ),
                Expanded(
                  child: ClipRect(
                    child: AnimatedBuilder(
                      animation: locationAnimation,
                      builder: (context, child) {
                        final t = locationAnimation.value.clamp(0.0, 1.2);
                        return Transform.translate(
                          offset: Offset(0, -t * 28),
                          child: Opacity(
                            opacity: (1.0 - t * 0.35).clamp(0.0, 1.0),
                            child: child,
                          ),
                        );
                      },
                      child: GestureDetector(
                        onTap: onLocationTap,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: MausamPalette.textSecondary,
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                locationName,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: MausamPalette.textPrimary,
                                  fontWeight: FontWeight.w600,
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
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: MausamPalette.textPrimary, size: 22),
                  tooltip: 'Search City',
                  onPressed: onSearch,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
          border: Border.all(color: MausamPalette.cardBorder),
          boxShadow: MausamPalette.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: MausamPalette.cardSurfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                alert.icon,
                color: MausamPalette.textPrimary,
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
                          color: MausamPalette.textPrimary,
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
                      color: MausamPalette.textSecondary,
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
