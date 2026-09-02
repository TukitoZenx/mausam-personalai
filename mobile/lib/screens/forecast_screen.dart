import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/location_provider.dart';
import '../providers/weather_dashboard_provider.dart';
import '../theme/weather_palette.dart';
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
      backgroundColor: WeatherPalette.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: WeatherPalette.sky,
          backgroundColor: WeatherPalette.card,
          onRefresh: () => ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => showLocationSwitcherSheet(context: context, ref: ref),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              locState.cityName,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('forecast_location_search_button'),
                    tooltip: 'Saved locations',
                    onPressed: () => showLocationSwitcherSheet(context: context, ref: ref),
                    icon: const Icon(Icons.search_rounded, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Forecast', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              if (dash.isLoading && data == null)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator(color: WeatherPalette.sky)),
                )
              else if (data != null) ...[
                HourlyForecastStrip(hourly: data.hourly),
                DailyForecastPanel(days: data.daily, initiallyExpanded: true),
                SunMoonCard(
                  current: data.current,
                  today: data.daily.isEmpty ? null : data.daily.first,
                ),
              ] else
                Text(
                  dash.errorMessage ?? 'Forecast will appear after live weather loads.',
                  style: GoogleFonts.inter(color: Colors.white70),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
