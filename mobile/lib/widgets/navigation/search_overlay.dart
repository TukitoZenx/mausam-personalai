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

  Future<void> _selectCurrentLocation() async {
    final userState = ref.read(userProvider);
    final apiClient = ref.read(apiClientProvider);
    final idToken = userState.idToken ?? 'test_token';

    try {
      await ref.read(locationProvider.notifier).detectDeviceLocation(apiClient, idToken).timeout(
        const Duration(milliseconds: 1500),
        onTimeout: () {},
      );
    } catch (_) {}

    ref.read(locationProvider.notifier).useCurrentLocation();
    ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
    ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true);

    if (mounted) {
      Navigator.pop(context);
      context.go('/home');
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
          color: Color(0xFF0F0F13),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF26262E))),
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
                  color: const Color(0xFF33333E),
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

            // Luxury Search Bar
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF15151B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF272730), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Color(0xFF71717A), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: false,
                      cursorColor: const Color(0xFFE4E4E7),
                      cursorWidth: 1.5,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search any city or locality…',
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF52525B),
                          fontSize: 13.5,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_isSearching || _isSubmitting)
                    Container(
                      width: 26,
                      height: 26,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E26),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF333340), width: 1),
                      ),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () => _searchController.clear(),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E24),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF2E2E38), width: 1),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.close_rounded,
                            color: Color(0xFFA1A1AA),
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Current Location Tile (Below Search Bar)
            _buildCurrentLocationTile(locState),
            const SizedBox(height: 12),
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

  Widget _buildCurrentLocationTile(LocationState locState) {
    final isGpsActive = !locState.isCustomSelected;
    var deviceCity = locState.deviceCityName ?? 'Current Location';
    if (deviceCity == 'Locating...' || deviceCity.isEmpty) {
      deviceCity = (locState.activeCityName.isNotEmpty && locState.activeCityName != 'Locating...')
          ? locState.activeCityName
          : 'Live GPS Location';
    }
    final hasCoords = (locState.deviceLatitude != null && locState.deviceLatitude != 0.0) ||
        (locState.activeLatitude != 0.0);
    final lat = locState.deviceLatitude ?? locState.activeLatitude;
    final lon = locState.deviceLongitude ?? locState.activeLongitude;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _selectCurrentLocation,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isGpsActive ? const Color(0xFF131722) : const Color(0xFF14141A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isGpsActive
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.45)
                  : const Color(0xFF262630),
              width: isGpsActive ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isGpsActive ? const Color(0xFF1D283A) : const Color(0xFF1D1D24),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isGpsActive
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
                        : const Color(0xFF2E2E38),
                  ),
                ),
                child: Icon(
                  Icons.my_location_rounded,
                  color: isGpsActive ? const Color(0xFF60A5FA) : const Color(0xFFA1A1AA),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            deviceCity,
                            style: GoogleFonts.inter(
                              color: MausamPalette.textPrimary,
                              fontSize: 14,
                              fontWeight: isGpsActive ? FontWeight.w700 : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF202028),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'GPS',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFA1A1AA),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasCoords
                          ? '${lat.toStringAsFixed(3)}° N, ${lon.toStringAsFixed(3)}° E • Live GPS'
                          : 'Tap to lock onto device GPS',
                      style: GoogleFonts.inter(
                        color: isGpsActive ? const Color(0xFF93C5FD) : MausamPalette.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isGpsActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF34D399),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: MausamPalette.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
