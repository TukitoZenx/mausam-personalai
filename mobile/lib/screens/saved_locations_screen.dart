import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../providers/homepage_provider.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';
import '../providers/weather_dashboard_provider.dart';
import '../services/geocoding_service.dart';
import '../theme/weather_palette.dart';
import '../widgets/navigation/shell_section_title.dart';
import '../widgets/staggered_item_wrapper.dart';

class SavedLocationsScreen extends ConsumerStatefulWidget {
  const SavedLocationsScreen({super.key});

  @override
  ConsumerState<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends ConsumerState<SavedLocationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GeocodingService _geocoding = GeocodingService();
  Timer? _debounce;
  List<GeocodedPlace> _results = [];
  bool _isSearching = false;
  bool _isSubmitting = false;
  String? _searchError;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String raw) {
    final query = raw.trim();
    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
        _searchError = null;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  Future<void> _search(String query) async {
    final apiClient = ref.read(apiClientProvider);
    final idToken = ref.read(userProvider).idToken ?? 'test_token';
    try {
      final results = await _geocoding.search(
        query: query,
        apiClient: apiClient,
        idToken: idToken,
      );
      if (!mounted || _searchController.text.trim() != query) return;
      setState(() {
        _results = results;
        _isSearching = false;
        _searchError = results.isEmpty ? 'No matching places found for “$query”.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchError = 'Search failed. Try another city name.';
      });
    }
  }

  Future<void> _selectPlace(GeocodedPlace place) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final apiClient = ref.read(apiClientProvider);
    final idToken = ref.read(userProvider).idToken ?? 'test_token';

    try {
      await ref.read(locationProvider.notifier).saveAndSelect(
            apiClient: apiClient,
            idToken: idToken,
            name: place.name,
            latitude: place.latitude,
            longitude: place.longitude,
            placeName: place.displayName,
          );
      if (!mounted) return;
      ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
      ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true);
      _searchController.clear();
      setState(() {
        _results = [];
        _searchError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Now showing weather for ${place.name}'),
          backgroundColor: MausamPalette.cardSurface,
        ),
      );
      context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not add ${place.name}'),
            backgroundColor: MausamPalette.cardSurface,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
          const SnackBar(
            content: Text('Failed to delete location'),
            backgroundColor: MausamPalette.cardSurface,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locState = ref.watch(locationProvider);
    final saved = locState.savedLocations;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 72, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ShellSectionTitle('MY LOCATIONS'),
          ),
        ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: MausamPalette.cardSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: MausamPalette.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: MausamPalette.textSecondary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search any city or locality…',
                          hintStyle: GoogleFonts.inter(color: MausamPalette.textTertiary, fontSize: 14),
                          border: InputBorder.none,
                        ),
                        onChanged: _onQueryChanged,
                      ),
                    ),
                    if (_isSearching || _isSubmitting)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: MausamPalette.textPrimary),
                      )
                    else if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, color: MausamPalette.textTertiary, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onQueryChanged('');
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (_results.isNotEmpty)
              Flexible(
                flex: 2,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(color: MausamPalette.cardBorderSubtle, height: 1),
                  itemBuilder: (context, index) {
                    final place = _results[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: const Icon(Icons.location_on_outlined, color: MausamPalette.textSecondary, size: 20),
                      title: Text(
                        place.name,
                        style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        place.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 12),
                      ),
                      onTap: () => _selectPlace(place),
                    );
                  },
                ),
              )
            else if (_searchError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  _searchError!,
                  style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 13),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SAVED',
                  style: GoogleFonts.inter(
                    color: MausamPalette.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
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
                            'Search any city, then tap a result to save it.',
                            style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: saved.length,
                      itemBuilder: (context, index) {
                        final item = saved[index];
                        final isSelected = (item.placeName ?? item.name).toLowerCase() == locState.cityName.toLowerCase() ||
                            item.name.toLowerCase() == locState.cityName.toLowerCase();

                        return StaggeredItemWrapper(
                          index: index,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? MausamPalette.cardSurfaceLight : MausamPalette.cardSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? MausamPalette.textTertiary : MausamPalette.cardBorder,
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
                                  color: MausamPalette.bgDeep,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.location_on_rounded,
                                  color: isSelected ? MausamPalette.textPrimary : MausamPalette.textSecondary,
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
                                        color: MausamPalette.cardSurfaceLight,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: MausamPalette.cardBorder),
                                      ),
                                      child: Text(
                                        'ACTIVE',
                                        style: GoogleFonts.inter(
                                          color: MausamPalette.textPrimary,
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
    );
  }
}
