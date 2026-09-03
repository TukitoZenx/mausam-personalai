import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/home_card.dart';
import '../../providers/appearance_provider.dart';
import '../../theme/weather_palette.dart';

class RecommendedSectionWidget extends ConsumerWidget {
  final RankedHomeCard card;
  final VoidCallback? onTap;

  const RecommendedSectionWidget({
    super.key,
    required this.card,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surfaceOpacity = ref.watch(cardSurfaceOpacityProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: MausamPalette.cardSurface.withValues(alpha: surfaceOpacity),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MausamPalette.cardBorder),
        boxShadow: MausamPalette.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: MausamPalette.textSecondary,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'FOR YOU',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: MausamPalette.textPrimary,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      if (card.category != null && card.category!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: MausamPalette.cardSurfaceLight.withValues(alpha: surfaceOpacity),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: MausamPalette.cardBorder),
                          ),
                          child: Text(
                            card.category!.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: MausamPalette.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    card.title ?? 'Personalized Recommendation',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MausamPalette.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (card.subtitle != null && card.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      card.subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: MausamPalette.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (card.effectiveReason.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: MausamPalette.bgDeep.withValues(alpha: surfaceOpacity * 0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: MausamPalette.cardBorderSubtle),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline_rounded,
                            color: MausamPalette.textTertiary,
                            size: 15,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              card.effectiveReason,
                              style: GoogleFonts.inter(
                                color: MausamPalette.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (card.actionLabel != null && card.actionLabel!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            card.actionLabel!,
                            style: GoogleFonts.inter(
                              color: MausamPalette.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: MausamPalette.textSecondary,
                            size: 13,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
