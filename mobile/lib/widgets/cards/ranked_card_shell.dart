import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/home_card.dart';
import '../../providers/appearance_provider.dart';
import '../../theme/weather_palette.dart';

class RankedCardShell extends ConsumerWidget {
  final RankedHomeCard card;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final bool showRankBadge;

  const RankedCardShell({
    super.key,
    required this.card,
    required this.child,
    this.onTap,
    this.onDismiss,
    this.showRankBadge = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surfaceOpacity = ref.watch(cardSurfaceOpacityProvider);

    Widget content = Container(
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
            highlightColor: Colors.white.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (card.category != null && card.category!.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                              fontWeight: FontWeight.w700,
                              color: MausamPalette.textSecondary,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        if (showRankBadge && card.rank < 99)
                          Text(
                            '#${card.rank}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: MausamPalette.textTertiary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (card.title != null && card.title!.isNotEmpty) ...[
                    Text(
                      card.title!,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: MausamPalette.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  child,

                  if (card.effectiveReason.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: MausamPalette.bgDeep.withValues(alpha: surfaceOpacity * 0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: MausamPalette.cardBorderSubtle),
                      ),
                      child: Text(
                        card.effectiveReason,
                        style: GoogleFonts.inter(
                          color: MausamPalette.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
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

    if (onDismiss != null) {
      return Dismissible(
        key: ValueKey(card.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismiss!(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: MausamPalette.cardSurfaceLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: MausamPalette.textPrimary),
        ),
        child: content,
      );
    }

    return content;
  }
}
