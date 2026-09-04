import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/location_provider.dart';
import '../providers/weather_dashboard_provider.dart';
import '../theme/weather_palette.dart';
import '../widgets/navigation/shell_section_title.dart';
import '../widgets/staggered_item_wrapper.dart';
import '../widgets/weather/weather_sections.dart';

class ForecastScreen extends ConsumerWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherDash = ref.watch(weatherDashboardProvider);
    final locState = ref.watch(locationProvider);
    final data = weatherDash.data;

    return RefreshIndicator(
      color: MausamPalette.textPrimary,
      backgroundColor: MausamPalette.cardSurface,
      onRefresh: () async {
        await ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 72, 16, 32),
        children: [
          const ShellSectionTitle('DETAILED FORECAST'),
          // Active Location Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: MausamPalette.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MausamPalette.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: MausamPalette.textSecondary, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        locState.cityName.isNotEmpty ? locState.cityName : (data?.current.location ?? 'Active Area'),
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (data != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${data.current.temperatureCelsius.round()}°C • ${data.current.condition}',
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (data != null) ...[
                // Hourly Forecast Timeline
                StaggeredItemWrapper(
                  index: 0,
                  child: HourlyForecastStrip(
                    hourly: data.hourly,
                  ),
                ),

                const SizedBox(height: 14),

                // 7-Day Forecast Panel
                StaggeredItemWrapper(
                  index: 1,
                  child: DailyForecastPanel(
                    days: data.daily,
                    initiallyExpanded: true,
                  ),
                ),

                const SizedBox(height: 14),

                // Sun & Moon Solar Cycle
                StaggeredItemWrapper(
                  index: 2,
                  child: SunMoonCard(
                    current: data.current,
                    today: data.daily.isEmpty ? null : data.daily.first,
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Text(
                    weatherDash.isLoading
                        ? 'Updating forecast…'
                        : 'Forecast will appear here once weather is ready.',
                    style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
    );
  }
}
