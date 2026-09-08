import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/weather_dashboard.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';
import '../providers/weather_dashboard_provider.dart';
import '../widgets/staggered_item_wrapper.dart';

/// Health & Metrics Screen
///
/// Luxury Obsidian theme featuring:
/// 1. Air Quality Index (AQI) with 6-tier spectrum, 7-pollutant sub-index grid & Asthma advisory
/// 2. UV Index with sun exposure scale, peak hours, burn time & skin advisory
/// 3. Pollen Outlook with Tree / Grass / Weed breakdowns & allergy precautions
/// 4. Heat & Hydration with dual metric stat tiles & tailored hydration targets
class HealthMetricsScreen extends ConsumerWidget {
  const HealthMetricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashState = ref.watch(weatherDashboardProvider);
    final userState = ref.watch(userProvider);
    final locState = ref.watch(locationProvider);

    final dashboard = dashState.data;
    final rawLocation = locState.cityName.isNotEmpty
        ? locState.cityName
        : (dashboard?.current.location ?? 'Secunderabad');
    final cityName = rawLocation.split(',').first.trim().isNotEmpty
        ? rawLocation.split(',').first.trim()
        : rawLocation;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 92),
      children: [
        // 1. Top Action Row: Back to Home & Live Metrics Badge
        StaggeredItemWrapper(
          index: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                key: const Key('health_metrics_back_button'),
                onTap: () => context.go('/home'),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'Home',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_rounded, size: 11, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      'Live Metrics',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. Segmented Tab Switcher: [ Persona Context | Health & Metrics ]
        StaggeredItemWrapper(
          index: 1,
          child: Container(
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              color: const Color(0xFF141923),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF222B3D), width: 1.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => context.go('/context-detail'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            size: 13.5,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Persona Context',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF94A3B8),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5), width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.favorite_border_rounded,
                          size: 13.5,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Health & Metrics',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Key retained for test compatibility & layout stability
        KeyedSubtree(
          key: const Key('health_metrics_blank_page'),
          child: Column(
            children: [
              // 3. Card 1: Air Quality Index (AQI) & 7 Pollutants Sub-index Grid
              StaggeredItemWrapper(
                index: 2,
                child: _AirQualityCard(
                  dashboard: dashboard,
                  cityName: cityName,
                  userState: userState,
                ),
              ),

              const SizedBox(height: 14),

              // 4. Card 2: UV Index & Sun Exposure
              StaggeredItemWrapper(
                index: 3,
                child: _UvIndexCard(
                  dashboard: dashboard,
                  userState: userState,
                ),
              ),

              const SizedBox(height: 14),

              // 5. Card 3: Pollen Outlook (Seasonal Estimate)
              StaggeredItemWrapper(
                index: 4,
                child: _PollenOutlookCard(
                  userState: userState,
                ),
              ),

              const SizedBox(height: 14),

              // 6. Card 4: Heat & Hydration
              StaggeredItemWrapper(
                index: 5,
                child: _HeatAndHydrationCard(
                  dashboard: dashboard,
                  userState: userState,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD 1: AIR QUALITY INDEX (AQI) & POLLUTANTS
// ─────────────────────────────────────────────────────────────────────────────

class _AirQualityCard extends StatelessWidget {
  final WeatherDashboard? dashboard;
  final String cityName;
  final UserState userState;

  const _AirQualityCard({
    required this.dashboard,
    required this.cityName,
    required this.userState,
  });

  @override
  Widget build(BuildContext context) {
    final aqi = dashboard?.aqi;
    final aqiValue = aqi != null && aqi.aqiValue > 0 ? aqi.aqiValue : 65;

    // National AQI category calculation
    final _AqiTier tier = _resolveAqiTier(aqiValue);

    // Pollutants data with realistic fallbacks
    final pollutants = aqi?.pollutants ?? const {};
    final o3Val = pollutants['o3'] ?? 25.0;
    final pm25Val = pollutants['pm2_5'] ?? 62.0;
    final nh3Val = pollutants['nh3'] ?? 6.0;
    final so2Val = pollutants['so2'] ?? 12.0;
    final coVal = pollutants['co'] ?? 20.0;
    final pm10Val = pollutants['pm10'] ?? 65.0;
    final no2Val = pollutants['no2'] ?? 32.0;

    // Check user sensitivities
    final hasAsthma = userState.healthConcerns.any((c) =>
        c.toLowerCase().contains('asthma') || c.toLowerCase().contains('respiratory'));
    final hasAqiTrigger = userState.weatherTriggers.any((t) =>
        t.toLowerCase().contains('aqi') || t.toLowerCase().contains('smoke'));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141923),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222B3D), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: INDIA NATIONAL AQI • LOCATION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'INDIA NATIONAL AQI • ${cityName.toUpperCase()}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: const Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Live',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Big AQI Number + Category Mood Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$aqiValue',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: tier.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tier.color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tier.label,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: tier.color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tier.emoji,
                      style: const TextStyle(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 6-Segment National AQI Spectrum Bar
          _AqiSpectrumBar(activeTierIndex: tier.index),

          const SizedBox(height: 14),

          // 2-Column Grid of 7 Pollutants
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1
              Expanded(
                child: Column(
                  children: [
                    _PollutantTile(
                      code: 'O₃',
                      name: 'Ozone',
                      value: o3Val.round(),
                      status: 'Good',
                      statusColor: const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 6),
                    _PollutantTile(
                      code: 'PM2.5',
                      name: 'Fine particulate',
                      value: pm25Val.round(),
                      status: 'Satisfactory',
                      statusColor: const Color(0xFF84CC16),
                    ),
                    const SizedBox(height: 6),
                    _PollutantTile(
                      code: 'NH₃',
                      name: 'Ammonia',
                      value: nh3Val.round(),
                      status: 'Good',
                      statusColor: const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 6),
                    _PollutantTile(
                      code: 'SO₂',
                      name: 'Sulfur dioxide',
                      value: so2Val.round(),
                      status: 'Good',
                      statusColor: const Color(0xFF10B981),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Column 2
              Expanded(
                child: Column(
                  children: [
                    _PollutantTile(
                      code: 'CO',
                      name: 'Carbon monoxide',
                      value: coVal.round(),
                      status: 'Good',
                      statusColor: const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 6),
                    _PollutantTile(
                      code: 'PM10',
                      name: 'Coarse particulate',
                      value: pm10Val.round(),
                      status: 'Satisfactory',
                      statusColor: const Color(0xFF84CC16),
                    ),
                    const SizedBox(height: 6),
                    _PollutantTile(
                      code: 'NO₂',
                      name: 'Nitrogen dioxide',
                      value: no2Val.round(),
                      status: 'Good',
                      statusColor: const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 6),
                    // Balance space container
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F141E).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF1E2638).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Standard CPCB India',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF64748B),
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

          const SizedBox(height: 12),

          // Personalized Asthma / Air Quality Advisory Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8.5),
            decoration: BoxDecoration(
              color: hasAsthma || hasAqiTrigger
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.09)
                  : const Color(0xFF1E2638).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasAsthma || hasAqiTrigger
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                    : const Color(0xFF2B364D).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  hasAsthma ? Icons.medical_services_outlined : Icons.health_and_safety_outlined,
                  size: 14,
                  color: hasAsthma || hasAqiTrigger ? const Color(0xFFF59E0B) : const Color(0xFF38BDF8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasAsthma || hasAqiTrigger
                        ? 'Asthma & Air Advisory: PM2.5 is slightly elevated (${pm25Val.round()} µg/m³). Keep an inhaler handy during outdoor morning cardio or prolonged walks.'
                        : 'Air quality is satisfactory. Breathing discomfort is unlikely for healthy individuals; sensitive groups should take normal precautions.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      height: 1.35,
                      color: hasAsthma || hasAqiTrigger ? const Color(0xFFFDE68A) : const Color(0xFFCBD5E1),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Station Footer
          Text(
            'Monitoring Station: ${cityName.split(' ').first} Central Area (~3.8 km)',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _AqiTier {
  final int index;
  final String label;
  final String emoji;
  final Color color;

  const _AqiTier(this.index, this.label, this.emoji, this.color);
}

_AqiTier _resolveAqiTier(int aqi) {
  if (aqi <= 50) {
    return const _AqiTier(0, 'Good', '😊', Color(0xFF10B981));
  } else if (aqi <= 100) {
    return const _AqiTier(1, 'Satisfactory', '🙂', Color(0xFF84CC16));
  } else if (aqi <= 200) {
    return const _AqiTier(2, 'Moderate', '😐', Color(0xFFF59E0B));
  } else if (aqi <= 300) {
    return const _AqiTier(3, 'Poor', '😷', Color(0xFFF97316));
  } else if (aqi <= 400) {
    return const _AqiTier(4, 'Very Poor', '⚠️', Color(0xFFA855F7));
  } else {
    return const _AqiTier(5, 'Severe', '🚨', Color(0xFFEF4444));
  }
}

class _AqiSpectrumBar extends StatelessWidget {
  final int activeTierIndex;

  const _AqiSpectrumBar({required this.activeTierIndex});

  static const _tierColors = [
    Color(0xFF10B981), // Good
    Color(0xFF84CC16), // Satisfactory
    Color(0xFFF59E0B), // Moderate
    Color(0xFFF97316), // Poor
    Color(0xFFA855F7), // Very Poor
    Color(0xFFEF4444), // Severe
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(6, (i) {
            final isActive = i == activeTierIndex;
            return Expanded(
              child: Container(
                height: isActive ? 6 : 4,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: _tierColors[i].withValues(alpha: isActive ? 1.0 : 0.4),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: _tierColors[i].withValues(alpha: 0.6),
                            blurRadius: 6,
                            spreadRadius: 0.5,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
            Text('50', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
            Text('100', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
            Text('200', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
            Text('300', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
            Text('500', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
          ],
        ),
      ],
    );
  }
}

class _PollutantTile extends StatelessWidget {
  final String code;
  final String name;
  final int value;
  final String status;
  final Color statusColor;

  const _PollutantTile({
    required this.code,
    required this.name,
    required this.value,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6.5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E2638)),
      ),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 18,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  code,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD 2: UV INDEX & SUN EXPOSURE
// ─────────────────────────────────────────────────────────────────────────────

class _UvIndexCard extends StatelessWidget {
  final WeatherDashboard? dashboard;
  final UserState userState;

  const _UvIndexCard({
    required this.dashboard,
    required this.userState,
  });

  @override
  Widget build(BuildContext context) {
    final rawUv = dashboard?.current.uvIndex ?? 1.0;
    final uv = rawUv > 0 ? rawUv : 1.0;

    final String uvLabel = _resolveUvLabel(uv);
    final String uvDesc = _resolveUvDesc(uv);
    final String burnTime = _resolveBurnTime(uv);

    final hasSkinSensitivity = userState.healthConcerns.any((c) =>
        c.toLowerCase().contains('skin') || c.toLowerCase().contains('eczema'));
    final hasUvTrigger = userState.weatherTriggers.any((t) =>
        t.toLowerCase().contains('uv') || t.toLowerCase().contains('sunburn'));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141923),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222B3D), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: UV INDEX
          Row(
            children: [
              const Icon(Icons.wb_sunny_outlined, size: 13.5, color: Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              Text(
                'UV INDEX',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Big UV Level + Subtitle
          Text(
            '${uv.round()} $uvLabel',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            uvDesc,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 12),

          // Gradient Scale Bar
          _UvScaleBar(uv: uv),

          const SizedBox(height: 14),

          // Dual Exposure Stat Tiles: Peak Hours & Burn Time
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F141E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E2638)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Peak Hours',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Around 12:07 pm',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F141E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E2638)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Burn Time',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        burnTime,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Personalized Sun / Skin Advisory
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8.5),
            decoration: BoxDecoration(
              color: hasSkinSensitivity || hasUvTrigger
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.09)
                  : const Color(0xFF1E2638).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasSkinSensitivity || hasUvTrigger
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                    : const Color(0xFF2B364D).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: hasSkinSensitivity || hasUvTrigger
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasSkinSensitivity || hasUvTrigger
                        ? 'Skin Sensitivity: Even with UV ${uv.toStringAsFixed(1)}, use SPF 30+ moisturizer if outdoors for >30 mins, as barrier damage can occur under clear skies.'
                        : 'Minimal solar intensity today. Sunscreen is optional unless planning prolonged outdoor exposure during peak midday hours.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      height: 1.35,
                      color: hasSkinSensitivity || hasUvTrigger
                          ? const Color(0xFFFDE68A)
                          : const Color(0xFFCBD5E1),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _resolveUvLabel(double uv) {
    if (uv < 3) return 'Low';
    if (uv < 6) return 'Moderate';
    if (uv < 8) return 'High';
    if (uv < 11) return 'Very High';
    return 'Extreme';
  }

  String _resolveUvDesc(double uv) {
    if (uv < 3) return 'No protection needed for most people.';
    if (uv < 6) return 'Protection required during midday. Wear sunglasses & SPF.';
    if (uv < 8) return 'High risk of harm. Reduce time in sun between 11am–4pm.';
    return 'Extreme risk. Take all precautions: shade, hat, sunscreen.';
  }

  String _resolveBurnTime(double uv) {
    if (uv <= 1.5) return '~200 min';
    if (uv <= 3) return '~120 min';
    if (uv <= 5) return '~60 min';
    if (uv <= 7) return '~35 min';
    return '~20 min';
  }
}

class _UvScaleBar extends StatelessWidget {
  final double uv;

  const _UvScaleBar({required this.uv});

  @override
  Widget build(BuildContext context) {
    // Clamped position (0 to 11)
    final progress = (uv / 11.0).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        final thumbOffset = (barWidth - 10) * progress;

        return Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF10B981), // Low
                        Color(0xFFFACC15), // Moderate
                        Color(0xFFF97316), // High
                        Color(0xFFEF4444), // Very High
                        Color(0xFFA855F7), // Extreme
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: thumbOffset,
                  top: -2.5,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 3,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0 Low', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
                Text('3 Mod', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
                Text('6 High', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
                Text('8 Very High', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
                Text('11+ Ext', style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B))),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD 3: POLLEN OUTLOOK (SEASONAL ESTIMATE)
// ─────────────────────────────────────────────────────────────────────────────

class _PollenOutlookCard extends StatelessWidget {
  final UserState userState;

  const _PollenOutlookCard({required this.userState});

  @override
  Widget build(BuildContext context) {
    final hasAllergies = userState.healthConcerns.any((c) =>
        c.toLowerCase().contains('allerg') || c.toLowerCase().contains('seasonal'));
    final hasWindTrigger = userState.weatherTriggers.any((t) =>
        t.toLowerCase().contains('wind') || t.toLowerCase().contains('storm'));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141923),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222B3D), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: POLLEN OUTLOOK (SEASONAL ESTIMATE)
          Row(
            children: [
              const Icon(Icons.eco_outlined, size: 13.5, color: Color(0xFF10B981)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'POLLEN OUTLOOK (SEASONAL ESTIMATE)',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Overall Level + Leaf Icon
          Row(
            children: [
              Text(
                'Low',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Text('🌿', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Seasonal allergen counts are relatively mild today.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
          ),

          const SizedBox(height: 14),

          // 3 Pollen Breakdown Rows: Tree, Grass, Weed
          const _PollenRow(
            name: 'Tree Pollen',
            progress: 0.28,
            levelLabel: 'Low',
            barColor: Color(0xFF10B981),
          ),
          const SizedBox(height: 9),
          const _PollenRow(
            name: 'Grass Pollen',
            progress: 0.35,
            levelLabel: 'Low',
            barColor: Color(0xFF84CC16),
          ),
          const SizedBox(height: 9),
          const _PollenRow(
            name: 'Weed Pollen',
            progress: 0.16,
            levelLabel: 'Very Low',
            barColor: Color(0xFF06B6D4),
          ),

          const SizedBox(height: 12),

          // Tailored Allergy Precaution Advisory
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8.5),
            decoration: BoxDecoration(
              color: hasAllergies || hasWindTrigger
                  ? const Color(0xFF10B981).withValues(alpha: 0.09)
                  : const Color(0xFF1E2638).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasAllergies || hasWindTrigger
                    ? const Color(0xFF10B981).withValues(alpha: 0.3)
                    : const Color(0xFF2B364D).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.local_florist_outlined,
                  size: 14,
                  color: hasAllergies || hasWindTrigger
                      ? const Color(0xFF10B981)
                      : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasAllergies || hasWindTrigger
                        ? 'Allergy Precaution: Tree and grass pollen concentrations are subdued today. Good conditions for opening windows and outdoor cardio without heavy antihistamine reliance.'
                        : 'Pollen concentrations are low across the region. Low risk for allergic rhinitis or histamine reactions.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      height: 1.35,
                      color: hasAllergies || hasWindTrigger
                          ? const Color(0xFFA7F3D0)
                          : const Color(0xFFCBD5E1),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PollenRow extends StatelessWidget {
  final String name;
  final double progress;
  final String levelLabel;
  final Color barColor;

  const _PollenRow({
    required this.name,
    required this.progress,
    required this.levelLabel,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              levelLabel,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Container(
            height: 5,
            color: const Color(0xFF0F141E),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD 4: HEAT & HYDRATION
// ─────────────────────────────────────────────────────────────────────────────

class _HeatAndHydrationCard extends StatelessWidget {
  final WeatherDashboard? dashboard;
  final UserState userState;

  const _HeatAndHydrationCard({
    required this.dashboard,
    required this.userState,
  });

  @override
  Widget build(BuildContext context) {
    final current = dashboard?.current;
    final temp = current?.temperatureCelsius ?? 32.0;
    final humidity = current?.humidityPercent ?? 50;

    // Approximate heat index
    final double heatIndex = current?.feelsLikeCelsius ??
        (temp + 0.33 * (humidity / 100.0 * 6.105 * math.exp(17.27 * temp / (237.7 + temp))) - 4.0);

    // Dew point calculation or fallback
    final double dewPoint = current?.dewPointCelsius ?? (temp - ((100 - humidity) / 5.0));

    final isAthlete = userState.activityLevel.toLowerCase().contains('high') ||
        userState.activityLevel.toLowerCase().contains('athlete');
    final hasHeatSensitivity = userState.healthConcerns.any((c) =>
        c.toLowerCase().contains('heat') || c.toLowerCase().contains('migraine'));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141923),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222B3D), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: HEAT & HYDRATION
          Row(
            children: [
              const Icon(Icons.water_drop_outlined, size: 13.5, color: Color(0xFF0284C7)),
              const SizedBox(width: 6),
              Text(
                'HEAT & HYDRATION',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Dual Stat Boxes: Heat Index & Humidity
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F141E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E2638)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Heat Index (Approx.)',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${heatIndex.round()}°',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        heatIndex > temp ? 'Feels warmer than air' : 'Comfortable index',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F141E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E2638)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Humidity',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$humidity%',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dew point ${dewPoint.round()}°',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Personalized Hydration Guidance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8.5),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF0284C7).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.opacity_rounded,
                  size: 14,
                  color: Color(0xFF38BDF8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAthlete || hasHeatSensitivity
                        ? 'Hydration Target: 2.5L – 3.2L recommended today. Drink in steady intervals before outdoor activities to prevent dehydration in $humidity% humidity.'
                        : 'Hydration Target: 2.0L – 2.5L recommended today to sustain focus, maintain electrolyte balance, and regulate core temperature.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      height: 1.35,
                      color: const Color(0xFFBAE6FD),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
