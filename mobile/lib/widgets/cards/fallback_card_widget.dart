import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/home_card.dart';
import '../../theme/weather_palette.dart';

class FallbackCardWidget extends StatelessWidget {
  final RankedHomeCard card;

  const FallbackCardWidget({super.key, required this.card});

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
          child: const Icon(Icons.info_outline_rounded, color: MausamPalette.textSecondary, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.title ?? card.cardType.toUpperCase(),
                style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                card.subtitle ?? 'Personalized weather insight',
                style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
