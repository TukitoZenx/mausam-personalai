import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/weather_dashboard.dart';
import '../../providers/appearance_provider.dart';
import '../../theme/weather_palette.dart';
import 'weather_glyphs.dart';

/// A luxury, pixel-perfect Sun & Moon visualization card matching the reference design:
/// - Top dual highlight cards for Sunrise & Sunset with large bold typography and badges.
/// - Parabolic solar trajectory arc with moving sun orb, solar noon apex label, and start/end anchors.
/// - Bottom triplet cards: Moon Phase, Golden Hour (featured with progress slider), and Moonrise.
class SunMoonCard extends ConsumerWidget {
  final CurrentConditions current;
  final DailyForecastItem? today;
  final double? surfaceOpacity;

  const SunMoonCard({
    super.key,
    required this.current,
    this.today,
    this.surfaceOpacity,
  });

  static String _fmt12h(int? unix, int? offsetSec, {String fallback = '--'}) {
    if (unix == null) return fallback;
    final dt = DateTime.fromMillisecondsSinceEpoch(unix * 1000, isUtc: true)
        .add(Duration(seconds: offsetSec ?? 0));
    final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'am' : 'pm';
    return '$h12:$m $ampm';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double effectiveOpacity = surfaceOpacity ?? ref.watch(cardSurfaceOpacityProvider);
    final riseUnix = current.sunriseUnix;
    final setUnix = current.sunsetUnix;
    final offsetSec = current.timezoneOffsetSec;
    final nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Solar progress t from 0.0 (sunrise) to 1.0 (sunset)
    double t = 0.5;
    if (riseUnix != null && setUnix != null && setUnix > riseUnix) {
      t = ((nowUnix - riseUnix) / (setUnix - riseUnix)).clamp(0.0, 1.0);
    }

    final sunriseStr = _fmt12h(riseUnix, offsetSec, fallback: '5:55 am');
    final sunsetStr = _fmt12h(setUnix, offsetSec, fallback: '6:15 pm');

    // Solar noon apex (exact midpoint between sunrise and sunset)
    final solarNoonUnix = (riseUnix != null && setUnix != null)
        ? ((riseUnix + setUnix) ~/ 2)
        : null;
    final solarNoonStr = _fmt12h(solarNoonUnix, offsetSec, fallback: '12:07 pm');

    // Golden hour: ~50 minutes before sunset
    final goldenUnix = setUnix != null ? (setUnix - 50 * 60) : null;
    final goldenStr = _fmt12h(goldenUnix, offsetSec, fallback: '5:48 pm');

    // Golden hour progress (how close or active)
    double goldenProgress = 0.65;
    if (setUnix != null && goldenUnix != null) {
      if (nowUnix < goldenUnix) {
        // Approaching golden hour
        goldenProgress = 0.35;
      } else if (nowUnix <= setUnix) {
        // Inside golden hour window
        goldenProgress = ((nowUnix - goldenUnix) / (setUnix - goldenUnix)).clamp(0.0, 1.0);
      } else {
        // Past golden hour
        goldenProgress = 1.0;
      }
    }

    // Moon phase
    final phaseValue = today?.moonPhase ?? 0.78; // Default waning crescent
    final phaseName = moonPhaseName(phaseValue);

    // Moonrise
    final moonriseUnix = today?.moonriseUnix;
    final moonriseStr = _fmt12h(moonriseUnix, offsetSec, fallback: '4:04 am');

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
          // Section Header: SUN & MOON
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'SUN & MOON',
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
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: MausamPalette.cardBorderSubtle),
                  ),
                  child: Text(
                    'ASTRONOMICAL RADAR',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: MausamPalette.textTertiary,
                      fontSize: 9.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Top Dual Highlight Cards: Sunrise & Sunset
          Row(
            children: [
              Expanded(
                child: _buildHighlightCard(
                  icon: Icons.wb_sunny_rounded,
                  iconBgColor: const Color(0x22FBBF24),
                  iconColor: const Color(0xFFFBBF24),
                  time: sunriseStr,
                  label: 'Sunrise',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHighlightCard(
                  icon: Icons.wb_twilight_rounded,
                  iconBgColor: const Color(0x22F97316),
                  iconColor: const Color(0xFFF97316),
                  time: sunsetStr,
                  label: 'Sunset',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Center Solar Trajectory Arc & Solar Noon Indicator
          SizedBox(
            height: 115,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SolarTrajectoryArcPainter(t: t),
                  ),
                ),
                // Left Start Time Label
                Positioned(
                  left: 6,
                  bottom: 2,
                  child: Text(
                    sunriseStr,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: MausamPalette.textTertiary,
                    ),
                  ),
                ),
                // Right End Time Label
                Positioned(
                  right: 6,
                  bottom: 2,
                  child: Text(
                    sunsetStr,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: MausamPalette.textTertiary,
                    ),
                  ),
                ),
                // Center Apex: Solar Noon Label
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 4,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Solar noon · $solarNoonStr',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: MausamPalette.textSecondary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Bottom Triplet Cards: Moon Phase, Golden Hour, Moonrise
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Moon Phase Card
              Expanded(
                child: _buildBottomTile(
                  icon: moonVectorIcon(phaseValue),
                  iconColor: const Color(0xFF93C5FD),
                  value: phaseName,
                  label: 'Moon Phase',
                ),
              ),
              const SizedBox(width: 8),

              // 2. Golden Hour Card (Featured / Highlighted with Gold Border & Slider)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0x18F59E0B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x66F59E0B), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wb_sunny_outlined, size: 16, color: Color(0xFFF59E0B)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            goldenStr,
                            maxLines: 1,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFDE68A),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Golden Hour',
                            maxLines: 1,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Golden Hour Progress Slider
                      Container(
                        height: 3,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0x44D97706),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: goldenProgress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 3. Moonrise Card
              Expanded(
                child: _buildBottomTile(
                  icon: Icons.brightness_3_rounded,
                  iconColor: const Color(0xFFA78BFA),
                  value: moonriseStr,
                  label: 'Moonrise',
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
),
);
  }

  Widget _buildHighlightCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String time,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MausamPalette.cardBorderSubtle),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              time,
              maxLines: 1,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: MausamPalette.textPrimary,
                fontFeatures: MausamTypography.tabularFeatures,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: MausamPalette.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTile({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MausamPalette.cardBorderSubtle),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: MausamPalette.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: MausamPalette.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: 9), // Align height with the golden hour progress bar
        ],
      ),
    );
  }
}

