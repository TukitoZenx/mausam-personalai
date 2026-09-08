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
class HealthMetricsScreen extends ConsumerStatefulWidget {
  const HealthMetricsScreen({super.key});

  @override
  ConsumerState<HealthMetricsScreen> createState() => _HealthMetricsScreenState();
}

class _HealthMetricsScreenState extends ConsumerState<HealthMetricsScreen> {
  final Set<String> _hiddenCards = {};
  bool _showDetailedAnalysis = false;

  void _restoreAllCards() {
    setState(() => _hiddenCards.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Restored all health metric cards'),
        backgroundColor: Color(0xFF18181B),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleCard(String cardKey) {
    setState(() {
      if (_hiddenCards.contains(cardKey)) {
        _hiddenCards.remove(cardKey);
      } else {
        _hiddenCards.add(cardKey);
      }
    });
  }

  void _showManageCardsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121218),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final cards = [
              (key: 'aqi', title: 'Air Quality Index & Pollutants', icon: Icons.air_rounded),
              (key: 'uv', title: 'UV Index & Sun Exposure', icon: Icons.wb_sunny_rounded),
              (key: 'pollen', title: 'Pollen Outlook & Allergens', icon: Icons.grass_rounded),
              (key: 'heat', title: 'Heat Index & Hydration', icon: Icons.water_drop_rounded),
            ];

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CUSTOMIZE METRIC CARDS',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF71717A), size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...cards.map((c) {
                    final isVisible = !_hiddenCards.contains(c.key);
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(c.icon, color: isVisible ? const Color(0xFF10B981) : const Color(0xFF71717A)),
                      title: Text(
                        c.title,
                        style: GoogleFonts.inter(
                          color: isVisible ? Colors.white : const Color(0xFF71717A),
                          fontWeight: isVisible ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 13.5,
                        ),
                      ),
                      trailing: Switch(
                        value: isVisible,
                        activeThumbColor: const Color(0xFF10B981),
                        onChanged: (val) {
                          setModalState(() {
                            _toggleCard(c.key);
                          });
                          setState(() {});
                        },
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 88),
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

        // 3. Screen Headline Typography (Synchronized layout with Persona Context)
        StaggeredItemWrapper(
          index: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overline: LIVE BIOMETRICS & VITALS
              Text(
                'LIVE BIOMETRICS & VITALS'.toUpperCase(),
                style: GoogleFonts.inter(
                  color: const Color(0xFF10B981),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),

              // Main Headline
              Text(
                'Health & Environmental Metrics',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),

              // Subtitle
              Text(
                'Real-time air quality, UV index, allergen exposure, and hydration metrics.',
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 4. Interactive Health Focus Choice: Add or Remove Active Health Concerns
        StaggeredItemWrapper(
          index: 3,
          child: _HealthFocusBar(
            userState: userState,
            ref: ref,
          ),
        ),

        const SizedBox(height: 12),

        // 5. Controls: Detailed Analysis Toggle & Manage Cards Action
        StaggeredItemWrapper(
          index: 4,
          child: _MetricsControlsBar(
            showDetailedAnalysis: _showDetailedAnalysis,
            hiddenCount: _hiddenCards.length,
            onToggleDetailedAnalysis: () {
              setState(() => _showDetailedAnalysis = !_showDetailedAnalysis);
            },
            onManageCards: () => _showManageCardsModal(context),
          ),
        ),

        const SizedBox(height: 14),

        // Key retained for test compatibility & layout stability
        KeyedSubtree(
          key: const Key('health_metrics_blank_page'),
          child: Column(
            children: [
              // 3. Card 1: Air Quality Index (AQI) & 7 Pollutants Sub-index Grid
              if (!_hiddenCards.contains('aqi')) ...[
                StaggeredItemWrapper(
                  index: 5,
                  child: _AirQualityCard(
                    dashboard: dashboard,
                    cityName: cityName,
                    userState: userState,
                    detailedMode: _showDetailedAnalysis,
                    onRemove: () => setState(() => _hiddenCards.add('aqi')),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 4. Card 2: UV Index & Sun Exposure
              if (!_hiddenCards.contains('uv')) ...[
                StaggeredItemWrapper(
                  index: 6,
                  child: _UvIndexCard(
                    dashboard: dashboard,
                    userState: userState,
                    detailedMode: _showDetailedAnalysis,
                    onRemove: () => setState(() => _hiddenCards.add('uv')),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 5. Card 3: Pollen Outlook (Seasonal Estimate)
              if (!_hiddenCards.contains('pollen')) ...[
                StaggeredItemWrapper(
                  index: 7,
                  child: _PollenOutlookCard(
                    userState: userState,
                    detailedMode: _showDetailedAnalysis,
                    onRemove: () => setState(() => _hiddenCards.add('pollen')),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 6. Card 4: Heat & Hydration
              if (!_hiddenCards.contains('heat')) ...[
                StaggeredItemWrapper(
                  index: 8,
                  child: _HeatAndHydrationCard(
                    dashboard: dashboard,
                    userState: userState,
                    detailedMode: _showDetailedAnalysis,
                    onRemove: () => setState(() => _hiddenCards.add('heat')),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              if (_hiddenCards.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: InkWell(
                    onTap: _restoreAllCards,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141923),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF222B3D)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Text(
                            'Restore ${_hiddenCards.length} hidden metric cards',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HealthFocusBar extends StatelessWidget {
  final UserState userState;
  final WidgetRef ref;

  const _HealthFocusBar({
    required this.userState,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    const allOptions = [
      (label: 'Asthma & Air', icon: Icons.air_rounded, key: 'Asthma'),
      (label: 'UV & Skin Care', icon: Icons.wb_sunny_rounded, key: 'Skin sensitivity'),
      (label: 'Pollen & Allergy', icon: Icons.grass_rounded, key: 'Pollen allergy'),
      (label: 'Heat & Hydration', icon: Icons.water_drop_rounded, key: 'Heat sensitivity'),
      (label: 'Cardio & Stamina', icon: Icons.favorite_rounded, key: 'Cardiovascular'),
    ];

    final active = userState.healthConcerns.toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ACTIVE HEALTH FOCUSES',
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            Flexible(
              child: Text(
                'Tap to toggle',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: allOptions.map((opt) {
              final isEnabled = active.any((c) =>
                  c.toLowerCase().contains(opt.key.toLowerCase().split(' ').first));

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    final newConcerns = List<String>.from(userState.healthConcerns);
                    if (isEnabled) {
                      newConcerns.removeWhere((c) =>
                          c.toLowerCase().contains(opt.key.toLowerCase().split(' ').first));
                    } else {
                      newConcerns.add(opt.key);
                    }
                    ref.read(userProvider.notifier).setTriggersAndConcerns(
                          triggers: userState.weatherTriggers,
                          concerns: newConcerns,
                        );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? const Color(0xFF10B981).withValues(alpha: 0.16)
                          : const Color(0xFF141923),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isEnabled
                            ? const Color(0xFF10B981).withValues(alpha: 0.5)
                            : const Color(0xFF222B3D),
                        width: isEnabled ? 1.2 : 0.9,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isEnabled ? Icons.check_circle_rounded : opt.icon,
                          size: 13,
                          color: isEnabled ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          opt.label,
                          style: GoogleFonts.inter(
                            color: isEnabled ? Colors.white : const Color(0xFF94A3B8),
                            fontSize: 11.5,
                            fontWeight: isEnabled ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MetricsControlsBar extends StatelessWidget {
  final bool showDetailedAnalysis;
  final int hiddenCount;
  final VoidCallback onToggleDetailedAnalysis;
  final VoidCallback onManageCards;

  const _MetricsControlsBar({
    required this.showDetailedAnalysis,
    required this.hiddenCount,
    required this.onToggleDetailedAnalysis,
    required this.onManageCards,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Detailed Analysis Toggle
        Expanded(
          child: InkWell(
            onTap: onToggleDetailedAnalysis,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
              decoration: BoxDecoration(
                color: showDetailedAnalysis
                    ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                    : const Color(0xFF141923),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: showDetailedAnalysis
                      ? const Color(0xFF38BDF8).withValues(alpha: 0.5)
                      : const Color(0xFF222B3D),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    showDetailedAnalysis ? Icons.analytics_rounded : Icons.analytics_outlined,
                    size: 14,
                    color: showDetailedAnalysis ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      showDetailedAnalysis ? 'Detailed: ON' : 'Detailed Analysis',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: showDetailedAnalysis ? FontWeight.w700 : FontWeight.w500,
                        color: showDetailedAnalysis ? Colors.white : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Manage Cards Button
        InkWell(
          onTap: onManageCards,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF141923),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF222B3D)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 5),
                Text(
                  hiddenCount > 0 ? 'Cards ($hiddenCount hidden)' : 'Customize Cards',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
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
  final bool detailedMode;
  final VoidCallback? onRemove;

  const _AirQualityCard({
    required this.dashboard,
    required this.cityName,
    required this.userState,
    this.detailedMode = false,
    this.onRemove,
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
              if (onRemove != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF71717A)),
                  ),
                ),
              ],
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

          if (detailedMode) ...[
            const SizedBox(height: 12),
            _AirQualityDetailedAnalysis(
              pm25: pm25Val,
              pm10: pm10Val,
              no2: no2Val,
              so2: so2Val,
              co: coVal,
              o3: o3Val,
              hasAsthma: hasAsthma,
            ),
          ],

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

class _AirQualityDetailedAnalysis extends StatelessWidget {
  final double pm25;
  final double pm10;
  final double no2;
  final double so2;
  final double co;
  final double o3;
  final bool hasAsthma;

  const _AirQualityDetailedAnalysis({
    required this.pm25,
    required this.pm10,
    required this.no2,
    required this.so2,
    required this.co,
    required this.o3,
    required this.hasAsthma,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.biotech_rounded, size: 14, color: Color(0xFF38BDF8)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'CLINICAL PULMONARY & EXPOSURE ANALYSIS',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: const Color(0xFF38BDF8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'WHO 24-Hour Permissible Limits Comparison',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          _ComparisonRow(label: 'PM2.5', current: '${pm25.round()} µg/m³', whoLimit: '15 µg/m³', isElevated: pm25 > 15),
          _ComparisonRow(label: 'PM10', current: '${pm10.round()} µg/m³', whoLimit: '45 µg/m³', isElevated: pm10 > 45),
          _ComparisonRow(label: 'NO2', current: '${no2.round()} µg/m³', whoLimit: '25 µg/m³', isElevated: no2 > 25),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF161E2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hasAsthma
                        ? 'High sensitivity alert: Microscopic particles (PM2.5) penetrate deep alveolar tissue. Consider HEPA-grade air filtration indoors and keep quick-relief inhalers nearby.'
                        : 'Vulnerable populations (pediatric, cardiac, elderly) should minimize strenuous outdoor exercise during early morning temperature inversion layers.',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: const Color(0xFF94A3B8),
                      height: 1.35,
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

class _ComparisonRow extends StatelessWidget {
  final String label;
  final String current;
  final String whoLimit;
  final bool isElevated;

  const _ComparisonRow({
    required this.label,
    required this.current,
    required this.whoLimit,
    required this.isElevated,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                current,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isElevated ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '• WHO: $whoLimit',
                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
              ),
            ],
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
  final bool detailedMode;
  final VoidCallback? onRemove;

  const _UvIndexCard({
    required this.dashboard,
    required this.userState,
    this.detailedMode = false,
    this.onRemove,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              if (onRemove != null)
                InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF71717A)),
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

          if (detailedMode) ...[
            const SizedBox(height: 12),
            _UvDetailedAnalysis(
              uv: uv,
              hasSkinSensitivity: hasSkinSensitivity,
            ),
          ],
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

class _UvDetailedAnalysis extends StatelessWidget {
  final double uv;
  final bool hasSkinSensitivity;

  const _UvDetailedAnalysis({
    required this.uv,
    required this.hasSkinSensitivity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_rounded, size: 14, color: Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'FITZPATRICK PHOTOTYPE & DERMAL PROTOCOL',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _PhototypeRow(type: 'Type I–II (Fair)', burnRisk: 'Very High', spf: 'SPF 50+ Broad Spectrum', med: '~15–20 min MED'),
          const _PhototypeRow(type: 'Type III–IV (Medium/Olive)', burnRisk: 'Moderate', spf: 'SPF 30+ Daily', med: '~35–50 min MED'),
          const _PhototypeRow(type: 'Type V–VI (Deep Brown)', burnRisk: 'Low Erythema', spf: 'SPF 15–30 / UV400 Eyewear', med: '~60+ min MED'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF161E2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.light_mode_outlined, size: 13, color: Color(0xFFFACC15)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Vitamin D Synthesis Window: 12–15 minutes of non-burning limb exposure before 11:00 AM satisfies optimal 1,000 IU synthesis with minimal photo-damage risk.',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: const Color(0xFF94A3B8),
                      height: 1.35,
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

class _PhototypeRow extends StatelessWidget {
  final String type;
  final String burnRisk;
  final String spf;
  final String med;

  const _PhototypeRow({
    required this.type,
    required this.burnRisk,
    required this.spf,
    required this.med,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  type,
                  style: GoogleFonts.inter(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(burnRisk, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFF59E0B), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  spf,
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(med, style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
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
  final bool detailedMode;
  final VoidCallback? onRemove;

  const _PollenOutlookCard({
    required this.userState,
    this.detailedMode = false,
    this.onRemove,
  });

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.eco_outlined, size: 13.5, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Expanded(
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
              ),
              if (onRemove != null)
                InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF71717A)),
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

          if (detailedMode) ...[
            const SizedBox(height: 12),
            _PollenDetailedAnalysis(hasAllergies: hasAllergies),
          ],
        ],
      ),
    );
  }
}

class _PollenDetailedAnalysis extends StatelessWidget {
  final bool hasAllergies;

  const _PollenDetailedAnalysis({required this.hasAllergies});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.science_outlined, size: 14, color: Color(0xFF10B981)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'ALLERGEN PHENOLOGY & BIO-AEROSOL DISPERSAL',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _AllergenTimelineTile(
            time: '06:00 – 10:00 AM',
            phenomenon: 'Morning Thermal Dispersal',
            impact: 'Pollen release peaks with morning temperature rise and turbulent updrafts.',
          ),
          const SizedBox(height: 6),
          const _AllergenTimelineTile(
            time: '12:00 – 04:00 PM',
            phenomenon: 'Dry Convective Circulation',
            impact: 'Aerosolized grasses and weed particulates remain suspended in high wind.',
          ),
          const SizedBox(height: 6),
          const _AllergenTimelineTile(
            time: '06:00 – 09:00 PM',
            phenomenon: 'Nightfall Sedimentation',
            impact: 'Cooling air pulls spores and pollen down toward ground level.',
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF161E2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.medication_outlined, size: 13, color: Color(0xFF34D399)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Pharmacokinetics Note: Second-generation oral antihistamines (e.g. cetirizine, fexofenadine) reach maximum plasma concentrations in ~1–2 hours. Pre-dose prior to prolonged outdoor park visits.',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: const Color(0xFF94A3B8),
                      height: 1.35,
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

class _AllergenTimelineTile extends StatelessWidget {
  final String time;
  final String phenomenon;
  final String impact;

  const _AllergenTimelineTile({
    required this.time,
    required this.phenomenon,
    required this.impact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                phenomenon,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Text(time, style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF38BDF8), fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 2),
        Text(impact, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8), height: 1.3)),
      ],
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
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
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
  final bool detailedMode;
  final VoidCallback? onRemove;

  const _HeatAndHydrationCard({
    required this.dashboard,
    required this.userState,
    this.detailedMode = false,
    this.onRemove,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              if (onRemove != null)
                InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF71717A)),
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

          if (detailedMode) ...[
            const SizedBox(height: 12),
            _HeatDetailedAnalysis(
              temp: temp,
              humidity: humidity,
              heatIndex: heatIndex,
            ),
          ],
        ],
      ),
    );
  }
}

class _HeatDetailedAnalysis extends StatelessWidget {
  final double temp;
  final int humidity;
  final double heatIndex;

  const _HeatDetailedAnalysis({
    required this.temp,
    required this.humidity,
    required this.heatIndex,
  });

  @override
  Widget build(BuildContext context) {
    final sweatRate = (350 + (heatIndex - 25).clamp(0, 30) * 22).round();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.thermostat_rounded, size: 14, color: Color(0xFF0284C7)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'THERMAL STRAIN & OSMOREGULATION MODEL',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: const Color(0xFF38BDF8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141A26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Est. Sweat Loss', style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF64748B))),
                      const SizedBox(height: 2),
                      Text('~$sweatRate ml/hr', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text('Moderate activity', style: GoogleFonts.inter(fontSize: 8.5, color: const Color(0xFF94A3B8))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141A26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Evaporative Efficiency', style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF64748B))),
                      const SizedBox(height: 2),
                      Text(humidity > 65 ? 'Reduced ($humidity%)' : 'Optimal ($humidity%)',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: humidity > 65 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                          )),
                      Text(humidity > 65 ? 'High latent heat load' : 'Rapid evaporative cooling',
                          style: GoogleFonts.inter(fontSize: 8.5, color: const Color(0xFF94A3B8))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF161E2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.water_drop_rounded, size: 13, color: Color(0xFF38BDF8)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Electrolyte Replenishment Protocol: For continuous exercise lasting > 60 minutes in this humidity, include ~300-500 mg sodium per liter to prevent exercise-associated hyponatremia.',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: const Color(0xFF94A3B8),
                      height: 1.35,
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
