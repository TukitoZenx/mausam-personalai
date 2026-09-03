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
import '../../services/geocoding_service.dart';
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
  final GeocodingService _geocoding = GeocodingService();
  Timer? _debounceTimer;
  List<GeocodedPlace> _searchResults = [];
  bool _isSearching = false;
  bool _isSubmitting = false;
  String? _searchError;

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
        _searchError = null;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _performGeocodingSearch(query);
    });
  }

  Future<void> _performGeocodingSearch(String query) async {
    if (!mounted) return;
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
        _searchResults = results;
        _isSearching = false;
        _searchError = results.isEmpty ? 'No matching places found for “$query”.' : null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchError = 'Search failed. Try another city name.';
        });
      }
    }
  }

  Future<void> _selectSearchResult(GeocodedPlace place) async {
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

      Navigator.pop(context);
      context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save location (${place.name})'),
            backgroundColor: MausamPalette.cardSurface,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: MausamPalette.cardSurfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MausamPalette.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: MausamPalette.textSecondary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search any city or locality…',
                        hintStyle: GoogleFonts.inter(color: MausamPalette.textTertiary, fontSize: 14),
                        border: InputBorder.none,
                      ),
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
                      onPressed: () => _searchController.clear(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_searchResults.isNotEmpty) ...[
              Text(
                'RESULTS',
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
                    final place = _searchResults[index];
                    return ListTile(
                      dense: true,
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
                      onTap: () => _selectSearchResult(place),
                    );
                  },
                ),
              ),
            ] else if (_searchError != null && !_isSearching) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  _searchError!,
                  style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 16),
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
                  final isActive = item.name.toLowerCase() == locState.cityName.toLowerCase() ||
                      (item.placeName ?? '').toLowerCase() == locState.cityName.toLowerCase();
                  return ActionChip(
                    backgroundColor: isActive ? MausamPalette.cardSurfaceLight : MausamPalette.bgDeep,
                    side: BorderSide(color: isActive ? MausamPalette.textTertiary : MausamPalette.cardBorder),
                    label: Text(
                      item.name,
                      style: GoogleFonts.inter(
                        color: MausamPalette.textPrimary,
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
