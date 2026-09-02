import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/home_card.dart';

class WeatherCardWidget extends StatelessWidget {
  final RankedHomeCard card;

  const WeatherCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final temp = card.data?['temperature_celsius'] ?? card.data?['temp'];
    final condition = card.data?['condition'] ?? card.subtitle ?? 'Current conditions';
    final humidity = card.data?['humidity_percent'] ?? card.data?['humidity'];
    final windSpeed = card.data?['wind_speed_kmh'] ?? card.data?['wind_speed'];
    final tempLabel = temp == null ? '--' : '$temp';
    final humidityLabel = humidity == null ? '--' : '$humidity';
    final windLabel = windSpeed == null ? '--' : '$windSpeed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              card.title ?? 'Current Weather',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 30),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$tempLabel°C',
          style: GoogleFonts.inter(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          '$condition',
          style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Humidity: $humidityLabel%',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
            ),
            Text(
              'Wind: $windLabel km/h',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}
