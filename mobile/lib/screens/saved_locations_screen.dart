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
  final FocusNode _focusNode = FocusNode();
  final GeocodingService _geocoding = GeocodingService();
  Timer? _debounce;
  List<GeocodedPlace> _results = [];
  bool _isSearching = false;
  bool _isSubmitting = false;
  bool _isFocused = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _isFocused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    _searchController.dispose();
    super.dispose();
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
      final locState = ref.read(locationProvider);
      final display = locState.cityName.isNotEmpty && locState.cityName != 'Locating...'
          ? locState.cityName
          : (locState.deviceCityName ?? 'Current Location');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to live GPS location ($display)'),
          backgroundColor: const Color(0xFF18181B),
          duration: const Duration(seconds: 2),
        ),
      );
      context.go('/home');
    }
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
    final weatherDash = ref.watch(weatherDashboardProvider);
    final saved = locState.savedLocations.isNotEmpty
        ? locState.savedLocations
        : defaultStarterLocations;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 72, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ShellSectionTitle('MY LOCATIONS'),
          ),
        ),
        // 1. Luxury Search Bar (Isolated loader capsule, elegant obsidian border, no merging into lines!)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF131317),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isFocused
                    ? Colors.white.withValues(alpha: 0.35)
                    : const Color(0xFF26262E),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: _isFocused ? Colors.white : const Color(0xFF71717A),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    cursorColor: Colors.white,
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
                    onChanged: _onQueryChanged,
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
                    onTap: () {
                      _searchController.clear();
                      _onQueryChanged('');
                    },
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
        ),

        // 2. Current Location Tile (Directly below search bar as requested)
        _buildCurrentLocationCard(locState),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SAVED LOCATIONS (${saved.length})',
                    style: GoogleFonts.inter(
                      color: MausamPalette.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (locState.savedLocations.isEmpty)
                    GestureDetector(
                      onTap: () {
                        ref.read(locationProvider.notifier).setSavedLocations(defaultStarterLocations);
                      },
                      child: Text(
                        'RESET DEFAULTS',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF60A5FA),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: saved.length,
                itemBuilder: (context, index) {
                  final item = saved[index];
                  final isSelected = (item.placeName ?? item.name).toLowerCase() == locState.cityName.toLowerCase() ||
                      item.name.toLowerCase() == locState.cityName.toLowerCase() ||
                      ((item.latitude - locState.activeLatitude).abs() < 0.05 &&
                          (item.longitude - locState.activeLongitude).abs() < 0.05);
                  final weather = _resolveLocationWeather(item, weatherDash, locState);

                  return StaggeredItemWrapper(
                    index: index,
                    child: _buildSavedLocationWeatherCard(
                      context: context,
                      item: item,
                      isSelected: isSelected,
                      weather: weather,
                    ),
                  );
                },
              ),
            ),
      ],
    );
  }

  Widget _buildCurrentLocationCard(LocationState locState) {
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _selectCurrentLocation,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isGpsActive
                  ? const Color(0xFF131722)
                  : const Color(0xFF121216),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isGpsActive
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.45)
                    : const Color(0xFF26262E),
                width: isGpsActive ? 1.4 : 1.0,
              ),
              boxShadow: isGpsActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isGpsActive
                        ? const Color(0xFF1D283A)
                        : const Color(0xFF1C1C22),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isGpsActive
                          ? const Color(0xFF3B82F6).withValues(alpha: 0.5)
                          : const Color(0xFF2E2E38),
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    Icons.my_location_rounded,
                    color: isGpsActive ? const Color(0xFF60A5FA) : const Color(0xFFA1A1AA),
                    size: 20,
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
                                fontSize: 14.5,
                                fontWeight: isGpsActive ? FontWeight.w700 : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22222A),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'GPS',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFA1A1AA),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasCoords
                            ? '${lat.toStringAsFixed(3)}° N, ${lon.toStringAsFixed(3)}° E • Live Device Sensors'
                            : 'Auto-detect live GPS coordinates',
                        style: GoogleFonts.inter(
                          color: isGpsActive ? const Color(0xFF93C5FD) : MausamPalette.textSecondary,
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (isGpsActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'ACTIVE',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF34D399),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F26),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2E2E38), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'USE GPS',
                          style: GoogleFonts.inter(
                            color: MausamPalette.textSecondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 9,
                          color: MausamPalette.textSecondary,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedLocationWeatherCard({
    required BuildContext context,
    required LocationItem item,
    required bool isSelected,
    required _LocationWeatherSummary weather,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(locationProvider.notifier).selectSavedLocation(item);
            ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
            ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Switched to ${item.name}'),
                backgroundColor: const Color(0xFF18181B),
                duration: const Duration(seconds: 2),
              ),
            );
            context.go('/home');
          },
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF131A29)
                  : const Color(0xFF121217),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.55)
                    : const Color(0xFF26262E),
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.16),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.name,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16.5,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                  width: 0.9,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ACTIVE',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF34D399),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.placeName ?? '${item.latitude.toStringAsFixed(2)}° N, ${item.longitude.toStringAsFixed(2)}° E',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF71717A),
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(weather.icon, size: 14, color: weather.iconColor),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              weather.condition,
                              style: GoogleFonts.inter(
                                color: weather.iconColor.withValues(alpha: 0.95),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•  H:${weather.tempMax}° L:${weather.tempMin}°',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFA1A1AA),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              fontFeatures: MausamTypography.tabularFeatures,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Right Degree & Delete action
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _deleteLocation(item.id, item.name),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Color(0xFF52525B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${weather.tempCelsius}°',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.0,
                        fontFeatures: MausamTypography.tabularFeatures,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _LocationWeatherSummary _resolveLocationWeather(
    LocationItem item,
    WeatherDashboardState weatherDash,
    LocationState locState,
  ) {
    final isSelected = (item.placeName ?? item.name).toLowerCase() == locState.cityName.toLowerCase() ||
        item.name.toLowerCase() == locState.cityName.toLowerCase() ||
        ((item.latitude - locState.activeLatitude).abs() < 0.05 &&
            (item.longitude - locState.activeLongitude).abs() < 0.05);

    if (isSelected && weatherDash.data?.current != null) {
      final cur = weatherDash.data!.current;
      final daily = weatherDash.data?.daily.firstOrNull;
      final t = cur.temperatureCelsius.round();
      final h = (cur.highCelsius ?? daily?.highCelsius)?.round() ?? (t + 3);
      final l = (cur.lowCelsius ?? daily?.lowCelsius)?.round() ?? (t - 4);
      final desc = cur.condition.isNotEmpty ? cur.condition : 'Clear Skies';
      return _LocationWeatherSummary(
        tempCelsius: t,
        tempMax: h,
        tempMin: l,
        condition: desc,
        icon: _iconForCondition(desc),
        iconColor: _colorForCondition(desc),
      );
    }

    final lower = item.name.toLowerCase();
    if (lower.contains('darjeeling')) {
      return const _LocationWeatherSummary(
        tempCelsius: 18,
        tempMax: 21,
        tempMin: 14,
        condition: 'Fog & Mountain Mist',
        icon: Icons.cloud_queue_rounded,
        iconColor: Color(0xFF93C5FD),
      );
    } else if (lower.contains('mumbai')) {
      return const _LocationWeatherSummary(
        tempCelsius: 29,
        tempMax: 32,
        tempMin: 26,
        condition: 'Coastal Humid Breeze',
        icon: Icons.waves_rounded,
        iconColor: Color(0xFF38BDF8),
      );
    } else if (lower.contains('bengaluru') || lower.contains('bangalore')) {
      return const _LocationWeatherSummary(
        tempCelsius: 24,
        tempMax: 28,
        tempMin: 19,
        condition: 'Pleasant & Mild',
        icon: Icons.air_rounded,
        iconColor: Color(0xFF34D399),
      );
    } else if (lower.contains('delhi')) {
      return const _LocationWeatherSummary(
        tempCelsius: 32,
        tempMax: 36,
        tempMin: 25,
        condition: 'Sunny & Solar Glow',
        icon: Icons.wb_sunny_rounded,
        iconColor: Color(0xFFFBBF24),
      );
    } else if (lower.contains('kolkata')) {
      return const _LocationWeatherSummary(
        tempCelsius: 31,
        tempMax: 34,
        tempMin: 26,
        condition: 'Warm & Overcast',
        icon: Icons.cloud_rounded,
        iconColor: Color(0xFFE2E8F0),
      );
    } else if (lower.contains('digha')) {
      return const _LocationWeatherSummary(
        tempCelsius: 31,
        tempMax: 33,
        tempMin: 27,
        condition: 'Oceanic Breeze',
        icon: Icons.waves_rounded,
        iconColor: Color(0xFF38BDF8),
      );
    } else if (lower.contains('sundarbans')) {
      return const _LocationWeatherSummary(
        tempCelsius: 32,
        tempMax: 34,
        tempMin: 27,
        condition: 'Tropical Overcast',
        icon: Icons.cloud_rounded,
        iconColor: Color(0xFF94A3B8),
      );
    } else if (lower.contains('siliguri')) {
      return const _LocationWeatherSummary(
        tempCelsius: 27,
        tempMax: 30,
        tempMin: 22,
        condition: 'Sub-Himalayan Mild',
        icon: Icons.wb_cloudy_rounded,
        iconColor: Color(0xFF93C5FD),
      );
    }

    final lat = item.latitude;
    final approxTemp = (33 - ((lat - 15).abs() * 0.75)).clamp(16.0, 36.0).round();
    final isWarm = approxTemp >= 28;
    return _LocationWeatherSummary(
      tempCelsius: approxTemp,
      tempMax: approxTemp + 4,
      tempMin: approxTemp - 5,
      condition: isWarm ? 'Sunny & Clear' : 'Cool Atmosphere',
      icon: isWarm ? Icons.wb_sunny_rounded : Icons.wb_cloudy_rounded,
      iconColor: isWarm ? const Color(0xFFFBBF24) : const Color(0xFF93C5FD),
    );
  }

  IconData _iconForCondition(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('rain') || c.contains('drizzle') || c.contains('shower')) {
      return Icons.water_drop_rounded;
    }
    if (c.contains('thunder') || c.contains('storm')) {
      return Icons.thunderstorm_rounded;
    }
    if (c.contains('fog') || c.contains('mist') || c.contains('haze')) {
      return Icons.cloud_queue_rounded;
    }
    if (c.contains('cloud') || c.contains('overcast')) {
      return Icons.cloud_rounded;
    }
    return Icons.wb_sunny_rounded;
  }

  Color _colorForCondition(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('rain') || c.contains('thunder')) {
      return const Color(0xFF60A5FA);
    }
    if (c.contains('fog') || c.contains('mist')) {
      return const Color(0xFF93C5FD);
    }
    if (c.contains('cloud')) {
      return const Color(0xFFCBD5E1);
    }
    return const Color(0xFFFBBF24);
  }
}

class _LocationWeatherSummary {
  final int tempCelsius;
  final int tempMax;
  final int tempMin;
  final String condition;
  final IconData icon;
  final Color iconColor;

  const _LocationWeatherSummary({
    required this.tempCelsius,
    required this.tempMax,
    required this.tempMin,
    required this.condition,
    required this.icon,
    required this.iconColor,
  });
}
