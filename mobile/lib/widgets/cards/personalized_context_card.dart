import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/weather_dashboard.dart';
import '../../providers/appearance_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/weather_palette.dart';

/// Compact, personalized context card placed directly below the top navbar
/// on the Home screen before the main Weather Hero.
///
/// Communicates:
/// - Greeting based on local time of day
/// - Real user profile name
/// - Current active location
/// - Live conditions being watched (e.g. Rain + AQI, Heat + UV)
///
/// Strictly monochrome obsidian aesthetic: black, white, grayscale only.
class PersonalizedContextCard extends ConsumerWidget {
  final String locationName;
  final WeatherDashboard? dashboard;
  final UserState? userStateOverride;
  final int? hourOverride;
  final String? userNameOverride;
  final VoidCallback? onTap;

  const PersonalizedContextCard({
    super.key,
    required this.locationName,
    this.dashboard,
    this.userStateOverride,
    this.hourOverride,
    this.userNameOverride,
    this.onTap,
  });

  /// Computes time-of-day greeting string based on the provided hour (0..23).
  static String greetingForHour(int hour) {
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else if (hour >= 17 && hour < 22) {
      return 'Good evening';
    } else {
      return 'Good night';
    }
  }

  /// Resolves the user's display name from user state, FirebaseAuth, or email.
  static String resolveUserName(UserState? userState) {
    // 1. Explicit display name in UserState or Firebase User
    final displayName = userState?.displayName ?? _safeFirebaseDisplayName();
    if (displayName != null && displayName.trim().isNotEmpty) {
      final firstToken = displayName.trim().split(RegExp(r'\s+')).first;
      return _capitalize(firstToken);
    }

    // 2. Email prefix for registered (non-guest) accounts
    final email = userState?.email ?? _safeFirebaseEmail();
    if (email != null && email.isNotEmpty && !email.toLowerCase().startsWith('guest@')) {
      final prefix = email.split('@').first;
      final firstToken = prefix.split(RegExp(r'[._\-]')).first;
      if (firstToken.isNotEmpty) {
        return _capitalize(firstToken);
      }
    }

    // 3. Fallback for guest or unspecified profile
    if (userState?.isGuest == true) {
      return 'Guest';
    }
    return 'User';
  }

  static String? _safeFirebaseDisplayName() {
    try {
      return FirebaseAuth.instance.currentUser?.displayName;
    } catch (_) {
      return null;
    }
  }

  static String? _safeFirebaseEmail() {
    try {
      return FirebaseAuth.instance.currentUser?.email;
    } catch (_) {
      return null;
    }
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + (s.length > 1 ? s.substring(1).toLowerCase() : '');
  }

  /// Intelligently derives the conditions Mausam is currently watching
  /// based on live weather data, AQI, time of day, and user persona.
  static String resolveWatchingConditions({
    WeatherDashboard? dashboard,
    String? persona,
    int? hour,
  }) {
    final current = dashboard?.current;
    final temp = current?.temperatureCelsius;
    final rain = current?.rainMm1h ?? 0.0;
    final cond = (current?.condition ?? '').toLowerCase();
    final uv = current?.uvIndex ?? 0.0;
    final wind = current?.windSpeedKmh ?? 0.0;
    final aqi = dashboard?.aqi?.aqiValue ?? 0;
    final localHour = hour ?? DateTime.now().hour;
    final activePersona = persona ?? 'Fitness';
    final isNight = localHour >= 21 || localHour < 5;

    final isRain = rain > 0.0 ||
        cond.contains('rain') ||
        cond.contains('drizzle') ||
        cond.contains('shower');
    final isStorm = cond.contains('thunder') || cond.contains('storm');
    final hasUpcomingRain = (dashboard?.hourly ?? []).take(3).any((h) => h.rainProbabilityPercent >= 40);

    final isAqiElevated = aqi >= 80 || (activePersona == 'Health' && aqi >= 60);
    final isAqiHigh = aqi >= 120;

    final isHeat = (temp != null && temp >= 32.0) || ((current?.feelsLikeCelsius ?? 0) >= 34.0);
    final isUvHigh = uv >= 5.0 && localHour >= 9 && localHour <= 17;
    final isWindy = wind >= 22.0;
    final isCold = temp != null && temp <= 12.0;

    final List<String> triggers = [];

    // Prioritized condition extraction
    if (isStorm) {
      triggers.add('Storm');
    } else if (isRain || hasUpcomingRain) {
      triggers.add('Rain');
    }

    if (isHeat) {
      triggers.add('Heat');
    }

    if (isUvHigh) {
      triggers.add('UV');
    }

    if (isAqiElevated || isAqiHigh) {
      triggers.add(isNight ? 'Air Quality' : 'AQI');
    }

    if (isWindy) {
      triggers.add('Wind');
    }

    if (isCold) {
      triggers.add('Chill');
    }

    // Persona-informed default when conditions are mild
    if (triggers.isEmpty) {
      if (isNight) {
        triggers.add('Air Quality');
      } else if (activePersona == 'Health') {
        triggers.add(aqi > 0 ? 'Air Quality' : 'Clean Air');
      } else if (activePersona == 'Fitness') {
        triggers.add((localHour >= 6 && localHour < 10) || (localHour >= 16 && localHour < 19)
            ? 'Running Window'
            : 'Clear Skies');
      } else if (activePersona == 'Traveler') {
        triggers.add('Commute Comfort');
      } else {
        triggers.add('Clear Skies');
      }
    }

    // Limit to top 2 conditions combined with ' + '
    return triggers.take(2).join(' + ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = userStateOverride ?? ref.watch(userProvider);
    final surfaceOpacity = ref.watch(cardSurfaceOpacityProvider);

    final hour = hourOverride ?? DateTime.now().hour;
    final greeting = greetingForHour(hour);
    final userName = userNameOverride ?? resolveUserName(userState);
    final persona = userState?.selectedPersona ?? 'Fitness';

    final cleanLocation = locationName.split(',').first.trim().isNotEmpty
        ? locationName.split(',').first.trim()
        : 'Active Location';

    final watchingConditions = resolveWatchingConditions(
      dashboard: dashboard,
      persona: userState?.selectedPersona,
      hour: hour,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: MausamPalette.cardSurface.withValues(alpha: surfaceOpacity),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MausamPalette.cardBorder, width: 1.0),
        boxShadow: MausamPalette.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.05),
          highlightColor: Colors.white.withValues(alpha: 0.02),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Leading Icon Squircle + Titles + Trailing Chevron
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: MausamPalette.cardSurfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: MausamPalette.cardBorderSubtle),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: MausamPalette.textPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting, $userName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: MausamPalette.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Personalised for $cleanLocation',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: MausamPalette.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: MausamPalette.cardSurfaceLight.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: MausamPalette.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Bottom Pill: Live Watching Status & Persona Capsule
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: MausamPalette.bgDeep.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: MausamPalette.cardBorderSubtle),
                  ),
                  child: Row(
                    children: [
                      // Live pulse indicator
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: MausamPalette.textPrimary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: MausamPalette.textPrimary.withValues(alpha: 0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Watching $watchingConditions',
                          style: GoogleFonts.inter(
                            color: MausamPalette.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (persona.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: MausamPalette.cardSurfaceLight,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: MausamPalette.cardBorderSubtle),
                          ),
                          child: Text(
                            persona.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: MausamPalette.textTertiary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
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
