import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/location_provider.dart';
import '../providers/user_provider.dart';
import '../theme/weather_palette.dart';

class AppDrawer extends ConsumerWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final locationState = ref.watch(locationProvider);

    final persona = userState.selectedPersona ?? 'General';
    final email = userState.email ?? 'guest@mausam.ai';
    final isGuest = userState.isGuest || !userState.isAuthenticated;
    final cityName = locationState.cityName;

    return Drawer(
      backgroundColor: MausamPalette.drawerBg,
      child: SafeArea(
        child: Column(
          children: [
            // --- Header Block ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: MausamPalette.cardBorder, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MausamPalette.cardSurface,
                          border: Border.all(color: MausamPalette.glassBorder, width: 1),
                        ),
                        child: const Icon(
                          Icons.cloud_rounded,
                          color: MausamPalette.accentBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mausam AI',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: MausamPalette.textPrimary,
                              ),
                            ),
                            Text(
                              isGuest ? 'Guest Session' : email,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: MausamPalette.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Persona & Active Location Row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: MausamPalette.cardSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: MausamPalette.cardBorder, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_pin_rounded, color: MausamPalette.accentCyan, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              persona,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: MausamPalette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: MausamPalette.cardSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: MausamPalette.cardBorder, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded, color: MausamPalette.accentOrange, size: 14),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                cityName,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: MausamPalette.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // --- Navigation Items ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _DrawerItem(
                    icon: Icons.wb_sunny_rounded,
                    label: 'Weather & Insights',
                    isSelected: currentRoute == '/home',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != '/home') {
                        context.go('/home');
                      }
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.calendar_month_rounded,
                    label: '7-Day Forecast',
                    isSelected: currentRoute == '/forecast',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != '/forecast') {
                        context.go('/forecast');
                      }
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.bookmark_rounded,
                    label: 'Saved Destinations',
                    isSelected: currentRoute == '/saved-locations',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != '/saved-locations') {
                        context.go('/saved-locations');
                      }
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.tune_rounded,
                    label: 'Profile & Preferences',
                    isSelected: currentRoute == '/profile',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != '/profile') {
                        context.go('/profile');
                      }
                    },
                  ),
                ],
              ),
            ),

            // --- Footer / Sign out ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: MausamPalette.cardBorder, width: 1),
                ),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  ref.read(userProvider.notifier).signOut();
                  context.go('/login');
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        isGuest ? 'Exit Guest Session' : 'Sign Out',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? MausamPalette.cardSurface : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: MausamPalette.cardBorder, width: 1)
            : null,
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon,
          color: isSelected ? MausamPalette.accentBlue : MausamPalette.textSecondary,
          size: 22,
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? MausamPalette.textPrimary : MausamPalette.textSecondary,
          ),
        ),
      ),
    );
  }
}
