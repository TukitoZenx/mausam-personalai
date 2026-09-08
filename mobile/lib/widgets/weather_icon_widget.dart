import 'package:flutter/material.dart';
import 'weather/weather_glyphs.dart';

/// Modern high-definition weather icon widget with sleek ambient glow container.
class WeatherIconWidget extends StatelessWidget {
  final String? condition;
  final String? iconCode;
  final double size;

  const WeatherIconWidget({
    super.key,
    this.condition,
    this.iconCode,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    final cond = condition ?? '';
    final glyph = weatherGlyph(cond, icon: iconCode);
    final color = weatherGlyphColor(cond, icon: iconCode);

    return Container(
      width: size * 1.35,
      height: size * 1.35,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      child: Center(
        child: Icon(
          glyph,
          size: size,
          color: color,
        ),
      ),
    );
  }
}
