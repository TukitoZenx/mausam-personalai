import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/home_card.dart';
import '../../theme/weather_palette.dart';

class ActivityWindowCardWidget extends StatelessWidget {
  final RankedHomeCard card;

  const ActivityWindowCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: MausamPalette.cardSurfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.directions_run_rounded, color: MausamPalette.textPrimary, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.title ?? 'Optimal Activity Window',
                style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                card.subtitle ?? 'Based on live temperature and humidity',
                style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
