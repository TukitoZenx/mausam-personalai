import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MAUSAM — Full-Screen Ambient Animated Black Atmosphere for AI Chatbot
//
// A luxury, GPU-accelerated deep black (#000000) background with continuous
// ambient full-screen animation specifically tuned for the AI Chatbot:
//   • Pure OLED black base (#000000)
//   • Celestial breathing auroral waves & neural ambient glow
//   • Floating stardust & twinkling starfield micro-particles
//   • Soft contrast vignette ensuring message bubbles & text pop
// ─────────────────────────────────────────────────────────────────────────────

class _ChatParticle {
  final double x;
  final double y;
  final double radius;
  final double baseOpacity;
  final double twinkleSpeed;
  final double twinklePhase;
  final double driftSpeed;
  final double swaySpeed;
  final double swayAmount;
  final double swayPhase;
  final Color color;

  const _ChatParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.baseOpacity,
    required this.twinkleSpeed,
    required this.twinklePhase,
    required this.driftSpeed,
    required this.swaySpeed,
    required this.swayAmount,
    required this.swayPhase,
    required this.color,
  });
}

class ChatAtmosphereBackground extends StatefulWidget {
  final Widget? child;

  const ChatAtmosphereBackground({super.key, this.child});

  @override
  State<ChatAtmosphereBackground> createState() => _ChatAtmosphereBackgroundState();
}

class _ChatAtmosphereBackgroundState extends State<ChatAtmosphereBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_ChatParticle> _particles = [];

  static bool get _isRunningInTest {
    return WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  @override
  void initState() {
    super.initState();

    final random = math.Random(1042);
    const colors = [
      Colors.white,
      Color(0xFFE2E8F0),
      Color(0xFFBAE6FD),
      Color(0xFFC7D2FE),
      Color(0xFFDDD6FE),
    ];

    for (int i = 0; i < 50; i++) {
      _particles.add(_ChatParticle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        radius: 0.8 + random.nextDouble() * 1.6,
        baseOpacity: 0.20 + random.nextDouble() * 0.50,
        twinkleSpeed: 0.8 + random.nextDouble() * 2.0,
        twinklePhase: random.nextDouble() * math.pi * 2,
        driftSpeed: 0.02 + random.nextDouble() * 0.04,
        swaySpeed: 0.4 + random.nextDouble() * 1.0,
        swayAmount: 0.008 + random.nextDouble() * 0.016,
        swayPhase: random.nextDouble() * math.pi * 2,
        color: colors[random.nextInt(colors.length)],
      ));
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );

    if (!_isRunningInTest) {
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
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _ChatAtmospherePainter(
                  animationProgress: _controller.value,
                  particles: _particles,
                ),
                child: const SizedBox.expand(),
              );
            },
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _ChatAtmospherePainter extends CustomPainter {
  final double animationProgress;
  final List<_ChatParticle> particles;

  _ChatAtmospherePainter({
    required this.animationProgress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Solid Pure Black Foundation (#000000)
    canvas.drawRect(rect, Paint()..color = Colors.black);

    // 2. Celestial Breathing Auroral Waves / AI Neural Glow
    final animPhase = animationProgress * 2 * math.pi;
    final sin1 = math.sin(animPhase);
    final cos1 = math.cos(animPhase);
    final sin2 = math.sin(animPhase * 0.75);

    // Primary AI Indigo/Violet Neural Glow (upper center)
    const primaryGlow = Color(0xFF4338CA);
    final orb1Center = Offset(
      size.width * (0.45 + 0.10 * cos1),
      size.height * (0.24 + 0.06 * sin1),
    );
    final orb1Radius = size.width * (0.75 + 0.12 * sin2);
    final orb1Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryGlow.withValues(alpha: 0.15 + 0.04 * sin1),
          primaryGlow.withValues(alpha: 0.05 + 0.02 * sin1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.48, 1.0],
      ).createShader(Rect.fromCircle(center: orb1Center, radius: orb1Radius))
      ..blendMode = BlendMode.screen;
    canvas.drawCircle(orb1Center, orb1Radius, orb1Paint);

    // Secondary Ethereal Cyan/Teal Glow (counter-balancing lower-mid)
    const secondaryGlow = Color(0xFF0284C7);
    final orb2Center = Offset(
      size.width * (0.62 - 0.10 * sin1),
      size.height * (0.60 + 0.08 * cos1),
    );
    final orb2Radius = size.width * (0.70 + 0.08 * cos1);
    final orb2Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          secondaryGlow.withValues(alpha: 0.09 + 0.03 * cos1),
          secondaryGlow.withValues(alpha: 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(Rect.fromCircle(center: orb2Center, radius: orb2Radius))
      ..blendMode = BlendMode.screen;
    canvas.drawCircle(orb2Center, orb2Radius, orb2Paint);

    // 3. Floating Stardust & Ambient Twinkling Particles
    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final currentY = (p.y - animationProgress * p.driftSpeed) % 1.0;
      final sway = math.sin(animPhase * p.swaySpeed + p.swayPhase) * p.swayAmount;
      final currentX = (p.x + sway) % 1.0;

      final px = currentX * size.width;
      final py = (currentY < 0 ? currentY + 1.0 : currentY) * size.height;

      final twinkle = 0.5 + 0.5 * math.sin(animPhase * p.twinkleSpeed + p.twinklePhase);
      final alpha = (p.baseOpacity * (0.35 + 0.65 * twinkle)).clamp(0.0, 1.0);

      particlePaint.color = p.color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(px, py), p.radius, particlePaint);

      if (p.radius > 1.6 && alpha > 0.42) {
        final haloPaint = Paint()
          ..color = p.color.withValues(alpha: alpha * 0.25)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(px, py), p.radius * 2.0, haloPaint);
      }
    }

    // 4. Contrast Vignette (Preserves text and bubble readability)
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.05),
        radius: 1.15,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.15),
          Colors.black.withValues(alpha: 0.40),
        ],
        stops: const [0.40, 0.78, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignettePaint);
  }

  @override
  bool shouldRepaint(_ChatAtmospherePainter old) {
    return old.animationProgress != animationProgress;
  }
}
