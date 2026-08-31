import 'package:flutter/material.dart';

class MountainSilhouettePainter extends CustomPainter {
  const MountainSilhouettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final paintBack = Paint()
      ..color = const Color(0xFF162544).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    // Background mountain ridge
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.45);
    path.lineTo(size.width * 0.18, size.height * 0.35);
    path.lineTo(size.width * 0.35, size.height * 0.50);
    path.lineTo(size.width * 0.55, size.height * 0.28);
    path.lineTo(size.width * 0.75, size.height * 0.42);
    path.lineTo(size.width * 0.88, size.height * 0.30);
    path.lineTo(size.width, size.height * 0.48);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paintBack);

    // Foreground mountain ridge
    final pathFront = Path();
    final paintFront = Paint()
      ..color = const Color(0xFF0F1A30).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    pathFront.moveTo(0, size.height);
    pathFront.lineTo(0, size.height * 0.65);
    pathFront.lineTo(size.width * 0.25, size.height * 0.48);
    pathFront.lineTo(size.width * 0.45, size.height * 0.62);
    pathFront.lineTo(size.width * 0.68, size.height * 0.40);
    pathFront.lineTo(size.width * 0.85, size.height * 0.55);
    pathFront.lineTo(size.width, size.height * 0.42);
    pathFront.lineTo(size.width, size.height);
    pathFront.close();
    canvas.drawPath(pathFront, paintFront);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
