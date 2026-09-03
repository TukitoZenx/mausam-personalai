import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../providers/homepage_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/weather_dashboard_provider.dart';
import '../../theme/weather_palette.dart';

Future<void> showLocationSwitcherSheet({
  required BuildContext context,
  required WidgetRef ref,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: MausamPalette.cardSurface.withValues(alpha: 0.92),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Consumer(
              builder: (context, ref, child) {
                final locState = ref.watch(locationProvider);
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Location',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: !locState.isCustomSelected
                              ? MausamPalette.cardSurfaceLight
                              : MausamPalette.bgDeep,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: MausamPalette.cardBorder,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                          leading: const Icon(Icons.my_location, color: MausamPalette.textPrimary),
                          title: Text(
                            'Current Location',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: !locState.isCustomSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            locState.deviceCityName ?? 'Live GPS Location',
                            style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 12),
                          ),
                          trailing: !locState.isCustomSelected
                              ? const Icon(Icons.check_circle_rounded, color: MausamPalette.textPrimary)
                              : null,
                          onTap: () async {
                            final locationNotifier = ref.read(locationProvider.notifier);
                            final userState = ref.read(userProvider);
                            final apiClient = ref.read(apiClientProvider);
                            locationNotifier.useCurrentLocation();
                            Navigator.pop(context);
                            final idToken = userState.idToken ?? 'test_token';
                            await locationNotifier.detectDeviceLocation(apiClient, idToken);
                            ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true);
                            ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
                          },
                        ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(color: MausamPalette.cardBorder),
                      ),
                      Text(
                        'Saved Destinations',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: MausamPalette.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (locState.savedLocations.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No saved destinations yet.',
                              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: locState.savedLocations.length,
                            itemBuilder: (context, index) {
                              final item = locState.savedLocations[index];
                              final isSelected = locState.isCustomSelected &&
                                  locState.activeLatitude == item.latitude &&
                                  locState.activeLongitude == item.longitude;
                              return ListTile(
                                leading: const Icon(Icons.location_city, color: MausamPalette.textSecondary),
                                title: Text(
                                  item.name,
                                  style: GoogleFonts.outfit(color: Colors.white),
                                ),
                                subtitle: Text(
                                  item.placeName ?? 'Saved Destination',
                                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle, color: MausamPalette.textPrimary)
                                    : null,
                                onTap: () {
                                  ref.read(locationProvider.notifier).setActiveLocation(
                                        item.latitude,
                                        item.longitude,
                                        item.name,
                                        isCustom: true,
                                      );
                                  Navigator.pop(context);
                                  ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true);
                                  ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}
