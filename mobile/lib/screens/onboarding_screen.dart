import 'dart:ui';

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
/// with persona selection, smart notification preferences, and location permission onboarding.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;

  // Slide 1 state
  String? _selectedPersona;

  // Slide 2 state
  bool _notificationsEnabled = true;
  bool _notifyRain = true;
  bool _notifyHeat = true;
  bool _notifyAqi = true;

  // Slide 3 state
  bool _isSubmitting = false;

  static const List<Map<String, dynamic>> _personas = [
    {
      'id': 'Fitness',
      'title': 'Outdoor fitness',
      'subtitle': 'Workout windows, UV, heat.',
      'icon': Icons.directions_run_rounded,
    },
    {
      'id': 'Health',
      'title': 'Health-conscious',
      'subtitle': 'AQI, UV, humidity.',
      'icon': Icons.favorite_rounded,
    },
    {
      'id': 'Traveler',
      'title': 'Traveler',
      'subtitle': 'Destinations, packing, severe weather.',
      'icon': Icons.flight_takeoff_rounded,
    },
    {
      'id': 'Commuter',
      'title': 'Commuter',
      'subtitle': 'Visibility, storms, travel conditions.',
      'icon': Icons.commute_rounded,
    },
    {
      'id': 'Family',
      'title': 'Parents / family',
      'subtitle': 'School run and rain warnings.',
      'icon': Icons.family_restroom_rounded,
    },
    {
      'id': 'Garden',
      'title': 'Garden / farm',
      'subtitle': 'Rainfall and frost risk.',
      'icon': Icons.grass_rounded,
    },
    {
      'id': 'Events',
      'title': 'Event planner',
      'subtitle': 'Rain chance and outdoor comfort.',
      'icon': Icons.event_rounded,
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
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Back button & 3 Progress Dots Indicator
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
                        children: List.generate(3, (index) {
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
                  physics: _selectedPersona == null && _currentPage == 0
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildSlide1Persona(),
                    _buildSlide2Notifications(),
                    _buildSlide3Location(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SLIDE 1: Persona Type
  Widget _buildSlide1Persona() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Choose Your Persona',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: MausamPalette.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Who is this for? Mausam will rank the day around this.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: MausamPalette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: _personas.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _personas[index];
                final isSelected = _selectedPersona == item['id'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPersona = item['id'] as String;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? MausamPalette.cardSurfaceLight
                          : MausamPalette.cardSurface.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? MausamPalette.textPrimary
                            : MausamPalette.cardBorder,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected ? MausamPalette.cardShadow : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? MausamPalette.textPrimary
                                : const Color(0xFF202024),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: isSelected ? MausamPalette.bgDeep : MausamPalette.textPrimary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: MausamPalette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['subtitle'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: MausamPalette.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected
                              ? MausamPalette.textPrimary
                              : MausamPalette.textTertiary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _selectedPersona != null ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: MausamPalette.textPrimary,
                disabledBackgroundColor: MausamPalette.textPrimary.withValues(alpha: 0.25),
                foregroundColor: MausamPalette.bgDeep,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  // SLIDE 2: Notifications
  Widget _buildSlide2Notifications() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Smart Alerts',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: MausamPalette.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'What should Mausam notify you about?',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: MausamPalette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: MausamPalette.cardSurface.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: MausamPalette.cardBorder),
                  boxShadow: MausamPalette.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF202024),
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: MausamPalette.textPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weather Alerts & AI Tips',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: MausamPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Timely updates tailored to your persona.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: MausamPalette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _notificationsEnabled,
                      activeThumbColor: MausamPalette.textPrimary,
                      activeTrackColor: MausamPalette.cardSurfaceLight,
                      inactiveThumbColor: MausamPalette.textTertiary,
                      inactiveTrackColor: MausamPalette.cardSurface,
                      onChanged: (val) {
                        setState(() {
                          _notificationsEnabled = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Opacity(
            opacity: _notificationsEnabled ? 1 : 0.4,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _alertChip('Rain', _notifyRain, (v) => setState(() => _notifyRain = v)),
                _alertChip('Heat', _notifyHeat, (v) => setState(() => _notifyHeat = v)),
                _alertChip('Air quality', _notifyAqi, (v) => setState(() => _notifyAqi = v)),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: MausamPalette.textPrimary,
                foregroundColor: MausamPalette.bgDeep,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  // SLIDE 3: Location Access
  Widget _buildSlide3Location() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Location Access',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: MausamPalette.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Where are you? Local forecasts need a place to start.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: MausamPalette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 36),
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MausamPalette.cardSurfaceLight,
                border: Border.all(color: MausamPalette.cardBorder, width: 1.5),
                boxShadow: MausamPalette.cardShadow,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: MausamPalette.textPrimary,
                size: 40,
              ),
            ),
          ),
          const Spacer(),
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
              height: 48,
              child: ElevatedButton(
                onPressed: () => _completeOnboarding(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MausamPalette.textPrimary,
                  foregroundColor: MausamPalette.bgDeep,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Allow Location Access',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => _completeOnboarding(false),
                style: TextButton.styleFrom(
                  foregroundColor: MausamPalette.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Not Now',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: MausamPalette.textTertiary,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _alertChip(String label, bool selected, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? MausamPalette.bgDeep : MausamPalette.textSecondary,
        ),
      ),
      selected: selected,
      showCheckmark: false,
      selectedColor: MausamPalette.textPrimary,
      backgroundColor: MausamPalette.cardSurface,
      side: BorderSide(
        color: selected ? MausamPalette.textPrimary : MausamPalette.cardBorder,
      ),
      onSelected: _notificationsEnabled ? onChanged : null,
    );
  }
}
