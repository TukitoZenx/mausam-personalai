import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Map<String, dynamic>? _weatherData;
  Map<String, dynamic>? _aqiData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocationAndFetchData();
    });
  }

  Future<void> _initLocationAndFetchData() async {
    final locationState = ref.read(locationProvider);
    final userState = ref.read(userProvider);
    final apiClient = ref.read(apiClientProvider);
    final idToken = userState.idToken ?? 'test_token';

    // 1. Fetch current location reverse-geocode from backend
    try {
      final lat = locationState.latitude;
      final lon = locationState.longitude;
      final locData = await apiClient.fetchCurrentLocation(
        lat: lat,
        lon: lon,
        idToken: idToken,
      );
      if (locData['place_name'] != null && !locationState.isCustomSelected) {
        ref.read(locationProvider.notifier).setDeviceLocation(
              lat,
              lon,
              locData['place_name'] as String,
            );
      }
    } catch (_) {}

    // 2. Fetch saved locations list from backend
    try {
      final savedRaw = await apiClient.fetchSavedLocations(idToken: idToken);
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

    // 3. Fetch weather & AQI for active location
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    final locState = ref.read(locationProvider);

    setState(() {
      _weatherData = {
        'location': locState.cityName,
        'temperature_celsius': 24.5,
        'condition': 'Partly Cloudy',
        'humidity_percent': 72,
        'wind_speed_kmh': 14.2,
      };
      _aqiData = {
        'aqi_value': 35,
        'category': 'Good',
      };
    });
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

                  // Option 1: Device / Current Location
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
                      locState.deviceCityName ?? '${locState.deviceLatitude ?? 12.9716}, ${locState.deviceLongitude ?? 77.5946}',
                      style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                    ),
                    trailing: !locState.isCustomSelected ? const Icon(Icons.check, color: Color(0xFF3FA9F5)) : null,
                    onTap: () {
                      ref.read(locationProvider.notifier).useCurrentLocation();
                      Navigator.pop(context);
                      _fetchWeatherData();
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
                                      await ref.read(apiClientProvider).deleteSavedLocation(id: item.id, idToken: idToken);
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
                              _fetchWeatherData();
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
              Text(
                locState.cityName,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              ref.read(userProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location status banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF152238),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF233554)),
              ),
              child: Row(
                children: [
                  Icon(
                    locState.isCustomSelected ? Icons.star_rounded : Icons.my_location,
                    color: const Color(0xFF3FA9F5),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    locState.isCustomSelected ? 'Viewing Saved Destination' : 'Viewing Current Location',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Weather Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1C2C4E), Color(0xFF111E35)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2A3F6A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _weatherData?['location'] as String? ?? locState.cityName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 32),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_weatherData?['temperature_celsius'] ?? 24.5}°C',
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _weatherData?['condition'] as String? ?? 'Partly Cloudy',
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Humidity: ${_weatherData?['humidity_percent'] ?? 72}%',
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                      Text('Wind: ${_weatherData?['wind_speed_kmh'] ?? 14.2} km/h',
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // AQI Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF152238),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF233554)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_aqiData?['aqi_value'] ?? 35}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Air Quality Index',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Category: ${_aqiData?['category'] ?? "Good"}',
                        style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
