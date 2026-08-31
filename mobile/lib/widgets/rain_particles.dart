import 'dart:math';
import 'package:flutter/material.dart';

class RainParticlesWidget extends StatefulWidget {
  const RainParticlesWidget({
    super.key,
    this.particleCount = 30,
    this.opacity = 0.08,
  });

  final int particleCount;
  final double opacity;

  @override
  State<RainParticlesWidget> createState() => _RainParticlesWidgetState();
}

class _RainParticlesWidgetState extends State<RainParticlesWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_RainDrop> _drops = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.particleCount; i++) {
      _drops.add(_RainDrop(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.3 + _random.nextDouble() * 0.5,
        length: 10 + _random.nextDouble() * 14,
      ));
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _RainPainter(
            drops: _drops,
            progress: _controller.value,
            opacity: widget.opacity,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _RainDrop {
  _RainDrop({
    required this.x,
    required this.y,
    required this.speed,
    required this.length,
  });

  final double x;
  final double y;
  final double speed;
  final double length;
}

class _RainPainter extends CustomPainter {
  _RainPainter({
    required this.drops,
    required this.progress,
    required this.opacity,
  });

  final List<_RainDrop> drops;
  final double progress;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3FA9F5).withValues(alpha: opacity)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (final drop in drops) {
      final currentY = (drop.y + progress * drop.speed) % 1.0;
      final startX = drop.x * size.width;
      final startY = currentY * size.height;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX - 1.5, startY + drop.length),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) => true;
}
