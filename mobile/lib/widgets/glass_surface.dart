import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/weather_palette.dart';

/// Frosted glass panel. Wallpaper shows through; type stays readable.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final double blur;

  const GlassSurface({
    super.key,
    required this.child,
    required this.opacity,
    this.radius = 16,
    this.padding,
    this.blur = 22,
  });

  @override
  Widget build(BuildContext context) {
    final fill = opacity.clamp(0.20, 0.98);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: MausamPalette.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: const Color(0xFF12141A).withValues(alpha: fill),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
