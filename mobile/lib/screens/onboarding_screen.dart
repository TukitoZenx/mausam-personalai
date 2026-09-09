import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';
import '../theme/environment_theme.dart';
import '../theme/weather_palette.dart';
import '../widgets/weather_environment_background.dart';

/// OnboardingScreen featuring a swipeable PageView carousel
/// with About You profile setup, persona selection, smart notification preferences,
/// and location permission onboarding.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;

  // Slide 0: About You state (matching interactive sliders & 2x2 gender pills)
  double _ageValue = 29.0;
  String? _selectedGender;
  double _heightValue = 168.0;
  double _weightValue = 64.0;

  // Slide 1 state (supports multiple personas)
  final Set<String> _selectedPersonas = {'Fitness'};
  String? get _selectedPersona => _selectedPersonas.isNotEmpty ? _selectedPersonas.first : null;

  // Slide 2 state: Triggers & Concerns (matching reference layout)
  final Set<String> _selectedTriggers = {'Dust', 'AQI / smoke'};
  final Set<String> _selectedConcerns = {};

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

  // Slide 3 state: Your Rhythm
  final Set<String> _selectedMattersMost = {'Daily energy'};
  String _selectedActivityLevel = 'Low';

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

  final bool _notificationsEnabled = true;
  bool _notifyRain = true;
  bool _notifyHeat = true;
  bool _notifyAqi = true;

  // Slide 4 state
  bool _isSubmitting = false;

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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onSeeMyPlanContinue() {
    ref.read(userProvider.notifier).setRhythmPreferences(
      whatMattersMost: _selectedMattersMost.toList(),
      activityLevel: _selectedActivityLevel,
    );
    _nextPage();
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onAboutYouContinue() {
    ref.read(userProvider.notifier).setUserProfileDetails(
      age: _ageValue.round(),
      gender: _selectedGender,
      height: _heightValue.roundToDouble(),
      weight: _weightValue.roundToDouble(),
      heightUnit: 'cm',
      weightUnit: 'kg',
    );
    _nextPage();
  }

  void _onAboutYouSkip() {
    _nextPage();
  }

  Future<void> _completeOnboarding(bool locationAllowed) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    if (locationAllowed) {
      try {
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
          ref.read(locationProvider.notifier).setLocation(12.9716, 77.5946, 'Bengaluru');
        } else {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (serviceEnabled) {
            LocationPermission permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.denied) {
              permission = await Geolocator.requestPermission();
            }

            if (permission == LocationPermission.whileInUse ||
                permission == LocationPermission.always) {
              final lastPosition = await Geolocator.getLastKnownPosition();
              if (lastPosition != null) {
                ref.read(locationProvider.notifier).setLocation(
                      lastPosition.latitude,
                      lastPosition.longitude,
                      'Current Location',
                    );
              }

              Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.medium,
                timeLimit: const Duration(seconds: 6),
              ).then((position) {
                ref.read(locationProvider.notifier).setLocation(
                      position.latitude,
                      position.longitude,
                      'Current Location',
                    );
              }).catchError((_) {});
            }
          }
        }
      } catch (_) {}
    }

    final persona = _selectedPersona ?? 'Fitness';
    final userState = ref.read(userProvider);
    final apiClient = ref.read(apiClientProvider);

    try {
      if (userState.idToken != null && userState.email != null) {
        await apiClient.postUser(
          idToken: userState.idToken!,
          email: userState.email!,
          personaType: persona,
          notificationsEnabled: _notificationsEnabled,
          locationAccess: locationAllowed,
          persona: persona,
        );
      } else {
        await apiClient.postUser(
          idToken: 'demo_token',
          email: userState.email ?? 'user@mausam.ai',
          personaType: persona,
          notificationsEnabled: _notificationsEnabled,
          locationAccess: locationAllowed,
          persona: persona,
        );
      }
    } catch (e) {
      debugPrint('POST /users/me warning: $e');
    }

    ref.read(userProvider.notifier).setPersona(persona);
    ref.read(userProvider.notifier).setAlertPreferences(
          rain: _notificationsEnabled && _notifyRain,
          heat: _notificationsEnabled && _notifyHeat,
          aqi: _notificationsEnabled && _notifyAqi,
        );
    ref.read(userProvider.notifier).completeOnboarding();

    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MausamPalette.bgDeep,
      body: WeatherEnvironmentBackground(
        wallpaperTheme: WallpaperTheme.dynamic,
        showCelestialDisc: false,
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Back button & 4 Progress Dots Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: _currentPage > 0
                          ? IconButton(
                              icon: const Icon(Icons.arrow_back_rounded, color: MausamPalette.textPrimary, size: 20),
                              onPressed: _previousPage,
                            )
                          : null,
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final isCurrent = index == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isCurrent ? 24 : 8,
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: isCurrent
                                  ? MausamPalette.textPrimary
                                  : MausamPalette.cardBorder,
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              // PageView Carousel
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: _currentPage == 1 && _selectedPersona == null
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildSlide0AboutYou(),
                    _buildSlide1Persona(),
                    _buildSlide2Notifications(),
                    _buildSlide3Rhythm(),
                    _buildSlide4Location(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SLIDE 0: About You (matching interactive sliders & 2x2 gender pills in obsidian monochrome)
  Widget _buildSlide0AboutYou() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'STEP 1 / YOUR BASICS',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: MausamPalette.textTertiary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'About You',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: MausamPalette.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'A little context\ngoes a long way.',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: MausamPalette.textPrimary,
                      letterSpacing: -0.6,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'These numbers help us make hydration, heat and activity guidance more personal.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: MausamPalette.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Age Slider
                  _buildMetricSlider(
                    key: const Key('about_you_age_slider'),
                    label: 'Age',
                    value: _ageValue,
                    min: 0,
                    max: 100,
                    unit: 'yrs',
                    minLabel: '0 yrs',
                    maxLabel: '100 yrs',
                    onChanged: (v) => setState(() => _ageValue = v),
                  ),
                  const SizedBox(height: 16),

                  // Gender 2x2 Grid
                  _buildGenderSection(),
                  const SizedBox(height: 16),

                  // Height Slider
                  _buildMetricSlider(
                    key: const Key('about_you_height_slider'),
                    label: 'Height',
                    value: _heightValue,
                    min: 120,
                    max: 220,
                    unit: 'cm',
                    minLabel: '120 cm',
                    maxLabel: '220 cm',
                    onChanged: (v) => setState(() => _heightValue = v),
                  ),
                  const SizedBox(height: 16),

                  // Weight Slider
                  _buildMetricSlider(
                    key: const Key('about_you_weight_slider'),
                    label: 'Weight',
                    value: _weightValue,
                    min: 35,
                    max: 150,
                    unit: 'kg',
                    minLabel: '35 kg',
                    maxLabel: '150 kg',
                    onChanged: (v) => setState(() => _weightValue = v),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              key: const Key('about_you_continue_button'),
              onPressed: _onAboutYouContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: MausamPalette.textPrimary,
                foregroundColor: MausamPalette.bgDeep,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Save & continue',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: TextButton(
              key: const Key('about_you_skip_button'),
              onPressed: _onAboutYouSkip,
              style: TextButton.styleFrom(
                foregroundColor: MausamPalette.textSecondary,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Skip for now',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: MausamPalette.textTertiary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildMetricSlider({
    required Key key,
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required String minLabel,
    required String maxLabel,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: MausamPalette.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MausamPalette.textPrimary,
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${value.round()}',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: MausamPalette.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: MausamPalette.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  11,
                  (i) => Container(
                    width: 1.2,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.5,
                activeTrackColor: MausamPalette.textPrimary,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.14),
                thumbShape: _MausamRulerSliderThumbShape(
                  radius: 7.5,
                  label: '${value.round()}',
                ),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                overlayColor: Colors.white.withValues(alpha: 0.06),
              ),
              child: Slider(
                key: key,
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                minLabel,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: MausamPalette.textSecondary,
                ),
              ),
              Text(
                maxLabel,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: MausamPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            Expanded(child: _buildGenderPill('Female', key: const Key('about_you_gender_female'))),
            const SizedBox(width: 8),
            Expanded(child: _buildGenderPill('Male', key: const Key('about_you_gender_male'))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildGenderPill('Non-binary', key: const Key('about_you_gender_non_binary'))),
            const SizedBox(width: 8),
            Expanded(child: _buildGenderPill('Prefer not to say', key: const Key('about_you_gender_prefer_not'))),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderPill(String option, {required Key key}) {
    final isSelected = _selectedGender == option;
    return GestureDetector(
      key: key,
      onTap: () {
        setState(() {
          _selectedGender = isSelected ? null : option;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? MausamPalette.textPrimary
              : const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? MausamPalette.textPrimary
                : const Color(0xFF3F3F46),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            option,
            maxLines: 1,
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

  // SLIDE 1: Persona Type
  Widget _buildSlide1Persona() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '02 / YOUR PROFILE',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: MausamPalette.textTertiary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Persona Selection',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: MausamPalette.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Choose Your Persona',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: MausamPalette.textPrimary,
              letterSpacing: -0.5,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Who is this for? Mausam will rank the day around this.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: MausamPalette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: _personas.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _personas[index];
                final isSelected = _selectedPersonas.contains(item['id']);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      final id = item['id'] as String;
                      if (_selectedPersonas.contains(id)) {
                        if (_selectedPersonas.length > 1) {
                          _selectedPersonas.remove(id);
                        }
                      } else {
                        _selectedPersonas.add(id);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1E1E24)
                          : const Color(0xFF141416).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? MausamPalette.textPrimary
                            : const Color(0xFF27272A),
                        width: isSelected ? 1.4 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.10),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Compact Icon Circle
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? MausamPalette.textPrimary
                                : const Color(0xFF1C1C20),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: isSelected ? MausamPalette.bgDeep : const Color(0xFFA1A1AA),
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Titles
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: isSelected
                                      ? MausamPalette.textPrimary
                                      : const Color(0xFFE4E4E7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['subtitle'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: isSelected
                                      ? const Color(0xFFA1A1AA)
                                      : MausamPalette.textTertiary,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Active / Inactive Radio Indicator
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? MausamPalette.textPrimary : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? MausamPalette.textPrimary
                                  : const Color(0xFF3F3F46),
                              width: 1.2,
                            ),
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 12,
                                    color: MausamPalette.bgDeep,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: _selectedPersonas.isNotEmpty
                  ? () {
                      ref.read(userProvider.notifier).setPersonas(_selectedPersonas.toList());
                      _nextPage();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: MausamPalette.textPrimary,
                disabledBackgroundColor: MausamPalette.textPrimary.withValues(alpha: 0.15),
                foregroundColor: MausamPalette.bgDeep,
                disabledForegroundColor: MausamPalette.bgDeep.withValues(alpha: 0.4),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continue',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _onTuneAlertsContinue() {
    final notifyRain = _selectedTriggers.contains('Monsoon damp');
    final notifyHeat = _selectedTriggers.contains('Heat') || _selectedTriggers.contains('UV / sun');
    final notifyAqi = _selectedTriggers.contains('AQI / smoke') ||
        _selectedTriggers.contains('Dust') ||
        _selectedTriggers.contains('Pollen');

    setState(() {
      _notifyRain = notifyRain;
      _notifyHeat = notifyHeat;
      _notifyAqi = notifyAqi;
    });

    ref.read(userProvider.notifier).setAlertPreferences(
          rain: notifyRain,
          heat: notifyHeat,
          aqi: notifyAqi,
        );
    ref.read(userProvider.notifier).setTriggersAndConcerns(
          triggers: _selectedTriggers.toList(),
          concerns: _selectedConcerns.toList(),
        );

    _nextPage();
  }

  // Helper map for trigger chip icons
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

  // SLIDE 2: What does the weather stir up? (matching reference layout)
  Widget _buildSlide2Notifications() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '03 / YOUR RESPONSE',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: MausamPalette.textTertiary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Smart Alerts',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: MausamPalette.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'What does the\nweather stir up?',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: MausamPalette.textPrimary,
                      letterSpacing: -0.5,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select everything that affects you. We\'ll surface the risk before it becomes a bad day.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: MausamPalette.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Section 1: Weather & Air Triggers
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
                      final isSelected = _selectedTriggers.contains(trigger);
                      return _buildTriggerChip(
                        key: Key('trigger_${trigger.replaceAll(' ', '_').replaceAll('/', '_')}'),
                        label: trigger,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (_selectedTriggers.contains(trigger)) {
                              _selectedTriggers.remove(trigger);
                            } else {
                              _selectedTriggers.add(trigger);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Section 2: Health Concerns
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'HEALTH CONCERNS',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: MausamPalette.textSecondary,
                        ),
                      ),
                      Text(
                        'OPTIONAL',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                          color: MausamPalette.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _healthConcernsList.map((concern) {
                      final isSelected = _selectedConcerns.contains(concern);
                      return _buildTriggerChip(
                        key: Key('concern_${concern.replaceAll(' ', '_')}'),
                        label: concern,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (concern == 'None of these') {
                              if (_selectedConcerns.contains('None of these')) {
                                _selectedConcerns.remove('None of these');
                              } else {
                                _selectedConcerns.clear();
                                _selectedConcerns.add('None of these');
                              }
                            } else {
                              _selectedConcerns.remove('None of these');
                              if (_selectedConcerns.contains(concern)) {
                                _selectedConcerns.remove(concern);
                              } else {
                                _selectedConcerns.add(concern);
                              }
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              key: const Key('tune_my_alerts_button'),
              onPressed: _onTuneAlertsContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: MausamPalette.textPrimary,
                foregroundColor: MausamPalette.bgDeep,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tune my alerts',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildTriggerChip({
    Key? key,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final emoji = _triggerIcons[label];

    return GestureDetector(
      key: key,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? MausamPalette.textPrimary
              : const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? MausamPalette.textPrimary
                : const Color(0xFF3F3F46),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(
                emoji,
                style: const TextStyle(fontSize: 11.5),
              ),
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

  String _generateLiveInsightPreview() {
    final persona = _selectedPersona ?? 'Fitness';
    final activity = _selectedActivityLevel;
    final hasAqi = _selectedTriggers.contains('AQI / smoke') || _selectedTriggers.contains('Dust');
    final hasHeat = _selectedTriggers.contains('Heat') || _selectedTriggers.contains('UV / sun');

    if (persona == 'Fitness') {
      return 'Optimal outdoor window: 6:15 AM – 8:30 AM · Temp 24°C · UV Low. Best $activity-intensity workout slot before afternoon heat peak.';
    } else if (persona == 'Health' || hasAqi) {
      return 'Air quality alert tuned · Moderate AQI 84 · Sensitivity protection enabled. Surface risk warnings before peak exposure hours.';
    } else if (persona == 'Traveler') {
      return 'Hyper-local travel sync · Rain probability 35% at 4:30 PM. Personal afternoon packing nudge & dry-window routing active.';
    } else if (persona == 'Commuter') {
      return 'Commute safety monitor · Morning visibility clear · Evening rain warning tuned for your usual route.';
    } else if (hasHeat) {
      return 'Heat & UV shield active · High UV 7 forecast at 1:30 PM. Hydration nudges scheduled for peak warmth hours.';
    } else {
      return 'Bright & Sunny · 31°C · 89% humidity. Customized $activity activity guidance & personalized outdoor windows active.';
    }
  }

  // SLIDE 3: What should your day feel like? (matching reference layout)
  Widget _buildSlide3Rhythm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '04 / YOUR RHYTHM',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: MausamPalette.textTertiary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your Rhythm',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: MausamPalette.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'What should\nyour day feel like?',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: MausamPalette.textPrimary,
                      letterSpacing: -0.5,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We\'ll turn conditions into useful nudges for the way you actually live.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: MausamPalette.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Section 1: What Matters Most
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
                      final isSelected = _selectedMattersMost.contains(item);
                      return _buildTriggerChip(
                        key: Key('matter_${item.replaceAll(' ', '_')}'),
                        label: item,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (_selectedMattersMost.contains(item)) {
                              if (_selectedMattersMost.length > 1) {
                                _selectedMattersMost.remove(item);
                              }
                            } else {
                              _selectedMattersMost.add(item);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Section 2: Your Usual Activity
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
                        final isSelected = _selectedActivityLevel == level;
                        return Expanded(
                          child: GestureDetector(
                            key: Key('activity_$level'),
                            onTap: () {
                              setState(() {
                                _selectedActivityLevel = level;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? MausamPalette.textPrimary : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
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
                  const SizedBox(height: 20),

                  // Section 3: Your First Insight Card (Interactive AI Live Preview)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141417),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0x66FB7185),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFB7185).withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  size: 15,
                                  color: Color(0xFFFB7185),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Your first insight',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: MausamPalette.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0x22FB7185),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0x44FB7185), width: 0.8),
                              ),
                              child: Text(
                                'AI LIVE PREVIEW',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: const Color(0xFFFB7185),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _generateLiveInsightPreview(),
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                            color: MausamPalette.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              key: const Key('see_my_plan_button'),
              onPressed: _onSeeMyPlanContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: MausamPalette.textPrimary,
                foregroundColor: MausamPalette.bgDeep,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'See my plan',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSlide4Location() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '05 / LOCATION ACCESS',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: MausamPalette.textTertiary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Location Access',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: MausamPalette.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Where are you?',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: MausamPalette.textPrimary,
              letterSpacing: -0.5,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Local forecasts need a place to start.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: MausamPalette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Concentric animated radar location avatar
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer aura ring
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.03),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                          ),
                        ),
                        // Middle aura ring
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14),
                              width: 1,
                            ),
                          ),
                        ),
                        // Core location badge
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: MausamPalette.textPrimary,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.25),
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.location_on_rounded,
                              color: MausamPalette.bgDeep,
                              size: 34,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Feature Trust Badges Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141417),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF27272A), width: 1.0),
                    ),
                    child: Column(
                      children: [
                        _buildTrustRow('🔒', '100% On-Device Privacy', 'Location is stored locally and never shared.'),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(color: Color(0xFF23232A), height: 1, thickness: 1),
                        ),
                        _buildTrustRow('⚡', 'Hyper-local Weather Signals', 'Accurate micro-climate updates for your exact area.'),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(color: Color(0xFF23232A), height: 1, thickness: 1),
                        ),
                        _buildTrustRow('🔔', 'Timely Rain & Risk Nudges', 'Get notified before rain or high UV strikes.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          if (_isSubmitting)
            const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(MausamPalette.textPrimary),
                ),
              ),
            )
          else ...[
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: () => _completeOnboarding(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MausamPalette.textPrimary,
                  foregroundColor: MausamPalette.bgDeep,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Allow Location Access',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.arrow_forward_rounded, size: 14),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 34,
              child: TextButton(
                onPressed: () => _completeOnboarding(false),
                style: TextButton.styleFrom(
                  foregroundColor: MausamPalette.textSecondary,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Not Now',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: MausamPalette.textTertiary,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildTrustRow(String icon, String title, String subtitle) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: MausamPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: MausamPalette.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom slider thumb shape rendering a monochrome outer ring, dark core,
/// and a floating badge bubble directly above the thumb showing current value.
class _MausamRulerSliderThumbShape extends SliderComponentShape {
  final double radius;
  final String label;

  const _MausamRulerSliderThumbShape({
    this.radius = 7.5,
    required this.label,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.fromRadius(radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // Outer thumb ring (High-contrast white)
    final outerPaint = Paint()
      ..color = MausamPalette.textPrimary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, outerPaint);

    // Inner thumb core (Obsidian deep dark)
    final innerPaint = Paint()
      ..color = MausamPalette.bgDeep
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.45, innerPaint);

    // Floating Tooltip Bubble above thumb (compact sleek badge)
    const badgeWidth = 28.0;
    const badgeHeight = 18.0;
    final badgeCenter = Offset(center.dx, center.dy - radius - 11);
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: badgeCenter, width: badgeWidth, height: badgeHeight),
      const Radius.circular(5),
    );

    // Subtle pointer triangle under badge
    final pointerPath = Path()
      ..moveTo(center.dx - 3, badgeCenter.dy + badgeHeight / 2)
      ..lineTo(center.dx + 3, badgeCenter.dy + badgeHeight / 2)
      ..lineTo(center.dx, badgeCenter.dy + badgeHeight / 2 + 2.5)
      ..close();

    final badgePaint = Paint()
      ..color = const Color(0xFF1E1E22)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(badgeRect, badgePaint);
    canvas.drawPath(pointerPath, badgePaint);

    final borderPaint = Paint()
      ..color = MausamPalette.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(badgeRect, borderPaint);

    // Text in badge
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: GoogleFonts.inter(
          color: MausamPalette.textPrimary,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(badgeCenter.dx - textPainter.width / 2, badgeCenter.dy - textPainter.height / 2),
    );
  }
}
