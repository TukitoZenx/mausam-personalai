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
    with TickerProviderStateMixin {
  late AnimationController _crossfadeController;
  late Animation<double> _crossfadeAnimation;

  late AnimationController _ambientController;
  late Animation<double> _ambientAnimation;

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

    // Crossfade controller for smooth 1.2s transitions when changing wallpaper/time
    _crossfadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _crossfadeAnimation = CurvedAnimation(parent: _crossfadeController, curve: Curves.easeInOut);

    // Continuous ambient breathing controller for live dynamic wallpaper
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );
    _ambientAnimation = CurvedAnimation(parent: _ambientController, curve: Curves.easeInOut);

    final isTestMode = WidgetsBinding.instance.runtimeType.toString().contains('TestWidgetsFlutterBinding');
    if (!isTestMode && widget.wallpaperTheme.isDynamic) {
      _ambientController.repeat(reverse: true);
    }

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
    if (newGradient.visuallyEquals(_toGradient) &&
        (_crossfadeController.status == AnimationStatus.completed || !_crossfadeController.isAnimating)) {
      _toGradient = newGradient;
      return;
    }
    setState(() {
      _fromGradient = EnvironmentGradient.lerp(_fromGradient, _toGradient, _crossfadeAnimation.value);
      _toGradient = newGradient;
      _crossfadeController.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(WeatherEnvironmentBackground old) {
    super.didUpdateWidget(old);
    if (old.wallpaperTheme != widget.wallpaperTheme || old.hourOverride != widget.hourOverride) {
      final isTestMode = WidgetsBinding.instance.runtimeType.toString().contains('TestWidgetsFlutterBinding');
      if (!isTestMode) {
        if (widget.wallpaperTheme.isDynamic && !_ambientController.isAnimating) {
          _ambientController.repeat(reverse: true);
        } else if (!widget.wallpaperTheme.isDynamic && _ambientController.isAnimating) {
          _ambientController.stop();
        }
      }
      _updateGradient();
    }
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    _crossfadeController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_crossfadeAnimation, _ambientAnimation]),
      builder: (context, _) {
        final t = _crossfadeAnimation.value;
        final current = EnvironmentGradient.lerp(_fromGradient, _toGradient, t);

        return Stack(
          fit: StackFit.expand,
          children: [
            // ── Layer 1: Atmospheric gradient + radial celestial glow (isolated repaint)
            RepaintBoundary(
              child: CustomPaint(
                painter: _EnvironmentPainter(
                  gradient: current,
                  isDynamic: widget.wallpaperTheme.isDynamic,
                  ambientProgress: _ambientAnimation.value,
                ),
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
  final bool isDynamic;
  final double ambientProgress;

  const _EnvironmentPainter({
    required this.gradient,
    this.isDynamic = true,
    this.ambientProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient.linearColors,
          stops: gradient.linearStops,
        ).createShader(rect),
    );

    if (!gradient.hasGlow || gradient.glowOpacity <= 0.002) return;

    final body = math.min(size.width, size.height);
    final center = Offset(size.width * gradient.glowX, size.height * gradient.glowY);

    // Horizon wash — warmth pooled near the sun, fading into the ground.
    final horizonY = size.height * (gradient.glowY + 0.22).clamp(0.35, 0.72);
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            gradient.glowColor.withValues(alpha: gradient.glowOpacity * 0.18),
            Colors.black.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY))
        ..blendMode = BlendMode.softLight,
    );

    // Wide atmospheric bloom.
    final bloomR = math.max(size.width, size.height) * gradient.glowRadius;
    canvas.drawCircle(
      center,
      bloomR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            gradient.glowColor.withValues(alpha: gradient.glowOpacity * 0.55),
            gradient.glowColor.withValues(alpha: gradient.glowOpacity * 0.18),
            gradient.glowColor.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.38, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: bloomR))
        ..blendMode = BlendMode.screen,
    );

    // Tight celestial disc (sun / moon).
    final discR = body * gradient.discRadius;
    canvas.drawCircle(
      center,
      discR * 2.4,
      Paint()
        ..shader = RadialGradient(
          colors: [
            gradient.glowColor.withValues(alpha: 0.55),
            gradient.glowColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: discR * 2.4))
        ..blendMode = BlendMode.plus,
    );
    canvas.drawCircle(
      center,
      discR,
      Paint()..color = gradient.glowColor.withValues(alpha: gradient.starfield ? 0.72 : 0.88),
    );
    canvas.drawCircle(
      center,
      discR * 0.42,
      Paint()..color = Colors.white.withValues(alpha: gradient.starfield ? 0.55 : 0.92),
    );

    if (!isDynamic) return;

    if (gradient.starfield) {
      final starPaint = Paint()..style = PaintingStyle.fill;
      for (int i = 0; i < 42; i++) {
        final sx = ((i * 47 + 13) % 100) / 100.0 * size.width;
        final sy = ((i * 73 + 29) % 62) / 100.0 * size.height;
        final phase = ambientProgress * 2 * math.pi + i * 0.37;
        final twinkle = 0.12 + 0.28 * (0.5 + 0.5 * math.sin(phase));
        starPaint.color = Colors.white.withValues(alpha: twinkle);
        canvas.drawCircle(Offset(sx, sy), i % 7 == 0 ? 1.15 : 0.55, starPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_EnvironmentPainter old) {
    return old.gradient.linearColors != gradient.linearColors ||
        old.gradient.glowOpacity != gradient.glowOpacity ||
        old.gradient.glowX != gradient.glowX ||
        old.gradient.starfield != gradient.starfield ||
        (isDynamic && (old.ambientProgress - ambientProgress).abs() > 0.008);
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
