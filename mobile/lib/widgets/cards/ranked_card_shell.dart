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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16243D), Color(0xFF0F1A2E)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: card.cardType == 'alerts'
              ? const Color(0xFFEF4444)
              : const Color(0xFF233659),
          width: card.cardType == 'alerts' ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
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
                              color: const Color(0xFF3FA9F5).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF3FA9F5).withOpacity(0.4)),
                            ),
                            child: Text(
                              'Rank #${card.rank}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF3FA9F5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (card.category != null && card.category!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2D4A),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              card.category!.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white60,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (onDismiss != null)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                        onPressed: onDismiss,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Card Specific Content Body
                child,

                // Reason Banner (for ranks 1-3 or when reason present)
                if (showReasonBanner && card.effectiveReason.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1E3050)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFFF59E0B),
                          size: 15,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            card.effectiveReason,
                            style: GoogleFonts.inter(
                              color: const Color(0xDDFFFFFF),
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Reason codes chips
                if (card.reasonCodes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: card.reasonCodes.map((code) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF13223A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          code.startsWith('#') ? code : '#$code',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
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
    );
  }
}
