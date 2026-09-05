import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../theme/environment_theme.dart';
import '../theme/weather_palette.dart';
import '../widgets/animated_logo_container.dart';
import '../widgets/google_icon.dart';
import '../widgets/weather_environment_background.dart';

enum AuthViewMode { signIn, createAccount }

class LoginScreen extends ConsumerStatefulWidget {
  final AuthViewMode initialMode;

  const LoginScreen({
    super.key,
    this.initialMode = AuthViewMode.signIn,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late AuthViewMode _mode;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
        backgroundColor: MausamPalette.cardSurfaceLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: MausamPalette.cardSurfaceLight,
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
      final msg = e.message ?? e.code;
      setState(() {
        _inlineError = msg;
      });
      _showErrorSnackBar(msg);
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('12501') || errStr.contains('CANCELED')) return;
      final friendlyMsg = errStr.contains('ApiException: 10')
          ? 'Google Sign-In configuration mismatch. Try Email or Guest Sign In.'
          : errStr.contains('TimeoutException') || errStr.contains('Timeout')
              ? 'Connection timed out. Please try again.'
              : 'Google Sign-In failed ($errStr). Try Email or Guest Sign In.';
      setState(() {
        _inlineError = friendlyMsg;
      });
      _showErrorSnackBar(friendlyMsg);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleSignInSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showErrorSnackBar('Please enter a valid email address.');
      return;
    }
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

