import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/location_provider.dart';
import '../providers/weather_dashboard_provider.dart';
import '../theme/weather_palette.dart';
import '../widgets/staggered_item_wrapper.dart';
import '../widgets/weather/weather_sections.dart';

class ForecastScreen extends ConsumerWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherDash = ref.watch(weatherDashboardProvider);
    final locState = ref.watch(locationProvider);
    final data = weatherDash.data;

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
        title: Text(
          'DETAILED FORECAST',
          style: GoogleFonts.inter(
            color: MausamPalette.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: MausamPalette.textPrimary),
            onPressed: () => context.push('/profile'),
          ),
          const SizedBox(width: 4),
        ],
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
                    const Icon(Icons.location_on_outlined, color: MausamPalette.accentBlue, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      locState.cityName.isNotEmpty ? locState.cityName : (data?.current.location ?? 'Active Area'),
                      style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    if (data != null)
                      Text(
                        '${data.current.temperatureCelsius.round()}°C • ${data.current.condition}',
                        style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 12),
                      ),
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: MausamPalette.accentBlue, strokeWidth: 2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
