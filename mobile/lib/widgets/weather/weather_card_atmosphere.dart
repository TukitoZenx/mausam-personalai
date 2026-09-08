import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

enum WeatherAtmosphereType {
  rain,
  sun,
  thunder,
  clouds,
  snow,
}

WeatherAtmosphereType resolveAtmosphereType(String condition, {String? icon}) {
  final c = condition.toLowerCase();
  if (c.contains('thunder') || c.contains('storm')) return WeatherAtmosphereType.thunder;
  if (c.contains('rain') || c.contains('drizzle') || c.contains('shower')) return WeatherAtmosphereType.rain;
  if (c.contains('snow') || c.contains('ice') || c.contains('sleet')) return WeatherAtmosphereType.snow;
  if (c.contains('cloud') || c.contains('overcast') || c.contains('fog') || c.contains('mist') || c.contains('haze')) {
    return WeatherAtmosphereType.clouds;
  }
  return WeatherAtmosphereType.sun;
}

/// Dynamic, GPU-accelerated weather animation background for Hero cards.
/// Supports animated Rain, rotating Sun with playful Solar Yellow theme,
/// Thunderstorm flashes, floating Clouds, and drifting Snow.
class WeatherCardAtmosphere extends StatefulWidget {
  final WeatherAtmosphereType type;
  final bool isYellowTheme;
  final double surfaceOpacity;
  final Widget child;

  const WeatherCardAtmosphere({
    super.key,
    required this.type,
    this.isYellowTheme = false,
    this.surfaceOpacity = 0.85,
    required this.child,
  });

  @override
  State<WeatherCardAtmosphere> createState() => _WeatherCardAtmosphereState();
}

