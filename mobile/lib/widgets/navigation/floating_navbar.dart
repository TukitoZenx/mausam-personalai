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
          // 1. Opaque near-black background on scroll (solid, no content bleed-through)
          Positioned.fill(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              opacity: isScrolled ? 1.0 : 0.0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0C0D12),
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFF1F2028),
                      width: 0.8,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 16,
                      offset: Offset(0, 2),
                    ),
                  ],
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
