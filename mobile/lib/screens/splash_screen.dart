import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/bootstrap_provider.dart';
import '../theme/weather_palette.dart';

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
    final path = GoRouterState.of(context).uri.path;
    final onLaunch = path == '/splash' || path == '/';
    if (!onLaunch) return;
    if (boot.destination == LaunchDestination.login) {
      context.go('/login');
    } else if (boot.destination == LaunchDestination.home && boot.ready) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BootstrapState>(bootstrapProvider, (prev, next) {
      _maybeNavigate(next);
    });
    final boot = ref.watch(bootstrapProvider);

    return Scaffold(
      backgroundColor: MausamPalette.bgDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Text(
                'MAUSAM',
                style: GoogleFonts.inter(
                  color: MausamPalette.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4.0,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your weather, understood.',
                style: GoogleFonts.inter(
                  color: MausamPalette.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: MausamPalette.textTertiary, width: 1.2),
                ),
              ),
              const SizedBox(height: 36),
              Text(
                'Preparing your experience…',
                style: GoogleFonts.inter(
                  color: MausamPalette.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 28),
              _LaunchSteps(state: boot),
              if (boot.locationPermissionNeeded) ...[
                const SizedBox(height: 28),
                Text(
                  'Location permission needed',
                  style: GoogleFonts.inter(
                    color: MausamPalette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mausam can use a saved city, or you can search for one.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => ref.read(bootstrapProvider.notifier).continueWithoutGps(),
                      child: const Text('Continue'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(bootstrapProvider.notifier).continueWithoutGps();
                        context.go('/saved-locations');
                      },
                      child: const Text('Search a city'),
                    ),
                  ],
                ),
              ],
              if (boot.errorMessage != null) ...[
                const SizedBox(height: 28),
                Text(
                  'Weather unavailable',
                  style: GoogleFonts.inter(
                    color: MausamPalette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  boot.errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(bootstrapProvider.notifier).retryWeather(),
                  child: const Text('Try again'),
                ),
              ],
              const Spacer(flex: 4),
            ],
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
      ('Initializing', state.initializing),
      ('Restoring session', state.restoringSession),
      ('Getting location', state.gettingLocation),
      ('Loading weather', state.loadingWeather),
    ];
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: _StepMark(status: row.$2),
                ),
                const SizedBox(width: 10),
                Text(
                  row.$1,
                  style: GoogleFonts.inter(
                    color: row.$2 == LaunchStepStatus.pending
                        ? MausamPalette.textMuted
                        : MausamPalette.textSecondary,
                    fontSize: 13,
                    fontWeight: row.$2 == LaunchStepStatus.running ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StepMark extends StatelessWidget {
  final LaunchStepStatus status;
  const _StepMark({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case LaunchStepStatus.done:
        return const Icon(Icons.check, size: 16, color: MausamPalette.textPrimary);
      case LaunchStepStatus.running:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.4, color: MausamPalette.textSecondary),
        );
      case LaunchStepStatus.blocked:
      case LaunchStepStatus.failed:
        return const Icon(Icons.remove, size: 16, color: MausamPalette.textTertiary);
      case LaunchStepStatus.pending:
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: MausamPalette.textMuted),
          ),
        );
    }
  }
}
