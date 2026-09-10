import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/weather_dashboard.dart';
import '../providers/user_provider.dart';
import '../providers/weather_dashboard_provider.dart';
import '../widgets/cards/personalized_context_card.dart';
import '../widgets/staggered_item_wrapper.dart';

class ContextDetailScreen extends ConsumerStatefulWidget {
  const ContextDetailScreen({super.key});

  /// Computes the dynamic weather accent color based on live weather condition data.
  static Color resolveWeatherAccentColor(WeatherDashboard? dashboard, int hour) {
    if (dashboard == null) return const Color(0xFFFB7185);

    final current = dashboard.current;
    final temp = current.temperatureCelsius;
    final rain = current.rainMm1h ?? 0.0;
    final cond = current.condition.toLowerCase();
    final aqi = dashboard.aqi?.aqiValue ?? 0;

    if (temp >= 32.0 || cond.contains('hot') || cond.contains('sunny')) {
      return const Color(0xFFF59E0B);
    }
    if (rain > 0.0 || cond.contains('rain') || cond.contains('drizzle') || cond.contains('thunder') || cond.contains('shower')) {
      return const Color(0xFF38BDF8);
    }
    if (aqi >= 80) {
      return const Color(0xFF34D399);
    }
    if (hour >= 20 || hour < 5) {
      return const Color(0xFFA78BFA);
    }
    return const Color(0xFFFB7185);
  }

  @override
  ConsumerState<ContextDetailScreen> createState() => _ContextDetailScreenState();
}

