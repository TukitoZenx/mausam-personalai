import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/weather_palette.dart';

/// Mausam 3-Destination Obsidian Bottom Navigation Bar.
///
/// Features:
/// - Left: Home
/// - Center: Raised Weather AI / Mausam Intelligence Action (elevated above dock)
/// - Right: Settings / Profile
class MausamBottomNavbar extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onNavigate;

  const MausamBottomNavbar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  bool get _isHome => currentRoute == '/home';
  bool get _isInsights => currentRoute == '/insights';
  bool get _isProfile => currentRoute == '/profile';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Base Dock Bar
          Container(
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(29),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(29),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: MausamPalette.cardSurface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(29),
                    border: Border.all(
                      color: MausamPalette.cardBorder.withValues(alpha: 0.7),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // LEFT: Home
                      Expanded(
                        child: _NavItem(
                          key: const Key('bottom_nav_home'),
                          label: 'Home',
                          icon: _isHome ? Icons.home_rounded : Icons.home_outlined,
                          isActive: _isHome,
                          onTap: () => onNavigate('/home'),
                        ),
                      ),

                      // Center spacing placeholder for the raised action
                      const SizedBox(width: 72),

                      // RIGHT: Settings / Profile
                      Expanded(
                        child: _NavItem(
                          key: const Key('bottom_nav_settings'),
                          label: 'Settings',
                          icon: _isProfile ? Icons.person_rounded : Icons.person_outline_rounded,
                          isActive: _isProfile,
                          onTap: () => onNavigate('/profile'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // CENTER: Raised Weather AI Action Button
          Positioned(
            top: 0,
            child: GestureDetector(
              key: const Key('bottom_nav_insights'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onNavigate('/insights'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isInsights
                            ? const [
                                Color(0xFF3F3F46),
                                Color(0xFF27272A),
                                Color(0xFF18181B),
                              ]
                            : const [
                                Color(0xFF27272A),
                                Color(0xFF18181B),
                                Color(0xFF09090B),
                              ],
                      ),
                      border: Border.all(
                        color: _isInsights
                            ? MausamPalette.textPrimary
                            : MausamPalette.cardBorder,
                        width: _isInsights ? 1.6 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.65),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                        if (_isInsights)
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.18),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isInsights ? Icons.auto_awesome_rounded : Icons.cloud_outlined,
                        color: MausamPalette.textPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mausam',
                    style: GoogleFonts.inter(
                      color: _isInsights ? MausamPalette.textPrimary : MausamPalette.textTertiary,
                      fontSize: 10,
                      fontWeight: _isInsights ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    super.key,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? MausamPalette.textPrimary : MausamPalette.textTertiary,
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isActive ? MausamPalette.textPrimary : MausamPalette.textTertiary,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
