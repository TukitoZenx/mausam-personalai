import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/home_card.dart';
import '../../theme/weather_palette.dart';

class HeatCardWidget extends StatelessWidget {
  final RankedHomeCard card;

  const HeatCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final heatIndex = card.data?['heat_index_c'] ?? 34.0;
    final level = card.data?['warning_level'] ?? 'Moderate';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: MausamPalette.cardSurfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.local_fire_department_rounded, color: MausamPalette.textPrimary, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.title ?? 'Heat Index Advisory',
                style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                card.subtitle ?? 'Feels like $heatIndex°C ($level)',
                style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
