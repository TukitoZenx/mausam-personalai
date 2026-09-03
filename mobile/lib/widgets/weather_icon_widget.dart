import 'package:flutter/material.dart';
import '../theme/weather_palette.dart';

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
    final cond = (condition ?? '').toLowerCase();
    final code = (iconCode ?? '').toLowerCase();

    IconData iconData = Icons.wb_sunny_rounded;
    Color iconColor = MausamPalette.accentOrange;

    if (cond.contains('thunder') || cond.contains('storm') || code.contains('11')) {
      iconData = Icons.thunderstorm_rounded;
      iconColor = MausamPalette.accentMagenta;
    } else if (cond.contains('rain') || cond.contains('drizzle') || code.contains('09') || code.contains('10')) {
      iconData = Icons.water_drop_rounded;
      iconColor = MausamPalette.accentBlue;
    } else if (cond.contains('snow') || cond.contains('ice') || cond.contains('sleet') || code.contains('13')) {
      iconData = Icons.ac_unit_rounded;
      iconColor = MausamPalette.accentCyan;
    } else if (cond.contains('cloud') || code.contains('02') || code.contains('03') || code.contains('04')) {
      if (cond.contains('few') || cond.contains('scattered') || code == '02d') {
        iconData = Icons.wb_cloudy_rounded;
        iconColor = MausamPalette.accentBlue;
      } else {
        iconData = Icons.cloud_rounded;
        iconColor = MausamPalette.textSecondary;
      }
    } else if (cond.contains('mist') || cond.contains('fog') || cond.contains('haze') || code.contains('50')) {
      iconData = Icons.dehaze_rounded;
      iconColor = MausamPalette.textSecondary;
    } else if (code.endsWith('n') || cond.contains('night')) {
      iconData = Icons.nights_stay_rounded;
      iconColor = MausamPalette.accentBlue;
    }

    return Container(
      width: size * 1.3,
      height: size * 1.3,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        size: size,
        color: iconColor,
      ),
    );
  }
}
