import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/location_provider.dart';
import '../../theme/weather_palette.dart';
import 'drawer_time_header.dart';

class MausamAppDrawer extends ConsumerWidget {
  final String currentRoute;

  const MausamAppDrawer({
    super.key,
    this.currentRoute = '/home',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locState = ref.watch(locationProvider);

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
              DrawerTimeHeader(
                locationName: locState.cityName.isNotEmpty ? locState.cityName : 'Current Location',
              ),
              const Divider(color: MausamPalette.drawerDivider, height: 1),
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
                      title: 'Extended Forecast',
                      icon: Icons.calendar_today_rounded,
                      route: '/forecast',
                      isActive: currentRoute == '/forecast',
                    ),
                    _drawerItem(
                      context: context,
                      title: 'Health Metrics',
                      icon: Icons.favorite_border_rounded,
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
                    _drawerItem(
                      context: context,
                      title: 'Travel & Commute',
                      icon: Icons.commute_rounded,
                      route: '/insights',
                      isActive: false,
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
            color: isActive ? MausamPalette.textPrimary : MausamPalette.textSecondary,
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
