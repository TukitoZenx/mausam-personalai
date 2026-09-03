import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/location_provider.dart';
import '../providers/weather_dashboard_provider.dart';
import '../theme/weather_palette.dart';
import '../widgets/staggered_item_wrapper.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherDash = ref.watch(weatherDashboardProvider);
    final locState = ref.watch(locationProvider);
    final data = weatherDash.data;

    final alerts = _computeActiveAlerts(data);

    return Scaffold(
      backgroundColor: MausamPalette.bgPrimary,
      appBar: AppBar(
        backgroundColor: MausamPalette.bgDeep,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: MausamPalette.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: alerts.isNotEmpty ? MausamPalette.accentAmber : MausamPalette.accentGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'WEATHER ALERTS',
              style: GoogleFonts.inter(
                color: MausamPalette.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: MausamPalette.accentBlue,
          backgroundColor: MausamPalette.cardSurface,
          onRefresh: () async {
            await ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: MausamPalette.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MausamPalette.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: MausamPalette.textTertiary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      locState.cityName.isNotEmpty ? locState.cityName : (data?.current.location ?? 'Current Area'),
                      style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      '${alerts.length} Active',
                      style: GoogleFonts.inter(
                        color: alerts.isNotEmpty ? MausamPalette.accentAmber : MausamPalette.accentGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (alerts.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  decoration: BoxDecoration(
                    color: MausamPalette.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: MausamPalette.cardBorder),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: MausamPalette.accentGreen, size: 44),
                      const SizedBox(height: 16),
                      Text(
                        'No Severe Weather Alerts',
                        style: GoogleFonts.inter(
                          color: MausamPalette.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Current weather and air quality conditions are within normal ranges for your area.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: MausamPalette.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                for (int i = 0; i < alerts.length; i++)
                  StaggeredItemWrapper(
                    index: i,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: MausamPalette.cardSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: alerts[i].isSevere ? MausamPalette.accentRed.withValues(alpha: 0.6) : MausamPalette.cardBorder,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: alerts[i].isSevere
                                  ? MausamPalette.accentRed.withValues(alpha: 0.15)
                                  : MausamPalette.accentAmber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              alerts[i].icon,
                              color: alerts[i].isSevere ? MausamPalette.accentRed : MausamPalette.accentAmber,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        alerts[i].title,
                                        style: GoogleFonts.inter(
                                          color: MausamPalette.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      alerts[i].severityLabel,
                                      style: GoogleFonts.inter(
                                        color: alerts[i].isSevere ? MausamPalette.accentRed : MausamPalette.accentAmber,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  alerts[i].description,
                                  style: GoogleFonts.inter(
                                    color: MausamPalette.textSecondary,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<_AlertItem> _computeActiveAlerts(data) {
    if (data == null) return [];
    final List<_AlertItem> items = [];
    final current = data.current;
    final temp = current.temperatureCelsius;
    final precip = current.rainMm1h ?? 0;
    final uv = current.uvIndex;
    final aqi = data.aqi?.aqiValue ?? 0;

    if (temp >= 38) {
      items.add(_AlertItem(
        title: 'Extreme Heat Warning',
        description: 'Temperatures reaching ${temp.round()}°C. Stay hydrated and avoid outdoor exposure during peak hours.',
        icon: Icons.thermostat_rounded,
        severityLabel: 'EXTREME',
        isSevere: true,
      ));
    } else if (temp >= 33) {
      items.add(_AlertItem(
        title: 'Moderate Heat Advisory',
        description: 'High temperature of ${temp.round()}°C. Keep hydrated during outdoor activities.',
        icon: Icons.wb_sunny_rounded,
        severityLabel: 'MODERATE',
        isSevere: false,
      ));
    }

    if (precip > 5.0) {
      items.add(_AlertItem(
        title: 'Heavy Rainfall Warning',
        description: 'Active rainfall detected (${precip.toStringAsFixed(1)} mm/h). Plan indoor activity and exercise caution during travel.',
        icon: Icons.thunderstorm_rounded,
        severityLabel: 'HIGH',
        isSevere: true,
      ));
    } else if (precip > 0.0) {
      items.add(_AlertItem(
        title: 'Precipitation Advisory',
        description: 'Light rain in your area. Carry an umbrella if heading outside.',
        icon: Icons.water_drop_rounded,
        severityLabel: 'MODERATE',
        isSevere: false,
      ));
    }

    if (aqi >= 200) {
      items.add(_AlertItem(
        title: 'Very Poor Air Quality Alert',
        description: 'AQI at $aqi (${data.aqi?.category}). Limit prolonged outdoor exertion and consider wearing an N95 mask.',
        icon: Icons.air_rounded,
        severityLabel: 'SEVERE',
        isSevere: true,
      ));
    } else if (aqi >= 100) {
      items.add(_AlertItem(
        title: 'Unhealthy AQI Advisory',
        description: 'AQI at $aqi (${data.aqi?.category}). Sensitive individuals should reduce outdoor physical activity.',
        icon: Icons.air_rounded,
        severityLabel: 'MODERATE',
        isSevere: false,
      ));
    }

    if (uv >= 8) {
      items.add(_AlertItem(
        title: 'High UV Index Warning',
        description: 'UV Index at ${uv.toStringAsFixed(1)}. Sun protection (SPF 30+ & sunglasses) strongly recommended.',
        icon: Icons.wb_sunny_outlined,
        severityLabel: 'HIGH',
        isSevere: false,
      ));
    }

    return items;
  }
}

class _AlertItem {
  final String title;
  final String description;
  final IconData icon;
  final String severityLabel;
  final bool isSevere;

  _AlertItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.severityLabel,
    required this.isSevere,
  });
}
