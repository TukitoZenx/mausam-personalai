import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/appearance_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/units_provider.dart';
import '../providers/user_provider.dart';
import '../theme/environment_theme.dart';
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
  bool _offlineCacheEnabled = true;
  bool _notifyRain = true;
  bool _notifyHeat = true;
  bool _notifyAqi = true;
  bool _morningBrief = true;
  String _cacheSize = '1.4 MB';

  static const List<Map<String, dynamic>> _personas = [
    {
      'id': 'Fitness',
      'title': 'Outdoor fitness',
      'subtitle': 'Workout windows, UV, heat.',
      'icon': Icons.directions_run_rounded,
      'color': MausamPalette.personaFitness,
    },
    {
      'id': 'Health',
      'title': 'Health-conscious',
      'subtitle': 'AQI, UV, humidity.',
      'icon': Icons.favorite_rounded,
      'color': MausamPalette.personaHealth,
    },
    {
      'id': 'Traveler',
      'title': 'Traveler',
      'subtitle': 'Destinations, packing, severe weather.',
      'icon': Icons.flight_takeoff_rounded,
      'color': MausamPalette.personaTraveler,
    },
    {
      'id': 'Commuter',
      'title': 'Commuter',
      'subtitle': 'Visibility, storms, travel conditions.',
      'icon': Icons.commute_rounded,
      'color': Color(0xFF38BDF8),
    },
    {
      'id': 'Family',
      'title': 'Parents / family',
      'subtitle': 'School run and rain warnings.',
      'icon': Icons.family_restroom_rounded,
      'color': Color(0xFFF472B6),
    },
    {
      'id': 'Garden',
      'title': 'Garden / farm',
      'subtitle': 'Rainfall and frost risk.',
      'icon': Icons.grass_rounded,
      'color': Color(0xFF34D399),
    },
    {
      'id': 'Events',
      'title': 'Event planner',
      'subtitle': 'Rain chance and outdoor comfort.',
      'icon': Icons.event_rounded,
      'color': Color(0xFFF59E0B),
    },
  ];

  static const List<String> _weatherTriggersList = [
    'Dust',
    'Pollen',
    'AQI / smoke',
    'Humidity',
    'Heat',
    'Monsoon damp',
    'Cold',
    'UV / sun',
  ];

  static const List<String> _healthConcernsList = [
    'Asthma',
    'Allergies',
    'Migraine',
    'Skin sensitivity',
    'Heart health',
    'None of these',
  ];

  static const Map<String, String> _triggerIcons = {
    'Dust': '🌫',
    'Pollen': '🌸',
    'AQI / smoke': '💨',
    'Humidity': '💧',
    'Heat': '☀️',
    'Monsoon damp': '🌧',
    'Cold': '❄️',
    'UV / sun': '🕶',
    'Asthma': '🫁',
    'Allergies': '🤧',
    'Migraine': '🧠',
    'Skin sensitivity': '✨',
    'Heart health': '❤️',
    'None of these': '🛡',
  };

  static const List<String> _mattersMostList = [
    'Daily energy',
    'Outdoor plans',
    'Fitness',
    'Sleep',
    'Travel',
    'Family care',
  ];

  static const List<String> _activityLevels = [
    'Low',
    'Moderate',
    'High',
  ];

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
        _offlineCacheEnabled = prefs.getBool('pref_offline_cache') ?? true;
        _notifyRain = prefs.getBool('notify_rain') ?? true;
        _notifyHeat = prefs.getBool('notify_heat') ?? true;
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

  Future<void> _togglePersona(String personaId) async {
    final userState = ref.read(userProvider);
    final userNotifier = ref.read(userProvider.notifier);
    final currentPersonas = List<String>.from(userState.selectedPersonas);

    if (currentPersonas.contains(personaId)) {
      if (currentPersonas.length > 1) {
        currentPersonas.remove(personaId);
      }
    } else {
      currentPersonas.add(personaId);
    }

    userNotifier.setPersonas(currentPersonas);

    final apiClient = ref.read(apiClientProvider);
    final idToken = userState.idToken ?? 'test_token';

    try {
      await apiClient.postUser(
        idToken: idToken,
        email: userState.email ?? 'guest@mausam.ai',
        personaType: currentPersonas.isNotEmpty ? currentPersonas.first : 'Fitness',
        notificationsEnabled: _notifications,
        locationAccess: _locationAccess,
      );
    } catch (_) {}
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
    final selectedPersonas = userState.selectedPersonas.isNotEmpty
        ? userState.selectedPersonas
        : [userState.selectedPersona ?? 'Fitness'];
    final triggers = userState.weatherTriggers;
    final concerns = userState.healthConcerns;
    final mattersMost = userState.whatMattersMost;
    final activityLevel = userState.activityLevel;

    final age = userState.age ?? 29;
    final gender = userState.gender;
    final height = userState.height ?? 168.0;
    final weight = userState.weight ?? 64.0;

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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              userState.email?.split('@').first ?? 'Mausam User',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: MausamPalette.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0x2234D399),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0x4434D399)),
                            ),
                            child: Text(
                              'Setup Completed ✓',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF34D399),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
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

        // SECTION 1: ABOUT YOU (Onboarding Slide 0)
        _buildSectionHeader('ABOUT YOU', 'SLIDE 1 PREFERENCES'),
        const SizedBox(height: 12),

        StaggeredItemWrapper(
          index: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MausamPalette.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MausamPalette.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Age Slider
                _buildMetricSliderRow(
                  label: 'Age',
                  value: age.toDouble(),
                  min: 0,
                  max: 100,
                  unit: 'yrs',
                  onChanged: (v) {
                    ref.read(userProvider.notifier).setUserProfileDetails(age: v.round());
                  },
                ),
                const Divider(color: MausamPalette.cardBorderSubtle, height: 24),

                // Gender Selection 2x2 Grid
                Text(
                  'GENDER',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: MausamPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildGenderOption('Female', gender)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildGenderOption('Male', gender)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildGenderOption('Non-binary', gender)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildGenderOption('Prefer not to say', gender)),
                  ],
                ),

                const Divider(color: MausamPalette.cardBorderSubtle, height: 24),

                // Height Slider
                _buildMetricSliderRow(
                  label: 'Height',
                  value: height,
                  min: 120,
                  max: 220,
                  unit: 'cm',
                  onChanged: (v) {
                    ref.read(userProvider.notifier).setUserProfileDetails(height: v.roundToDouble());
                  },
                ),
                const Divider(color: MausamPalette.cardBorderSubtle, height: 24),

                // Weight Slider
                _buildMetricSliderRow(
                  label: 'Weight',
                  value: weight,
                  min: 35,
                  max: 150,
                  unit: 'kg',
                  onChanged: (v) {
                    ref.read(userProvider.notifier).setUserProfileDetails(weight: v.roundToDouble());
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // SECTION 2: PERSONA SELECTION (Onboarding Slide 1)
        _buildSectionHeader('PERSONAS & LIFESTYLE', 'SLIDE 2 PREFERENCES'),
        const SizedBox(height: 12),

        StaggeredItemWrapper(
          index: 2,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MausamPalette.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MausamPalette.cardBorder),
            ),
            child: Column(
              children: _personas.map((item) {
                final id = item['id'] as String;
                final isSelected = selectedPersonas.contains(id);

                return Column(
                  children: [
                    _personaTile(
                      title: item['title'] as String,
                      subtitle: item['subtitle'] as String,
                      icon: item['icon'] as IconData,
                      color: item['color'] as Color,
                      isSelected: isSelected,
                      onTap: () => _togglePersona(id),
                    ),
                    if (item != _personas.last)
                      const Divider(color: MausamPalette.cardBorderSubtle, height: 12),
                  ],
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // SECTION 3: WEATHER TRIGGERS & HEALTH CONCERNS (Onboarding Slide 2)
        _buildSectionHeader('WEATHER TRIGGERS & CONCERNS', 'SLIDE 3 PREFERENCES'),
        const SizedBox(height: 12),

        StaggeredItemWrapper(
          index: 3,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MausamPalette.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MausamPalette.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WEATHER & AIR TRIGGERS',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: MausamPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _weatherTriggersList.map((trigger) {
                    final isSelected = triggers.contains(trigger);
                    return _buildChip(
                      label: trigger,
                      isSelected: isSelected,
                      onTap: () {
                        final updated = List<String>.from(triggers);
                        if (isSelected) {
                          updated.remove(trigger);
                        } else {
                          updated.add(trigger);
                        }
                        ref.read(userProvider.notifier).setTriggersAndConcerns(
                              triggers: updated,
                              concerns: concerns,
                            );
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                Text(
                  'HEALTH CONCERNS',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: MausamPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _healthConcernsList.map((concern) {
                    final isSelected = concerns.contains(concern);
                    return _buildChip(
                      label: concern,
                      isSelected: isSelected,
                      onTap: () {
                        final updated = List<String>.from(concerns);
                        if (concern == 'None of these') {
                          if (isSelected) {
                            updated.remove('None of these');
                          } else {
                            updated.clear();
                            updated.add('None of these');
                          }
                        } else {
                          updated.remove('None of these');
                          if (isSelected) {
                            updated.remove(concern);
                          } else {
                            updated.add(concern);
                          }
                        }
                        ref.read(userProvider.notifier).setTriggersAndConcerns(
                              triggers: triggers,
                              concerns: updated,
                            );
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // SECTION 4: YOUR RHYTHM & ACTIVITY (Onboarding Slide 3)
        _buildSectionHeader('YOUR RHYTHM & ACTIVITY', 'SLIDE 4 PREFERENCES'),
        const SizedBox(height: 12),

        StaggeredItemWrapper(
          index: 4,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MausamPalette.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MausamPalette.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WHAT MATTERS MOST',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: MausamPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _mattersMostList.map((item) {
                    final isSelected = mattersMost.contains(item);
                    return _buildChip(
                      label: item,
                      isSelected: isSelected,
                      onTap: () {
                        final updated = List<String>.from(mattersMost);
                        if (isSelected) {
                          if (updated.length > 1) {
                            updated.remove(item);
                          }
                        } else {
                          updated.add(item);
                        }
                        ref.read(userProvider.notifier).setRhythmPreferences(
                              whatMattersMost: updated,
                              activityLevel: activityLevel,
                            );
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                Text(
                  'YOUR USUAL ACTIVITY',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: MausamPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 38,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141417),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF27272A), width: 1),
                  ),
                  child: Row(
                    children: _activityLevels.map((level) {
                      final isSelected = activityLevel == level;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            ref.read(userProvider.notifier).setRhythmPreferences(
                                  whatMattersMost: mattersMost,
                                  activityLevel: level,
                                );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? MausamPalette.textPrimary : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              level,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? MausamPalette.bgDeep : MausamPalette.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // SECTION 5: SMART ALERTS & NOTIFICATIONS (Onboarding Slide 4)
        _buildSectionHeader('SMART WEATHER ALERTS', 'SLIDE 5 PREFERENCES'),
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
                      ref.read(userProvider.notifier).setAlertPreferences(
                            rain: val,
                            heat: _notifyHeat,
                            aqi: _notifyAqi,
                          );
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
                    value: _notifyHeat,
                    onChanged: (val) {
                      setState(() => _notifyHeat = val);
                      _saveBoolPref('notify_heat', val);
                      ref.read(userProvider.notifier).setAlertPreferences(
                            rain: _notifyRain,
                            heat: val,
                            aqi: _notifyAqi,
                          );
                    },
                    activeThumbColor: MausamPalette.textPrimary,
                    title: Text(
                      'High Heat & UV Protection Alerts',
                      style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Notifies during high UV index (>6) or temperature surges',
                      style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 11.5),
                    ),
                  ),
                  const Divider(color: MausamPalette.cardBorderSubtle, height: 1),
                  SwitchListTile(
                    value: _notifyAqi,
                    onChanged: (val) {
                      setState(() => _notifyAqi = val);
                      _saveBoolPref('notify_aqi', val);
                      ref.read(userProvider.notifier).setAlertPreferences(
                            rain: _notifyRain,
                            heat: _notifyHeat,
                            aqi: val,
                          );
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

        // SECTION 6: UNITS OF MEASURE
        _buildSectionHeader('UNITS OF MEASURE', 'DISPLAY PREFERENCES'),
        const SizedBox(height: 12),

        StaggeredItemWrapper(
          index: 6,
          child: Consumer(
            builder: (context, ref, child) {
              final units = ref.watch(unitsProvider);
              return Container(
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
                        Expanded(
                          child: Column(
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
                                units.isCelsius ? 'Metric (°Celsius)' : 'Imperial (°Fahrenheit)',
                                style: GoogleFonts.inter(
                                  color: MausamPalette.textSecondary,
                                  fontSize: 11.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF141417),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF27272A)),
                          ),
                          child: Row(
                            children: [
                              _unitButton('°C', units.isCelsius, () {
                                ref.read(unitsProvider.notifier).setTempCelsius(true);
                              }),
                              _unitButton('°F', !units.isCelsius, () {
                                ref.read(unitsProvider.notifier).setTempCelsius(false);
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
                        Expanded(
                          child: Column(
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
                                units.isKmh ? 'Kilometers/hour (km/h)' : 'Miles/hour (mph)',
                                style: GoogleFonts.inter(
                                  color: MausamPalette.textSecondary,
                                  fontSize: 11.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF141417),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF27272A)),
                          ),
                          child: Row(
                            children: [
                              _unitButton('km/h', units.isKmh, () {
                                ref.read(unitsProvider.notifier).setWindKmh(true);
                              }),
                              _unitButton('mph', !units.isKmh, () {
                                ref.read(unitsProvider.notifier).setWindKmh(false);
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // SECTION 7: APPEARANCE & WALLPAPER
        _buildSectionHeader('APPEARANCE & WALLPAPER', '2 THEME OPTIONS'),
        const SizedBox(height: 12),

        StaggeredItemWrapper(
          index: 7,
          child: Consumer(
            builder: (context, ref, child) {
              final appearance = ref.watch(appearanceProvider);
              final opacity = ref.watch(cardSurfaceOpacityProvider);
              final isDynamic = appearance.wallpaperTheme.isDynamic;
              final currentHour = DateTime.now().hour;
              final currentPeriod = EnvironmentTheme.periodForHour(currentHour);

              String currentPeriodName;
              switch (currentPeriod) {
                case TimeOfDayPeriod.morning:
                  currentPeriodName = 'Morning';
                  break;
                case TimeOfDayPeriod.afternoon:
                  currentPeriodName = 'Afternoon';
                  break;
                case TimeOfDayPeriod.evening:
                  currentPeriodName = 'Evening';
                  break;
                case TimeOfDayPeriod.night:
                  currentPeriodName = 'Night';
                  break;
              }

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
                    Text(
                      'HOME WALLPAPER PREFERENCE',
                      style: GoogleFonts.inter(
                        color: MausamPalette.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Option 1: Dynamic Live Wallpaper (DEFAULT)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const Key('wallpaper_option_dynamic'),
                        onTap: () {
                          ref.read(appearanceProvider.notifier).setWallpaperTheme(WallpaperTheme.dynamic);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDynamic ? const Color(0xFF181C26) : const Color(0xFF131317),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDynamic ? MausamPalette.textPrimary.withValues(alpha: 0.45) : MausamPalette.cardBorder,
                              width: isDynamic ? 1.2 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Color(0xFF2A3344), Color(0xFF12151C)],
                                      ),
                                    ),
                                    child: const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            Text(
                                              'Dynamic Live Wallpaper',
                                              style: GoogleFonts.inter(
                                                color: MausamPalette.textPrimary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: MausamPalette.cardSurfaceLight,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: MausamPalette.cardBorder, width: 0.8),
                                              ),
                                              child: Text(
                                                'DEFAULT',
                                                style: GoogleFonts.inter(
                                                  color: MausamPalette.textSecondary,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Sky follows morning, afternoon, evening, and night',
                                          style: GoogleFonts.inter(
                                            color: MausamPalette.textSecondary,
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDynamic ? MausamPalette.cardSurfaceLight : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isDynamic ? MausamPalette.cardBorder : Colors.transparent),
                                    ),
                                    child: Text(
                                      isDynamic ? 'ACTIVE' : 'SELECT',
                                      style: GoogleFonts.inter(
                                        color: isDynamic ? MausamPalette.textPrimary : MausamPalette.textTertiary,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),
                              Text(
                                appearance.previewHour == null
                                    ? 'Following local time · $currentPeriodName'
                                    : 'Preview · ${_previewHourName(appearance.previewHour!)}',
                                style: GoogleFonts.inter(
                                  color: MausamPalette.textTertiary,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _buildSkyChip(
                                    key: const Key('preview_time_live'),
                                    label: 'Live',
                                    selected: appearance.previewHour == null,
                                    onTap: () => ref.read(appearanceProvider.notifier).setPreviewHour(null),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildSkyChip(
                                    key: const Key('preview_time_am'),
                                    label: 'Morning',
                                    selected: appearance.previewHour == 8 ||
                                        (appearance.previewHour == null && currentPeriod == TimeOfDayPeriod.morning),
                                    onTap: () => ref.read(appearanceProvider.notifier).setPreviewHour(8),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildSkyChip(
                                    key: const Key('preview_time_noon'),
                                    label: 'Afternoon',
                                    selected: appearance.previewHour == 13 ||
                                        (appearance.previewHour == null && currentPeriod == TimeOfDayPeriod.afternoon),
                                    onTap: () => ref.read(appearanceProvider.notifier).setPreviewHour(13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _buildSkyChip(
                                    key: const Key('preview_time_eve'),
                                    label: 'Evening',
                                    selected: appearance.previewHour == 18 ||
                                        (appearance.previewHour == null && currentPeriod == TimeOfDayPeriod.evening),
                                    onTap: () => ref.read(appearanceProvider.notifier).setPreviewHour(18),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildSkyChip(
                                    key: const Key('preview_time_night'),
                                    label: 'Night',
                                    selected: appearance.previewHour == 22 ||
                                        (appearance.previewHour == null && currentPeriod == TimeOfDayPeriod.night),
                                    onTap: () => ref.read(appearanceProvider.notifier).setPreviewHour(22),
                                  ),
                                  const Expanded(child: SizedBox()),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Option 2: Fixed Obsidian Black (Second Choice)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const Key('wallpaper_option_fixed'),
                        onTap: () {
                          ref.read(appearanceProvider.notifier).setWallpaperTheme(WallpaperTheme.wallpaper2);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: !isDynamic ? const Color(0xFF18181D) : const Color(0xFF131317),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: !isDynamic ? const Color(0xFFA1A1AA) : const Color(0xFF27272A),
                              width: !isDynamic ? 1.4 : 1.0,
                            ),
                            boxShadow: !isDynamic
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF030304),
                                  border: Border.all(color: const Color(0xFF27272A), width: 1.2),
                                ),
                                child: const Icon(Icons.nightlight_round, color: Color(0xFFD4D4D8), size: 17),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fixed Obsidian Black',
                                      style: GoogleFonts.inter(
                                        color: MausamPalette.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Permanent deep OLED black • Never changes with time',
                                      style: GoogleFonts.inter(
                                        color: MausamPalette.textSecondary,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: !isDynamic ? const Color(0xFF27272A) : const Color(0xFF222226),
                                  borderRadius: BorderRadius.circular(6),
                                  border: !isDynamic ? Border.all(color: const Color(0xFFA1A1AA), width: 0.8) : null,
                                ),
                                child: Text(
                                  !isDynamic ? 'ACTIVE' : 'SELECT',
                                  style: GoogleFonts.inter(
                                    color: !isDynamic ? Colors.white : MausamPalette.textTertiary,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Card Glassmorphism & Opacity',
                            style: GoogleFonts.inter(
                              color: MausamPalette.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                        Flexible(
                          child: Text(
                            'Solid (OLED)',
                            style: GoogleFonts.inter(color: MausamPalette.textTertiary, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            'Glass (Translucent)',
                            style: GoogleFonts.inter(color: MausamPalette.textTertiary, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isDynamic
                                      ? 'Live Dynamic Wallpaper active'
                                      : 'Fixed Obsidian Black active',
                                  style: GoogleFonts.inter(
                                    color: MausamPalette.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Card surface opacity ${(opacity * 100).round()}% preview',
                                  style: GoogleFonts.inter(
                                    color: MausamPalette.textSecondary,
                                    fontSize: 11,
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

        const SizedBox(height: 24),

        // SECTION 8: PERFORMANCE & CACHE MANAGEMENT
        _buildSectionHeader('PERFORMANCE & CACHE', 'LOCAL STORAGE'),
        const SizedBox(height: 12),

        StaggeredItemWrapper(
          index: 8,
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
                        Expanded(
                          child: Column(
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
                        ),
                        const SizedBox(width: 8),
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

        const SizedBox(height: 32),

        // Logout Button & App Version Footer
        StaggeredItemWrapper(
          index: 8,
          child: Column(
            children: [
              Center(
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
              const SizedBox(height: 12),
              Text(
                'Mausam PersonalAI v1.2.0',
                style: GoogleFonts.inter(
                  color: MausamPalette.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String tag) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: MausamPalette.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          tag,
          style: GoogleFonts.inter(
            color: const Color(0xFF64748B),
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
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
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: MausamPalette.textPrimary,
              ),
            ),
            Text(
              '${value.round()} $unit',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: MausamPalette.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            activeTrackColor: MausamPalette.textPrimary,
            inactiveTrackColor: const Color(0xFF27272A),
            thumbColor: MausamPalette.textPrimary,
            overlayColor: Colors.white.withValues(alpha: 0.08),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption(String option, String? currentGender) {
    final isSelected = currentGender == option;

    return GestureDetector(
      onTap: () {
        ref.read(userProvider.notifier).setUserProfileDetails(gender: isSelected ? null : option);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? MausamPalette.textPrimary : const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? MausamPalette.textPrimary : const Color(0xFF3F3F46),
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            option,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? MausamPalette.bgDeep : MausamPalette.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final emoji = _triggerIcons[label];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? MausamPalette.textPrimary : const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? MausamPalette.textPrimary : const Color(0xFF3F3F46),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji, style: const TextStyle(fontSize: 11.5)),
              const SizedBox(width: 5),
            ] else
              Icon(
                isSelected ? Icons.check_rounded : Icons.add_rounded,
                size: 13,
                color: isSelected ? MausamPalette.bgDeep : MausamPalette.textSecondary,
              ),
            if (emoji == null) const SizedBox(width: 4.5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? MausamPalette.bgDeep : MausamPalette.textPrimary,
              ),
            ),
          ],
        ),
      ),
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
                  color: color.withValues(alpha: isSelected ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withValues(alpha: isSelected ? 0.45 : 0.15),
                    width: 1,
                  ),
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
                        color: isSelected ? color : MausamPalette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: isSelected ? color.withValues(alpha: 0.75) : MausamPalette.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected ? color : MausamPalette.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkyChip({
    required Key key,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        key: key,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? MausamPalette.cardSurfaceLight : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? MausamPalette.textPrimary.withValues(alpha: 0.55) : MausamPalette.cardBorder,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: selected ? MausamPalette.textPrimary : MausamPalette.textTertiary,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _previewHourName(int hour) {
    if (hour >= 5 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    if (hour >= 17 && hour < 21) return 'Evening';
    return 'Night';
  }
}
