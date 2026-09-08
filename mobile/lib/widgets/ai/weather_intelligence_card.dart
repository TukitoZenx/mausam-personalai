import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/weather_ai_card_data.dart';
import '../../theme/weather_palette.dart';

/// Ultra-premium, scannable Weather Intelligence Card for Mausam AI chat.
/// Supports Activity Window, Wardrobe/Clothing, Health & Environment, Travel, and Daily Plan.
class WeatherIntelligenceCard extends StatelessWidget {
  final WeatherAiCardData cardData;
  final VoidCallback? onActionTap;

  const WeatherIntelligenceCard({
    super.key,
    required this.cardData,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141722),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF262E40),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Category with Glow Dot
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cardData.category.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF10B981),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. Primary Headline (Scannable in 2-3 seconds)
          Text(
            cardData.headline,
            style: GoogleFonts.inter(
              color: MausamPalette.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          if (cardData.subtitle != null && cardData.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              cardData.subtitle!,
              style: GoogleFonts.inter(
                color: MausamPalette.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // 3. Compact Metrics Row
          if (cardData.metrics.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: cardData.metrics.map((m) {
                return _MetricPill(
                  icon: m.icon,
                  label: m.label,
                  value: m.value,
                  accentColor: m.color,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // 4. Daily Plan Timeline (if available)
          if (cardData.dailyPlanPeriods != null && cardData.dailyPlanPeriods!.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF181D2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A344A)),
              ),
              child: Column(
                children: cardData.dailyPlanPeriods!.map((period) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(period.icon, size: 16, color: MausamPalette.accentCyan),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 70,
                          child: Text(
                            period.period,
                            style: GoogleFonts.inter(
                              color: MausamPalette.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          period.temp,
                          style: GoogleFonts.inter(
                            color: MausamPalette.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            period.advice,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF94A3B8),
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // 5. Checklist Items (e.g. for Packing / Travel)
          if (cardData.checklistItems != null && cardData.checklistItems!.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF181D2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A344A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cardData.checklistItems!.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: GoogleFonts.inter(
                              color: MausamPalette.textPrimary,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // 6. Explainable "Why" Section
          if (cardData.explanation != null && cardData.explanation!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B202D),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A3245)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cardData.explanation!,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFCBD5E1),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 7. Contextual Action Button (Single Primary Action)
          if (cardData.actionLabel != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onActionTap?.call();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2536),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF374151),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          cardData.actionLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: MausamPalette.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: MausamPalette.textPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? accentColor;

  const _MetricPill({
    required this.icon,
    required this.label,
    required this.value,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2333),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF2C354B),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: accentColor ?? MausamPalette.textSecondary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: MausamPalette.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
