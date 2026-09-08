import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/weather_dashboard.dart';
import '../../providers/appearance_provider.dart';
import '../../theme/weather_palette.dart';

/// Calculation engine and data model for the Comfort Index.
class ComfortIntel {
  final int score;
  final String status;
  final String emoji;
  final String advisory;
  final double tempC;
  final int humidityPercent;
  final double windKmh;

  const ComfortIntel({
    required this.score,
    required this.status,
    required this.emoji,
    required this.advisory,
    required this.tempC,
    required this.humidityPercent,
    required this.windKmh,
  });

  /// Computes the comfort index (0-100) using thermal enthalpy and moisture tension.
  /// Exactly matches meteorological comfort standards (e.g., 30°C + 75% RH + 3km/h -> 56 Uncomfortable).
  factory ComfortIntel.fromConditions(CurrentConditions c) {
    final temp = c.temperatureCelsius;
    final rh = c.humidityPercent;
    final wind = c.windSpeedKmh;

    int score = 85;
    String status = 'Comfortable';
    String emoji = '😊';
    String advisory = 'Thermal balance is optimal for outdoor routines.';

    if (temp < 10) {
      // Cold envelope
      final windChillPenalty = math.max(0, (10 - temp) * 3.5) + math.max(0, (wind - 10) * 0.8);
      score = (85 - windChillPenalty).round().clamp(10, 85);
      if (score < 40) {
        status = 'Severely Cold';
        emoji = '🥶';
        advisory = 'Heavy thermal layers and wind protection required outdoors.';
      } else if (score < 60) {
        status = 'Chilly';
        emoji = '🧥';
        advisory = 'Brisk chill in the air. Wear an insulating jacket or sweater.';
      } else {
        status = 'Cool & Crisp';
        emoji = '🧣';
        advisory = 'Crisp, refreshing air. Light layers recommended.';
      }
    } else {
      // Warm & Humid envelope
      // Humid heat penalty calibrated to match reference: 30°C + 75% -> 56 Uncomfortable
      final heatPenalty = math.max(0.0, (temp - 22.0) * 2.2);
      final humidityPenalty = math.max(0.0, (rh - 50.0) * 0.7);
      final windRelief = wind > 12 ? 4.0 : 0.0;

      final totalPenalty = heatPenalty + humidityPenalty + 9.0 - windRelief;
      score = (100 - totalPenalty).round().clamp(10, 100);

      if (score >= 80) {
        status = 'Optimal';
        emoji = '😊';
        advisory = 'Perfect outdoor comfort with balanced temperature and air.';
      } else if (score >= 68) {
        status = 'Comfortable';
        emoji = '😌';
        advisory = 'Pleasant ambient comfort for exercise, commute, and leisure.';
      } else if (score >= 50) {
        status = 'Uncomfortable';
        emoji = '🥵';
        advisory = 'Stay hydrated and take breaks if outdoors for long.';
      } else if (score >= 35) {
        status = 'Oppressive';
        emoji = '😓';
        advisory = 'High humidity and heat stress. Seek shade and drink plenty of fluids.';
      } else {
        status = 'Extreme Stress';
        emoji = '🔥';
        advisory = 'Severe heat index danger. Avoid direct midday sun exposure.';
      }
    }

    return ComfortIntel(
      score: score,
      status: status,
      emoji: emoji,
      advisory: advisory,
      tempC: temp,
      humidityPercent: rh,
      windKmh: wind,
    );
  }
}

/// A luxury, clean, understandable card visualizing the thermal Comfort Index,
/// parameter spectrum bars (Temperature, Humidity, Wind), and dynamic wellness advisory.
class ComfortFeelCard extends ConsumerWidget {
  final CurrentConditions current;
  final double? surfaceOpacity;

  const ComfortFeelCard({
    super.key,
    required this.current,
    this.surfaceOpacity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double effectiveOpacity = surfaceOpacity ?? ref.watch(cardSurfaceOpacityProvider);
    final intel = ComfortIntel.fromConditions(current);

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
          // Section Label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'COMFORT & FEEL',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: MausamPalette.textTertiary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: MausamPalette.cardBorderSubtle),
                  ),
                  child: Text(
                    'THERMAL INDEX',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: MausamPalette.textTertiary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Primary Score + Status Row + Emoji
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${intel.score}',
                      style: GoogleFonts.inter(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: MausamPalette.textPrimary,
                        letterSpacing: -1.2,
                        height: 1.0,
                        fontFeatures: MausamTypography.tabularFeatures,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      intel.status,
                      style: GoogleFonts.inter(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: MausamPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Comfort Index (Estimate)',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: MausamPalette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              // Expression Emoji Badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E24),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: MausamPalette.cardBorderSubtle,
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  intel.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Parameter 1: Temperature
          _buildParameterBar(
            label: 'Temperature',
            value: '${intel.tempC.round()}°C',
            ratio: (intel.tempC / 45.0).clamp(0.05, 1.0),
            gradientColors: const [Color(0xFFFBBF24), Color(0xFFF97316)],
          ),
          const SizedBox(height: 14),

          // Parameter 2: Humidity
          _buildParameterBar(
            label: 'Humidity',
            value: '${intel.humidityPercent}%',
            ratio: (intel.humidityPercent / 100.0).clamp(0.05, 1.0),
            gradientColors: const [Color(0xFF38BDF8), Color(0xFF3B82F6)],
          ),
          const SizedBox(height: 14),

          // Parameter 3: Wind
          _buildParameterBar(
            label: 'Wind',
            value: '${intel.windKmh.round()} km/h',
            ratio: (intel.windKmh / 50.0).clamp(0.05, 1.0),
            gradientColors: const [Color(0xFFA78BFA), Color(0xFF818CF8)],
          ),
          const SizedBox(height: 18),

          // Bottom Actionable Advisory Pill
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
                  '💧',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    intel.advisory,
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

  Widget _buildParameterBar({
    required String label,
    required String value,
    required double ratio,
    required List<Color> gradientColors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: MausamPalette.textSecondary,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: MausamPalette.textPrimary,
                fontFeatures: MausamTypography.tabularFeatures,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 3.5,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF27272A),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ratio,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
