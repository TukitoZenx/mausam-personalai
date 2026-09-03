import 'package:flutter/material.dart';

import '../../theme/weather_palette.dart';

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

Color weatherGlyphColor(String condition) {
  return MausamPalette.textPrimary;
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
