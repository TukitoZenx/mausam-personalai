import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/location_provider.dart';
import '../providers/weather_dashboard_provider.dart';
import '../theme/weather_palette.dart';
import '../widgets/navigation/shell_section_title.dart';
import '../widgets/staggered_item_wrapper.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherDash = ref.watch(weatherDashboardProvider);
    final locState = ref.watch(locationProvider);
    final data = weatherDash.data;

    final alerts = _computeActiveAlerts(data);

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
          const ShellSectionTitle('WEATHER ALERTS'),
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
                    Expanded(
                      child: Text(
                        locState.cityName.isNotEmpty ? locState.cityName : (data?.current.location ?? 'Current Area'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${alerts.length} Active',
                      style: GoogleFonts.inter(
                        color: MausamPalette.textSecondary,
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
                      const Icon(Icons.check_circle_outline_rounded, color: MausamPalette.textSecondary, size: 44),
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
                          color: MausamPalette.cardBorder,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: MausamPalette.cardSurfaceLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              alerts[i].icon,
                              color: MausamPalette.textPrimary,
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
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: MausamPalette.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      alerts[i].severityLabel,
                                      style: GoogleFonts.inter(
                                        color: MausamPalette.textSecondary,
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
    );
  }

  List<_AlertItem> _computeActiveAlerts(data) {
    if (data == null) return [];
    final List<_AlertItem> items = [];
    final current = data.current;
    final temp = current.temperatureCelsius;
    final precip = current.rainMm1h ?? 0.0;
    final cond = (current.condition ?? '').toLowerCase();
    final uv = current.uvIndex ?? 0.0;
    final aqi = data.aqi?.aqiValue ?? 0;
    final wind = current.windSpeedKmh;

    if (temp >= 36) {
      items.add(_AlertItem(
        title: 'Extreme Heat Warning',
        description: 'Temperatures reaching ${temp.round()}°C. Stay hydrated and avoid peak sun exposure.',
        icon: Icons.thermostat_rounded,
        severityLabel: 'EXTREME',
        isSevere: true,
      ));
    } else if (temp >= 30) {
      items.add(_AlertItem(
        title: 'Elevated Heat Caution',
        description: 'High temperature of ${temp.round()}°C. Drink extra fluids during outdoor activities.',
        icon: Icons.wb_sunny_rounded,
        severityLabel: 'MODERATE',
        isSevere: false,
      ));
    }

    if (precip >= 5.0 || cond.contains('thunder') || cond.contains('heavy rain')) {
      items.add(_AlertItem(
        title: 'Heavy Rainfall Warning',
        description: 'Active rainfall detected (${precip > 0 ? precip.toStringAsFixed(1) : "5.0"} mm/h). Exercise caution during travel.',
        icon: Icons.thunderstorm_rounded,
        severityLabel: 'HIGH',
        isSevere: true,
      ));
    } else if (precip > 0.0 || cond.contains('rain') || cond.contains('drizzle') || cond.contains('shower')) {
      items.add(_AlertItem(
        title: 'Precipitation Advisory',
        description: '${current.condition ?? "Rain"} reported in your area. Carry an umbrella if heading outside.',
        icon: Icons.water_drop_rounded,
        severityLabel: 'MODERATE',
        isSevere: false,
      ));
    }

    if (aqi >= 200) {
      items.add(_AlertItem(
        title: 'Severe Air Quality Alert',
        description: 'AQI at $aqi (${data.aqi?.category}). Limit outdoor exertion and wear an N95 mask.',
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
    } else if (aqi >= 50) {
      items.add(_AlertItem(
        title: 'Moderate AQI Advisory',
        description: 'AQI at $aqi (${data.aqi?.category}). Generally acceptable air quality.',
        icon: Icons.air_rounded,
        severityLabel: 'INFO',
        isSevere: false,
      ));
    }

    if (wind >= 25.0) {
      items.add(_AlertItem(
        title: 'Gusty Wind Advisory',
        description: 'Wind speed reaching ${wind.round()} km/h. Take care during outdoor activities.',
        icon: Icons.air_rounded,
        severityLabel: 'MODERATE',
        isSevere: false,
      ));
    }

    if (uv >= 6.0) {
      items.add(_AlertItem(
        title: 'High UV Index Warning',
        description: 'UV Index at ${uv.toStringAsFixed(1)}. Sun protection (SPF 30+ & sunglasses) recommended.',
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
