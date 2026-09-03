import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _breathingController;
  late final Animation<double> _scaleAnimation;

  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    // 1. Logo Breathing Animation 0.96 -> 1.04 loop 2.5s
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    );

    // 2. Progress Controller 0 to 1 over 2500ms linear
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );

    _progressController.forward();

    // OPTIMIZED: Defer auth check and router navigation until 2.5s splash animation completes
    _navigationTimer = Timer(const Duration(milliseconds: 2500), _checkAuthAndNavigate);
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;

    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser ?? FirebaseAuth.instance.currentUser;

    if (user != null) {
      String? idToken;
      try {
        idToken = await user.getIdToken();
      } catch (_) {}

      final userNotifier = ref.read(userProvider.notifier);
      userNotifier.setAuthenticated(
        userId: user.uid,
        email: user.email ?? 'user@mausam.ai',
        idToken: idToken ?? 'test_token',
      );

      final userState = ref.read(userProvider);
      if (userState.selectedPersona == null) {
        try {
          final me = await ref.read(apiClientProvider).getMe(idToken: idToken ?? 'test_token');
          final persona = me['persona'] as String? ?? me['persona_type'] as String? ?? 'Fitness';
          userNotifier.setPersona(persona);
        } catch (_) {
          userNotifier.setPersona('Fitness');
        }
      }

      userNotifier.completeOnboarding();
      if (mounted) {
        context.go('/home');
      }
    } else {
      // Try to restore a persisted guest session before falling through to /login
      final userNotifier = ref.read(userProvider.notifier);
      final guestRestored = await userNotifier.restoreGuestSession();
      if (guestRestored && mounted) {
        context.go('/home');
      } else if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _breathingController.stop();
    _progressController.stop();
    _breathingController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // OPTIMIZED: Pre-construct image asset widget to prevent rebuilds on scale animation ticks
    final Widget logoAsset = Image.asset(
      'assets/images/logo.png',
      height: 80,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.cloud_queue,
        size: 80,
        color: Color(0xFF3FA9F5),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure black #000000
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // OPTIMIZED: Isolated RepaintBoundary for breathing logo animation to eliminate layout thrashing
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                child: logoAsset,
                builder: (context, cachedLogo) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3FA9F5).withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: cachedLogo!,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Title: "Mausam" bold 26 white, "PersonalAI" regular 14 tracking 5px, "AI" color #3FA9F5
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Mausam ',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Personal',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    letterSpacing: 5.0,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'AI',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    letterSpacing: 5.0,
                    color: const Color(0xFF3FA9F5),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Single Progress loader line
            Container(
              width: 110,
              height: 2,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2A40),
                borderRadius: BorderRadius.circular(2),
              ),
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: const LinearGradient(
                              colors: [
                                Colors.white,
                                Color(0xFF3FA9F5),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Loading your sky...',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF5A6A8A).withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
