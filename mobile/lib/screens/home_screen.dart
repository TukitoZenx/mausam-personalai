import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/home_card.dart';
import '../providers/auth_provider.dart';
import '../providers/homepage_provider.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/cards/card_registry.dart';
import '../widgets/cards/recommended_section_widget.dart';
import '../widgets/location_hero_card_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocationAndFetchData();
    });
  }

  Future<void> _initLocationAndFetchData() async {
    final userState = ref.read(userProvider);
    final apiClient = ref.read(apiClientProvider);
    final idToken = userState.idToken ?? 'test_token';

    // 1. Detect live device GPS location using geolocator
    await ref.read(locationProvider.notifier).detectDeviceLocation(apiClient, idToken);
    if (!mounted) return;

    // 2. Fetch saved locations list from backend
    try {
      final savedRaw = await apiClient.fetchSavedLocations(idToken: idToken);
      if (!mounted) return;
      final items = savedRaw.map((e) {
        final itemMap = e as Map<String, dynamic>;
        return LocationItem(
          id: itemMap['id'] as String,
          name: itemMap['name'] as String,
          latitude: (itemMap['latitude'] as num).toDouble(),
          longitude: (itemMap['longitude'] as num).toDouble(),
          placeName: itemMap['place_name'] as String?,
        );
      }).toList();
      ref.read(locationProvider.notifier).setSavedLocations(items);
    } catch (_) {}

    if (!mounted) return;
    // 3. Fetch initial homepage feed
    ref.read(homepageProvider.notifier).fetchHomeFeed();
  }

  void _showLocationSwitcher() {
    showModalBottomSheet(
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
                color: const Color(0xFF0B132B).withValues(alpha: 0.85),
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

                        // Option 1: Current GPS Location
                        Container(
                          decoration: BoxDecoration(
                            color: !locState.isCustomSelected
                                ? const Color(0xFF00F5FF).withValues(alpha: 0.12)
                                : Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: !locState.isCustomSelected
                                  ? const Color(0xFF00F5FF).withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.my_location, color: Color(0xFF00F5FF)),
                            title: Text(
                              'Current Location',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: !locState.isCustomSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              locState.deviceCityName ?? 'Live GPS Location',
                              style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
                            ),
                            trailing: !locState.isCustomSelected
                                ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00F5FF))
                                : null,
                            onTap: () async {
                              final locationNotifier = ref.read(locationProvider.notifier);
                              final userState = ref.read(userProvider);
                              final apiClient = ref.read(apiClientProvider);
                              final homepageNotifier = ref.read(homepageProvider.notifier);

                              locationNotifier.useCurrentLocation();
                              Navigator.pop(context);

                              final idToken = userState.idToken ?? 'test_token';
                              await locationNotifier.detectDeviceLocation(apiClient, idToken);
                              homepageNotifier.fetchHomeFeed(forceRefresh: true);
                            },
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(color: Color(0xFF1E2F4F)),
                        ),

                        // Saved Destinations Header & Add button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Saved Destinations',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF7DD3FC),
                                letterSpacing: 0.5,
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.add_location_alt_rounded, size: 16, color: Color(0xFF00F5FF)),
                              label: Text(
                                'Add Destination',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF00F5FF),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _showAddDestinationDialog();
                              },
                            ),
                          ],
                        ),

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

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF00F5FF).withValues(alpha: 0.12)
                                        : Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF00F5FF).withValues(alpha: 0.4)
                                          : Colors.white.withValues(alpha: 0.08),
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: const Icon(Icons.location_city, color: Color(0xFF3FA9F5)),
                                    title: Text(
                                      item.name,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      item.placeName ?? 'Saved Destination',
                                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF00F5FF)),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                          onPressed: () async {
                                            final userState = ref.read(userProvider);
                                            final apiClient = ref.read(apiClientProvider);
                                            final locationNotifier = ref.read(locationProvider.notifier);
                                            final idToken = userState.idToken ?? 'test_token';
                                            try {
                                              await apiClient.deleteSavedLocation(id: item.id, idToken: idToken);
                                              locationNotifier.removeSavedLocation(item.id);
                                            } catch (_) {}
                                          },
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      final locationNotifier = ref.read(locationProvider.notifier);
                                      final homepageNotifier = ref.read(homepageProvider.notifier);

                                      locationNotifier.setActiveLocation(
                                        item.latitude,
                                        item.longitude,
                                        item.name,
                                        isCustom: true,
                                      );
                                      Navigator.pop(context);
                                      homepageNotifier.fetchHomeFeed(forceRefresh: true);
                                    },
                                  ),
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

  void _showAddDestinationDialog() {
    final nameCtrl = TextEditingController();

    // Preset city map so users can just type city names without needing lat/lon
    final cityPresets = <String, Map<String, double>>{
      'mysuru': {'lat': 12.3052, 'lon': 76.6552},
      'bengaluru': {'lat': 12.9716, 'lon': 77.5946},
      'delhi': {'lat': 28.6139, 'lon': 77.2090},
      'mumbai': {'lat': 19.0760, 'lon': 72.8777},
      'london': {'lat': 51.5074, 'lon': -0.1278},
      'new york': {'lat': 40.7128, 'lon': -74.0060},
      'tokyo': {'lat': 35.6762, 'lon': 139.6503},
      'paris': {'lat': 48.8566, 'lon': 2.3522},
    };

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0B132B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
          title: Text(
            'Add Saved Destination',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter city or destination name:',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Destination Name (e.g. Mysuru)',
                  labelStyle: GoogleFonts.inter(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF00F5FF)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Popular presets: Mysuru, Bengaluru, Delhi, Mumbai, London, New York',
                style: GoogleFonts.inter(color: const Color(0xFF7DD3FC), fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F5FF),
                foregroundColor: const Color(0xFF070B16),
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  final key = name.toLowerCase();
                  final coords = cityPresets[key] ?? {'lat': 12.3052, 'lon': 76.6552};
                  final lat = coords['lat']!;
                  final lon = coords['lon']!;

                  final idToken = ref.read(userProvider).idToken ?? 'test_token';
                  try {
                    final resp = await ref.read(apiClientProvider).saveLocation(
                          name: name,
                          latitude: lat,
                          longitude: lon,
                          idToken: idToken,
                        );
                    final newItem = LocationItem(
                      id: resp['id'] as String,
                      name: name,
                      latitude: lat,
                      longitude: lon,
                      placeName: resp['place_name'] as String?,
                    );
                    ref.read(locationProvider.notifier).addSavedLocation(newItem);
                  } catch (_) {}
                }
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: Text('Save', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locState = ref.watch(locationProvider);
    final homeState = ref.watch(homepageProvider);

    final allCards = homeState.data?.cards ?? [];

    // Select recommended card: highest ranked non-weather card, or fallback to first
    RankedHomeCard? recommendedCard;
    if (allCards.isNotEmpty) {
      final nonWeather = allCards.where((c) => c.cardType.toLowerCase() != 'weather').toList();
      recommendedCard = nonWeather.isNotEmpty ? nonWeather.first : allCards.first;
    }

    // Remaining list excludes recommended card to avoid duplicate rendering
    final feedCards = allCards.where((c) => c.id != recommendedCard?.id).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF070B16),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AppBar(
              backgroundColor: const Color(0xFF070B16).withValues(alpha: 0.65),
              elevation: 0,
              title: GestureDetector(
                onTap: _showLocationSwitcher,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF00F5FF), size: 20),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        locState.cityName,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 20),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
                  tooltip: 'Profile & Persona',
                  onPressed: () => context.push('/profile'),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white54),
                  tooltip: 'Logout',
                  onPressed: () async {
                    await ref.read(authServiceProvider).signOut();
                    ref.read(userProvider.notifier).signOut();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background ambient glowing aura circles
          Positioned(
            top: -50,
            left: -40,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00F5FF).withValues(alpha: 0.12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F5FF).withValues(alpha: 0.2),
                    blurRadius: 100,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 250,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.18),
                    blurRadius: 120,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -30,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFB703).withValues(alpha: 0.08),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB703).withValues(alpha: 0.12),
                    blurRadius: 90,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),

          // Main Glass Scrollable Content
          SafeArea(
            child: RefreshIndicator(
              color: const Color(0xFF00F5FF),
              backgroundColor: const Color(0xFF0B132B),
              onRefresh: () => ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Degraded context banner
                    if ((homeState.data?.degradedContext ?? false) ||
                        (homeState.isStale && homeState.errorMessage != null && homeState.data != null)) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.history_rounded, color: Color(0xFFF59E0B), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Showing last known conditions (stale or partial context)',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFFDE68A),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Prominent Glassmorphic Location Hero Card
                    LocationHeroCardWidget(
                      locationState: locState,
                      onSwitchLocation: _showLocationSwitcher,
                      onRefreshGps: () async {
                        ref.read(locationProvider.notifier).useCurrentLocation();
                        final idToken = ref.read(userProvider).idToken ?? 'test_token';
                        await ref.read(locationProvider.notifier).detectDeviceLocation(
                              ref.read(apiClientProvider),
                              idToken,
                            );
                        ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true);
                      },
                    ),

                    // Greeting & Insight Header
                    if (homeState.data != null) ...[
                      Text(
                        homeState.effectiveGreeting,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        homeState.effectiveSummaryInsight,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Loading skeleton if fetching for first time
                    if (homeState.isLoading && homeState.data == null) ...[
                      _buildLoadingSkeleton(),
                    ] else if (homeState.errorMessage != null && homeState.data == null) ...[
                      // Error view when no cached data exists
                      _buildErrorView(homeState.errorMessage!),
                    ] else ...[
                      // 1. Recommended For You Top Highlight Section
                      if (recommendedCard != null)
                        RecommendedSectionWidget(
                          card: recommendedCard,
                          onTap: () {
                            ref.read(homepageProvider.notifier).logCardClick(recommendedCard!);
                          },
                        ),

                      // Section divider / title for dynamic feed
                      if (feedCards.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Live Insights Feed',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00F5FF).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF00F5FF).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    homeState.data?.ranker == 'ml' ? Icons.psychology : Icons.tune_rounded,
                                    size: 14,
                                    color: const Color(0xFF00F5FF),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    homeState.data?.ranker == 'ml' ? 'ML Reranked' : 'Rule Engine',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: const Color(0xFF00F5FF),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // 2. Dynamic Ranked Cards List
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: feedCards.length,
                          itemBuilder: (context, index) {
                            final card = feedCards[index];
                            return CardRegistry.buildCardWidget(
                              card: card,
                              onTap: () {
                                ref.read(homepageProvider.notifier).logCardClick(card);
                              },
                            );
                          },
                        ),
                      ],

                      if (feedCards.isEmpty && recommendedCard == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'No personalized insights available right now.',
                              style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          width: double.infinity,
          height: 120,
          margin: const EdgeInsets.only(bottom: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00F5FF),
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              Text(
                'Failed to Load Insights',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                error,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00F5FF),
                  foregroundColor: const Color(0xFF070B16),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text('Retry', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                onPressed: () {
                  ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
