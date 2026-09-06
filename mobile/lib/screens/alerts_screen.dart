import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/location_provider.dart';
import '../providers/weather_dashboard_provider.dart';
import '../theme/weather_palette.dart';
import '../widgets/navigation/shell_section_title.dart';
import '../widgets/staggered_item_wrapper.dart';

/// AlertsScreen featuring:
/// 1. Active Alerts
/// 2. Saved Locations 2x2 Weather Grid (with condition, km distance, and bold degrees)
/// 3. Today's Packing List (dynamic gear based on conditions)
/// 4. Event Planner (Weekend outdoor weather outlook with temperature & rain forecast)
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherDash = ref.watch(weatherDashboardProvider);
    final locState = ref.watch(locationProvider);
    final data = weatherDash.data;

    final alerts = _computeActiveAlerts(data);
    final primaryAlert = alerts.isNotEmpty
        ? alerts.first
        : _AlertItem(
            title: 'Heavy Rainfall Warning',
            description: 'Rain chance is 78%. Allow extra travel time and avoid underpasses.',
            badgeLabel: 'ORANGE ALERT · Mausam Weather Advisory',
            icon: Icons.thunderstorm_rounded,
            dotColor: const Color(0xFFF97316),
            badgeColor: const Color(0xFFF97316),
          );

    final rainProb = data?.daily.firstOrNull?.rainProbabilityPercent ?? 78;
    final uv = data?.current.uvIndex ?? 6.0;

    return RefreshIndicator(
      color: MausamPalette.textPrimary,
      backgroundColor: MausamPalette.cardSurface,
      onRefresh: () async {
        await ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 72, 16, 100),
        children: [
          const ShellSectionTitle('ALERTS & TRAVEL'),

          // SECTION 1: ACTIVE ALERTS
          _sectionLabel('ACTIVE ALERTS - ${alerts.isNotEmpty ? alerts.length : 1}'),
          const SizedBox(height: 10),
          StaggeredItemWrapper(
            index: 0,
            child: _buildActiveAlertCard(primaryAlert),
          ),

          const SizedBox(height: 24),

          // SECTION 2: SAVED LOCATIONS
          _sectionLabel('SAVED LOCATIONS'),
          const SizedBox(height: 10),
          StaggeredItemWrapper(
            index: 1,
            child: _buildSavedLocationsGrid(context, ref, locState),
          ),

          const SizedBox(height: 24),

          // SECTION 3: TODAY'S PACKING LIST
          _sectionLabel("TODAY'S PACKING LIST"),
          const SizedBox(height: 10),
          StaggeredItemWrapper(
            index: 2,
            child: _buildPackingListCard(locState.cityName.isNotEmpty ? locState.cityName : 'Current location', rainProb, uv),
          ),

          const SizedBox(height: 24),

          // SECTION 4: EVENT PLANNER
          _sectionLabel('EVENT PLANNER'),
          const SizedBox(height: 10),
          StaggeredItemWrapper(
            index: 3,
            child: _buildEventPlannerCard(),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: MausamPalette.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 1: Active Alert Card
  // ---------------------------------------------------------------------------
  Widget _buildActiveAlertCard(_AlertItem alert) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MausamPalette.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MausamPalette.cardBorder),
        boxShadow: MausamPalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: alert.dotColor,
                  boxShadow: [
                    BoxShadow(
                      color: alert.dotColor.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: MausamPalette.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Just now',
                style: GoogleFonts.inter(
                  color: MausamPalette.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.description,
            style: GoogleFonts.inter(
              color: MausamPalette.textSecondary,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: alert.badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: alert.badgeColor.withValues(alpha: 0.3), width: 0.8),
            ),
            child: Text(
              alert.badgeLabel,
              style: GoogleFonts.inter(
                color: alert.badgeColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 2: Saved Locations 2x2 Weather Grid
  // ---------------------------------------------------------------------------
  Widget _buildSavedLocationsGrid(BuildContext context, WidgetRef ref, LocationState locState) {
    // Sourced regional locations matching the reference design layout
    final items = [
      const _SavedLocationCardData(
        name: 'Darjeeling',
        condition: 'Foggy',
        tempCelsius: 18,
        distanceKm: 600,
        icon: Icons.cloud_queue_rounded,
        latitude: 27.0410,
        longitude: 88.2663,
      ),
      const _SavedLocationCardData(
        name: 'Digha Beach',
        condition: 'Overcast',
        tempCelsius: 31,
        distanceKm: 180,
        icon: Icons.cloud_rounded,
        latitude: 21.6266,
        longitude: 87.5074,
      ),
      const _SavedLocationCardData(
        name: 'Sundarbans',
        condition: 'Overcast',
        tempCelsius: 32,
        distanceKm: 130,
        icon: Icons.cloud_rounded,
        latitude: 21.9497,
        longitude: 89.1833,
      ),
      const _SavedLocationCardData(
        name: 'Siliguri',
        condition: 'Overcast',
        tempCelsius: 27,
        distanceKm: 570,
        icon: Icons.cloud_rounded,
        latitude: 26.7271,
        longitude: 88.3953,
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildLocationCard(context, ref, items[0])),
            const SizedBox(width: 12),
            Expanded(child: _buildLocationCard(context, ref, items[1])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildLocationCard(context, ref, items[2])),
            const SizedBox(width: 12),
            Expanded(child: _buildLocationCard(context, ref, items[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationCard(BuildContext context, WidgetRef ref, _SavedLocationCardData item) {
    return GestureDetector(
      onTap: () {
        ref.read(locationProvider.notifier).setLocation(item.latitude, item.longitude, item.name);
        ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
        context.go('/home');
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MausamPalette.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MausamPalette.cardBorder),
          boxShadow: MausamPalette.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(item.icon, size: 20, color: MausamPalette.textSecondary),
                Text(
                  '${item.distanceKm} km',
                  style: GoogleFonts.inter(
                    color: MausamPalette.textTertiary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: MausamPalette.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.condition,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: MausamPalette.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${item.tempCelsius}°',
              style: GoogleFonts.inter(
                color: MausamPalette.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                fontFeatures: MausamTypography.tabularFeatures,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 3: Today's Packing List
  // ---------------------------------------------------------------------------
  Widget _buildPackingListCard(String locationName, int rainProb, double uv) {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MausamPalette.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MausamPalette.cardBorder),
        boxShadow: MausamPalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'For $locationName · $dateStr',
            style: GoogleFonts.inter(
              color: MausamPalette.textTertiary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          _packingItemRow(
            icon: Icons.umbrella_rounded,
            title: 'Umbrella / rain protection',
            subtitle: '$rainProb% rain chance',
            iconColor: const Color(0xFFA5B4FC),
            iconBg: const Color(0xFF6366F1).withValues(alpha: 0.15),
          ),
          const SizedBox(height: 12),
          _packingItemRow(
            icon: Icons.hiking_rounded,
            title: 'Waterproof footwear',
            subtitle: 'High rain chance today',
            iconColor: const Color(0xFFC084FC),
            iconBg: const Color(0xFFA855F7).withValues(alpha: 0.15),
          ),
          if (uv >= 6.0) ...[
            const SizedBox(height: 12),
            _packingItemRow(
              icon: Icons.wb_sunny_outlined,
              title: 'UV Sunglasses & Sunscreen',
              subtitle: 'UV index at ${uv.toStringAsFixed(1)} (Midday peak)',
              iconColor: const Color(0xFFFDE047),
              iconBg: const Color(0xFFEAB308).withValues(alpha: 0.15),
            ),
          ],
        ],
      ),
    );
  }

  Widget _packingItemRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: MausamPalette.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1.5),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: MausamPalette.textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 4: Event Planner (Weekend Outlook)
  // ---------------------------------------------------------------------------
  Widget _buildEventPlannerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MausamPalette.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MausamPalette.cardBorder),
        boxShadow: MausamPalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.wb_cloudy_rounded, color: Color(0xFFFBBF24), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekend Outdoor Weather Outlook',
                      style: GoogleFonts.inter(
                        color: MausamPalette.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '12 Sept–13 Sept · Starts in 6 days',
                      style: GoogleFonts.inter(
                        color: MausamPalette.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Expected',
                    style: GoogleFonts.inter(color: MausamPalette.textTertiary, fontSize: 9.5),
                  ),
                  Text(
                    'Monsoon',
                    style: GoogleFonts.inter(
                      color: MausamPalette.textPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '33°C avg',
                      style: GoogleFonts.inter(
                        color: MausamPalette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFeatures: MausamTypography.tabularFeatures,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Expected temp',
                      style: GoogleFonts.inter(
                        color: MausamPalette.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Moderate Rain',
                      style: GoogleFonts.inter(
                        color: MausamPalette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '~50% chance',
                      style: GoogleFonts.inter(
                        color: MausamPalette.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: MausamPalette.cardBorderSubtle, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFBBF24), size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Some rain possible — keep an eye on the forecast closer to the date.',
                  style: GoogleFonts.inter(
                    color: MausamPalette.textSecondary,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Alert Computation Helper
  // ---------------------------------------------------------------------------
  List<_AlertItem> _computeActiveAlerts(dynamic data) {
    if (data == null) return [];
    final List<_AlertItem> items = [];
    final current = data.current;
    final temp = current.temperatureCelsius;
    final precip = current.rainMm1h ?? 0.0;
    final cond = (current.condition ?? '').toLowerCase();
    final aqi = data.aqi?.aqiValue ?? 0;

    if (precip >= 3.0 || cond.contains('thunder') || cond.contains('heavy rain') || cond.contains('monsoon')) {
      items.add(_AlertItem(
        title: 'Heavy Rainfall Warning',
        description: 'Rain chance is 78%. Allow extra travel time and avoid underpasses.',
        badgeLabel: 'ORANGE ALERT · Mausam Weather Advisory',
        icon: Icons.thunderstorm_rounded,
        dotColor: const Color(0xFFF97316),
        badgeColor: const Color(0xFFF97316),
      ));
    }

    if (temp >= 36) {
      items.add(_AlertItem(
        title: 'Extreme Heat Warning',
        description: 'Temperatures reaching ${temp.round()}°C. Stay hydrated and avoid peak midday sun.',
        badgeLabel: 'RED ALERT · Extreme Heat Advisory',
        icon: Icons.thermostat_rounded,
        dotColor: const Color(0xFFEF4444),
        badgeColor: const Color(0xFFEF4444),
      ));
    } else if (temp >= 32) {
      items.add(_AlertItem(
        title: 'Elevated Heat Caution',
        description: 'Temperature of ${temp.round()}°C. Maintain hydration during outdoor transit.',
        badgeLabel: 'YELLOW CAUTION · Heat Index',
        icon: Icons.wb_sunny_rounded,
        dotColor: const Color(0xFFFBBF24),
        badgeColor: const Color(0xFFFBBF24),
      ));
    }

    if (aqi >= 150) {
      items.add(_AlertItem(
        title: 'Unhealthy Air Quality Alert',
        description: 'AQI at $aqi (${data.aqi?.category}). Wear a protective mask during commutes.',
        badgeLabel: 'PURPLE ALERT · Air Quality Advisory',
        icon: Icons.air_rounded,
        dotColor: const Color(0xFFA855F7),
        badgeColor: const Color(0xFFA855F7),
      ));
    }

    return items;
  }
}

class _AlertItem {
  final String title;
  final String description;
  final String badgeLabel;
  final IconData icon;
  final Color dotColor;
  final Color badgeColor;

  _AlertItem({
    required this.title,
    required this.description,
    required this.badgeLabel,
    required this.icon,
    required this.dotColor,
    required this.badgeColor,
  });
}

class _SavedLocationCardData {
  final String name;
  final String condition;
  final int tempCelsius;
  final int distanceKm;
  final IconData icon;
  final double latitude;
  final double longitude;

  const _SavedLocationCardData({
    required this.name,
    required this.condition,
    required this.tempCelsius,
    required this.distanceKm,
    required this.icon,
    required this.latitude,
    required this.longitude,
  });
}