/// Custom painter rendering the parabolic solar trajectory arc with dashed curve
/// and radiant sun orb at current solar progress [t].
class _SolarTrajectoryArcPainter extends CustomPainter {
  final double t;

  _SolarTrajectoryArcPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    const startX = 24.0;
    final endX = size.width - 24.0;
    final baselineY = size.height - 24.0;
    const apexY = 16.0;
    final controlX = size.width / 2;

    // Draw dashed quadratic Bezier curve
    final dashedPaint = Paint()
      ..color = const Color(0x66D4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    const dashCount = 38;
    for (int i = 0; i < dashCount; i += 2) {
      final t0 = i / dashCount;
      final t1 = (i + 1) / dashCount;

      final p0 = _evalBezier(t0, startX, baselineY, controlX, apexY, endX, baselineY);
      final p1 = _evalBezier(t1, startX, baselineY, controlX, apexY, endX, baselineY);

      canvas.drawLine(p0, p1, dashedPaint);
    }

    // Evaluate sun position along arc
    final sunPos = _evalBezier(t.clamp(0.0, 1.0), startX, baselineY, controlX, apexY, endX, baselineY);

    // Glowing atmospheric aura around sun
    final auraPaint = Paint()
      ..color = const Color(0x33FBBF24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(sunPos, 14, auraPaint);

    // Secondary golden halo
    canvas.drawCircle(
      sunPos,
      10,
      Paint()..color = const Color(0x66FDE68A),
    );

    // Core vibrant Sun disk
    canvas.drawCircle(
      sunPos,
      6.5,
      Paint()..color = const Color(0xFFFBBF24),
    );
  }

  Offset _evalBezier(
    double u,
    double x0,
    double y0,
    double cx,
    double cy,
    double x1,
    double y1,
  ) {
    final inv = 1.0 - u;
    final x = inv * inv * x0 + 2 * inv * u * cx + u * u * x1;
    final y = inv * inv * y0 + 2 * inv * u * cy + u * u * y1;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant _SolarTrajectoryArcPainter oldDelegate) => oldDelegate.t != t;
}
