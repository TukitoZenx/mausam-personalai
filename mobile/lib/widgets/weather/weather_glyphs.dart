import 'package:flutter/material.dart';

IconData weatherGlyph(String condition, {String? icon}) {
  final c = condition.toLowerCase();
  final night = (icon ?? '').endsWith('n');
  if (c.contains('thunder')) return Icons.thunderstorm_rounded;
  if (c.contains('drizzle')) return Icons.grain_rounded;
  if (c.contains('rain')) return Icons.umbrella_rounded;
  if (c.contains('snow')) return Icons.ac_unit_rounded;
  if (c.contains('mist') || c.contains('fog') || c.contains('haze')) {
    return Icons.blur_on_rounded;
  }
  if (c.contains('cloud')) return Icons.cloud_rounded;
  if (c.contains('clear') || c.contains('sun')) {
    return night ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded;
  }
  return night ? Icons.nights_stay_rounded : Icons.wb_cloudy_rounded;
}

Color weatherGlyphColor(String condition, {String? icon}) {
  final c = condition.toLowerCase();
  final night = (icon ?? '').endsWith('n');
  if (c.contains('thunder')) return const Color(0xFFFACC15); // amber yellow
  if (c.contains('rain') || c.contains('drizzle') || c.contains('shower')) {
    return const Color(0xFF60A5FA); // rain blue
  }
  if (c.contains('snow')) return const Color(0xFF93C5FD); // soft cool ice
  if (c.contains('mist') || c.contains('fog') || c.contains('haze')) {
    return const Color(0xFFA1A1AA); // subtle mist gray
  }
  if (c.contains('cloud')) return const Color(0xFFD4D4D8); // light gray
  if (c.contains('clear') || c.contains('sun')) {
    return night ? const Color(0xFF93C5FD) : const Color(0xFFFBBF24); // moon cool tone or sun warm yellow
  }
  return night ? const Color(0xFF93C5FD) : const Color(0xFFD4D4D8);
}

Color aqiIconColor(int aqiValue) {
  if (aqiValue <= 50) return const Color(0xFF34D399); // good emerald
  if (aqiValue <= 100) return const Color(0xFFFBBF24); // moderate warm yellow
  if (aqiValue <= 150) return const Color(0xFFFB923C); // unhealthy sensitive orange
  return const Color(0xFFEF4444); // severe red
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
