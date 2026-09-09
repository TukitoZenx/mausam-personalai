import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/weather_palette.dart';

/// Minimalist Top Navigation Bar for Mausam AI.
///
/// Features:
/// - Unscrolled / Top state: 100% transparent background with only the text and icons visible.
/// - Scrolled state: Stays pinned at the top with a smooth dark glass backdrop, subtle shadow, and hairline divider.
/// - The location text remains pinned at the top without collapsing or moving away during scroll.
class FloatingNavbar extends StatelessWidget {
  final String locationName;
  final Animation<double>? locationAnimation;
  final bool isScrolled;
  final VoidCallback onLocationTap;
  final VoidCallback? onSearch;

  const FloatingNavbar({
    super.key,
    required this.locationName,
    this.locationAnimation,
    this.isScrolled = false,
    required this.onLocationTap,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Stack(
        children: [
          // 1. Scrolling Shadow & Glass Backdrop (Fades in smoothly only while scrolling)
          Positioned.fill(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              opacity: isScrolled ? 1.0 : 0.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFA090B10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 16,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Pinned Top Bar Content (Icons & Location Text - without search icon)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Builder(
                    builder: (drawerContext) => IconButton(
                      icon: const Icon(Icons.menu_rounded, color: MausamPalette.textPrimary, size: 22),
                      tooltip: 'Open Menu',
                      onPressed: () => Scaffold.of(drawerContext).openDrawer(),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: onLocationTap,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: MausamPalette.accentCyan,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              locationName,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: MausamPalette.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
