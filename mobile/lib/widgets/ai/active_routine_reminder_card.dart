import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/routine_reminder.dart';
import '../../theme/weather_palette.dart';

/// Card displaying the active or paused recurring routine reminder with management actions.
class ActiveRoutineReminderCard extends StatelessWidget {
  final RoutineReminder reminder;
  final VoidCallback onTogglePause;
  final VoidCallback onDelete;

  const ActiveRoutineReminderCard({
    super.key,
    required this.reminder,
    required this.onTogglePause,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = reminder.isActive;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131722),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : const Color(0xFF2A3245),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Activity Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                reminder.activityTitle,
                style: GoogleFonts.inter(
                  color: MausamPalette.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF10B981).withValues(alpha: 0.4)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  isActive ? 'Status: Active' : 'Status: Paused',
                  style: GoogleFonts.inter(
                    color: isActive ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Schedule Line: "Every day · 9:00 PM"
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: MausamPalette.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                reminder.scheduleDisplay,
                style: GoogleFonts.inter(
                  color: MausamPalette.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Actions Row: [Pause / Resume] and [Delete]
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Pause / Resume Button
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTogglePause();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F2C),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2B3346)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 13,
                        color: MausamPalette.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isActive ? 'Pause' : 'Resume',
                        style: GoogleFonts.inter(
                          color: MausamPalette.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Delete Button
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onDelete();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF261919),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.delete_outline_rounded,
                        size: 13,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Delete',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFEF4444),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
