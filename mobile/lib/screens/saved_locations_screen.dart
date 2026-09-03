import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../providers/homepage_provider.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';
import '../providers/weather_dashboard_provider.dart';

import '../theme/weather_palette.dart';
import '../widgets/staggered_item_wrapper.dart';

class SavedLocationsScreen extends ConsumerStatefulWidget {
  const SavedLocationsScreen({super.key});

  @override
  ConsumerState<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends ConsumerState<SavedLocationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addLocation() async {
    final text = _searchController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isAdding = true);
    final userState = ref.read(userProvider);
    final apiClient = ref.read(apiClientProvider);
    final idToken = userState.idToken ?? 'test_token';

    try {
      // 1. Perform geocoding search first to resolve real lat/lon
      final searchResults = await apiClient.searchLocations(query: text, idToken: idToken);
      double lat = 17.3850;
      double lon = 78.4867;
      String locationName = text;
      String? placeName;

      if (searchResults.isNotEmpty) {
        final first = searchResults.first as Map<String, dynamic>;
        locationName = first['name'] as String? ?? text;
        placeName = first['display_name'] as String?;
        lat = (first['latitude'] as num).toDouble();
        lon = (first['longitude'] as num).toDouble();
      }

      // 2. Save location on backend
      final created = await apiClient.saveLocation(
        name: locationName,
        latitude: lat,
        longitude: lon,
        idToken: idToken,
      );

      final newItem = LocationItem(
        id: created['id'] as String,
        name: created['name'] as String,
        latitude: (created['latitude'] as num).toDouble(),
        longitude: (created['longitude'] as num).toDouble(),
        placeName: created['place_name'] as String? ?? placeName,
      );

      if (!mounted) return;
      ref.read(locationProvider.notifier).addSavedLocation(newItem);
      ref.read(locationProvider.notifier).selectSavedLocation(newItem);
      ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
      ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true);

      _searchController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added and selected $locationName'),
          backgroundColor: MausamPalette.cardSurface,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save location: $e'),
            backgroundColor: MausamPalette.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _deleteLocation(String id, String name) async {
    final userState = ref.read(userProvider);
    final apiClient = ref.read(apiClientProvider);
    final idToken = userState.idToken ?? 'test_token';

    try {
      await apiClient.deleteSavedLocation(id: id, idToken: idToken);
      if (!mounted) return;
      ref.read(locationProvider.notifier).removeSavedLocation(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed $name'),
          backgroundColor: MausamPalette.cardSurface,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete location: $e'),
            backgroundColor: MausamPalette.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locState = ref.watch(locationProvider);
    final saved = locState.savedLocations;

    return Scaffold(
      backgroundColor: MausamPalette.bgPrimary,
      appBar: AppBar(
        backgroundColor: MausamPalette.bgDeep,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: MausamPalette.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'MY LOCATIONS',
          style: GoogleFonts.inter(
            color: MausamPalette.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search / Add Location Input Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: MausamPalette.cardSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MausamPalette.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: MausamPalette.accentBlue, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Enter city (e.g. Hyderabad, London, Tokyo)...',
                          hintStyle: GoogleFonts.inter(color: MausamPalette.textTertiary, fontSize: 14),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _addLocation(),
                      ),
                    ),
                    if (_isAdding)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: MausamPalette.accentBlue),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.add_rounded, color: MausamPalette.accentBlue),
                        onPressed: _addLocation,
                        tooltip: 'Add City',
                      ),
                  ],
                ),
              ),
            ),

            // Saved Locations List
            Expanded(
              child: saved.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.map_outlined, color: MausamPalette.textTertiary, size: 44),
                          const SizedBox(height: 12),
                          Text(
                            'No Saved Locations',
                            style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Type a city name above to add it to your list.',
                            style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: saved.length,
                      itemBuilder: (context, index) {
                        final item = saved[index];
                        final isSelected = item.name.toLowerCase() == locState.cityName.toLowerCase();

                        return StaggeredItemWrapper(
                          index: index,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? MausamPalette.cardSurfaceLight : MausamPalette.cardSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? MausamPalette.accentBlue : MausamPalette.cardBorder,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              onTap: () {
                                ref.read(locationProvider.notifier).selectSavedLocation(item);
                                ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
                                ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true);
                                context.go('/home');
                              },
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? MausamPalette.accentBlue.withValues(alpha: 0.15)
                                      : MausamPalette.bgDeep,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.location_on_rounded,
                                  color: isSelected ? MausamPalette.accentBlue : MausamPalette.textSecondary,
                                  size: 20,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: GoogleFonts.inter(
                                        color: MausamPalette.textPrimary,
                                        fontSize: 15,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: MausamPalette.accentBlue.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'ACTIVE',
                                        style: GoogleFonts.inter(
                                          color: MausamPalette.accentBlue,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                item.placeName ?? '${item.latitude.toStringAsFixed(2)}, ${item.longitude.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: MausamPalette.textTertiary, size: 20),
                                onPressed: () => _deleteLocation(item.id, item.name),
                                tooltip: 'Delete Location',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
