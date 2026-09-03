import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/environment_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MAUSAM — Weather Environment Background
//
// A premium, cinematic, time-aware atmospheric background for the Home screen.
//
// Features:
//   • Real local-time tracking (refreshes every 60s, live during session)
//   • Continuous fractional interpolation — NO abrupt hourly jumps
//   • Smooth AnimationController-driven crossfade between gradient states
//   • CustomPainter atmospheric rendering: multi-stop gradient + radial glow
//   • Per-state adaptive readability vignette overlay
//   • Weather condition modifiers
//   • RepaintBoundary isolation — content above never triggers bg repaint
//   • `hourOverride` for visual QA / testing
// ─────────────────────────────────────────────────────────────────────────────

class WeatherEnvironmentBackground extends StatefulWidget {
  final String? condition;
  final int? hourOverride;
  final Widget child;

  const WeatherEnvironmentBackground({
    super.key,
    this.condition,
    this.hourOverride,
    required this.child,
  });

  @override
  State<WeatherEnvironmentBackground> createState() => _WeatherEnvironmentBackgroundState();
}

class _WeatherEnvironmentBackgroundState extends State<WeatherEnvironmentBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  /// The gradient we are currently animating FROM.
  late EnvironmentGradient _fromGradient;

  /// The gradient we are currently animating TOWARD.
  late EnvironmentGradient _toGradient;

  Timer? _minuteTimer;

  @override
  void initState() {
    super.initState();

    // Resolve initial gradient immediately
    _fromGradient = _resolveGradient();
    _toGradient = _fromGradient;

    // Animation controller for crossfade on each update
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45), // smooth 45s crossfade between states
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Tick every 60 seconds to re-evaluate and trigger a new crossfade
    _minuteTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _updateGradient();
    });
  }

  EnvironmentGradient _resolveGradient() {
    final now = DateTime.now();
    final effectiveHour = widget.hourOverride;
    final condition = widget.condition ?? '';

    if (effectiveHour != null) {
      return EnvironmentTheme.resolveForHour(effectiveHour, condition: condition);
    }
    return EnvironmentTheme.resolve(now: now, condition: condition);
  }

  void _updateGradient() {
    final newGradient = _resolveGradient();
    setState(() {
      _fromGradient = EnvironmentGradient.lerp(_fromGradient, _toGradient, _animation.value);
      _toGradient = newGradient;
      _controller.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(WeatherEnvironmentBackground old) {
    super.didUpdateWidget(old);
    // React to condition or hourOverride changes from parent
    if (old.condition != widget.condition || old.hourOverride != widget.hourOverride) {
      _updateGradient();
    }
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final t = _animation.value;
        final current = EnvironmentGradient.lerp(_fromGradient, _toGradient, t);

        return Stack(
          fit: StackFit.expand,
          children: [
            // ── Layer 1: Atmospheric gradient + radial glow (isolated repaint)
            RepaintBoundary(
              child: CustomPaint(
                painter: _EnvironmentPainter(gradient: current),
                child: const SizedBox.expand(),
              ),
            ),

            // ── Layer 2: Adaptive readability vignette overlay
            RepaintBoundary(
              child: CustomPaint(
                painter: _VignettePainter(alphas: current.overlayAlphas),
                child: const SizedBox.expand(),
              ),
            ),

            // ── Layer 3: Content (navbar, cards, weather data)
            widget.child,
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Atmospheric Gradient Painter
//
// Renders two components:
//   1. Vertical linear gradient (5-stop, top → bottom)
//   2. Radial glow (sun/moon position) at very low opacity
// ─────────────────────────────────────────────────────────────────────────────
class _EnvironmentPainter extends CustomPainter {
  final EnvironmentGradient gradient;

  const _EnvironmentPainter({required this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Linear atmospheric gradient
    final linearPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradient.linearColors,
        stops: gradient.linearStops,
      ).createShader(rect);

    canvas.drawRect(rect, linearPaint);

    // 2. Radial glow (sun / moon / horizon warmth)
    if (gradient.hasGlow && gradient.glowOpacity > 0.002) {
      final glowCenter = Offset(
        size.width * gradient.glowX,
        size.height * gradient.glowY,
      );
      final glowRadius = math.max(size.width, size.height) * gradient.glowRadius;

      final glowPaint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            gradient.glowColor.withValues(alpha: gradient.glowOpacity),
            gradient.glowColor.withValues(alpha: gradient.glowOpacity * 0.5),
            gradient.glowColor.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius))
        ..blendMode = BlendMode.screen; // additive — enhances without washing out

      canvas.drawCircle(glowCenter, glowRadius, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_EnvironmentPainter old) {
    return old.gradient.linearColors != gradient.linearColors ||
        old.gradient.glowOpacity != gradient.glowOpacity;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Adaptive Readability Vignette Painter
//
// Renders a 5-stop vertical gradient of semi-transparent black ensuring
// white text is always readable regardless of background state.
// Alphas are interpolated per-state so the overlay is never heavier than needed.
// ─────────────────────────────────────────────────────────────────────────────
class _VignettePainter extends CustomPainter {
  final List<double> alphas; // [top, midUpper, midLower, bottom, base]

  const _VignettePainter({required this.alphas});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withValues(alpha: alphas[0]),
          Colors.black.withValues(alpha: alphas[1]),
          Colors.black.withValues(alpha: alphas[2]),
          Colors.black.withValues(alpha: alphas[3]),
          Colors.black.withValues(alpha: alphas.length > 4 ? alphas[4] : alphas[3]),
        ],
        stops: const [0.0, 0.25, 0.50, 0.75, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_VignettePainter old) => old.alphas != alphas;
}