  Future<void> _handleCreateAccountSubmit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showErrorSnackBar('Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters.');
      return;
    }
    if (password != confirmPassword) {
      _showErrorSnackBar('Passwords do not match.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _inlineError = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.registerWithEmail(email: email, password: password);
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
            displayName: name.isNotEmpty ? name : null,
            idToken: idToken,
          );

      if (!mounted) return;
      context.go('/onboarding');
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

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showErrorSnackBar('Enter your email in the field above to reset your password.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSuccessSnackBar('Password reset link sent to $email');
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(e.message ?? 'Failed to send reset email.');
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(
        color: MausamPalette.textMuted,
        fontSize: 13,
      ),
      filled: true,
      fillColor: const Color(0xFF141417),
      prefixIcon: Icon(
        prefixIcon,
        color: MausamPalette.textTertiary,
        size: 18,
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: MausamPalette.cardBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: MausamPalette.textPrimary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSignIn = _mode == AuthViewMode.signIn;

    return Scaffold(
      backgroundColor: MausamPalette.bgDeep,
      body: WeatherEnvironmentBackground(
        wallpaperTheme: WallpaperTheme.dynamic,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Brand Identity
                        const AnimatedLogoContainer(height: 58),
                        const SizedBox(height: 12),
                        Text(
                          'MAUSAM',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4.0,
                            color: MausamPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'PERSONAL WEATHER INTELLIGENCE',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.8,
                            color: MausamPalette.textTertiary,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Translucent Obsidian Auth Surface
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                              decoration: BoxDecoration(
                                color: MausamPalette.cardSurface.withValues(alpha: 0.78),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: MausamPalette.cardBorder.withValues(alpha: 0.8),
                                  width: 1,
                                ),
                                boxShadow: MausamPalette.heroShadow,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Section Header
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: MausamPalette.bgDeep.withValues(alpha: 0.55),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: MausamPalette.cardBorder),
                                    ),
                                    child: Row(
                                      children: [
                                        _modeTab('Sign In', isSignIn, AuthViewMode.signIn),
                                        _modeTab('Create Account', !isSignIn, AuthViewMode.createAccount),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    isSignIn ? 'Welcome back' : 'Create an account',
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: MausamPalette.textPrimary,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isSignIn
                                        ? 'Continue with email or Google.'
                                        : 'A few details, then we personalize the day.',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: MausamPalette.textSecondary,
                                    ),
                                  ),

                                  if (_inlineError != null) ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: MausamPalette.cardSurfaceLight,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: MausamPalette.cardBorder, width: 1),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _inlineError!,
                                              style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 18),

                                  // Name Field (Create Account mode only)
                                  if (!isSignIn) ...[
                                    TextField(
                                      controller: _nameController,
                                      enabled: !_isSubmitting,
                                      keyboardType: TextInputType.name,
                                      textCapitalization: TextCapitalization.words,
                                      style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 13),
                                      decoration: _inputDecoration(
                                        hintText: 'Full name (optional)',
                                        prefixIcon: Icons.person_outline_rounded,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],

                                  // Email Field
                                  TextField(
                                    key: const Key('login_email_field'),
                                    controller: _emailController,
                                    enabled: !_isSubmitting,
                                    keyboardType: TextInputType.emailAddress,
                                    style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 13),
                                    decoration: _inputDecoration(
                                      hintText: 'Enter your email',
                                      prefixIcon: Icons.mail_outline_rounded,
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Password Field
                                  TextField(
                                    key: const Key('login_password_field'),
                                    controller: _passwordController,
                                    enabled: !_isSubmitting,
                                    obscureText: _obscurePassword,
                                    style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 13),
                                    decoration: _inputDecoration(
                                      hintText: 'Password',
                                      prefixIcon: Icons.lock_outline_rounded,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: MausamPalette.textTertiary,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                  ),

                                  // Confirm Password Field (Create Account mode only)
                                  if (!isSignIn) ...[
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _confirmPasswordController,
                                      enabled: !_isSubmitting,
                                      obscureText: _obscureConfirmPassword,
                                      style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 13),
                                      decoration: _inputDecoration(
                                        hintText: 'Confirm password',
                                        prefixIcon: Icons.lock_reset_rounded,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: MausamPalette.textTertiary,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureConfirmPassword = !_obscureConfirmPassword;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],

                                  if (isSignIn) ...[
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _isSubmitting ? null : _handleForgotPassword,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Forgot password?',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: MausamPalette.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ] else
                                    const SizedBox(height: 16),

                                  // Primary Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      key: const Key('continue_with_email_button'),
                                      onPressed: _isSubmitting
                                          ? null
                                          : (isSignIn ? _handleSignInSubmit : _handleCreateAccountSubmit),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: MausamPalette.textPrimary,
                                        foregroundColor: MausamPalette.bgDeep,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: Text(
                                        isSignIn ? 'Sign In' : 'Create Account',
                                        key: const Key('sign_in_button'),
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Minimal Divider
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: MausamPalette.cardBorder,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          'or continue with',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: MausamPalette.textTertiary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: MausamPalette.cardBorder,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 14),

                                  // Google Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 46,
                                    child: OutlinedButton(
                                      key: const Key('google_sign_in_button'),
                                      onPressed: _isSubmitting ? null : _handleGoogleAuth,
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: const Color(0xFF141417),
                                        foregroundColor: MausamPalette.textPrimary,
                                        side: const BorderSide(color: MausamPalette.cardBorder, width: 1),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const GoogleIconWidget(size: 18),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Google',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: MausamPalette.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Mode Switcher Link
                                  Center(
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          isSignIn
                                              ? "Don't have an account? "
                                              : "Already have an account? ",
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: MausamPalette.textSecondary,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: _isSubmitting
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _mode = isSignIn
                                                        ? AuthViewMode.createAccount
                                                        : AuthViewMode.signIn;
                                                    _inlineError = null;
                                                  });
                                                },
                                          child: Text(
                                            isSignIn ? 'Create an account' : 'Sign in',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: MausamPalette.textPrimary,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Continue as Guest Button
                                  Center(
                                    child: TextButton(
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
                                          color: MausamPalette.textTertiary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Subtle Terms and Privacy
                        Text(
                          'By continuing, you agree to Mausam Terms of Service and Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: MausamPalette.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Full Screen Submitting Indicator
              if (_isSubmitting)
                Container(
                  color: Colors.black.withValues(alpha: 0.55),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        color: MausamPalette.cardSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: MausamPalette.cardBorder),
                        boxShadow: MausamPalette.heroShadow,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(MausamPalette.textPrimary),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            isSignIn ? 'Signing you in...' : 'Creating your account...',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: MausamPalette.textPrimary,
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
    );
  }

  Widget _modeTab(String label, bool selected, AuthViewMode mode) {
    return Expanded(
      child: GestureDetector(
        onTap: _isSubmitting
            ? null
            : () {
                setState(() {
                  _mode = mode;
                  _inlineError = null;
                });
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? MausamPalette.cardSurfaceLight : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? MausamPalette.textPrimary : MausamPalette.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
