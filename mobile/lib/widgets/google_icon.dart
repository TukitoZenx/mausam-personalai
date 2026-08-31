import 'package:flutter/material.dart';

class GoogleIconWidget extends StatelessWidget {
  const GoogleIconWidget({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleIconPainter(),
      ),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.22;

    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Top Red arc
    canvas.drawArc(rect, -0.6, 2.1, false, redPaint);
    // Left Yellow arc
    canvas.drawArc(rect, 1.5, 1.4, false, yellowPaint);
    // Bottom Green arc
    canvas.drawArc(rect, 2.9, 1.3, false, greenPaint);
    // Right Blue arc & bar
    canvas.drawArc(rect, 4.2, 0.9, false, bluePaint);

    final blueFillPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final barRect = Rect.fromLTWH(
      center.dx,
      center.dy - strokeWidth / 2,
      radius,
      strokeWidth,
    );
    canvas.drawRect(barRect, blueFillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
