import 'package:flutter/material.dart';

/// Returns modern, high-definition Material weather glyphs matching Mausam design.
IconData weatherGlyph(String condition, {String? icon}) {
  final c = condition.toLowerCase();
  final night = (icon ?? '').endsWith('n');
  if (c.contains('thunder')) return Icons.thunderstorm_rounded;
  if (c.contains('drizzle')) return Icons.water_drop_outlined;
  if (c.contains('rain')) return Icons.water_drop_rounded;
  if (c.contains('snow')) return Icons.ac_unit_rounded;
  if (c.contains('mist') || c.contains('fog') || c.contains('haze')) {
    return Icons.air_rounded;
  }
  if (c.contains('cloud')) {
    if (c.contains('few') || c.contains('scattered') || c.contains('partly')) {
      return night ? Icons.nights_stay_outlined : Icons.cloud_queue_rounded;
    }
    return Icons.cloud_rounded;
  }
  if (c.contains('clear') || c.contains('sun')) {
    return night ? Icons.nights_stay_rounded : Icons.light_mode_rounded;
  }
  return night ? Icons.nights_stay_rounded : Icons.cloud_queue_rounded;
}

Color weatherGlyphColor(String condition, {String? icon}) {
  final c = condition.toLowerCase();
  final night = (icon ?? '').endsWith('n');
  if (c.contains('thunder')) return const Color(0xFFFACC15); // Amber Electric
  if (c.contains('rain') || c.contains('drizzle') || c.contains('shower')) {
    return const Color(0xFF38BDF8); // Electric Sky Cyan
  }
  if (c.contains('snow')) return const Color(0xFFBAE6FD); // Ice Blue
  if (c.contains('mist') || c.contains('fog') || c.contains('haze')) {
    return const Color(0xFF94A3B8); // Slate Mist
  }
  if (c.contains('cloud')) return const Color(0xFFCBD5E1); // Cool Slate Gray
  if (c.contains('clear') || c.contains('sun')) {
    return night ? const Color(0xFFA78BFA) : const Color(0xFFF59E0B); // Soft Lavender Night or Solar Gold Sun
  }
  return night ? const Color(0xFFA78BFA) : const Color(0xFFCBD5E1);
}

Color aqiIconColor(int aqiValue) {
  if (aqiValue <= 50) return const Color(0xFF34D399); // Good emerald
  if (aqiValue <= 100) return const Color(0xFFFBBF24); // Moderate warm yellow
  if (aqiValue <= 150) return const Color(0xFFFB923C); // Unhealthy sensitive orange
  return const Color(0xFFEF4444); // Severe red
}

Color uvIconColor(double uv) {
  if (uv >= 8) return const Color(0xFFEF4444);
  if (uv >= 6) return const Color(0xFFFB923C);
  if (uv >= 3) return const Color(0xFFFBBF24);
  return const Color(0xFF34D399);
}

IconData moonVectorIcon(double? phase) {
  if (phase == null) return Icons.nightlight_round;
  if (phase < 0.05 || phase >= 0.95) return Icons.circle_outlined;
  if (phase < 0.45) return Icons.brightness_3_rounded;
  if (phase <= 0.55) return Icons.circle;
  return Icons.brightness_2_rounded;
}

String aqiMoodGlyph(String category) {
  switch (category.toLowerCase()) {
    case 'good':
      return '🙂';
    case 'fair':
      return '😐';
    case 'moderate':
      return '😷';
    case 'poor':
      return '😨';
    case 'very poor':
      return '☠️';
    default:
      return '•';
  }
}

String moonGlyph(double? phase) {
  if (phase == null) return '🌙';
  if (phase < 0.03 || phase >= 0.97) return '🌑';
  if (phase < 0.22) return '🌒';
  if (phase < 0.28) return '🌓';
  if (phase < 0.47) return '🌔';
  if (phase < 0.53) return '🌕';
  if (phase < 0.72) return '🌖';
  if (phase < 0.78) return '🌗';
  return '🌘';
}
