import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../providers/homepage_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/weather_dashboard_provider.dart';
import '../../theme/weather_palette.dart';

Future<void> showSearchOverlay({
  required BuildContext context,
  required WidgetRef ref,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (context) => const SearchOverlayModal(),
  );
}

class SearchOverlayModal extends ConsumerStatefulWidget {
  const SearchOverlayModal({super.key});

  @override
  ConsumerState<SearchOverlayModal> createState() => _SearchOverlayModalState();
}

class _SearchOverlayModalState extends ConsumerState<SearchOverlayModal> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchQueryChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchQueryChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchQueryChanged() {
    final query = _searchController.text.trim();
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _performGeocodingSearch(query);
    });
  }

  Future<void> _performGeocodingSearch(String query) async {
    if (!mounted) return;
    setState(() => _isSearching = true);

    final apiClient = ref.read(apiClientProvider);
    final userState = ref.read(userProvider);
    final idToken = userState.idToken ?? 'test_token';

    try {
      final raw = await apiClient.searchLocations(query: query, idToken: idToken);
      if (!mounted) return;
      setState(() {
        _searchResults = raw.map((e) => e as Map<String, dynamic>).toList();
        _isSearching = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _selectSearchResult({
    required String name,
    required double latitude,
    required double longitude,
    String? placeName,
  }) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final apiClient = ref.read(apiClientProvider);
    final userState = ref.read(userProvider);
    final idToken = userState.idToken ?? 'test_token';

    try {
      final created = await apiClient.saveLocation(
        name: name,
        latitude: latitude,
        longitude: longitude,
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

      // Trigger instant weather dashboard and homepage refresh for new active location
      ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
      ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true);

      Navigator.pop(context);
      context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save location ($name): $e'),
            backgroundColor: MausamPalette.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locState = ref.watch(locationProvider);
    final saved = locState.savedLocations;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        decoration: const BoxDecoration(
          color: MausamPalette.cardSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: MausamPalette.cardBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: MausamPalette.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'SEARCH LOCATION',
              style: GoogleFonts.inter(
                color: MausamPalette.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Search Bar Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: MausamPalette.cardSurfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MausamPalette.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: MausamPalette.accentBlue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search city or place (e.g. Hyderabad, London)...',
                        hintStyle: GoogleFonts.inter(color: MausamPalette.textTertiary, fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_isSearching || _isSubmitting)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: MausamPalette.accentBlue),
                    )
                  else if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, color: MausamPalette.textTertiary, size: 18),
                      onPressed: () => _searchController.clear(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Search Results List
            if (_searchResults.isNotEmpty) ...[
              Text(
                'GEOCODED RESULTS',
                style: GoogleFonts.inter(
                  color: MausamPalette.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => const Divider(color: MausamPalette.cardBorderSubtle, height: 1),
                  itemBuilder: (context, index) {
                    final item = _searchResults[index];
                    final name = item['name'] as String? ?? 'Unknown';
                    final displayName = item['display_name'] as String? ?? name;
                    final lat = (item['latitude'] as num).toDouble();
                    final lon = (item['longitude'] as num).toDouble();

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: const Icon(Icons.location_on_outlined, color: MausamPalette.accentBlue, size: 20),
                      title: Text(
                        name,
                        style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 12),
                      ),
                      onTap: () => _selectSearchResult(
                        name: name,
                        latitude: lat,
                        longitude: lon,
                        placeName: displayName,
                      ),
                    );
                  },
                ),
              ),
            ] else if (_searchController.text.isNotEmpty && !_isSearching) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No matching places found. Try typing city name (e.g. Hyderabad, Mumbai, Tokyo)',
                  style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 13),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Quick Select / Saved Locations
            if (saved.isNotEmpty) ...[
              Text(
                'SAVED LOCATIONS',
                style: GoogleFonts.inter(
                  color: MausamPalette.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: saved.map((item) {
                  final isActive = item.name.toLowerCase() == locState.cityName.toLowerCase();
                  return ActionChip(
                    backgroundColor: isActive ? MausamPalette.cardSurfaceLight : MausamPalette.bgDeep,
                    side: BorderSide(color: isActive ? MausamPalette.accentBlue : MausamPalette.cardBorder),
                    label: Text(
                      item.name,
                      style: GoogleFonts.inter(
                        color: isActive ? MausamPalette.accentBlue : MausamPalette.textPrimary,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: () {
                      ref.read(locationProvider.notifier).selectSavedLocation(item);
                      ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
                      ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true);
                      Navigator.pop(context);
                      context.go('/home');
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