class _WeatherCardAtmosphereState extends State<WeatherCardAtmosphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final math.Random _random = math.Random(42);

  final List<_RainDrop> _rainDrops = [];
  final List<_SnowFlake> _snowFlakes = [];
  final List<_CloudBlob> _cloudBlobs = [];

  @override
  void initState() {
    super.initState();

    // 1. Pre-generate rain drops
    for (int i = 0; i < 36; i++) {
      _rainDrops.add(_RainDrop(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.4 + _random.nextDouble() * 0.5,
        length: 12.0 + _random.nextDouble() * 12.0,
        opacity: 0.20 + _random.nextDouble() * 0.35,
      ));
    }

    // 3. Pre-generate snowflakes
    for (int i = 0; i < 24; i++) {
      _snowFlakes.add(_SnowFlake(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        radius: 1.8 + _random.nextDouble() * 2.2,
        speed: 0.2 + _random.nextDouble() * 0.3,
        drift: 0.05 + _random.nextDouble() * 0.1,
      ));
    }

    // 4. Pre-generate cloud blobs
    for (int i = 0; i < 4; i++) {
      _cloudBlobs.add(_CloudBlob(
        initialX: -0.2 + i * 0.35,
        y: 0.15 + (_random.nextDouble() * 0.3),
        width: 110.0 + _random.nextDouble() * 60.0,
        height: 38.0 + _random.nextDouble() * 22.0,
        speed: 0.04 + _random.nextDouble() * 0.03,
      ));
    }

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (!isTest) {
      _controller.repeat();
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isYellow = widget.isYellowTheme || widget.type == WeatherAtmosphereType.sun;

    // Palette adaptation
    final Color borderColor;
    final List<BoxShadow> boxShadows;
    final LinearGradient bgGradient;

    if (isYellow) {
      // Playful solar golden yellow theme
      borderColor = const Color(0x88F59E0B);
      boxShadows = const [
        BoxShadow(
          color: Color(0x3DF59E0B),
          blurRadius: 22,
          spreadRadius: 1,
          offset: Offset(0, 4),
        ),
      ];
      bgGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF221A06),
          Color(0xFF161104),
          Color(0xFF0D0A03),
        ],
      );
    } else if (widget.type == WeatherAtmosphereType.rain) {
      // Rain atmosphere
      borderColor = const Color(0x4460A5FA);
      boxShadows = const [
        BoxShadow(
          color: Color(0x223B82F6),
          blurRadius: 18,
          offset: Offset(0, 4),
        ),
      ];
      bgGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF070E1A),
          Color(0xFF0C1527),
          Color(0xFF060A13),
        ],
      );
    } else if (widget.type == WeatherAtmosphereType.thunder) {
      // Thunderstorm
      borderColor = const Color(0x66FACC15);
      boxShadows = const [
        BoxShadow(
          color: Color(0x33FACC15),
          blurRadius: 20,
          offset: Offset(0, 4),
        ),
      ];
      bgGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF130D21),
          Color(0xFF1C1330),
          Color(0xFF0D0717),
        ],
      );
    } else if (widget.type == WeatherAtmosphereType.snow) {
      // Snow
      borderColor = const Color(0x5593C5FD);
      boxShadows = const [
        BoxShadow(
          color: Color(0x2293C5FD),
          blurRadius: 18,
          offset: Offset(0, 4),
        ),
      ];
      bgGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF07101B),
          Color(0xFF0C1929),
          Color(0xFF060B12),
        ],
      );
    } else {
      // Clouds / Default obsidian
      borderColor = const Color(0x33D4D4D8);
      boxShadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
      bgGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF111215),
          Color(0xFF17181C),
          Color(0xFF0E0E11),
        ],
      );
    }

    final effectiveGradient = LinearGradient(
      begin: bgGradient.begin,
      end: bgGradient.end,
      stops: bgGradient.stops,
      colors: bgGradient.colors
          .map((c) => c.withValues(alpha: (c.a * widget.surfaceOpacity).clamp(0.0, 1.0)))
          .toList(),
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: boxShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: effectiveGradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.surfaceOpacity < 0.95
                    ? (isYellow ? const Color(0x66F59E0B) : Colors.white.withValues(alpha: 0.12))
                    : borderColor,
                width: 1.2,
              ),
            ),
            child: Stack(
              children: [
                // Ambient Canvas Layer (Rain, Sun rays, Storm flashes, Clouds)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _WeatherCardPainter(
                            type: widget.type,
                            isYellow: isYellow,
                            progress: _controller.value,
                            rainDrops: _rainDrops,
                            snowFlakes: _snowFlakes,
                            cloudBlobs: _cloudBlobs,
                          ),
                          size: Size.infinite,
                        );
                      },
                    ),
                  ),
                ),

                // Card Foreground Content
                widget.child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painter for Dynamic Weather Effects
// ─────────────────────────────────────────────────────────────────────────────
class _WeatherCardPainter extends CustomPainter {
  final WeatherAtmosphereType type;
  final bool isYellow;
  final double progress;
  final List<_RainDrop> rainDrops;
  final List<_SnowFlake> snowFlakes;
  final List<_CloudBlob> cloudBlobs;

  _WeatherCardPainter({
    required this.type,
    required this.isYellow,
    required this.progress,
    required this.rainDrops,
    required this.snowFlakes,
    required this.cloudBlobs,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isYellow || type == WeatherAtmosphereType.sun) {
      _paintSunAtmosphere(canvas, size);
    } else if (type == WeatherAtmosphereType.rain) {
      _paintRainAtmosphere(canvas, size, isStorm: false);
    } else if (type == WeatherAtmosphereType.thunder) {
      _paintRainAtmosphere(canvas, size, isStorm: true);
    } else if (type == WeatherAtmosphereType.snow) {
      _paintSnowAtmosphere(canvas, size);
    } else if (type == WeatherAtmosphereType.clouds) {
      _paintCloudsAtmosphere(canvas, size);
    }
  }

