import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/activity_recommendation_engine.dart';
import '../../theme/weather_palette.dart';

/// Compact weather intelligence card displaying tomorrow's personalized activity window.
class RoutineRecommendationCard extends StatelessWidget {
  final ActivityRecommendation recommendation;

  const RoutineRecommendationCard({
    super.key,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    final actUpper = recommendation.activity.toUpperCase();
    final headerTitle = "TOMORROW'S BEST $actUpper WINDOW";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141722),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF262E40),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Label
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                headerTitle,
                style: GoogleFonts.inter(
                  color: const Color(0xFF10B981),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Recommended Time Window
          Text(
            recommendation.recommendedWindow,
            style: GoogleFonts.inter(
              color: MausamPalette.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Compact Metrics Row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MetricPill(
                icon: Icons.thermostat_rounded,
                text: '${recommendation.temperatureCelsius}°',
              ),
              _MetricPill(
                icon: Icons.air_rounded,
                text: 'AQI ${recommendation.aqiValue} · ${recommendation.aqiCategory}',
              ),
              _MetricPill(
                icon: Icons.water_drop_outlined,
                text: recommendation.rainRiskLabel,
              ),
              _MetricPill(
                icon: Icons.wind_power_rounded,
                text: recommendation.windLabel,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // "Why" section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF262E3E)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WHY',
                  style: GoogleFonts.inter(
                    color: MausamPalette.textTertiary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    recommendation.whyReason,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFE4E4E7),
                      fontSize: 12.5,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Alternative Window if condition not ideal
          if (!recommendation.isIdeal && recommendation.alternativeWindow != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E2218),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Alternative window: ${recommendation.alternativeWindow}',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFDE68A),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetricPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1B202D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF283144)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: MausamPalette.textSecondary),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.inter(
              color: const Color(0xFFD4D4D8),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
