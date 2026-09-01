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
      backgroundColor: const Color(0xFF111E35),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final locState = ref.watch(locationProvider);

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Location',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Option 1: Current GPS Location
                  ListTile(
                    leading: const Icon(Icons.my_location, color: Color(0xFF3FA9F5)),
                    title: Text(
                      'Current Location',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: !locState.isCustomSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      locState.deviceCityName ??
                          '${locState.deviceLatitude ?? 12.9716}, ${locState.deviceLongitude ?? 77.5946}',
                      style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                    ),
                    trailing: !locState.isCustomSelected
                        ? const Icon(Icons.check, color: Color(0xFF3FA9F5))
                        : null,
                    onTap: () async {
                      ref.read(locationProvider.notifier).useCurrentLocation();
                      Navigator.pop(context);
                      final idToken = ref.read(userProvider).idToken ?? 'test_token';
                      await ref.read(locationProvider.notifier).detectDeviceLocation(
                            ref.read(apiClientProvider),
                            idToken,
                          );
                      ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true);
                    },
                  ),

                  const Divider(color: Color(0xFF1E2F4F)),

                  // Saved Destinations Header & Add button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saved Destinations',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7A8AA8),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16, color: Color(0xFF3FA9F5)),
                        label: Text(
                          'Add Destination',
                          style: GoogleFonts.inter(color: const Color(0xFF3FA9F5), fontSize: 13),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No saved destinations yet.',
                        style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
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
                            leading: const Icon(Icons.location_city, color: Color(0xFF0E7C86)),
                            title: Text(
                              item.name,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              '${item.latitude}, ${item.longitude}',
                              style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) const Icon(Icons.check, color: Color(0xFF3FA9F5)),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () async {
                                    final idToken = ref.read(userProvider).idToken ?? 'test_token';
                                    try {
                                      await ref
                                          .read(apiClientProvider)
                                          .deleteSavedLocation(id: item.id, idToken: idToken);
                                      ref.read(locationProvider.notifier).removeSavedLocation(item.id);
                                    } catch (_) {}
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              ref.read(locationProvider.notifier).setActiveLocation(
                                    item.latitude,
                                    item.longitude,
                                    item.name,
                                    isCustom: true,
                                  );
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddDestinationDialog() {
    final nameCtrl = TextEditingController();
    final latCtrl = TextEditingController(text: '12.3052');
    final lonCtrl = TextEditingController(text: '76.6552');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111E35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Add Saved Destination',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Destination Name (e.g. Mysuru Palace)',
                  labelStyle: GoogleFonts.inter(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: latCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Latitude',
                  labelStyle: GoogleFonts.inter(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: lonCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Longitude',
                  labelStyle: GoogleFonts.inter(color: Colors.grey),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3FA9F5)),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final lat = double.tryParse(latCtrl.text.trim()) ?? 12.3052;
                final lon = double.tryParse(lonCtrl.text.trim()) ?? 76.6552;

                if (name.isNotEmpty) {
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
              child: Text('Save', style: GoogleFonts.inter(color: Colors.white)),
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
      backgroundColor: const Color(0xFF0A1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1220),
        elevation: 0,
        title: GestureDetector(
          onTap: _showLocationSwitcher,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, color: Color(0xFF3FA9F5), size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  locState.cityName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
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
            icon: const Icon(Icons.logout, color: Colors.white60),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              ref.read(userProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF3FA9F5),
        backgroundColor: const Color(0xFF111E35),
        onRefresh: () => ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Degraded context banner
              if ((homeState.data?.degradedContext ?? false) ||
                  (homeState.isStale && homeState.errorMessage != null && homeState.data != null)) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded, color: Color(0xFFF59E0B), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Showing last known conditions (stale or partial context)',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFDE68A),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Greeting & Insight Header
              if (homeState.data != null) ...[
                Text(
                  homeState.effectiveGreeting,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  homeState.effectiveSummaryInsight,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 20),
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
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      Text(
                        'Persona: ${homeState.data?.persona ?? "Fitness"}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF3FA9F5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

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
          decoration: BoxDecoration(
            color: const Color(0xFF152238),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF233554)),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF3FA9F5),
              strokeWidth: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF152238),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF233554)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 40),
          const SizedBox(height: 12),
          Text(
            'Failed to Load Insights',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            error,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3FA9F5)),
            icon: const Icon(Icons.refresh, size: 18),
            label: Text('Retry', style: GoogleFonts.inter(color: Colors.white)),
            onPressed: () {
              ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true);
            },
          ),
        ],
      ),
    );
  }
}
