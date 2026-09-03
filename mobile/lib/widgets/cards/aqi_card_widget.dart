import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/home_card.dart';
import '../../theme/weather_palette.dart';

class AqiCardWidget extends StatelessWidget {
  final RankedHomeCard card;

  const AqiCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final aqiValue = card.data?['aqi_value'];
    final category = card.data?['category'] ?? 'Unknown';
    final aqiNum = (aqiValue is num) ? aqiValue.toDouble() : null;
    final isEstimated = card.data?['is_estimated'] == true;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: MausamPalette.cardSurfaceLight,
            shape: BoxShape.circle,
          ),
          child: Text(
            aqiNum == null ? '--' : '${aqiNum.round()}',
            style: GoogleFonts.inter(
              color: MausamPalette.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    card.title ?? 'Air Quality Index',
                    style: GoogleFonts.inter(
                      color: MausamPalette.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: MausamPalette.cardSurfaceLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: MausamPalette.cardBorder),
                    ),
                    child: Text(
                      isEstimated ? 'Estimated' : 'Live',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: MausamPalette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                card.subtitle ?? 'Category: $category',
                style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