  // 1. SUN & PLAYFUL YELLOW ATMOSPHERE
  void _paintSunAtmosphere(Canvas canvas, Size size) {
    // Elegant solar illumination aura aligned seamlessly behind the top-right weather icon
    final iconCenter = Offset(size.width - 45, 68);
    final pulse = 0.92 + 0.08 * math.sin(progress * math.pi * 2);

    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF59E0B).withValues(alpha: 0.25 * pulse),
          const Color(0xFFFBBF24).withValues(alpha: 0.10 * pulse),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: iconCenter, radius: 120));

    canvas.drawCircle(iconCenter, 120, auraPaint);
  }

  // 2. RAIN ATMOSPHERE
  void _paintRainAtmosphere(Canvas canvas, Size size, {required bool isStorm}) {
    // Storm subtle flash pulse
    if (isStorm) {
      final flashPhase = (progress * 8) % 1.0;
      if (flashPhase > 0.94) {
        final flashPaint = Paint()
          ..color = const Color(0xFFFACC15).withValues(alpha: 0.12);
        canvas.drawRect(Offset.zero & size, flashPaint);
      }
    }

    final dropPaint = Paint()
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round;

    for (final drop in rainDrops) {
      final yProgress = (drop.y + progress * (drop.speed * 1.5)) % 1.0;
      final startX = (drop.x * size.width) - (yProgress * 18);
      final startY = yProgress * size.height;

      dropPaint.color = const Color(0xFF93C5FD).withValues(alpha: drop.opacity);

      // Angled rain streak
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX - 2.8, startY + drop.length),
        dropPaint,
      );

      // Soft splash ripple near bottom
      if (startY > size.height - 18) {
        final rippleOpacity = ((size.height - startY) / 18.0).clamp(0.0, 1.0);
        final ripplePaint = Paint()
          ..color = const Color(0xFF60A5FA).withValues(alpha: rippleOpacity * 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(startX - 2.8, size.height - 4),
            width: 8.0 * (1.0 - rippleOpacity),
            height: 2.4 * (1.0 - rippleOpacity),
          ),
          ripplePaint,
        );
      }
    }
  }

  // 3. SNOW ATMOSPHERE
  void _paintSnowAtmosphere(Canvas canvas, Size size) {
    final flakePaint = Paint()..style = PaintingStyle.fill;
    for (final flake in snowFlakes) {
      final yProgress = (flake.y + progress * (flake.speed * 0.8)) % 1.0;
      final currentY = yProgress * size.height;
      final currentX = (flake.x * size.width) + math.sin(progress * math.pi * 3 + flake.drift * 20) * 14;

      flakePaint.color = Colors.white.withValues(alpha: 0.35 + 0.25 * math.sin(currentY));
      canvas.drawCircle(Offset(currentX, currentY), flake.radius, flakePaint);
    }
  }

  // 4. CLOUDS ATMOSPHERE
  void _paintCloudsAtmosphere(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFE4E4E7).withValues(alpha: 0.05);

    for (final cloud in cloudBlobs) {
      final xNorm = (cloud.initialX + progress * cloud.speed) % 1.4 - 0.2;
      final currentX = xNorm * size.width;
      final currentY = cloud.y * size.height;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(currentX, currentY),
          width: cloud.width,
          height: cloud.height,
        ),
        cloudPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherCardPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.type != type ||
        oldDelegate.isYellow != isYellow;
  }
}

// Particle Helper Data Structures
class _RainDrop {
  final double x;
  final double y;
  final double speed;
  final double length;
  final double opacity;

  const _RainDrop({
    required this.x,
    required this.y,
    required this.speed,
    required this.length,
    required this.opacity,
  });
}

class _SnowFlake {
  final double x;
  final double y;
  final double radius;
  final double speed;
  final double drift;

  const _SnowFlake({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.drift,
  });
}

class _CloudBlob {
  final double initialX;
  final double y;
  final double width;
  final double height;
  final double speed;

  const _CloudBlob({
    required this.initialX,
    required this.y,
    required this.width,
    required this.height,
    required this.speed,
  });
}
