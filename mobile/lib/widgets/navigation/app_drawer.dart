import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/appearance_provider.dart';
import '../../providers/location_provider.dart';
import '../../theme/environment_theme.dart';
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
                      title: 'Extended Forecast',
                      icon: Icons.calendar_today_rounded,
                      route: '/forecast',
                      isActive: currentRoute == '/forecast',
                    ),
                    _drawerItem(
                      context: context,
                      title: 'Persona Context',
                      icon: Icons.tune_rounded,
                      route: '/context-detail',
                      isActive: currentRoute == '/context-detail',
                    ),
                    _drawerItem(
                      context: context,
                      title: 'Health & Metrics',
                      icon: Icons.favorite_border_rounded,
                      route: '/health-metrics',
                      isActive: currentRoute == '/health-metrics',
                    ),
                    _drawerItem(
                      context: context,
                      title: 'Alerts & Travel',
                      icon: Icons.travel_explore_rounded,
                      route: '/alerts',
                      isActive: currentRoute == '/alerts',
                    ),
                    _drawerItem(
                      context: context,
                      title: 'Weather Map',
                      icon: Icons.map_rounded,
                      route: '/weather-map',
                      isActive: currentRoute == '/weather-map',
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Consumer(
                  builder: (context, ref, _) {
                    final appearance = ref.watch(appearanceProvider);
                    final isDynamic = appearance.wallpaperTheme.isDynamic;

                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131317),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: MausamPalette.cardBorder, width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              key: const Key('drawer_switch_dynamic'),
                              onTap: () {
                                ref.read(appearanceProvider.notifier).setWallpaperTheme(WallpaperTheme.dynamic);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                decoration: BoxDecoration(
                                  color: isDynamic ? const Color(0xFF1E293B) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                  border: isDynamic ? Border.all(color: const Color(0xFF3B82F6), width: 1) : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.wb_sunny_rounded, color: isDynamic ? const Color(0xFF60A5FA) : const Color(0xFF71717A), size: 13),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Live Sky',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: isDynamic ? Colors.white : const Color(0xFF71717A),
                                          fontSize: 11,
                                          fontWeight: isDynamic ? FontWeight.w700 : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: GestureDetector(
                              key: const Key('drawer_switch_fixed'),
                              onTap: () {
                                ref.read(appearanceProvider.notifier).setWallpaperTheme(WallpaperTheme.wallpaper2);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                decoration: BoxDecoration(
                                  color: !isDynamic ? const Color(0xFF27272A) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                  border: !isDynamic ? Border.all(color: const Color(0xFFA1A1AA), width: 1) : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.nightlight_round, color: !isDynamic ? Colors.white : const Color(0xFF71717A), size: 13),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Fixed Black',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: !isDynamic ? Colors.white : const Color(0xFF71717A),
                                          fontSize: 11,
                                          fontWeight: !isDynamic ? FontWeight.w700 : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Mausam PersonalAI',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: MausamPalette.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'v1.0 • Weather Intelligence',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: MausamPalette.textTertiary,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
        borderRadius: BorderRadius.circular(10),
        border: isActive ? Border.all(color: MausamPalette.cardBorder) : null,
      ),
      child: Material(
        color: isActive ? MausamPalette.cardSurface : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
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
