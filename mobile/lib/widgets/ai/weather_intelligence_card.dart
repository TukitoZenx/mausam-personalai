import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/weather_ai_card_data.dart';
import '../../theme/weather_palette.dart';

/// Ultra-premium, scannable Weather Intelligence Card for Mausam AI chat.
/// Supports Activity Window, Wardrobe/Clothing, Health & Environment, Travel, and Daily Plan.
class WeatherIntelligenceCard extends StatefulWidget {
  final WeatherAiCardData cardData;
  final VoidCallback? onActionTap;

  const WeatherIntelligenceCard({
    super.key,
    required this.cardData,
    this.onActionTap,
  });

  @override
  State<WeatherIntelligenceCard> createState() => _WeatherIntelligenceCardState();
}

class _WeatherIntelligenceCardState extends State<WeatherIntelligenceCard> {
  int? _selectedStationIndex;

  @override
  Widget build(BuildContext context) {
    final cardData = widget.cardData;
    final onActionTap = widget.onActionTap;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, anim, child) {
        return Opacity(
          opacity: anim,
          child: Transform.translate(
            offset: Offset(0, (1 - anim) * 8),
            child: child,
          ),
        );
      },
      child: Container(
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
            // 1. Header Category with Glow Dot
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
                Expanded(
                  child: Text(
                    cardData.category.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF10B981),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 2. Primary Headline (Scannable in 2-3 seconds)
            Text(
              cardData.headline,
              style: GoogleFonts.inter(
                color: MausamPalette.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            if (cardData.subtitle != null && cardData.subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                cardData.subtitle!,
                style: GoogleFonts.inter(
                  color: MausamPalette.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            // Compact Vector Route Preview Map (When Travel Route Intent)
            if (cardData.cardType == WeatherCardType.travelRoute) ...[
              const SizedBox(height: 12),
              _TravelRoutePreviewMap(
                cardData: cardData,
                selectedStationIndex: _selectedStationIndex,
                onSelectStation: (idx) {
                  setState(() {
                    _selectedStationIndex = idx;
                  });
                },
                onTap: () {
                  if (onActionTap != null) {
                    onActionTap();
                  } else {
                    context.push('/weather-map', extra: cardData);
                  }
                },
              ),
              if (cardData.routePoints != null && cardData.routePoints!.length > 1) ...[
                const SizedBox(height: 12),
                _AlongRouteWeatherStrip(
                  points: cardData.routePoints!,
                  selectedIndex: _selectedStationIndex,
                  onSelectStation: (idx) {
                    setState(() {
                      _selectedStationIndex = idx;
                    });
                  },
                ),
              ],
            ],
            const SizedBox(height: 12),

          // 3. Compact Metrics Row
          if (cardData.metrics.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: cardData.metrics.map((m) {
                return _MetricPill(
                  icon: m.icon,
                  label: m.label,
                  value: m.value,
                  accentColor: m.color,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // 4. Daily Plan Timeline (if available)
          if (cardData.dailyPlanPeriods != null && cardData.dailyPlanPeriods!.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF181D2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A344A)),
              ),
              child: Column(
                children: cardData.dailyPlanPeriods!.map((period) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(period.icon, size: 16, color: MausamPalette.accentCyan),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 70,
                          child: Text(
                            period.period,
                            style: GoogleFonts.inter(
                              color: MausamPalette.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          period.temp,
                          style: GoogleFonts.inter(
                            color: MausamPalette.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            period.advice,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF94A3B8),
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // 5. Checklist Items (e.g. for Packing / Travel)
          if (cardData.checklistItems != null && cardData.checklistItems!.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF181D2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A344A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cardData.checklistItems!.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: GoogleFonts.inter(
                              color: MausamPalette.textPrimary,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // 6. Explainable "Why" Section
          if (cardData.explanation != null && cardData.explanation!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B202D),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A3245)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cardData.explanation!,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFCBD5E1),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 7. Contextual Action Button (Single Primary Action)
          if (cardData.actionLabel != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (onActionTap != null) {
                    onActionTap();
                  } else if (cardData.cardType == WeatherCardType.travelRoute) {
                    context.push('/weather-map', extra: cardData);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2536),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF374151),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          cardData.actionLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: MausamPalette.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: MausamPalette.textPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? accentColor;

  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2333),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF2C354B),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: accentColor ?? MausamPalette.textSecondary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
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
    );
  }
}

class _TravelRoutePreviewMap extends StatelessWidget {
  final WeatherAiCardData cardData;
  final int? selectedStationIndex;
  final ValueChanged<int?> onSelectStation;
  final VoidCallback? onTap;

  const _TravelRoutePreviewMap({
    required this.cardData,
    required this.selectedStationIndex,
    required this.onSelectStation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final origin = cardData.origin ?? 'Origin';
    final destination = cardData.destination ?? 'Destination';
    final weather = cardData.destinationWeather;
    final destTemp = weather != null && weather['temperature'] != null ? '${weather['temperature']}°C' : null;

    final allPoints = cardData.routePoints ?? [
      TravelRoutePoint(
        name: origin,
        role: 'origin',
        lat: cardData.originCoords?['latitude'] ?? 0.0,
        lon: cardData.originCoords?['longitude'] ?? 0.0,
      ),
      TravelRoutePoint(
        name: destination,
        role: 'destination',
        lat: cardData.destCoords?['latitude'] ?? 0.0,
        lon: cardData.destCoords?['longitude'] ?? 0.0,
        weather: cardData.destinationWeather,
      ),
    ];

    // Intelligently downsample intermediate stops visually if there are many (> 6) to keep map uncluttered
    final List<TravelRoutePoint> visualPoints;
    if (allPoints.length > 8) {
      final intermediates = allPoints.where((p) => p.isIntermediate).toList();
      final sampled = <TravelRoutePoint>[];
      final step = intermediates.length / 4.0;
      for (int i = 0; i < 4; i++) {
        sampled.add(intermediates[(i * step).floor()]);
      }
      visualPoints = [allPoints.first, ...sampled, allPoints.last];
    } else {
      visualPoints = allPoints;
    }

    return Semantics(
      label: 'Route map preview from $origin to $destination',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: 136,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0F131C),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF232B3E),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                const h = 136.0;

                // Calculate node positions along cubic bezier curve for hit-testing
                final startOffset = Offset(w * 0.14, h * 0.70);
                final endOffset = Offset(w * 0.86, h * 0.32);
                final cp1 = Offset(w * 0.38, h * 0.80);
                final cp2 = Offset(w * 0.62, h * 0.22);

                final nodeOffsets = <Offset>[startOffset];
                final intermediateCount = visualPoints.length - 2;
                if (intermediateCount > 0) {
                  for (int i = 0; i < intermediateCount; i++) {
                    final t = (i + 1.0) / (intermediateCount + 1.0);
                    final u = 1.0 - t;
                    final tt = t * t;
                    final uu = u * u;
                    final uuu = uu * u;
                    final ttt = tt * t;

                    final px = uuu * startOffset.dx + 3 * uu * t * cp1.dx + 3 * u * tt * cp2.dx + ttt * endOffset.dx;
                    final py = uuu * startOffset.dy + 3 * uu * t * cp1.dy + 3 * u * tt * cp2.dy + ttt * endOffset.dy;
                    nodeOffsets.add(Offset(px, py));
                  }
                }
                nodeOffsets.add(endOffset);

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    final tapPos = details.localPosition;
                    int? closestIdx;
                    double minDist = 32.0;

                    for (int i = 0; i < nodeOffsets.length; i++) {
                      final dist = (tapPos - nodeOffsets[i]).distance;
                      if (dist < minDist) {
                        minDist = dist;
                        closestIdx = i;
                      }
                    }

                    if (closestIdx != null) {
                      HapticFeedback.selectionClick();
                      // Map visual point index to allPoints index if downsampled
                      final mappedPoint = visualPoints[closestIdx];
                      final realIdx = allPoints.indexOf(mappedPoint);
                      onSelectStation(selectedStationIndex == realIdx ? null : realIdx);
                    } else {
                      HapticFeedback.lightImpact();
                      onTap?.call();
                    }
                  },
                  child: Stack(
                    children: [
                      // Vector Custom Painter (Grid, Glowing Route Polyline, Nodes)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _RouteMapPainter(
                            points: visualPoints,
                            nodeOffsets: nodeOffsets,
                            selectedStationIndex: selectedStationIndex != null && selectedStationIndex! < allPoints.length
                                ? visualPoints.indexOf(allPoints[selectedStationIndex!])
                                : null,
                          ),
                        ),
                      ),

                      // Top Badges Row: Origin indicator & Destination Weather Capsule
                      Positioned(
                        top: 8,
                        left: 10,
                        right: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Origin Badge
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF161E2E).withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.trip_origin_rounded, size: 9, color: Color(0xFF06B6D4)),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        origin,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: MausamPalette.textPrimary,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Destination Badge with Weather
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF161E2E).withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on_rounded, size: 10, color: Color(0xFF10B981)),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        destination,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: MausamPalette.textPrimary,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (destTemp != null) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        destTemp,
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF34D399),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Interactive Floating Tooltip on Station Node Selection
                      if (selectedStationIndex != null &&
                          selectedStationIndex! >= 0 &&
                          selectedStationIndex! < allPoints.length)
                        Positioned(
                          top: 42,
                          left: 10,
                          right: 10,
                          child: Center(
                            child: StationTooltip(
                              point: allPoints[selectedStationIndex!],
                              onClose: () => onSelectStation(null),
                            ),
                          ),
                        ),

                      // Bottom Badges Row: Route Tag & Interactive hint
                      Positioned(
                        bottom: 8,
                        left: 10,
                        right: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Route Tag Badge
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A2234).withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF2D3B55)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.alt_route_rounded, size: 10, color: Color(0xFF10B981)),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        cardData.isEstimate ? 'ESTIMATED ROUTE' : 'DIRECT HIGHWAY',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF10B981),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Quick Action Hint
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.touch_app_rounded, size: 10, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Interactive preview',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF94A3B8),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class StationTooltip extends StatelessWidget {
  final TravelRoutePoint point;
  final VoidCallback onClose;

