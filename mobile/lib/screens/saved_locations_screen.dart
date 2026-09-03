import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';

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
      final created = await apiClient.saveLocation(
        name: text,
        latitude: 19.0760, // Fallback coordinates for new named search entry
        longitude: 72.8777,
        idToken: idToken,
      );

      final newItem = LocationItem(
        id: created['id'] as String,
        name: created['name'] as String,
        latitude: (created['latitude'] as num).toDouble(),
        longitude: (created['longitude'] as num).toDouble(),
        placeName: created['place_name'] as String?,
      );

      ref.read(locationProvider.notifier).addSavedLocation(newItem);
      _searchController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $text to saved locations'),
            backgroundColor: MausamPalette.cardSurface,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add location: $e'),
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
      ref.read(locationProvider.notifier).removeSavedLocation(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed $name'),
            backgroundColor: MausamPalette.cardSurface,
          ),
        );
      }
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
    final savedLocations = locState.savedLocations;

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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // Current GPS Location Banner
            StaggeredItemWrapper(
              index: 0,
              child: GestureDetector(
                onTap: () {
                  ref.read(locationProvider.notifier).useCurrentLocation();
                  context.go('/home');
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: MausamPalette.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: !locState.isCustomSelected ? MausamPalette.accentBlue : MausamPalette.cardBorder,
                      width: !locState.isCustomSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: MausamPalette.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: MausamPalette.accentBlue.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.my_location_rounded, color: MausamPalette.accentBlue, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Current Location',
                                  style: GoogleFonts.inter(
                                    color: MausamPalette.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (!locState.isCustomSelected) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: MausamPalette.accentBlue.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'ACTIVE',
                                      style: GoogleFonts.inter(
                                        color: MausamPalette.accentBlue,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              locState.deviceCityName ?? locState.cityName,
                              style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: MausamPalette.textTertiary),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Search / Add Location Section
            StaggeredItemWrapper(
              index: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: MausamPalette.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MausamPalette.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: MausamPalette.textTertiary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search city or location...',
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
                        icon: const Icon(Icons.add_rounded, color: MausamPalette.textPrimary),
                        onPressed: _addLocation,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'SAVED LOCATIONS',
              style: GoogleFonts.inter(
                color: MausamPalette.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            if (savedLocations.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: MausamPalette.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MausamPalette.cardBorder),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.bookmark_border_rounded, color: MausamPalette.textTertiary, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      'No saved locations yet',
                      style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Search above to save your favorite cities for quick weather access.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: MausamPalette.textTertiary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ] else ...[
              for (int i = 0; i < savedLocations.length; i++)
                StaggeredItemWrapper(
                  index: i + 2,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: MausamPalette.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: locState.isCustomSelected &&
                                locState.activeLatitude == savedLocations[i].latitude &&
                                locState.activeLongitude == savedLocations[i].longitude
                            ? MausamPalette.accentBlue
                            : MausamPalette.cardBorder,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        onTap: () {
                          ref.read(locationProvider.notifier).selectSavedLocation(savedLocations[i]);
                          context.go('/home');
                        },
                        leading: const Icon(Icons.place_outlined, color: MausamPalette.textSecondary),
                        title: Text(
                          savedLocations[i].name,
                          style: GoogleFonts.inter(
                            color: MausamPalette.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: MausamPalette.textTertiary, size: 20),
                          onPressed: () => _deleteLocation(savedLocations[i].id, savedLocations[i].name),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
