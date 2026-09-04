import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/environment_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MAUSAM — Weather Environment Background
//
// A premium, cinematic, time-aware & theme-adaptive background for the Home screen.
//
// Features:
//   • Mausam Dynamic (time of day) + fixed wallpapers
//   • Real local-time tracking for Dynamic (refreshes every 60s)
//   • Continuous fractional interpolation — no abrupt hourly jumps
//   • Smooth crossfade when the user changes wallpaper
//   • Fixed wallpapers ignore time and weather
// ─────────────────────────────────────────────────────────────────────────────

class WeatherEnvironmentBackground extends StatefulWidget {
  final WallpaperTheme wallpaperTheme;
  final String? condition;
  final int? hourOverride;
  final Widget child;

  const WeatherEnvironmentBackground({
    super.key,
    this.wallpaperTheme = WallpaperTheme.dynamic,
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
      duration: const Duration(milliseconds: 1200), // smooth 1.2s crossfade on theme toggle
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Dynamic wallpapers re-evaluate local time every minute.
    _minuteTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (widget.wallpaperTheme.isDynamic) {
        _updateGradient();
      }
    });
  }

  EnvironmentGradient _resolveGradient() {
    final now = DateTime.now();
    final theme = widget.wallpaperTheme;
    final effectiveHour = widget.hourOverride;

    if (effectiveHour != null) {
      return EnvironmentTheme.resolveForHour(effectiveHour, theme: theme);
    }
    return EnvironmentTheme.resolve(now: now, theme: theme);
  }

  void _updateGradient() {
    final newGradient = _resolveGradient();
    if (newGradient.visuallyEquals(_toGradient) && (_controller.status == AnimationStatus.completed || !_controller.isAnimating)) {
      _toGradient = newGradient;
      return;
    }
    setState(() {
      _fromGradient = EnvironmentGradient.lerp(_fromGradient, _toGradient, _animation.value);
      _toGradient = newGradient;
      _controller.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(WeatherEnvironmentBackground old) {
    super.didUpdateWidget(old);
    if (old.wallpaperTheme != widget.wallpaperTheme || old.hourOverride != widget.hourOverride) {
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
            // ── Layer 1: Atmospheric gradient + radial celestial glow (isolated repaint)
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
// ─────────────────────────────────────────────────────────────────────────────
class _EnvironmentPainter extends CustomPainter {
  final EnvironmentGradient gradient;

  const _EnvironmentPainter({required this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    Color grayOf(Color c) {
      final l = (0.299 * c.r + 0.587 * c.g + 0.114 * c.b);
      return Color.from(alpha: c.a, red: l, green: l, blue: l);
    }

    // 1. Linear atmospheric gradient (forced monochrome)
    final linearPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradient.linearColors.map(grayOf).toList(),
        stops: gradient.linearStops,
      ).createShader(rect);

    canvas.drawRect(rect, linearPaint);

    // 2. Celestial radial glow (sun / moon / horizon warmth)
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
            grayOf(gradient.glowColor).withValues(alpha: gradient.glowOpacity * 0.55),
            grayOf(gradient.glowColor).withValues(alpha: gradient.glowOpacity * 0.25),
            grayOf(gradient.glowColor).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius))
        ..blendMode = BlendMode.screen;

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
// ─────────────────────────────────────────────────────────────────────────────
class _VignettePainter extends CustomPainter {
  final List<double> alphas;

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
