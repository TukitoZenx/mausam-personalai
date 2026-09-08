import 'dart:ui';
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: MausamPalette.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: MausamPalette.cardSurface.withValues(alpha: surfaceOpacity),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: surfaceOpacity < 0.95
                    ? Colors.white.withValues(alpha: 0.10)
                    : MausamPalette.cardBorder,
              ),
            ),
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
                    const SizedBox(height: 6),
                    Text(
                      card.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: MausamPalette.textSecondary,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        card.actionLabel?.isNotEmpty == true ? card.actionLabel! : 'Why this matters',
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
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);
  }
}
