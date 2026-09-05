import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/homepage_provider.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';
import '../providers/weather_dashboard_provider.dart';
import '../theme/weather_palette.dart';
import '../services/notification_service.dart';
import '../widgets/cards/personalized_context_card.dart';
import '../widgets/cards/recommended_section_widget.dart';
import '../widgets/staggered_item_wrapper.dart';
import '../widgets/weather/weather_sections.dart';
import '../widgets/weather_skeleton_loader.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dash = ref.watch(weatherDashboardProvider);
    final locState = ref.watch(locationProvider);
    final userState = ref.watch(userProvider);
    final homeState = ref.watch(homepageProvider);
    final data = dash.data;
    final topCard = homeState.data?.cards.firstOrNull;
    final alert = _computeHomeAlert(data);
    final persona = userState.selectedPersona;

    final locationName = locState.cityName.isNotEmpty
        ? locState.cityName
        : (data?.current.location ?? 'Active Location');

    return RefreshIndicator(
      color: MausamPalette.textPrimary,
      backgroundColor: MausamPalette.cardSurface,
      onRefresh: () async {
        await ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
        await ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true);
      },
      child: dash.isLoading && data == null
          ? const WeatherSkeletonLoader()
          : data == null
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 78, 24, 24),
                  children: [
                    const SizedBox(height: 80),
                    const Icon(Icons.cloud_off_rounded, color: MausamPalette.textSecondary, size: 44),
                    const SizedBox(height: 16),
                    Text(
                      locState.activeLatitude == 0 && locState.activeLongitude == 0
                          ? 'Choose a location'
                          : 'Weather Unavailable',
                      style: GoogleFonts.inter(
                        color: MausamPalette.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      locState.activeLatitude == 0 && locState.activeLongitude == 0
                          ? 'Search a city to load live conditions.'
                          : "Mausam couldn't refresh the latest weather.",
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
                          if (locState.activeLatitude == 0 && locState.activeLongitude == 0) {
                            context.go('/saved-locations');
                            return;
                          }
                          ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
                          ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true);
                        },
                        icon: Icon(
                          locState.activeLatitude == 0 && locState.activeLongitude == 0
                              ? Icons.search_rounded
                              : Icons.refresh_rounded,
                          size: 18,
                        ),
                        label: Text(
                          locState.activeLatitude == 0 && locState.activeLongitude == 0
                              ? 'Search city'
                              : 'Try Again',
                        ),
                      ),
                    ),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 76, 16, 100),
                  children: [
                      StaggeredItemWrapper(
                        index: 0,
                        child: PersonalizedContextCard(
                          locationName: locationName,
                          dashboard: data,
                          userStateOverride: userState,
                          onTap: () => context.go('/insights'),
                        ),
                      ),
                      const SizedBox(height: 18),
                      StaggeredItemWrapper(
                        index: 1,
                        child: HeroCurrentCard(
                          current: data.current,
                          hourly: data.hourly,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (topCard != null) ...[
                        StaggeredItemWrapper(
                          index: 2,
                          child: RecommendedSectionWidget(
                            card: topCard,
                            onTap: () => context.go('/insights'),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                      StaggeredItemWrapper(
                        index: 3,
                        child: HourlyForecastStrip(
                          hourly: data.hourly,
                          onMore: () => context.go('/forecast'),
                        ),
                      ),
                      if (data.daily.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        StaggeredItemWrapper(
                          index: 4,
                          child: DailyForecastPanel(days: data.daily),
                        ),
                      ],
                      if (data.aqi != null) ...[
                        const SizedBox(height: 18),
                        StaggeredItemWrapper(
                          index: 5,
                          child: AqiGaugeCard(aqi: data.aqi!),
                        ),
                      ],
                      const SizedBox(height: 18),
                      StaggeredItemWrapper(
                        index: 6,
                        child: TodaysMetricsGrid(
                          dashboard: data,
                          persona: persona,
                        ),
                      ),
                      const SizedBox(height: 18),
                      StaggeredItemWrapper(
                        index: 7,
                        child: AdditionalConditionsSection(
                          dashboard: data,
                          persona: persona,
                        ),
                      ),
                      const SizedBox(height: 18),
                      StaggeredItemWrapper(
                        index: 8,
                        child: ConditionsAroundYouSection(
                          dashboard: data,
                          persona: persona,
                        ),
                      ),
                      if (alert != null) ...[
                        const SizedBox(height: 12),
                        StaggeredItemWrapper(
                          index: 9,
                          child: _HomeAlertBanner(
                            alert: alert,
                            onTap: () => context.go('/alerts'),
                          ),
                        ),
                      ],
                  ],
                ),
    );
  }
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
  if (precip > 0.0 || ['rain', 'drizzle', 'shower'].any((w) => cond.contains(w))) {
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
                color: alert.isSevere ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: MausamPalette.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
