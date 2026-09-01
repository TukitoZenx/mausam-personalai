import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/home_card.dart';

class AqiCardWidget extends StatelessWidget {
  final RankedHomeCard card;

  const AqiCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final aqiValue = card.data?['aqi_value'] ?? 35;
    final category = card.data?['category'] ?? 'Good';

    Color categoryColor = const Color(0xFF10B981);
    if (aqiValue > 100) {
      categoryColor = const Color(0xFFEF4444);
    } else if (aqiValue > 50) {
      categoryColor = const Color(0xFFF59E0B);
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: categoryColor,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$aqiValue',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.title ?? 'Air Quality Index',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              card.subtitle ?? 'Category: $category',
              style: GoogleFonts.inter(color: categoryColor, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}
