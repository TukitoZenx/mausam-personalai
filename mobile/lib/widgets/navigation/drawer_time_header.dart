import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/environment_theme.dart';
import '../../theme/weather_palette.dart';

class DrawerTimeHeader extends StatefulWidget {
  final String locationName;

  const DrawerTimeHeader({super.key, required this.locationName});

  @override
  State<DrawerTimeHeader> createState() => _DrawerTimeHeaderState();
}

class _DrawerTimeHeaderState extends State<DrawerTimeHeader> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final next = DateTime.now();
      if (next.hour != _now.hour || next.minute != _now.minute) {
        setState(() => _now = next);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final period = EnvironmentTheme.periodForHour(_now.hour);
    final visual = _visualFor(period);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      height: 118,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: visual.gradient,
        ),
      ),
      child: Stack(
        children: [
          if (period == TimeOfDayPeriod.night)
            const Positioned.fill(child: CustomPaint(painter: _StarFieldPainter())),
          Positioned(
            right: 18,
            top: 22,
            child: Icon(
              visual.icon,
              color: visual.iconColor,
              size: visual.iconSize,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: MausamPalette.textPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'MAUSAM',
                      style: GoogleFonts.inter(
                        color: MausamPalette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  visual.label.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: MausamPalette.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: MausamPalette.textSecondary, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.locationName,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: MausamPalette.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeVisual {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final Color iconColor;
  final double iconSize;

  const _TimeVisual({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.iconColor,
    this.iconSize = 28,
  });
}

_TimeVisual _visualFor(TimeOfDayPeriod period) {
  switch (period) {
    case TimeOfDayPeriod.dawn:
      return const _TimeVisual(
        label: 'Dawn',
        icon: Icons.wb_twilight_rounded,
        iconColor: Color(0xFFE4E4E7),
        gradient: [Color(0xFF1C1C1F), Color(0xFF2A2A2E), Color(0xFF3F3F46)],
      );
    case TimeOfDayPeriod.morning:
      return const _TimeVisual(
        label: 'Morning',
        icon: Icons.wb_sunny_outlined,
        iconColor: Color(0xFFFAFAFA),
        iconSize: 30,
        gradient: [Color(0xFF27272A), Color(0xFF3F3F46), Color(0xFF52525B)],
      );
    case TimeOfDayPeriod.afternoon:
      return const _TimeVisual(
        label: 'Afternoon',
        icon: Icons.wb_sunny_rounded,
        iconColor: Color(0xFFFAFAFA),
        iconSize: 34,
        gradient: [Color(0xFF3F3F46), Color(0xFF52525B), Color(0xFF71717A)],
      );
    case TimeOfDayPeriod.goldenHour:
      return const _TimeVisual(
        label: 'Evening',
        icon: Icons.wb_twilight_rounded,
        iconColor: Color(0xFFD4D4D8),
        gradient: [Color(0xFF18181B), Color(0xFF27272A), Color(0xFF3F3F46)],
      );
    case TimeOfDayPeriod.dusk:
      return const _TimeVisual(
        label: 'Dusk',
        icon: Icons.brightness_4_rounded,
        iconColor: Color(0xFFA1A1AA),
        gradient: [Color(0xFF0C0C0E), Color(0xFF141417), Color(0xFF1F1F23)],
      );
    case TimeOfDayPeriod.night:
      return const _TimeVisual(
        label: 'Night',
        icon: Icons.nights_stay_rounded,
        iconColor: Color(0xFFD4D4D8),
        gradient: [Color(0xFF050506), Color(0xFF09090B), Color(0xFF121214)],
      );
  }
}

class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7);
    final paint = Paint()..color = const Color(0x66FFFFFF);
    for (var i = 0; i < 18; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.7;
      canvas.drawCircle(Offset(x, y), rng.nextDouble() * 1.1 + 0.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
