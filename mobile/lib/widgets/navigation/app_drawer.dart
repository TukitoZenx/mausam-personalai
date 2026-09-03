import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/location_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/weather_palette.dart';

class MausamAppDrawer extends ConsumerWidget {
  final String currentRoute;

  const MausamAppDrawer({
    super.key,
    this.currentRoute = '/home',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locState = ref.watch(locationProvider);
    final userState = ref.watch(userProvider);
    final persona = userState.selectedPersona ?? 'Fitness';

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: MausamPalette.drawerBg.withValues(alpha: 0.95),
          border: const Border(
            right: BorderSide(color: MausamPalette.cardBorder, width: 1),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drawer Header Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: MausamPalette.accentBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'MAUSAM',
                          style: GoogleFonts.inter(
                            color: MausamPalette.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: MausamPalette.cardSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: MausamPalette.cardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_outlined, color: MausamPalette.accentBlue, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            locState.cityName,
                            style: GoogleFonts.inter(
                              color: MausamPalette.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: MausamPalette.drawerDivider, height: 1),

              // Navigation Links
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  children: [
                    _drawerItem(
                      context: context,
                      title: 'Home',
                      icon: Icons.grid_view_rounded,
                      route: '/home',
                      isActive: currentRoute == '/home',
                    ),
                    _drawerItem(
                      context: context,
                      title: 'My Locations',
                      icon: Icons.map_outlined,
                      route: '/saved-locations',
                      isActive: currentRoute == '/saved-locations',
                    ),
                    _drawerItem(
                      context: context,
                      title: 'Forecast',
                      icon: Icons.calendar_today_rounded,
                      route: '/forecast',
                      isActive: currentRoute == '/forecast',
                    ),
                    _drawerItem(
                      context: context,
                      title: 'Insights ($persona)',
                      icon: Icons.insights_rounded,
                      route: '/insights',
                      isActive: currentRoute == '/insights',
                    ),
                    _drawerItem(
                      context: context,
                      title: 'Alerts',
                      icon: Icons.warning_amber_rounded,
                      route: '/alerts',
                      isActive: currentRoute == '/alerts',
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: MausamPalette.drawerDivider, height: 1),
                    ),

                    _drawerItem(
                      context: context,
                      title: 'Profile & Settings',
                      icon: Icons.person_outline_rounded,
                      route: '/profile',
                      isActive: currentRoute == '/profile',
                    ),
                  ],
                ),
              ),

              // Footer Metadata
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Mausam AI v1.0 • SIH MVP',
                  style: GoogleFonts.inter(
                    color: MausamPalette.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String route,
    required bool isActive,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? MausamPalette.cardSurface : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isActive ? Border.all(color: MausamPalette.cardBorder) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onTap: () {
            Navigator.pop(context);
            if (!isActive) {
              context.go(route);
            }
          },
          leading: Icon(
            icon,
            color: isActive ? MausamPalette.accentBlue : MausamPalette.textSecondary,
            size: 20,
          ),
          title: Text(
            title,
            style: GoogleFonts.inter(
              color: isActive ? MausamPalette.textPrimary : MausamPalette.textSecondary,
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
