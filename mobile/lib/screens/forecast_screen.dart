import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/weather_dashboard.dart';
import '../providers/location_provider.dart';
import '../providers/weather_dashboard_provider.dart';
import '../theme/weather_palette.dart';
import '../widgets/navigation/shell_section_title.dart';
import '../widgets/staggered_item_wrapper.dart';
import '../widgets/weather/weather_glyphs.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 72, 16, 100),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: MausamPalette.cardSurfaceLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'OBSIDIAN RADAR',
                        style: GoogleFonts.inter(
                          color: MausamPalette.textTertiary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
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

                // 7-Day Extended Forecast
                StaggeredItemWrapper(
                  index: 1,
                  child: DailyForecastPanel(
                    days: data.daily,
                    initiallyExpanded: true,
                  ),
                ),

                const SizedBox(height: 14),

                // 1. Sun & Moon Feature Card
                StaggeredItemWrapper(
                  index: 2,
                  child: SunMoonCard(
                    current: data.current,
                    today: data.daily.firstOrNull,
                  ),
                ),

                const SizedBox(height: 14),

                // 2. Comfort & Feel Feature Card
                StaggeredItemWrapper(
                  index: 3,
                  child: ComfortFeelCard(
                    current: data.current,
                  ),
                ),

                const SizedBox(height: 14),

                // 3. Monthly Rainfall Feature Card (replaces unavailable placeholder)
                StaggeredItemWrapper(
                  index: 4,
                  child: MonthlyRainfallCard(
                    dashboard: data,
                  ),
                ),

                const SizedBox(height: 14),

                // Precipitation & Moisture Outlook
                StaggeredItemWrapper(
                  index: 5,
                  child: _PrecipitationOutlookCard(
                    current: data.current,
                    hourly: data.hourly,
                    daily: data.daily,
                  ),
                ),

                const SizedBox(height: 14),

                // Upcoming Weekend Outlook
                StaggeredItemWrapper(
                  index: 6,
                  child: _WeekendOutlookCard(
                    daily: data.daily,
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

class _PrecipitationOutlookCard extends StatelessWidget {
  final CurrentConditions current;
  final List<HourlyForecastItem> hourly;
  final List<DailyForecastItem> daily;

  const _PrecipitationOutlookCard({
    required this.current,
    required this.hourly,
    required this.daily,
  });

  @override
  Widget build(BuildContext context) {
    int maxRainChance = 0;
    String peakHour = '';
    for (final h in hourly.take(12)) {
      if (h.rainProbabilityPercent > maxRainChance) {
        maxRainChance = h.rainProbabilityPercent;
        peakHour = h.hourLabel;
      }
    }

    final totalRainMm = daily.isNotEmpty ? (daily.first.rainMm ?? current.rainMm1h ?? 0.0) : 0.0;

    return Container(
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
              const Icon(Icons.water_drop_rounded, size: 16, color: Color(0xFF60A5FA)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PRECIPITATION & RAIN OUTLOOK',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: MausamPalette.textTertiary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: maxRainChance > 40
                      ? const Color(0x223B82F6)
                      : const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: maxRainChance > 40
                        ? const Color(0x553B82F6)
                        : MausamPalette.cardBorderSubtle,
                  ),
                ),
                child: Text(
                  maxRainChance > 40 ? '$maxRainChance% RAIN CHANCE' : 'LOW PRECIP',
                  style: GoogleFonts.inter(
                    color: maxRainChance > 40 ? const Color(0xFF93C5FD) : MausamPalette.textTertiary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            maxRainChance > 0
                ? 'Peak rain probability reaches $maxRainChance%${peakHour.isNotEmpty ? ' around $peakHour' : ''}.'
                : 'Clear skies expected with zero significant precipitation today.',
            maxLines: 2,
            softWrap: true,
            style: GoogleFonts.inter(
              color: MausamPalette.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metricPill(
                '24H RAINFALL',
                totalRainMm > 0 ? '${totalRainMm.toStringAsFixed(1)} mm' : '0.0 mm',
                Icons.grain_rounded,
              ),
              const SizedBox(width: 8),
              _metricPill(
                'HUMIDITY',
                '${current.humidityPercent}%',
                Icons.water_rounded,
              ),
              const SizedBox(width: 8),
              _metricPill(
                'DEW POINT',
                current.dewPointCelsius != null ? '${current.dewPointCelsius!.round()}°C' : '--',
                Icons.thermostat_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricPill(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF141417),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 11, color: MausamPalette.textTertiary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: MausamPalette.textTertiary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: MausamPalette.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFeatures: MausamTypography.tabularFeatures,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekendOutlookCard extends StatelessWidget {
  final List<DailyForecastItem> daily;

  const _WeekendOutlookCard({required this.daily});

  @override
  Widget build(BuildContext context) {
    // Find upcoming weekend days (Saturday & Sunday)
    final weekendDays = daily.where((d) {
      final name = (d.weekday ?? d.day).toLowerCase();
      return name.contains('sat') || name.contains('sun');
    }).take(2).toList();

    if (weekendDays.isEmpty && daily.length >= 2) {
      // Fallback to next 2 days
      weekendDays.addAll(daily.skip(1).take(2));
    }

    return Container(
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
              const Icon(Icons.weekend_rounded, size: 16, color: Color(0xFFFBBF24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'WEEKEND OUTLOOK',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: MausamPalette.textTertiary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Text(
                'SAT & SUN',
                style: GoogleFonts.inter(
                  color: MausamPalette.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (weekendDays.isNotEmpty)
            Row(
              children: [
                for (int i = 0; i < weekendDays.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141417),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                weekendDays[i].weekday ?? weekendDays[i].day,
                                style: GoogleFonts.inter(
                                  color: MausamPalette.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Icon(
                                weatherGlyph(weekendDays[i].condition, icon: weekendDays[i].conditionIcon),
                                color: weatherGlyphColor(weekendDays[i].condition),
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            weekendDays[i].condition,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: MausamPalette.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '${weekendDays[i].highCelsius.round()}°',
                                style: GoogleFonts.inter(
                                  color: MausamPalette.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${weekendDays[i].lowCelsius.round()}°',
                                style: GoogleFonts.inter(
                                  color: MausamPalette.textTertiary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              if (weekendDays[i].rainProbabilityPercent > 0)
                                Text(
                                  '${weekendDays[i].rainProbabilityPercent}% rain',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF60A5FA),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            )
          else
            Text(
              'Weekend forecast will load with 7-day data.',
              style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 12),
            ),
        ],
      ),
    );
  }
}
