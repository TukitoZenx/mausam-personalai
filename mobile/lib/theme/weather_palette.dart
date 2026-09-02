import 'package:flutter/material.dart';

class WeatherPalette {
  static const Color navy = Color(0xFF0F2A4A);
  static const Color navyDeep = Color(0xFF071018);
  static const Color teal = Color(0xFF0E7C86);
  static const Color sky = Color(0xFF2E86AB);
  static const Color amber = Color(0xFFC9862B);
  static const Color background = Color(0xFF070B16);
  static const Color card = Color(0xFF0F1A2E);
  static const Color cardBorder = Color(0xFF1E2F4F);

  static LinearGradient heroGradient({required int hour, required String condition}) {
    final cond = condition.toLowerCase();
    final rainy = cond.contains('rain') ||
        cond.contains('drizzle') ||
        cond.contains('thunder') ||
        cond.contains('storm');
    final overcast = cond.contains('cloud') || cond.contains('mist') || cond.contains('fog');

    late List<Color> stops;
    if (hour >= 5 && hour < 8) {
      stops = const [Color(0xFF2E86AB), Color(0xFFC9862B), Color(0xFF0F2A4A)];
    } else if (hour >= 8 && hour < 17) {
      stops = const [Color(0xFF2E86AB), Color(0xFF0E7C86), Color(0xFF0F2A4A)];
    } else if (hour >= 17 && hour < 20) {
      stops = const [Color(0xFF0F2A4A), Color(0xFFC9862B), Color(0xFF071018)];
    } else {
      stops = const [Color(0xFF0F2A4A), Color(0xFF071018), Color(0xFF020617)];
    }

    if (rainy) {
      stops = stops.map((c) => Color.lerp(c, const Color(0xFF0A1220), 0.35)!).toList();
    } else if (overcast) {
      stops = stops.map((c) => Color.lerp(c, const Color(0xFF1E2F4F), 0.25)!).toList();
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: stops,
    );
  }
}
