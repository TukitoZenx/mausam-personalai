import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/appearance_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../theme/weather_palette.dart';
import '../widgets/navigation/shell_section_title.dart';
import '../widgets/staggered_item_wrapper.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final bool _notifications = true;
  bool _locationAccess = true;
  bool _tempIsCelsius = true;
  bool _windIsKmh = true;
  bool _offlineCacheEnabled = true;
  bool _notifyRain = true;
  bool _notifyAqi = true;
  bool _morningBrief = true;
  String _cacheSize = '1.4 MB';

  @override
  void initState() {
    super.initState();
    _loadLocalPrefs();
  }

  Future<void> _loadLocalPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _tempIsCelsius = prefs.getBool('pref_temp_celsius') ?? true;
        _windIsKmh = prefs.getBool('pref_wind_kmh') ?? true;
        _offlineCacheEnabled = prefs.getBool('pref_offline_cache') ?? true;
        _notifyRain = prefs.getBool('notify_rain') ?? true;
        _notifyAqi = prefs.getBool('notify_aqi') ?? true;
        _morningBrief = prefs.getBool('pref_morning_brief') ?? true;
        final raw = prefs.getString('weather_dashboard_cache_v1');
        if (raw == null || raw.isEmpty) {
          _cacheSize = '0 KB';
        } else {
          final kb = (raw.length / 1024).toStringAsFixed(1);
          _cacheSize = '$kb KB';
        }
      });
    } catch (_) {}
  }

  Future<void> _saveBoolPref(String key, bool val) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, val);
    } catch (_) {}
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('weather_dashboard_cache_v1');
      if (!mounted) return;
      setState(() {
        _cacheSize = '0 KB';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Weather cache cleared successfully (0 KB).',
            style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white),
          ),
          backgroundColor: MausamPalette.cardSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (_) {}
  }

  Future<void> _updatePersona(String persona) async {
    final userNotifier = ref.read(userProvider.notifier);
    final apiClient = ref.read(apiClientProvider);
    final userState = ref.read(userProvider);
    final idToken = userState.idToken ?? 'test_token';

    userNotifier.setPersona(persona);

    try {
      await apiClient.postUser(
        idToken: idToken,
        email: userState.email ?? 'guest@mausam.ai',
        personaType: persona,
        notificationsEnabled: _notifications,
        locationAccess: _locationAccess,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched persona to $persona'),
            backgroundColor: MausamPalette.cardSurface,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      // Persona updated locally in Riverpod even if backend network call fails
    }
  }

  Future<void> _logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.signOut();
    if (!mounted) return;
    ref.read(userProvider.notifier).signOut();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final activePersona = userState.selectedPersona ?? 'Fitness';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 72, 16, 100),
      children: [
        const ShellSectionTitle('PROFILE & SETTINGS'),
            // Account Badge Card
            StaggeredItemWrapper(
              index: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: MausamPalette.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MausamPalette.cardBorder),
                  boxShadow: MausamPalette.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: MausamPalette.cardSurfaceLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: MausamPalette.cardBorder),
                      ),
                      child: const Icon(Icons.person_rounded, color: MausamPalette.textPrimary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userState.email?.split('@').first ?? 'Mausam User',
                            style: GoogleFonts.inter(
                              color: MausamPalette.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userState.email ?? 'guest@mausam.ai',
                            style: GoogleFonts.inter(
                              color: MausamPalette.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Persona Selection Section
            Text(
              'ACTIVE PERSONA',
              style: GoogleFonts.inter(
                color: MausamPalette.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            StaggeredItemWrapper(
              index: 1,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MausamPalette.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MausamPalette.cardBorder),
                ),
                child: Column(
                  children: [
                    _personaTile(
                      title: 'Fitness Persona',
                      subtitle: 'Optimized for running windows, outdoor exercise & UV exposure.',
                      icon: Icons.directions_run_rounded,
                      color: MausamPalette.personaFitness,
                      isSelected: activePersona == 'Fitness',
                      onTap: () => _updatePersona('Fitness'),
                    ),
                    const Divider(color: MausamPalette.cardBorderSubtle, height: 16),
                    _personaTile(
                      title: 'Health Focus',
                      subtitle: 'Focuses on air quality precautions, AQI alerts & respiratory safety.',
                      icon: Icons.favorite_rounded,
                      color: MausamPalette.personaHealth,
                      isSelected: activePersona == 'Health',
                      onTap: () => _updatePersona('Health'),
                    ),
                    const Divider(color: MausamPalette.cardBorderSubtle, height: 16),
                    _personaTile(
                      title: 'Traveler Persona',
                      subtitle: 'Sightseeing comfort, commute rain warnings & packing essentials.',
                      icon: Icons.flight_takeoff_rounded,
                      color: MausamPalette.personaTraveler,
                      isSelected: activePersona == 'Traveler',
                      onTap: () => _updatePersona('Traveler'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Units of Measure
            Text(
              'UNITS OF MEASURE',
              style: GoogleFonts.inter(
                color: MausamPalette.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            StaggeredItemWrapper(
              index: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MausamPalette.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MausamPalette.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Temperature',
                              style: GoogleFonts.inter(
                                color: MausamPalette.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _tempIsCelsius ? 'Metric (°Celsius)' : 'Imperial (°Fahrenheit)',
                              style: GoogleFonts.inter(
                                color: MausamPalette.textSecondary,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF141417),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF27272A)),
                          ),
                          child: Row(
                            children: [
                              _unitButton('°C', _tempIsCelsius, () {
                                setState(() => _tempIsCelsius = true);
                                _saveBoolPref('pref_temp_celsius', true);
                              }),
                              _unitButton('°F', !_tempIsCelsius, () {
                                setState(() => _tempIsCelsius = false);
                                _saveBoolPref('pref_temp_celsius', false);
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: MausamPalette.cardBorderSubtle, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wind & Speed',
                              style: GoogleFonts.inter(
                                color: MausamPalette.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _windIsKmh ? 'Kilometers/hour (km/h)' : 'Miles/hour (mph)',
                              style: GoogleFonts.inter(
                                color: MausamPalette.textSecondary,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF141417),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF27272A)),
                          ),
                          child: Row(
                            children: [
                              _unitButton('km/h', _windIsKmh, () {
                                setState(() => _windIsKmh = true);
                                _saveBoolPref('pref_wind_kmh', true);
                              }),
                              _unitButton('mph', !_windIsKmh, () {
                                setState(() => _windIsKmh = false);
                                _saveBoolPref('pref_wind_kmh', false);
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Appearance: Single Obsidian Night Theme
            Text(
              'APPEARANCE & ATMOSPHERE',
              style: GoogleFonts.inter(
                color: MausamPalette.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            StaggeredItemWrapper(
              index: 3,
              child: Consumer(
                builder: (context, ref, child) {
                  final appearance = ref.watch(appearanceProvider);
                  final opacity = ref.watch(cardSurfaceOpacityProvider);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: MausamPalette.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: MausamPalette.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Single Theme Indicator
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141417),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF27272A)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF09090B),
                                ),
                                child: const Icon(Icons.nightlight_round, color: Color(0xFFD4D4D8), size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Mausam Obsidian Night',
                                      style: GoogleFonts.inter(
                                        color: MausamPalette.textPrimary,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Ultra-dark OLED palette • Single luxury theme',
                                      style: GoogleFonts.inter(
                                        color: MausamPalette.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF222226),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'ACTIVE',
                                  style: GoogleFonts.inter(
                                    color: MausamPalette.textPrimary,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Card Glassmorphism & Opacity',
                              style: GoogleFonts.inter(
                                color: MausamPalette.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: MausamPalette.cardSurfaceLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${appearance.transparencyPercent}%',
                                style: GoogleFonts.inter(
                                  color: MausamPalette.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: MausamTypography.tabularFeatures,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Solid (OLED)', style: GoogleFonts.inter(color: MausamPalette.textTertiary, fontSize: 11)),
                            Text('Glass (Translucent)', style: GoogleFonts.inter(color: MausamPalette.textTertiary, fontSize: 11)),
                          ],
                        ),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: MausamPalette.textSecondary,
                            inactiveTrackColor: MausamPalette.cardBorder,
                            thumbColor: MausamPalette.textPrimary,
                            overlayColor: MausamPalette.textPrimary.withValues(alpha: 0.12),
                          ),
                          child: Slider(
                            value: appearance.transparencyPercent.toDouble(),
                            min: 0,
                            max: 100,
                            divisions: 20,
                            onChanged: (val) {
                              ref.read(appearanceProvider.notifier).setTransparency(val.round());
                            },
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Live Preview Widget
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: MausamPalette.cardSurface.withValues(alpha: opacity),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: MausamPalette.cardBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cloud_queue_rounded, color: MausamPalette.textPrimary, size: 24),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '28°C • Clear Obsidian Night',
                                    style: GoogleFonts.inter(
                                      color: MausamPalette.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Surface opacity ${(opacity * 100).round()}% preview',
                                    style: GoogleFonts.inter(
                                      color: MausamPalette.textSecondary,
                                      fontSize: 11,
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
                },
              ),
            ),

            const SizedBox(height: 24),

            // Performance & Cache Management
            Text(
              'PERFORMANCE & CACHE',
              style: GoogleFonts.inter(
                color: MausamPalette.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            StaggeredItemWrapper(
              index: 4,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MausamPalette.cardBorder),
                ),
                child: Material(
                  color: MausamPalette.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _offlineCacheEnabled,
                        onChanged: (val) {
                          setState(() => _offlineCacheEnabled = val);
                          _saveBoolPref('pref_offline_cache', val);
                        },
                        activeThumbColor: MausamPalette.textPrimary,
                        title: Text(
                          'Fast Launch & Offline Cache',
                          style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Instantly render last known weather conditions on app startup',
                          style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 11.5),
                        ),
                      ),
                      const Divider(color: MausamPalette.cardBorderSubtle, height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Weather Data Storage',
                                  style: GoogleFonts.inter(
                                    color: MausamPalette.textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Local offline cache: $_cacheSize',
                                  style: GoogleFonts.inter(
                                    color: MausamPalette.textSecondary,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                            OutlinedButton.icon(
                              onPressed: _clearCache,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: MausamPalette.textPrimary,
                                side: const BorderSide(color: Color(0xFF27272A)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                              label: Text(
                                'Clear Cache',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
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

            const SizedBox(height: 24),

            // Smart Alerts & Notifications
            Text(
              'SMART WEATHER & HEALTH ALERTS',
              style: GoogleFonts.inter(
                color: MausamPalette.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            StaggeredItemWrapper(
              index: 5,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MausamPalette.cardBorder),
                ),
                child: Material(
                  color: MausamPalette.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _notifyRain,
                        onChanged: (val) {
                          setState(() => _notifyRain = val);
                          _saveBoolPref('notify_rain', val);
                        },
                        activeThumbColor: MausamPalette.textPrimary,
                        title: Text(
                          'Severe Rain & Monsoon Alerts',
                          style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Instant push when rain chance exceeds 70% or thunderstorm forms',
                          style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 11.5),
                        ),
                      ),
                      const Divider(color: MausamPalette.cardBorderSubtle, height: 1),
                      SwitchListTile(
                        value: _notifyAqi,
                        onChanged: (val) {
                          setState(() => _notifyAqi = val);
                          _saveBoolPref('notify_aqi', val);
                        },
                        activeThumbColor: MausamPalette.textPrimary,
                        title: Text(
                          'High CPCB Pollution Alert',
                          style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Notifies when Indian AQI exceeds Moderate threshold (>150)',
                          style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 11.5),
                        ),
                      ),
                      const Divider(color: MausamPalette.cardBorderSubtle, height: 1),
                      SwitchListTile(
                        value: _morningBrief,
                        onChanged: (val) {
                          setState(() => _morningBrief = val);
                          _saveBoolPref('pref_morning_brief', val);
                        },
                        activeThumbColor: MausamPalette.textPrimary,
                        title: Text(
                          'Morning Daily Briefing',
                          style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Daily 7:00 AM summary of temperature, rain probability & packing tips',
                          style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 11.5),
                        ),
                      ),
                      const Divider(color: MausamPalette.cardBorderSubtle, height: 1),
                      SwitchListTile(
                        value: _locationAccess,
                        onChanged: (val) => setState(() => _locationAccess = val),
                        activeThumbColor: MausamPalette.textPrimary,
                        title: Text(
                          'Continuous GPS Auto-Detection',
                          style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Automatically resolves nearest weather station as you travel',
                          style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Data Sources & About
            Text(
              'DATA SOURCES & TRANSPARENCY',
              style: GoogleFonts.inter(
                color: MausamPalette.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            StaggeredItemWrapper(
              index: 6,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MausamPalette.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MausamPalette.cardBorder),
                ),
                child: Column(
                  children: [
                    _sourceRow(
                      'Indian Central Pollution Control Board',
                      'Official Indian National AQI station network (PM2.5, PM10, NO2, SO2, CO, O3)',
                      Icons.account_balance_rounded,
                    ),
                    const Divider(color: MausamPalette.cardBorderSubtle, height: 20),
                    _sourceRow(
                      'Open-Meteo Weather APIs',
                      'High-resolution ECMWF / GFS ensemble global meteorological forecast',
                      Icons.cloud_sync_rounded,
                    ),
                    const Divider(color: MausamPalette.cardBorderSubtle, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mausam PersonalAI Version',
                          style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'v1.2.0 • Production Release',
                          style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Logout Button
            StaggeredItemWrapper(
              index: 7,
              child: Center(
                child: TextButton.icon(
                  onPressed: _logout,
                  style: TextButton.styleFrom(
                    foregroundColor: MausamPalette.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(
                    'Sign Out',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        );
  }

  Widget _unitButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF27272A) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? MausamPalette.textPrimary : MausamPalette.textTertiary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _sourceRow(String title, String subtitle, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MausamPalette.cardSurfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: MausamPalette.cardBorderSubtle),
          ),
          child: Icon(icon, color: MausamPalette.textPrimary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: MausamPalette.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: MausamPalette.textSecondary,
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _personaTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: MausamPalette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 12, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: isSelected ? color : MausamPalette.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
