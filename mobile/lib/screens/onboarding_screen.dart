import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:geolocator/geolocator.dart';

import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';

/// OPTIMIZED: OnboardingScreen featuring a swipeable PageView carousel
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

  // Slide 3 state
  bool _isSubmitting = false;

  // OPTIMIZED: Const list of fixed persona options (Fitness, Health, Traveler)
  static const List<Map<String, dynamic>> _personas = [
    {
      'id': 'Fitness',
      'title': 'Fitness Enthusiast',
      'subtitle': 'Optimized workout timing, UV alerts & outdoor running weather.',
      'icon': Icons.directions_run_rounded,
    },
    {
      'id': 'Health',
      'title': 'Health Sensitive',
      'subtitle': 'Air quality (AQI), pollen, pressure & temperature shifts.',
      'icon': Icons.favorite_rounded,
    },
    {
      'id': 'Traveler',
      'title': 'Daily Traveler',
      'subtitle': 'Commute forecasts, rain warnings & destination weather.',
      'icon': Icons.flight_takeoff_rounded,
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

  // OPTIMIZED: Asynchronous onboarding completion handler using getLastKnownPosition + background update
  Future<void> _completeOnboarding(bool locationAllowed) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    if (locationAllowed) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            // 1. Try last known position first (near-instant)
            final lastPosition = await Geolocator.getLastKnownPosition();
            if (lastPosition != null) {
              ref.read(locationProvider.notifier).setLocation(
                    lastPosition.latitude,
                    lastPosition.longitude,
                    'Current Location',
                  );
            }

            // 2. In background, fetch fresh position with medium accuracy & 6s timeout
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
    ref.read(userProvider.notifier).completeOnboarding();

    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1220),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1220),
              Color(0xFF0F2A4A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // OPTIMIZED: Top Bar with Back button & 3 Progress Dots Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: _currentPage > 0
                          ? IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
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
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: isCurrent
                                  ? const Color(0xFF0E7C86)
                                  : const Color(0xFF0E7C86).withValues(alpha: 0.3),
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(width: 40),
                  ],
                ),
              ),

              // OPTIMIZED: PageView Carousel with conditional scroll physics (blocked until Slide 1 input)
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          Text(
            'Choose Your Persona',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mausam AI adapts weather forecasts and recommendations to your lifestyle.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF8A9BB5),
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
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0E7C86).withValues(alpha: 0.2)
                          : const Color(0xFF152238).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0E7C86)
                            : const Color(0xFF233554),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0E7C86).withValues(alpha: 0.3),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? const Color(0xFF0E7C86)
                                : const Color(0xFF1E3352),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: Colors.white,
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['subtitle'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF8A9BB5),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF0E7C86),
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _selectedPersona != null ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E7C86),
                disabledBackgroundColor: const Color(0xFF0E7C86).withValues(alpha: 0.3),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // SLIDE 2: Notifications
  Widget _buildSlide2Notifications() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          Text(
            'Smart Alerts',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Get proactive notifications before rain, extreme heat, or sudden air quality shifts.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF8A9BB5),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 36),

          // Card with Switch
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF152238).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF233554)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF2E86AB),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 24,
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
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Timely updates tailored to your persona.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF8A9BB5),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _notificationsEnabled,
                  activeThumbColor: const Color(0xFF0E7C86),
                  activeTrackColor: const Color(0xFF0E7C86).withValues(alpha: 0.5),
                  onChanged: (val) {
                    setState(() {
                      _notificationsEnabled = val;
                    });
                  },
                ),
              ],
            ),
          ),

          const Spacer(),

          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E7C86),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // SLIDE 3: Location Access
  Widget _buildSlide3Location() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          Text(
            'Location Access',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Allow Mausam AI to access your location for hyper-local forecasts and real-time alerts.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF8A9BB5),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 36),

          // Illustration Icon Box
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0E7C86).withValues(alpha: 0.15),
                border: Border.all(color: const Color(0xFF0E7C86), width: 2),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Color(0xFF0E7C86),
                size: 48,
              ),
            ),
          ),

          const Spacer(),

          if (_isSubmitting)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0E7C86),
              ),
            )
          else ...[
            // Allow location access primary button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _completeOnboarding(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E7C86),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  'Allow Location Access',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Not now secondary button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () => _completeOnboarding(false),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8A9BB5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  'Not Now',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8A9BB5),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
