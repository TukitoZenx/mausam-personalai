import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/location_provider.dart';
import '../providers/weather_dashboard_provider.dart';
import '../theme/weather_palette.dart';
import '../widgets/app_drawer.dart';
import '../widgets/weather/location_switcher_sheet.dart';
import '../widgets/weather/weather_sections.dart';

class ForecastScreen extends ConsumerWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locState = ref.watch(locationProvider);
    final dash = ref.watch(weatherDashboardProvider);
    final data = dash.data;

    return Scaffold(
      backgroundColor: MausamPalette.bgPrimary,
      drawer: const AppDrawer(currentRoute: '/forecast'),
      appBar: AppBar(
        backgroundColor: MausamPalette.bgDeep,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: MausamPalette.textPrimary, size: 24),
            tooltip: 'Open navigation',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: GestureDetector(
          onTap: () => showLocationSwitcherSheet(context: context, ref: ref),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  locState.cityName.isNotEmpty ? locState.cityName : 'Forecast',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: MausamPalette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, color: MausamPalette.textSecondary),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Saved Locations',
            icon: const Icon(Icons.location_city_rounded, color: MausamPalette.textSecondary),
            onPressed: () => showLocationSwitcherSheet(context: context, ref: ref),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: MausamPalette.accentBlue,
          backgroundColor: MausamPalette.cardSurface,
          onRefresh: () => ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
            children: [
              Text(
                '7-Day Extended Forecast',
                style: GoogleFonts.inter(
                  color: MausamPalette.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              if (dash.isLoading && data == null)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: CircularProgressIndicator(color: MausamPalette.accentBlue),
                  ),
                )
              else if (dash.errorMessage != null && data == null)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Text(
                        'Could not load weather forecast.\n${dash.errorMessage}',
                        style: GoogleFonts.inter(color: MausamPalette.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MausamPalette.accentBlue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (data != null) ...[
                HourlyForecastStrip(hourly: data.hourly),
                const SizedBox(height: 14),
                DailyForecastPanel(days: data.daily, initiallyExpanded: true),
                const SizedBox(height: 14),
                SunMoonCard(
                  current: data.current,
                  today: data.daily.isEmpty ? null : data.daily.first,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
