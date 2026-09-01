import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/home_card.dart';

class UvCardWidget extends StatelessWidget {
  final RankedHomeCard card;

  const UvCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final uvIndex = card.data?['uv_index'] ?? 4.2;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.wb_sunny_outlined,
            color: Color(0xFF8B5CF6),
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.title ?? 'UV Protection Advice',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                card.subtitle ?? 'Peak UV Index: $uvIndex',
                style: GoogleFonts.inter(
                  color: const Color(0xFFA78BFA),
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
