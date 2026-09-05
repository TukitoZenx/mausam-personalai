import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/weather_palette.dart';

class FloatingNavbar extends StatelessWidget {
  final String locationName;
  final Animation<double> locationAnimation;
  final VoidCallback onLocationTap;
  final VoidCallback onSearch;

  const FloatingNavbar({
    super.key,
    required this.locationName,
    required this.locationAnimation,
    required this.onLocationTap,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: MausamPalette.navbarShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: MausamPalette.cardSurface.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MausamPalette.cardBorder.withValues(alpha: 0.6), width: 1.0),
            ),
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
                  child: ClipRect(
                    child: AnimatedBuilder(
                      animation: locationAnimation,
                      builder: (context, child) {
                        final t = locationAnimation.value.clamp(0.0, 1.2);
                        return Transform.translate(
                          offset: Offset(0, -t * 28),
                          child: Opacity(
                            opacity: (1.0 - t * 0.35).clamp(0.0, 1.0),
                            child: child,
                          ),
                        );
                      },
                      child: GestureDetector(
                        onTap: onLocationTap,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: MausamPalette.textSecondary,
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                locationName,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: MausamPalette.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: MausamPalette.textPrimary, size: 22),
                  tooltip: 'Search City',
                  onPressed: onSearch,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
