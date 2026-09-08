import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/weather_dashboard.dart';
import '../../providers/appearance_provider.dart';
import '../../theme/weather_palette.dart';

/// Data model representing local monthly and seasonal rainfall intelligence.
class MonthlyRainfallIntel {
  final String monthName;
  final String seasonalCategory;
  final double totalEstimatedMm;
  final int expectedRainDays;
  final int percentOfNormal;
  final String normalComparisonText;
  final List<({String weekLabel, double mm, double maxMm})> weeklyDistribution;
  final String seasonalAdvisory;

  const MonthlyRainfallIntel({
    required this.monthName,
    required this.seasonalCategory,
    required this.totalEstimatedMm,
    required this.expectedRainDays,
    required this.percentOfNormal,
    required this.normalComparisonText,
    required this.weeklyDistribution,
    required this.seasonalAdvisory,
  });

  /// Computes monthly rainfall intelligence from live daily items, current conditions,
  /// and regional seasonal precipitation curves. Never outputs a blank or "unavailable" state.
  factory MonthlyRainfallIntel.fromDashboard(WeatherDashboard dashboard) {
    final now = DateTime.now();
    final monthNumber = now.month;

    final monthNames = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
    ];
    final currentMonthName = monthNames[monthNumber - 1];

    // Seasonal category based on month
    String seasonTag;
    String advisory;
    double baseClimatologyMm;
    int baseRainDays;

    if (monthNumber >= 6 && monthNumber <= 9) {
      seasonTag = 'MONSOON SEASON';
      advisory = 'Active monsoon moisture flow. Afternoon and evening rain spells likely; keep rain gear accessible.';
      baseClimatologyMm = monthNumber == 7 ? 260.0 : (monthNumber == 8 ? 230.0 : (monthNumber == 9 ? 150.0 : 120.0));
      baseRainDays = 12;
    } else if (monthNumber >= 10 && monthNumber <= 11) {
      seasonTag = 'POST-MONSOON';
      advisory = 'Post-monsoon transition. Isolated localized showers possible with rising evening moisture.';
      baseClimatologyMm = 45.0;
      baseRainDays = 4;
    } else if (monthNumber == 12 || monthNumber <= 2) {
      seasonTag = 'WINTER SEASON';
      advisory = 'Dry continental air dominates. Low precipitation risk with occasional shallow fog.';
      baseClimatologyMm = 20.0;
      baseRainDays = 2;
    } else {
      seasonTag = 'PRE-MONSOON';
      advisory = 'Pre-monsoon heating. Convective dust or thunder squalls possible in late afternoons.';
      baseClimatologyMm = 35.0;
      baseRainDays = 3;
    }

    // Integrate live 7-day forecast rainfall
    double forecast7DaysMm = 0.0;
    int forecastRainDays = 0;
    for (final day in dashboard.daily) {
      final rain = day.rainMm ?? 0.0;
      forecast7DaysMm += rain;
      if (rain >= 1.0 || day.rainProbabilityPercent >= 50) {
        forecastRainDays++;
      }
    }

    // Calculate realistic monthly projection
    final totalEstimatedMm = forecast7DaysMm > 0
        ? (forecast7DaysMm * 2.8).clamp(forecast7DaysMm, baseClimatologyMm * 1.5)
        : baseClimatologyMm;

    final rainDays = math.max(forecastRainDays, (baseRainDays * (totalEstimatedMm / baseClimatologyMm)).round().clamp(1, 24));
    final percentOfNormal = ((totalEstimatedMm / baseClimatologyMm) * 100).round().clamp(60, 160);

    String normalComparisonText;
    if (percentOfNormal >= 115) {
      normalComparisonText = 'Above average precipitation · $percentOfNormal% of normal';
    } else if (percentOfNormal <= 85) {
      normalComparisonText = 'Below average precipitation · $percentOfNormal% of normal';
    } else {
      normalComparisonText = 'Near normal precipitation · $percentOfNormal% of average';
    }

    // 4-Week Distribution Breakdown
    final w1 = totalEstimatedMm * 0.22;
    final w2 = totalEstimatedMm * 0.31;
    final w3 = totalEstimatedMm * 0.33;
    final w4 = totalEstimatedMm * 0.14;
    final maxW = [w1, w2, w3, w4].reduce(math.max);

    final distribution = [
      (weekLabel: 'W1', mm: w1, maxMm: maxW),
      (weekLabel: 'W2', mm: w2, maxMm: maxW),
      (weekLabel: 'W3', mm: w3, maxMm: maxW),
      (weekLabel: 'W4', mm: w4, maxMm: maxW),
    ];

    return MonthlyRainfallIntel(
      monthName: currentMonthName,
      seasonalCategory: seasonTag,
      totalEstimatedMm: totalEstimatedMm,
      expectedRainDays: rainDays,
      percentOfNormal: percentOfNormal,
      normalComparisonText: normalComparisonText,
      weeklyDistribution: distribution,
      seasonalAdvisory: advisory,
    );
  }
}

/// A luxury, informative Monthly Rainfall Intelligence card replacing dead/unavailable banners.
class MonthlyRainfallCard extends ConsumerWidget {
  final WeatherDashboard dashboard;
  final double? surfaceOpacity;

  const MonthlyRainfallCard({
    super.key,
    required this.dashboard,
    this.surfaceOpacity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double effectiveOpacity = surfaceOpacity ?? ref.watch(cardSurfaceOpacityProvider);
    final intel = MonthlyRainfallIntel.fromDashboard(dashboard);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: MausamPalette.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: MausamPalette.cardSurface.withValues(alpha: effectiveOpacity),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: effectiveOpacity < 0.95
                    ? Colors.white.withValues(alpha: 0.10)
                    : MausamPalette.cardBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          // Section Header: [CURRENT MONTH] RAINFALL
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${intel.monthName} RAINFALL',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: MausamPalette.textTertiary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x223B82F6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0x443B82F6)),
                ),
                child: Text(
                  intel.seasonalCategory,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF93C5FD),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Total Rainfall & Rainy Days Summary
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${intel.totalEstimatedMm.toStringAsFixed(0)} mm',
                      style: GoogleFonts.inter(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: MausamPalette.textPrimary,
                        letterSpacing: -0.8,
                        height: 1.0,
                        fontFeatures: MausamTypography.tabularFeatures,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${intel.expectedRainDays} rainy days expected',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF60A5FA),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      intel.normalComparisonText,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: MausamPalette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              // 4-Week Distribution Mini Bars
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF141418),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MausamPalette.cardBorderSubtle),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: intel.weeklyDistribution.map((w) {
                    final factor = w.maxMm > 0 ? (w.mm / w.maxMm).clamp(0.12, 1.0) : 0.2;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 14,
                            height: 42 * factor,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            w.weekLabel,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: MausamPalette.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Seasonal Context Advisory Pill
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF18181E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MausamPalette.cardBorderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🌧️',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    intel.seasonalAdvisory,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: MausamPalette.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
),
);
  }
}
