import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/bootstrap_provider.dart';
import '../theme/weather_palette.dart';
import '../widgets/animated_logo_container.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bootstrapProvider.notifier).run();
    });
  }

  void _maybeNavigate(BootstrapState boot) {
    if (!mounted) return;
    String path = '/splash';
    try {
      path = GoRouterState.of(context).uri.path;
    } catch (_) {
      // Context not directly within a GoRoute
    }
    final onLaunch = path == '/splash' || path == '/';
    if (!onLaunch) return;
    if (boot.destination == LaunchDestination.login) {
      context.go('/login');
    } else if (boot.destination == LaunchDestination.home && boot.ready) {
      context.go('/home');
    }
  }

  double _calculateProgress(BootstrapState boot) {
    int doneCount = 0;
    if (boot.initializing == LaunchStepStatus.done) doneCount++;
    if (boot.restoringSession == LaunchStepStatus.done) doneCount++;
    if (boot.gettingLocation == LaunchStepStatus.done) doneCount++;
    if (boot.loadingWeather == LaunchStepStatus.done) doneCount++;

    if (boot.ready) return 1.0;
    if (doneCount == 0) return 0.15;
    if (doneCount == 1) return 0.40;
    if (doneCount == 2) return 0.70;
    if (doneCount == 3) return 0.90;
    return 1.0;
  }

  String _currentStatusMessage(BootstrapState boot) {
    if (boot.errorMessage != null) return 'Weather service temporarily unavailable';
    if (boot.locationPermissionNeeded) return 'Location access required for live weather';
    if (boot.ready) return 'System ready • Launching dashboard';
    if (boot.loadingWeather == LaunchStepStatus.running) return 'Fetching live atmospheric data & AQI...';
    if (boot.gettingLocation == LaunchStepStatus.running) return 'Acquiring high-speed coordinates...';
    if (boot.restoringSession == LaunchStepStatus.running) return 'Restoring your session & preferences...';
    if (boot.initializing == LaunchStepStatus.running) return 'Initializing weather intelligence core...';
    return 'Calibrating local weather feeds...';
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BootstrapState>(bootstrapProvider, (prev, next) {
      _maybeNavigate(next);
    });
    final boot = ref.watch(bootstrapProvider);
    final progress = _calculateProgress(boot);
    final statusMsg = _currentStatusMessage(boot);

    return Scaffold(
      backgroundColor: MausamPalette.bgDeep,
      body: SafeArea(
        child: SizedBox.expand(
          child: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Center(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Centered Brand Emblem
                      const Center(
                        child: AnimatedLogoContainer(height: 64),
                      ),
                      const SizedBox(height: 16),

                      // Optically Centered Title
                      Padding(
                        padding: const EdgeInsets.only(left: 4.5),
                        child: Text(
                          'MAUSAM',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: MausamPalette.textPrimary,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Subtitle
                      Padding(
                        padding: const EdgeInsets.only(left: 2.0),
                        child: Text(
                          'PERSONAL WEATHER INTELLIGENCE',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: MausamPalette.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Refined, Centered Initializing Glass Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111115),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF24242A), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card Header: Indicator & Progress %
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: boot.ready
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFFAFAFA),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (boot.ready
                                                      ? const Color(0xFF10B981)
                                                      : Colors.white)
                                                  .withValues(alpha: 0.6),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'INITIALIZING',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: MausamPalette.textTertiary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A20),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF2E2E36), width: 0.8),
                                  ),
                                  child: Text(
                                    '${(progress * 100).toInt()}%',
                                    style: GoogleFonts.inter(
                                      color: MausamPalette.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Micro Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: Container(
                                height: 4,
                                width: double.infinity,
                                color: const Color(0xFF1F1F26),
                                child: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeOutCubic,
                                  tween: Tween<double>(begin: 0.05, end: progress),
                                  builder: (context, value, child) {
                                    return FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: value.clamp(0.0, 1.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFD4D4D8), Color(0xFFFFFFFF)],
                                          ),
                                          borderRadius: BorderRadius.circular(3),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.white.withValues(alpha: 0.45),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Dynamic Status Message
                            Text(
                              statusMsg,
                              style: GoogleFonts.inter(
                                color: boot.errorMessage != null
                                    ? const Color(0xFFF87171)
                                    : (boot.locationPermissionNeeded
                                        ? const Color(0xFFFBBF24)
                                        : MausamPalette.textSecondary),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 14),
                            const Divider(color: Color(0xFF222228), height: 1),
                            const SizedBox(height: 10),

                            // Steps Breakdown
                            _LaunchSteps(state: boot),
                          ],
                        ),
                      ),

                      // Location Permission Needed Action
                      if (boot.locationPermissionNeeded) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16161B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF2A2A32)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Location Access Recommended',
                                style: GoogleFonts.inter(
                                  color: MausamPalette.textPrimary,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Mausam can use a saved city or quick search if GPS is denied.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: MausamPalette.textSecondary,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => ref
                                          .read(bootstrapProvider.notifier)
                                          .continueWithoutGps(),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        side: const BorderSide(color: Color(0xFF3F3F46)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text('Continue', style: TextStyle(fontSize: 12.5)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        ref
                                            .read(bootstrapProvider.notifier)
                                            .continueWithoutGps();
                                        context.go('/saved-locations');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        backgroundColor: const Color(0xFFFAFAFA),
                                        foregroundColor: const Color(0xFF09090B),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text('Search City', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Error Retry Banner
                      if (boot.errorMessage != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1212),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF3D1F1F)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Connection Interrupted',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFFCA5A5),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                boot.errorMessage!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: MausamPalette.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () =>
                                    ref.read(bootstrapProvider.notifier).retryWeather(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFAFAFA),
                                  foregroundColor: const Color(0xFF09090B),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Retry Connection', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LaunchSteps extends StatelessWidget {
  final BootstrapState state;
  const _LaunchSteps({required this.state});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Core Initialization', state.initializing),
      ('Profile & Session', state.restoringSession),
      ('Fast Location Lock', state.gettingLocation),
      ('Atmospheric & AQI Sync', state.loadingWeather),
    ];

    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.5),
            child: Row(
              children: [
                _StepMark(status: row.$2),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    row.$1,
                    style: GoogleFonts.inter(
                      color: row.$2 == LaunchStepStatus.running
                          ? MausamPalette.textPrimary
                          : (row.$2 == LaunchStepStatus.done
                              ? MausamPalette.textSecondary
                              : MausamPalette.textMuted),
                      fontSize: 12.5,
                      fontWeight: row.$2 == LaunchStepStatus.running
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                Text(
                  _statusLabel(row.$2),
                  style: GoogleFonts.inter(
                    color: row.$2 == LaunchStepStatus.running
                        ? const Color(0xFFFAFAFA)
                        : (row.$2 == LaunchStepStatus.done
                            ? const Color(0xFF71717A)
                            : const Color(0xFF3F3F46)),
                    fontSize: 10.5,
                    fontWeight: row.$2 == LaunchStepStatus.running
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _statusLabel(LaunchStepStatus status) {
    switch (status) {
      case LaunchStepStatus.done:
        return 'Done';
      case LaunchStepStatus.running:
        return 'Active';
      case LaunchStepStatus.blocked:
        return 'Skipped';
      case LaunchStepStatus.failed:
        return 'Failed';
      case LaunchStepStatus.pending:
        return '—';
    }
  }
}

class _StepMark extends StatelessWidget {
  final LaunchStepStatus status;
  const _StepMark({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case LaunchStepStatus.done:
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1),
          ),
          child: const Center(
            child: Icon(Icons.check, size: 11, color: Colors.white),
          ),
        );
      case LaunchStepStatus.running:
        return const SizedBox(
          width: 18,
          height: 18,
          child: Center(
            child: SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 1.6,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        );
      case LaunchStepStatus.blocked:
      case LaunchStepStatus.failed:
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFEF4444).withValues(alpha: 0.16),
            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4), width: 1),
          ),
          child: const Center(
            child: Icon(Icons.close, size: 10, color: Color(0xFFF87171)),
          ),
        );
      case LaunchStepStatus.pending:
        return Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF3F3F46),
            ),
          ),
        );
    }
  }
}