class _ContextDetailScreenState extends ConsumerState<ContextDetailScreen> {
  bool _initializedFromRoute = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFromRoute) {
      try {
        final uri = GoRouterState.of(context).uri;
        if (uri.queryParameters['tab'] == 'health') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/health-metrics');
          });
        }
      } catch (_) {}
      _initializedFromRoute = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final dash = ref.watch(weatherDashboardProvider);
    final hour = DateTime.now().hour;
    final userName = PersonalizedContextCard.resolveUserName(userState);
    final accentColor = ContextDetailScreen.resolveWeatherAccentColor(dash.data, hour);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 88),
      children: [
        // 1. Top Navigation Row: Back to Home + Persona Badge
        StaggeredItemWrapper(
          index: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                key: const Key('context_detail_back_button'),
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
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 11, color: accentColor),
                    const SizedBox(width: 4),
                    Text(
                      userState.selectedPersona ?? 'Persona',
                      style: GoogleFonts.inter(
                        color: accentColor,
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 13.5,
                          color: accentColor,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Persona Context',
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
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => context.go('/health-metrics'),
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
                            Icons.favorite_border_rounded,
                            size: 13.5,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Health & Metrics',
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
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 3. Screen Headline Typography
        StaggeredItemWrapper(
          index: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overline: PERSONALIZED FOR [USER_NAME]
              Text(
                'PERSONALIZED FOR $userName'.toUpperCase(),
                style: GoogleFonts.inter(
                  color: accentColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),

              // Main Headline
              Text(
                'Lifestyle & Physical Context',
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
                'Daily climate adaptation tailored to your rhythm, biometrics, and triggers.',
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

        // Persona Context View Sections
        StaggeredItemWrapper(
          index: 2,
          child: _PersonaProfileCard(
            userState: userState,
            accentColor: accentColor,
          ),
        ),
        const SizedBox(height: 18),
        StaggeredItemWrapper(
          index: 3,
          child: _TodayAtAGlanceCard(
            dashboard: dash.data,
            userState: userState,
          ),
        ),
        const SizedBox(height: 20),
        StaggeredItemWrapper(
          index: 4,
          child: _ForYourDaySection(
            dashboard: dash.data,
            userState: userState,
          ),
        ),
        const SizedBox(height: 20),
        StaggeredItemWrapper(
          index: 5,
          child: _WhatShouldIDoSection(
            dashboard: dash.data,
            userState: userState,
          ),
        ),
        const SizedBox(height: 20),
        StaggeredItemWrapper(
          index: 6,
          child: _WhyTheseRecommendationsSection(
            dashboard: dash.data,
            userState: userState,
          ),
        ),
      ],
    );
  }
}

class _TodayAtAGlanceCard extends StatelessWidget {
  final WeatherDashboard? dashboard;
  final UserState? userState;

  const _TodayAtAGlanceCard({
    required this.dashboard,
    required this.userState,
  });

  @override
  Widget build(BuildContext context) {
    final current = dashboard?.current;
    final temp = current?.temperatureCelsius.round() ?? 28;
    final humidity = current?.humidityPercent ?? 81;
    final uv = current?.uvIndex ?? 0.0;
    final cond = current?.condition ?? 'Clear sky';
    final persona = userState?.selectedPersona ?? 'Fitness';
    final triggers = [
      ...?userState?.healthConcerns,
      ...?userState?.weatherTriggers,
    ];

    String uvLevelStr;
    if (uv <= 2) {
      uvLevelStr = 'Low';
    } else if (uv <= 5) {
      uvLevelStr = 'Moderate';
    } else if (uv <= 7) {
      uvLevelStr = 'High';
    } else if (uv <= 10) {
      uvLevelStr = 'Very High';
    } else {
      uvLevelStr = 'Extreme';
    }

    String headline;
    if (uv <= 2) {
      headline = 'Low UV calls for a gentler outdoor plan.';
    } else if (uv > 5) {
      headline = 'High UV calls for sun protection today.';
    } else if ((current?.rainMm1h ?? 0) > 0) {
      headline = 'Rain expected today — plan indoor transitions.';
    } else if (temp >= 33) {
      headline = 'High heat ahead — stay hydrated & seek shade.';
    } else {
      headline = 'Clear sky conditions — ideal for your daily rhythm.';
    }

    final concernLabel = triggers.isNotEmpty
        ? triggers.join(' & ').toLowerCase()
        : 'skin sensitivity';
    final narrative =
        '$cond conditions are around $temp°C, with UV at ${uv.round()}. Since you marked $concernLabel, plan longer outdoor time outside the Around 12:07 pm peak and follow today’s protection guidance.';

    final footerProfileText = triggers.isNotEmpty
        ? 'Based on your profile • ${triggers.join(' + ')}'
        : 'Based on your profile • $persona persona';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF141923),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF222B3D), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Pill Header: Sparkle Icon + "Today at a glance" + Share button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFFFB7185),
                          size: 12.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Today at a glance',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Personalized briefing copied to clipboard! ☀️',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                      ),
                      backgroundColor: const Color(0xFF1E2538),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(7),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.share_rounded, color: Color(0xFF94A3B8), size: 11),
                      const SizedBox(width: 3.5),
                      Text(
                        'Share',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Headline
          Text(
            headline,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.25,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),

          // Narrative Description
          Text(
            narrative,
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              height: 1.38,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 14),

          // Horizontal Divider
          const Divider(
            color: Color(0xFF222B3D),
            height: 1,
            thickness: 1,
          ),
          const SizedBox(height: 14),

          // 3-Column Metrics Row: UV | HUMIDITY | TEMPERATURE
          Row(
            children: [
              // UV
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UV',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${uv.round()} • $uvLevelStr',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // HUMIDITY
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HUMIDITY',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$humidity%',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // TEMPERATURE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TEMPERATURE',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$temp°C',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Lower Exposure / Optimal Window Pill Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF202634),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A3346)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.show_chart_rounded,
                      color: Color(0xFFFB7185),
                      size: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LOWER EXPOSURE',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getPersonaSaferWindow(persona),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Footer Profile Metadata Tag
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFFFB7185),
                size: 11,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  footerProfileText,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _getPersonaSaferWindow(String persona) {
  final pLower = persona.toLowerCase();
  if (pLower.contains('health') || pLower.contains('sensitive')) {
    return '6:30 am–8:30 am';
  } else if (pLower.contains('travel') || pLower.contains('sightseeing')) {
    return '8:00 am–11:30 am';
  } else if (pLower.contains('commut') || pLower.contains('drive') || pLower.contains('transit')) {
    return '7:30 am–9:15 am';
  } else if (pLower.contains('family') || pLower.contains('parent') || pLower.contains('kid')) {
    return '7:15 am–8:30 am';
  } else if (pLower.contains('garden') || pLower.contains('farm') || pLower.contains('plant')) {
    return '5:45 am–7:30 am';
  } else if (pLower.contains('event') || pLower.contains('party') || pLower.contains('planner')) {
    return '9:30 am–11:30 am';
  } else {
    return '5:30 am–7:30 am';
  }
}

class _ForYourDaySection extends StatelessWidget {
  final WeatherDashboard? dashboard;
  final UserState? userState;

  const _ForYourDaySection({
    required this.dashboard,
    required this.userState,
  });

  @override
  Widget build(BuildContext context) {
    final persona = userState?.selectedPersona ?? 'Fitness';
    final saferWindow = _getPersonaSaferWindow(persona);

    final current = dashboard?.current;
    final uv = current?.uvIndex ?? 0.0;

    String uvLevelStr;
    if (uv <= 2) {
      uvLevelStr = 'Low';
    } else if (uv <= 5) {
      uvLevelStr = 'Moderate';
    } else if (uv <= 7) {
      uvLevelStr = 'High';
    } else if (uv <= 10) {
      uvLevelStr = 'Very High';
    } else {
      uvLevelStr = 'Extreme';
    }

    String skinSubtitle;
    if (uv <= 2) {
      skinSubtitle = 'No protection needed for most people';
    } else if (uv <= 5) {
      skinSubtitle = 'Wear SPF 30+ outdoors';
    } else if (uv <= 8) {
      skinSubtitle = 'Seek shade during peak midday hours';
    } else {
      skinSubtitle = 'Avoid direct sun exposure';
    }

    String burnTimeStr;
    if (uv <= 2) {
      burnTimeStr = 'Burn time ~200 min';
    } else if (uv <= 5) {
      burnTimeStr = 'Burn time ~45 min';
    } else if (uv <= 8) {
      burnTimeStr = 'Burn time ~20 min';
    } else {
      burnTimeStr = 'Burn time ~10 min';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FOR YOUR DAY',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFB7185),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Today, personalized for you',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '4 essentials',
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2x2 Grid of Essential Cards
        Column(
          children: [
            // Row 1: SKIN & SUN | EXPOSURE
            Row(
              children: [
                Expanded(
                  child: _EssentialCard(
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFFFB7185),
                    iconBg: const Color(0x22FB7185),
                    category: 'SKIN & SUN',
                    value: 'UV ${uv.round()} • $uvLevelStr',
                    subtitle: skinSubtitle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _EssentialCard(
                    icon: Icons.light_mode_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    iconBg: const Color(0x22F59E0B),
                    category: 'EXPOSURE',
                    value: 'Peak Around 12:07 pm',
                    subtitle: burnTimeStr,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 2: SAFER WINDOW | EVENING
            Row(
              children: [
                Expanded(
                  child: _EssentialCard(
                    icon: Icons.trending_up_rounded,
                    iconColor: const Color(0xFF34D399),
                    iconBg: const Color(0x2234D399),
                    category: 'SAFER WINDOW',
                    value: saferWindow,
                    subtitle: 'Good conditions $saferWindow',
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: _EssentialCard(
                    icon: Icons.nights_stay_outlined,
                    iconColor: Color(0xFFA78BFA),
                    iconBg: Color(0x22A78BFA),
                    category: 'EVENING',
                    value: '5:49 pm',
                    subtitle: 'Sunset 6:16 pm',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _EssentialCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String category;
  final String value;
  final String subtitle;

  const _EssentialCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.category,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF141923),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222B3D), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Squircle Icon
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                icon,
                color: iconColor,
                size: 15,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Category Header
          Text(
            category,
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 3),

          // Main Value
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),

          // Subtitle
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w400,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}


class _WhatShouldIDoSection extends StatefulWidget {
  final WeatherDashboard? dashboard;
  final UserState? userState;

  const _WhatShouldIDoSection({
    required this.dashboard,
    required this.userState,
  });

  @override
  State<_WhatShouldIDoSection> createState() => _WhatShouldIDoSectionState();
}

class _WhatShouldIDoSectionState extends State<_WhatShouldIDoSection> {
  final Set<int> _completedSteps = {};

  @override
  Widget build(BuildContext context) {
    final current = widget.dashboard?.current;
    final uv = current?.uvIndex ?? 0.0;

    final persona = widget.userState?.selectedPersona ?? 'Fitness';
    final pLower = persona.toLowerCase();

    String step1Title;
    String step1Subtitle;
    String step3Title;
    String step3Subtitle;

    if (pLower.contains('health') || pLower.contains('sensitive')) {
      step1Title = 'Plan outdoor walk 6:30 am–8:30 am';
      step1Subtitle = 'Optimal clean air & low humidity window';
      step3Title = 'Ventilate home 7:30 pm–9:00 pm';
      step3Subtitle = 'Calm evening air for respiratory comfort';
    } else if (pLower.contains('travel') || pLower.contains('sightseeing')) {
      step1Title = 'Start outdoor sightseeing 8:00 am–11:30 am';
      step1Subtitle = 'Clear morning light before midday solar heat';
      step3Title = 'Evening city exploration 5:00 pm–8:30 pm';
      step3Subtitle = 'Pleasant sunset views & mild transit weather';
    } else if (pLower.contains('commut') || pLower.contains('drive') || pLower.contains('transit')) {
      step1Title = 'Morning commute window 7:30 am–9:15 am';
      step1Subtitle = 'Check visibility & road surface dampness';
      step3Title = 'Evening return commute 5:00 pm–7:15 pm';
      step3Subtitle = 'Monitor rush hour rain hazard & sunset glare';
    } else if (pLower.contains('family') || pLower.contains('parent') || pLower.contains('kid')) {
      step1Title = 'School run window 7:15 am–8:30 am';
      step1Subtitle = 'Morning rain check & kid raincoat readiness';
      step3Title = 'Kids playground & park window 4:30 pm–6:30 pm';
      step3Subtitle = 'Cooler park conditions & low sun exposure';
    } else if (pLower.contains('garden') || pLower.contains('farm') || pLower.contains('plant')) {
      step1Title = 'Water garden early 5:45 am–7:30 am';
      step1Subtitle = 'Maximum soil absorption before solar evaporation';
      step3Title = 'Evening foliage care 5:00 pm–6:45 pm';
      step3Subtitle = 'Check dew point & overnight frost risk';
    } else if (pLower.contains('event') || pLower.contains('party') || pLower.contains('planner')) {
      step1Title = 'Event setup & stage check 9:30 am–11:30 am';
      step1Subtitle = 'Verify canopy tie-downs & morning wind speed';
      step3Title = 'Main outdoor event 4:30 pm–9:30 pm';
      step3Subtitle = 'Ideal guest thermal comfort & evening ambiance';
    } else {
      step1Title = 'Use 5:30 am–7:30 am for outdoor run';
      step1Subtitle = 'Cool pavement & optimal heart-rate regulation';
      step3Title = 'Post-work workout 5:30 pm–7:15 pm';
      step3Subtitle = 'Sunset window with declining temperature';
    }

    String step2Title;
    String step2Subtitle;
    if (uv <= 2) {
      step2Title = 'No protection needed for most people';
      step2Subtitle = 'UV is ${uv.round()} (Low) today.';
    } else if (uv <= 5) {
      step2Title = 'Apply SPF 30+ sun protection';
      step2Subtitle = 'UV is ${uv.round()} (Moderate) today.';
    } else {
      step2Title = 'Limit direct sun exposure at midday';
      step2Subtitle = 'UV is ${uv.round()} (High) today.';
    }

    final completedCount = _completedSteps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Completion Counter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SIMPLE NEXT STEPS',
              style: GoogleFonts.inter(
                color: const Color(0xFFFB7185),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            if (completedCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0x2234D399),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x4434D399)),
                ),
                child: Text(
                  '$completedCount of 3 done ✓',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF34D399),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          'What should I do?',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),

        // List Container Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF141923),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF222B3D), width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Step 01
              _StepActionTile(
                number: '01',
                icon: Icons.trending_up_rounded,
                iconColor: const Color(0xFF34D399),
                iconBg: const Color(0x2234D399),
                title: step1Title,
                subtitle: step1Subtitle,
                isCompleted: _completedSteps.contains(1),
                onTap: () {
                  setState(() {
                    if (_completedSteps.contains(1)) {
                      _completedSteps.remove(1);
                    } else {
                      _completedSteps.add(1);
                    }
                  });
                },
              ),

              const Divider(color: Color(0xFF222B3D), height: 1, thickness: 1),

              // Step 02
              _StepActionTile(
                number: '02',
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFFFB7185),
                iconBg: const Color(0x22FB7185),
                title: step2Title,
                subtitle: step2Subtitle,
                isCompleted: _completedSteps.contains(2),
                onTap: () {
                  setState(() {
                    if (_completedSteps.contains(2)) {
                      _completedSteps.remove(2);
                    } else {
                      _completedSteps.add(2);
                    }
                  });
                },
              ),

              const Divider(color: Color(0xFF222B3D), height: 1, thickness: 1),

              // Step 03
              _StepActionTile(
                number: '03',
                icon: Icons.nights_stay_outlined,
                iconColor: const Color(0xFFA78BFA),
                iconBg: const Color(0x22A78BFA),
                title: step3Title,
                subtitle: step3Subtitle,
                isCompleted: _completedSteps.contains(3),
                onTap: () {
                  setState(() {
                    if (_completedSteps.contains(3)) {
                      _completedSteps.remove(3);
                    } else {
                      _completedSteps.add(3);
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepActionTile extends StatelessWidget {
  final String number;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final VoidCallback onTap;

  const _StepActionTile({
    required this.number,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Step Number
            SizedBox(
              width: 24,
              child: Text(
                number,
                style: GoogleFonts.inter(
                  color: isCompleted ? const Color(0xFF34D399) : const Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Squircle Icon Container
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0x3334D399) : iconBg,
                borderRadius: BorderRadius.circular(10),
                border: isCompleted
                    ? Border.all(color: const Color(0xFF34D399), width: 1.2)
                    : null,
              ),
              child: Center(
                child: Icon(
                  isCompleted ? Icons.check_rounded : icon,
                  color: isCompleted ? const Color(0xFF34D399) : iconColor,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Title & Subtitle Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: isCompleted ? const Color(0xFF94A3B8) : Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhyTheseRecommendationsSection extends StatefulWidget {
  final WeatherDashboard? dashboard;
  final UserState? userState;

  const _WhyTheseRecommendationsSection({
    required this.dashboard,
    required this.userState,
  });

  @override
  State<_WhyTheseRecommendationsSection> createState() =>
      _WhyTheseRecommendationsSectionState();
}

class _WhyTheseRecommendationsSectionState
    extends State<_WhyTheseRecommendationsSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final current = widget.dashboard?.current;
    final uv = current?.uvIndex ?? 0.0;
    final temp = current?.temperatureCelsius.round() ?? 28;
    final humidity = current?.humidityPercent ?? 81;

    String uvLevelStr;
    if (uv <= 2) {
      uvLevelStr = 'Low';
    } else if (uv <= 5) {
      uvLevelStr = 'Moderate';
    } else if (uv <= 7) {
      uvLevelStr = 'High';
    } else if (uv <= 10) {
      uvLevelStr = 'Very High';
    } else {
      uvLevelStr = 'Extreme';
    }

    final userSensitivities = [
      ...?widget.userState?.healthConcerns,
      ...?widget.userState?.weatherTriggers,
    ];

    final sensitivities = userSensitivities.isNotEmpty
        ? userSensitivities
        : const ['Dust', 'Pollen', 'AQI / smoke', 'Humidity', 'Cold'];

    return Column(
      children: [
        // Main Collapsible Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF141923),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF222B3D), width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header Row (Tappable to expand/collapse)
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Question Icon Container
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xFF282F3B),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '?',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFE2E8F0),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Why these recommendations?',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'See the signals used for your briefing',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF94A3B8),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF94A3B8),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded Content
              if (_isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Text
                      Text(
                        'Mausam combines today’s weather factors with the sensitivities you selected during setup.',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),

                      const Divider(color: Color(0xFF222B3D), height: 1, thickness: 1),

                      // Metric 1: UV
                      _FactorSignalRow(
                        label: 'UV',
                        value: '${uv.round()} · $uvLevelStr',
                      ),
                      const Divider(color: Color(0xFF222B3D), height: 1, thickness: 1),

                      // Metric 2: Humidity
                      _FactorSignalRow(
                        label: 'Humidity',
                        value: '$humidity%',
                      ),
                      const Divider(color: Color(0xFF222B3D), height: 1, thickness: 1),

                      // Metric 3: Temperature
                      _FactorSignalRow(
                        label: 'Temperature',
                        value: '$temp°C',
                      ),
                      const SizedBox(height: 12),

                      // Sensitivities Pill Wrap
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: sensitivities.map((item) {
                          // Highlight active triggers like AQI / smoke or Humidity or user triggers
                          final isHighlighted = item.contains('AQI') ||
                              item.contains('Humidity') ||
                              (widget.userState?.weatherTriggers.contains(item) ?? false);

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isHighlighted
                                  ? const Color(0xFF3B2329)
                                  : const Color(0xFF232834),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isHighlighted
                                    ? const Color(0x66FB7185)
                                    : const Color(0xFF2E3545),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              item,
                              style: GoogleFonts.inter(
                                color: isHighlighted
                                    ? const Color(0xFFFB7185)
                                    : const Color(0xFF94A3B8),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Bottom Disclaimer
        Center(
          child: Text(
            'Weather guidance only — not medical advice',
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _FactorSignalRow extends StatelessWidget {
  final String label;
  final String value;

  const _FactorSignalRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonaProfileCard extends StatelessWidget {
  final UserState? userState;
  final Color accentColor;

  const _PersonaProfileCard({
    required this.userState,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final persona = userState?.selectedPersona ?? 'Fitness';
    final age = userState?.age != null ? '${userState!.age} yrs' : 'Not set';
    final gender = userState?.gender ?? 'Not set';
    final height = userState?.height != null ? '${userState!.height!.round()} ${userState?.heightUnit ?? "cm"}' : 'Not set';
    final weight = userState?.weight != null ? '${userState!.weight!.round()} ${userState?.weightUnit ?? "kg"}' : 'Not set';
    final activity = userState?.activityLevel ?? 'Moderate';
    final triggers = userState?.weatherTriggers ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF141923),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF222B3D), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6.5),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.tune_rounded, color: accentColor, size: 15),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACTIVE PERSONA',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: accentColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.9,
                            ),
                          ),
                          Text(
                            persona,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2638),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: const Color(0xFF2E3B55)),
                ),
                child: Text(
                  activity,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF38BDF8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Profile & Physical Context',
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _ProfilePill(label: 'AGE', value: age),
              _ProfilePill(label: 'GENDER', value: gender),
              _ProfilePill(label: 'HEIGHT', value: height),
              _ProfilePill(label: 'WEIGHT', value: weight),
            ],
          ),
          if (triggers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Weather Triggers Monitored',
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: triggers.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2333),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF2A344A)),
                ),
                child: Text(
                  t,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfilePill extends StatelessWidget {
  final String label;
  final String value;

  const _ProfilePill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2333),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF283247)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