  const StationTooltip({
    super.key,
    required this.point,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final temp = point.temperature;
    final cond = point.condition;
    final aqi = point.aqi;

    final accent = point.isOrigin ? const Color(0xFF06B6D4) : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0C121E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.25),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            point.isOrigin
                ? Icons.trip_origin_rounded
                : (point.isDestination ? Icons.location_on_rounded : Icons.radio_button_checked_rounded),
            size: 11,
            color: accent,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              point.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (temp != null) ...[
            const SizedBox(width: 5),
            Text(
              '$temp°C',
              style: GoogleFonts.inter(
                color: const Color(0xFF34D399),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (cond != null && cond.isNotEmpty) ...[
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                '· $cond',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          if (aqi != null) ...[
            const SizedBox(width: 5),
            Text(
              '· AQI $aqi',
              style: GoogleFonts.inter(
                color: const Color(0xFF38BDF8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close_rounded, size: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

class _AlongRouteWeatherStrip extends StatelessWidget {
  final List<TravelRoutePoint> points;
  final int? selectedIndex;
  final ValueChanged<int?> onSelectStation;

  const _AlongRouteWeatherStrip({
    required this.points,
    required this.selectedIndex,
    required this.onSelectStation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.alt_route_rounded, size: 12, color: Color(0xFF10B981)),
            const SizedBox(width: 5),
            Text(
              'ALONG YOUR ROUTE',
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            Text(
              '${points.length} STOPS',
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: points.length,
            separatorBuilder: (context, index) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                child: Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF475569)),
              ),
            ),
            itemBuilder: (context, index) {
              final pt = points[index];
              final isSelected = selectedIndex == index;
              final temp = pt.temperature;
              final cond = pt.condition;
              final aqi = pt.aqi;

              final roleLabel = pt.isOrigin
                  ? 'ORIGIN'
                  : (pt.isDestination ? 'DEST' : 'STOP $index');
              final roleColor = pt.isOrigin ? const Color(0xFF06B6D4) : const Color(0xFF10B981);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelectStation(isSelected ? null : index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 120,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF182236) : const Color(0xFF0F1522),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF10B981)
                            : const Color(0xFF232B3E),
                        width: isSelected ? 1.4 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                roleLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: roleColor,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (temp != null)
                              Text(
                                '$temp°C',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF34D399),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                        Text(
                          pt.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: MausamPalette.textPrimary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            if (aqi != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'AQI $aqi',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF38BDF8),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            if (cond != null)
                              Expanded(
                                child: Text(
                                  cond,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  final List<TravelRoutePoint> points;
  final List<Offset> nodeOffsets;
  final int? selectedStationIndex;

  _RouteMapPainter({
    required this.points,
    required this.nodeOffsets,
    this.selectedStationIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Background grid
    final gridPaint = Paint()
      ..color = const Color(0xFF1A2234).withValues(alpha: 0.45)
      ..strokeWidth = 0.75
      ..style = PaintingStyle.stroke;

    const gridSpacing = 24.0;
    for (double x = 0; x < w; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    if (nodeOffsets.length < 2) return;

    final start = nodeOffsets.first;
    final end = nodeOffsets.last;
    final cp1 = Offset(w * 0.38, h * 0.80);
    final cp2 = Offset(w * 0.62, h * 0.22);

    final routePath = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);

    // 2. Glowing Halo
    final glowPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF06B6D4), Color(0xFF10B981)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawPath(routePath, glowPaint);

    // 3. Primary Route Polyline
    final routePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF06B6D4), Color(0xFF10B981)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(routePath, routePaint);

    // 4. Draw Intermediate Station Nodes
    for (int i = 1; i < nodeOffsets.length - 1; i++) {
      final pos = nodeOffsets[i];
      final isSelected = selectedStationIndex == i;

      if (isSelected) {
        canvas.drawCircle(
          pos,
          10,
          Paint()
            ..color = const Color(0xFF10B981).withValues(alpha: 0.4)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          pos,
          5,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill,
        );
      } else {
        canvas.drawCircle(
          pos,
          6,
          Paint()
            ..color = const Color(0xFF10B981).withValues(alpha: 0.35)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          pos,
          3,
          Paint()
            ..color = const Color(0xFF10B981)
            ..style = PaintingStyle.fill,
        );
      }
    }

    // 5. Origin Node (Start)
    final isOriginSelected = selectedStationIndex == 0;
    canvas.drawCircle(
      start,
      isOriginSelected ? 11 : 8,
      Paint()
        ..color = const Color(0xFF06B6D4).withValues(alpha: isOriginSelected ? 0.45 : 0.25)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      start,
      isOriginSelected ? 5.5 : 4,
      Paint()
        ..color = isOriginSelected ? Colors.white : const Color(0xFF06B6D4)
        ..style = PaintingStyle.fill,
    );

    // 6. Destination Node (End)
    final isDestSelected = selectedStationIndex == nodeOffsets.length - 1;
    canvas.drawCircle(
      end,
      isDestSelected ? 12 : 9,
      Paint()
        ..color = const Color(0xFF10B981).withValues(alpha: isDestSelected ? 0.5 : 0.3)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      end,
      isDestSelected ? 6 : 4.5,
      Paint()
        ..color = isDestSelected ? Colors.white : const Color(0xFF10B981)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _RouteMapPainter oldDelegate) {
    return oldDelegate.selectedStationIndex != selectedStationIndex ||
        oldDelegate.points != points ||
        oldDelegate.nodeOffsets != nodeOffsets;
  }
}

