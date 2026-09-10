import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
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
  String? _submittingMessage;
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
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1416),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF132219),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF10B981), width: 1),
        ),
      ),
    );
  }

  String _friendlyAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'operation-not-allowed':
          return 'Email/Password sign-in is disabled in your Firebase project. Please enable it in the Firebase Console under Authentication > Sign-in method.';
        case 'unsupported-desktop-platform':
          return 'Google Sign-In is only available on Mobile (Android & iOS) and Web. On Windows desktop, please sign in with Email & Password or Continue as Guest.';
        case 'user-not-found':
          return 'No account found with this email address. Tap "Create an account" below to register.';
        case 'wrong-password':
          return 'Incorrect password. Please try again or tap "Forgot password?".';
        case 'invalid-credential':
          return 'Invalid email or password. Please verify your credentials or tap "Forgot password?".';
        case 'email-already-in-use':
          return 'An account already exists with this email. Please switch to "Sign in".';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a few minutes and try again.';
        case 'network-request-failed':
          return 'Network connection failed. Please check your internet connection.';
        default:
          final msg = error.message ?? error.code;
          if (msg.contains('PASSWORD_LOGIN_DISABLED') ||
              msg.contains('OPERATION_NOT_ALLOWED')) {
            return 'Email/Password sign-in is disabled in your Firebase project. Please enable it in the Firebase Console under Authentication > Sign-in method.';
          }
          return msg;
      }
    }
    final errStr = error.toString();
    if (errStr.contains('MissingPluginException') ||
        errStr.contains('No implementation found')) {
      return 'Google Sign-In is only available on Mobile (Android & iOS) and Web. On Windows desktop, please sign in with Email & Password or Continue as Guest.';
    }
    if (errStr.contains('PASSWORD_LOGIN_DISABLED') ||
        errStr.contains('OPERATION_NOT_ALLOWED')) {
      return 'Email/Password sign-in is disabled in your Firebase project. Please enable it in the Firebase Console under Authentication > Sign-in method.';
    }
    if (errStr.contains('ApiException: 10')) {
      return 'Google Sign-In configuration mismatch. Try Email or Guest Sign In.';
    }
    if (errStr.contains('TimeoutException') || errStr.contains('Timeout')) {
      return 'Connection timed out. Please check your internet and try again.';
    }
    return errStr;
  }

  Future<void> _handleGoogleAuth() async {
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux);

    setState(() {
      _isSubmitting = true;
      _inlineError = null;
      _submittingMessage = isDesktop
          ? 'Opening Google Sign-In in your browser...'
          : null;
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
      final msg = _friendlyAuthError(e);
      setState(() {
        _inlineError = msg;
      });
      _showErrorSnackBar(msg);
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('12501') || errStr.contains('CANCELED')) return;
      final friendlyMsg = _friendlyAuthError(e);
      setState(() {
        _inlineError = friendlyMsg;
      });
      _showErrorSnackBar(friendlyMsg);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submittingMessage = null;
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
      final user = await authService.signInWithEmail(email: email, password: password);
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
      final msg = _friendlyAuthError(e);
      setState(() {
        _inlineError = msg;
      });
      _showErrorSnackBar(msg);
    } catch (e) {
      final msg = _friendlyAuthError(e);
      setState(() {
        _inlineError = msg;
      });
      _showErrorSnackBar(msg);
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
      final msg = _friendlyAuthError(e);
      setState(() {
        _inlineError = msg;
      });
      _showErrorSnackBar(msg);
    } catch (e) {
      final msg = _friendlyAuthError(e);
      setState(() {
        _inlineError = msg;
      });
      _showErrorSnackBar(msg);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _sendPasswordReset(String email) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@') || !trimmedEmail.contains('.')) {
      _showErrorSnackBar('Please enter a valid email address.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submittingMessage = 'Sending password reset email...';
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendPasswordResetEmail(trimmedEmail);
      if (mounted) {
        _showSuccessSnackBar('Password reset link sent to $trimmedEmail. Check your inbox!');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'operation-not-allowed':
          errorMessage =
              'Password reset is disabled in your Firebase project. Please enable Email/Password provider in the Firebase Console.';
          break;
        case 'user-not-found':
          errorMessage = 'No account found with this email address.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address format is invalid.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again in a few minutes.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network connection failed. Please check your internet.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        default:
          errorMessage = _friendlyAuthError(e);
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('Unable to send reset email: ${_friendlyAuthError(e)}');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submittingMessage = null;
        });
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final dialogEmailController = TextEditingController(text: _emailController.text.trim());
    String? dialogError;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF141417),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF27272A), width: 1),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: Color(0xFFFAFAFA),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Reset Password',
                    style: GoogleFonts.inter(
                      color: MausamPalette.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enter your registered email address and we will send you a password reset link.',
                    style: GoogleFonts.inter(
                      color: MausamPalette.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('forgot_password_dialog_email_field'),
                    controller: dialogEmailController,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(
                      color: MausamPalette.textPrimary,
                      fontSize: 13.5,
                    ),
                    decoration: _inputDecoration(
                      hintText: 'name@example.com',
                      prefixIcon: Icons.mail_outline_rounded,
                    ).copyWith(
                      errorText: dialogError,
                    ),
                    onSubmitted: (value) {
                      final val = value.trim();
                      if (val.isEmpty || !val.contains('@') || !val.contains('.')) {
                        setDialogState(() {
                          dialogError = 'Enter a valid email address';
                        });
                        return;
                      }
                      Navigator.of(dialogContext).pop();
                      _emailController.text = val;
                      _sendPasswordReset(val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: MausamPalette.textMuted,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                ElevatedButton(
                  key: const Key('send_reset_link_button'),
                  onPressed: () {
                    final val = dialogEmailController.text.trim();
                    if (val.isEmpty || !val.contains('@') || !val.contains('.')) {
                      setDialogState(() {
                        dialogError = 'Enter a valid email address';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop();
                    _emailController.text = val;
                    _sendPasswordReset(val);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFAFAFA),
                    foregroundColor: const Color(0xFF09090B),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Send Link',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isNotEmpty && email.contains('@') && email.contains('.')) {
      await _sendPasswordReset(email);
    } else {
      await _showForgotPasswordDialog();
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
        fontSize: 12.5,
      ),
      filled: true,
      fillColor: const Color(0xFF141417),
      prefixIcon: Icon(
        prefixIcon,
        color: MausamPalette.textTertiary,
        size: 16,
      ),
      suffixIcon: suffixIcon,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF27272A), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFAFAFA), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
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
        showCelestialDisc: false,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Brand Identity (Spacious, airy feel)
                        const SizedBox(height: 6),
                        const AnimatedLogoContainer(height: 52),
                        const SizedBox(height: 10),
                        Text(
                          'MAUSAM',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4.5,
                            color: MausamPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'PERSONAL WEATHER INTELLIGENCE',
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                            color: MausamPalette.textTertiary,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Sleek, Minimalist Auth Surface (< 45% screen height)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xAA0E0E12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Compact Mode Pill Switcher
                                  Container(
                                    height: 36,
                                    padding: const EdgeInsets.all(2.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF141417),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFF27272A),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        _modeTab('Sign In', isSignIn, AuthViewMode.signIn),
                                        _modeTab('Create Account', !isSignIn, AuthViewMode.createAccount),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  Text(
                                    isSignIn ? 'Welcome back' : 'Create an account',
                                    style: GoogleFonts.inter(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: MausamPalette.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isSignIn
                                        ? 'Continue with email or Google.'
                                        : 'A few details, then we personalize the day.',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: MausamPalette.textSecondary,
                                    ),
                                  ),

                                  if (_inlineError != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: MausamPalette.cardSurfaceLight,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: MausamPalette.cardBorder, width: 1),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 15),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _inlineError!,
                                              style: GoogleFonts.inter(color: Colors.white, fontSize: 11.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 14),

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
                                    const SizedBox(height: 10),
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

                                  const SizedBox(height: 10),

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
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: MausamPalette.textTertiary,
                                          size: 16,
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
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _confirmPasswordController,
                                      enabled: !_isSubmitting,
                                      obscureText: _obscureConfirmPassword,
                                      style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 13),
                                      decoration: _inputDecoration(
                                        hintText: 'Confirm password',
                                        prefixIcon: Icons.lock_reset_rounded,
                                        suffixIcon: IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: MausamPalette.textTertiary,
                                            size: 16,
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
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Forgot password?',
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            color: MausamPalette.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                  ] else
                                    const SizedBox(height: 12),

                                  // Primary Action Button (42px compact)
                                  SizedBox(
                                    width: double.infinity,
                                    height: 42,
                                    child: ElevatedButton(
                                      key: const Key('continue_with_email_button'),
                                      onPressed: _isSubmitting
                                          ? null
                                          : (isSignIn ? _handleSignInSubmit : _handleCreateAccountSubmit),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFAFAFA),
                                        foregroundColor: const Color(0xFF09090B),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        isSignIn ? 'Sign In' : 'Create Account',
                                        key: const Key('sign_in_button'),
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Hairline Divider
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: const Color(0xFF27272A),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Text(
                                          'or continue with',
                                          style: GoogleFonts.inter(
                                            fontSize: 10.5,
                                            color: MausamPalette.textTertiary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: const Color(0xFF27272A),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Google Button (42px compact)
                                  SizedBox(
                                    width: double.infinity,
                                    height: 42,
                                    child: OutlinedButton(
                                      key: const Key('google_sign_in_button'),
                                      onPressed: _isSubmitting ? null : _handleGoogleAuth,
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: const Color(0xFF141417),
                                        foregroundColor: MausamPalette.textPrimary,
                                        side: const BorderSide(color: Color(0xFF27272A), width: 1),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const GoogleIconWidget(size: 16),
                                          const SizedBox(width: 8),
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

                                  const SizedBox(height: 12),

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
                                            fontSize: 11.5,
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
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: MausamPalette.textPrimary,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 4),

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
                                          fontSize: 11.5,
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

                        const SizedBox(height: 12),

                        // Subtle Terms and Privacy
                        Text(
                          'By continuing, you agree to Mausam Terms of Service and Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            color: MausamPalette.textMuted,
                            height: 1.3,
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
                  color: Colors.black.withValues(alpha: 0.65),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 320),
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
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF58A6FF)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _submittingMessage != null
                                ? 'Opening Google in Browser'
                                : (isSignIn ? 'Signing you in...' : 'Creating your account...'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: MausamPalette.textPrimary,
                            ),
                          ),
                          if (_submittingMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'A Google Sign-In window has opened in your default browser. Please select your Google account in that window to continue.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w400,
                                color: MausamPalette.textSecondary,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isSubmitting = false;
                                  _submittingMessage = null;
                                });
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: MausamPalette.textMuted,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
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
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF27272A) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? MausamPalette.textPrimary : MausamPalette.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
