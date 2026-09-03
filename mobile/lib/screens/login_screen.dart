import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../widgets/animated_logo_container.dart';
import '../widgets/google_icon.dart';
import '../widgets/rain_particles.dart';

enum LoginStep { initial, password }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  LoginStep _currentStep = LoginStep.initial;
  bool _isSubmitting = false;
  String? _inlineError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _handleGoogleAuth() async {
    setState(() {
      _isSubmitting = true;
      _inlineError = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.signInWithGoogle();
      final idToken = user.idToken ?? await authService.getIdToken();

      final apiClient = ref.read(apiClientProvider);
      if (idToken != null) {
        try {
          await apiClient.getMe(idToken: idToken);
          await apiClient.postUser(
            idToken: idToken,
            email: user.email,
          );
        } catch (_) {}
      }

      ref.read(userProvider.notifier).setAuthenticated(
            userId: user.uid,
            email: user.email,
            idToken: idToken,
          );

      final userState = ref.read(userProvider);
      if (!mounted) return;
      if (userState.onboardingCompleted || userState.selectedPersona != null) {
        context.go('/home');
      } else {
        context.go('/onboarding');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'ERROR_ABORTED_BY_USER' || e.code == '12501') return;
      setState(() {
        _inlineError = e.message ?? e.code;
      });
      _showErrorSnackBar(e.message ?? e.code);
    } catch (e) {
      final errStr = e.toString();
      setState(() {
        _inlineError = errStr.contains('TimeoutException') || errStr.contains('Timeout')
            ? 'Connection timed out. Please try again.'
            : errStr;
      });
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleEmailContinue() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showErrorSnackBar('Please enter a valid email address.');
      return;
    }

    setState(() {
      _currentStep = LoginStep.password;
    });
  }

  Future<void> _handlePasswordSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (password.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _inlineError = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      late final AuthUser user;

      try {
        user = await authService.signInWithEmail(email: email, password: password);
      } catch (e) {
        if (e is FirebaseAuthException &&
            (e.code == 'user-not-found' || e.code == 'invalid-credential')) {
          user = await authService.registerWithEmail(email: email, password: password);
        } else {
          rethrow;
        }
      }

      final idToken = user.idToken ?? await authService.getIdToken();

      final apiClient = ref.read(apiClientProvider);
      if (idToken != null) {
        try {
          await apiClient.getMe(idToken: idToken);
          await apiClient.postUser(
            idToken: idToken,
            email: user.email,
          );
        } catch (_) {}
      }

      ref.read(userProvider.notifier).setAuthenticated(
            userId: user.uid,
            email: user.email,
            idToken: idToken,
          );

      final userState = ref.read(userProvider);
      if (!mounted) return;
      if (userState.onboardingCompleted || userState.selectedPersona != null) {
        context.go('/home');
      } else {
        context.go('/onboarding');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _inlineError = e.message ?? e.code;
      });
      _showErrorSnackBar(e.message ?? e.code);
    } catch (e) {
      final errStr = e.toString();
      setState(() {
        _inlineError = errStr.contains('TimeoutException') || errStr.contains('Timeout')
            ? 'Connection timed out. Please try again.'
            : errStr;
      });
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
              Color(0xFF111E35),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Radial glow top center
            Positioned(
              top: -60,
              left: 0,
              right: 0,
              height: 240,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1E3A5F).withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                    radius: 0.7,
                  ),
                ),
              ),
            ),

            // Low-opacity rain dots (0.08)
            const RainParticlesWidget(particleCount: 30, opacity: 0.08),

            // NO AppBar, NO top navbar title "Mausam PersonalAI". SafeArea top padding 24.
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Stack(
                  children: [
                    if (_currentStep == LoginStep.password)
                      Positioned(
                        top: 0,
                        left: 8,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          onPressed: _isSubmitting
                              ? null
                              : () {
                                  setState(() {
                                    _currentStep = LoginStep.initial;
                                  });
                                },
                        ),
                      ),

                    Center(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 8),

                            // Center Hero Logo 72px with glow
                            const AnimatedLogoContainer(height: 72),

                            const SizedBox(height: 14),

                            // Title: "Mausam" 28px extra-bold white, "PersonalAI" 14px letterSpacing 5px, AI blue #3FA9F5
                            Text(
                              'Mausam',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Personal',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                    letterSpacing: 5.0,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                                Text(
                                  'AI',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                    letterSpacing: 5.0,
                                    color: const Color(0xFF3FA9F5),
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),

                            // Divider: width 160, Row line 60px #1E3A5F dot 6px blue line 60px, margin vertical 8
                            Container(
                              width: 160,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: const Color(0xFF1E3A5F),
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 6),
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF3FA9F5),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: const Color(0xFF1E3A5F),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Tagline: "Weather That Knows You" 12px #7A8AA8 centered margin 4
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                'Weather That Knows You',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                  color: const Color(0xFF7A8AA8),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Bottom Auth Container: maxWidth 320 centered, gap 10
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_inlineError != null) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B1D24),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFEF4444), width: 1),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _inlineError!,
                                              style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _inlineError = null;
                                              });
                                              if (_currentStep == LoginStep.password) {
                                                _handlePasswordSubmit();
                                              } else {
                                                _handleGoogleAuth();
                                              }
                                            },
                                            child: Text(
                                              'Retry',
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFF3FA9F5),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (_currentStep == LoginStep.initial) ...[
                                    // Google Button: height 44, radius 22, white bg, black text 14 medium, Google icon 18px, full width
                                    SizedBox(
                                      width: double.infinity,
                                      height: 44,
                                      child: ElevatedButton(
                                        key: const Key('google_sign_in_button'),
                                        onPressed: _isSubmitting ? null : _handleGoogleAuth,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black,
                                          elevation: 0,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(22),
                                          ),
                                        ),
                                        child: _isSubmitting
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                                ),
                                              )
                                            : Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const GoogleIconWidget(size: 18),
                                                  const SizedBox(width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      'Continue with Google',
                                                      overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),

                                    // OR Divider: lines 1px #1E2F4F, text "OR" 10px #5A6A8A, gap 12, vertical margin 6
                                    Container(
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              height: 1,
                                              color: const Color(0xFF1E2F4F),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: Text(
                                              'OR',
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                color: const Color(0xFF5A6A8A),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              height: 1,
                                              color: const Color(0xFF1E2F4F),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Email Input: height 44, radius 22, bg #151F35, border #1E2F4F 1px, text 13 white, placeholder 13 #5A6A8A, prefix icon mail 16
                                    SizedBox(
                                      height: 44,
                                      child: TextField(
                                        key: const Key('login_email_field'),
                                        controller: _emailController,
                                        enabled: !_isSubmitting,
                                        keyboardType: TextInputType.emailAddress,
                                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                        decoration: InputDecoration(
                                          hintText: 'Enter your email',
                                          hintStyle: GoogleFonts.inter(
                                            color: const Color(0xFF5A6A8A),
                                            fontSize: 13,
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFF151F35),
                                          prefixIcon: const Icon(
                                            Icons.mail_outline,
                                            color: Color(0xFF5A6A8A),
                                            size: 16,
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(22),
                                            borderSide: const BorderSide(color: Color(0xFF1E2F4F), width: 1),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(22),
                                            borderSide: const BorderSide(color: Color(0xFF3FA9F5), width: 1),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    // Email Button: height 44, radius 22, bg #1C2C4E, border #2A3F6A 1px, text 14 medium white "Continue with Email"
                                    SizedBox(
                                      width: double.infinity,
                                      height: 44,
                                      child: ElevatedButton(
                                        key: const Key('continue_with_email_button'),
                                        onPressed: _isSubmitting ? null : _handleEmailContinue,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1C2C4E),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(22),
                                            side: const BorderSide(color: Color(0xFF2A3F6A), width: 1),
                                          ),
                                        ),
                                        child: Text(
                                          'Continue with Email',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    // Step 2: Password Input
                                    SizedBox(
                                      height: 44,
                                      child: TextField(
                                        key: const Key('login_password_field'),
                                        controller: _passwordController,
                                        enabled: !_isSubmitting,
                                        obscureText: true,
                                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                        decoration: InputDecoration(
                                          hintText: 'Enter your password',
                                          hintStyle: GoogleFonts.inter(
                                            color: const Color(0xFF5A6A8A),
                                            fontSize: 13,
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFF151F35),
                                          prefixIcon: const Icon(
                                            Icons.lock_outline,
                                            color: Color(0xFF5A6A8A),
                                            size: 16,
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(22),
                                            borderSide: const BorderSide(color: Color(0xFF1E2F4F), width: 1),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(22),
                                            borderSide: const BorderSide(color: Color(0xFF3FA9F5), width: 1),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    SizedBox(
                                      width: double.infinity,
                                      height: 44,
                                      child: ElevatedButton(
                                        key: const Key('sign_in_button'),
                                        onPressed: _isSubmitting ? null : _handlePasswordSubmit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF3FA9F5),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(22),
                                          ),
                                        ),
                                        child: _isSubmitting
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                            : Text(
                                                'Continue',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],

                                  // Guest access: below the auth buttons,
                                  // appears regardless of login step
                                  const SizedBox(height: 12),
                                  TextButton(
                                    key: const Key('continue_as_guest_button'),
                                    onPressed: _isSubmitting
                                        ? null
                                        : () {
                                            ref.read(userProvider.notifier).setGuestSession();
                                            context.go('/onboarding');
                                          },
                                    child: Text(
                                      'Continue as Guest',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF5A6A8A),
                                      ),
                                    ),
                                  ),

                                  // Footer: "By continuing, you agree..." 9px #5A6A8A lineHeight 1.4 maxWidth 280 centered marginTop 12 links blue #3FA9F5 underline
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 280),
                                    child: Container(
                                      margin: const EdgeInsets.only(top: 12),
                                      child: Text.rich(
                                        TextSpan(
                                          text: "By continuing, you agree to Mausam's ",
                                          children: [
                                            TextSpan(
                                              text: "Terms of Service",
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFF3FA9F5),
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                            const TextSpan(text: " and "),
                                            TextSpan(
                                              text: "Privacy Policy",
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFF3FA9F5),
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                            const TextSpan(text: "."),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          height: 1.4,
                                          color: const Color(0xFF5A6A8A),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // NEXT LOADING OVERLAY (When user taps Google or Email Continue)
            if (_isSubmitting)
              Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0xFF0A1220).withValues(alpha: 0.8),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Centered Logo 60px
                      Image.asset(
                        'assets/images/logo.png',
                        height: 60,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.cloud_queue,
                          size: 60,
                          color: Color(0xFF3FA9F5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // CircularProgressIndicator stroke 2 color #3FA9F5
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF3FA9F5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Text "Setting up your sky..." 12px
                      Text(
                        'Setting up your sky...',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: const Color(0xFF8A9BB5),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
