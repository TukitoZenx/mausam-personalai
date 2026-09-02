import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/home_card.dart';

class RankedCardShell extends StatelessWidget {
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
    this.showRankBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final showReasonBanner = card.rank <= 3 ||
        card.cardType == 'alerts' ||
        card.effectiveReason.isNotEmpty;

    final isAlert = card.cardType == 'alerts';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isAlert
                    ? [
                        const Color(0xFFEF4444).withValues(alpha: 0.22),
                        const Color(0xFF7F1D1D).withValues(alpha: 0.12),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.04),
                      ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isAlert
                    ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.18),
                width: isAlert ? 1.4 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isAlert
                      ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.25),
                  blurRadius: 14,
                  spreadRadius: -2,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                splashColor: const Color(0xFF00F5FF).withValues(alpha: 0.1),
                highlightColor: Colors.white.withValues(alpha: 0.05),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (showRankBadge && card.rank < 99) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF00F5FF).withValues(alpha: 0.25),
                                        const Color(0xFF3FA9F5).withValues(alpha: 0.15),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF00F5FF).withValues(alpha: 0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'RANK #${card.rank}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF00F5FF),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (card.category != null && card.category!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: Text(
                                    card.category!.toUpperCase(),
                                    style: GoogleFonts.outfit(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white.withValues(alpha: 0.7),
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (onDismiss != null)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white70, size: 14),
                                onPressed: onDismiss,
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Card Specific Content Body
                      child,

                      // Reason Banner (for ranks 1-3 or when reason present)
                      if (showReasonBanner && card.effectiveReason.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFFB703).withValues(alpha: 0.15),
                                const Color(0xFFF59E0B).withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFFB703).withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: Color(0xFFFFB703),
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  card.effectiveReason,
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontSize: 11.5,
                                    height: 1.3,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Reason codes chips
                      if (card.reasonCodes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 5,
                          runSpacing: 3,
                          children: card.reasonCodes.map((code) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00F5FF).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: const Color(0xFF00F5FF).withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                code.startsWith('#') ? code : '#$code',
                                style: GoogleFonts.outfit(
                                  fontSize: 9.5,
                                  color: const Color(0xFF7DD3FC),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
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
