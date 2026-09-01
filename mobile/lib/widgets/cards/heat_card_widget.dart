import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/home_card.dart';

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
            color: const Color(0xFFF97316).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.local_fire_department_rounded,
            color: Color(0xFFF97316),
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.title ?? 'Heat Index Advisory',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                card.subtitle ?? 'Feels like $heatIndex°C ($level)',
                style: GoogleFonts.inter(
                  color: const Color(0xFFF97316),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
