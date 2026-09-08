import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';

class LocationItem {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? placeName;

  const LocationItem({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.placeName,
  });
}

class LocationState {
  final double? deviceLatitude;
  final double? deviceLongitude;
  final String? deviceCityName;

  final double activeLatitude;
  final double activeLongitude;
  final String activeCityName;
  final bool isCustomSelected;

  final List<LocationItem> savedLocations;
  final bool isLoading;

  const LocationState({
    this.deviceLatitude,
    this.deviceLongitude,
    this.deviceCityName,
    this.activeLatitude = 0.0,
    this.activeLongitude = 0.0,
    this.activeCityName = 'Current Location',
    this.isCustomSelected = false,
    this.savedLocations = const [],
    this.isLoading = false,
  });

  double get latitude => activeLatitude;
  double get longitude => activeLongitude;
  String get cityName => activeCityName;

  LocationState copyWith({
    double? deviceLatitude,
    double? deviceLongitude,
    String? deviceCityName,
    double? activeLatitude,
    double? activeLongitude,
    String? activeCityName,
    bool? isCustomSelected,
    List<LocationItem>? savedLocations,
    bool? isLoading,
  }) {
    return LocationState(
      deviceLatitude: deviceLatitude ?? this.deviceLatitude,
      deviceLongitude: deviceLongitude ?? this.deviceLongitude,
      deviceCityName: deviceCityName ?? this.deviceCityName,
      activeLatitude: activeLatitude ?? this.activeLatitude,
      activeLongitude: activeLongitude ?? this.activeLongitude,
      activeCityName: activeCityName ?? this.activeCityName,
      isCustomSelected: isCustomSelected ?? this.isCustomSelected,
      savedLocations: savedLocations ?? this.savedLocations,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

const _kActiveLat = 'active_latitude';
const _kActiveLon = 'active_longitude';
const _kActiveName = 'active_city_name';
const _kCustomSelected = 'is_custom_selected';

const defaultStarterLocations = [
  LocationItem(
    id: 'loc_delhi',
    name: 'New Delhi',
    latitude: 28.6139,
    longitude: 77.2090,
    placeName: 'National Capital Region, India',
  ),
  LocationItem(
    id: 'loc_mumbai',
    name: 'Mumbai',
    latitude: 19.0760,
    longitude: 72.8777,
    placeName: 'Maharashtra, India',
  ),
  LocationItem(
    id: 'loc_bengaluru',
    name: 'Bengaluru',
    latitude: 12.9716,
    longitude: 77.5946,
    placeName: 'Karnataka, India',
  ),
  LocationItem(
    id: 'loc_darjeeling',
    name: 'Darjeeling',
    latitude: 27.0410,
    longitude: 88.2663,
    placeName: 'West Bengal, India',
  ),
];

String? _resolveRegionalCityName(double lat, double lon) {
  if (lat == 0.0 && lon == 0.0) return null;
  // Delhi NCR / Gurugram / Noida / Faridabad / Ghaziabad
  if ((lat - 28.6139).abs() < 0.6 && (lon - 77.2090).abs() < 0.6) {
    if (lat < 28.5 && lon < 77.1) return 'Gurugram';
    if (lat > 28.65 && lon > 77.3) return 'Noida';
    if (lat < 28.45) return 'Faridabad';
    return 'New Delhi';
  }
  // Mumbai / Thane / Navi Mumbai
  if ((lat - 19.0760).abs() < 0.5 && (lon - 72.8777).abs() < 0.5) return 'Mumbai';
  // Bengaluru
  if ((lat - 12.9716).abs() < 0.5 && (lon - 77.5946).abs() < 0.5) return 'Bengaluru';
  // Kolkata / Howrah
  if ((lat - 22.5726).abs() < 0.5 && (lon - 88.3639).abs() < 0.5) return 'Kolkata';
  // Chennai
  if ((lat - 13.0827).abs() < 0.5 && (lon - 80.2707).abs() < 0.5) return 'Chennai';
  // Hyderabad / Secunderabad
  if ((lat - 17.3850).abs() < 0.5 && (lon - 78.4867).abs() < 0.5) return 'Hyderabad';
  // Pune
  if ((lat - 18.5204).abs() < 0.5 && (lon - 73.8567).abs() < 0.5) return 'Pune';
  // Ahmedabad
  if ((lat - 23.0225).abs() < 0.5 && (lon - 72.5714).abs() < 0.5) return 'Ahmedabad';
  // Jaipur
  if ((lat - 26.9124).abs() < 0.5 && (lon - 75.7873).abs() < 0.5) return 'Jaipur';
  // Darjeeling
  if ((lat - 27.0410).abs() < 0.4 && (lon - 88.2663).abs() < 0.4) return 'Darjeeling';
  // Siliguri
  if ((lat - 26.7271).abs() < 0.4 && (lon - 88.3953).abs() < 0.4) return 'Siliguri';
  // Digha
  if ((lat - 21.6266).abs() < 0.4 && (lon - 87.5074).abs() < 0.4) return 'Digha';
  // Chandigarh / Mohali / Panchkula
  if ((lat - 30.7333).abs() < 0.4 && (lon - 76.7794).abs() < 0.4) return 'Chandigarh';
  // Lucknow
  if ((lat - 26.8467).abs() < 0.5 && (lon - 80.9462).abs() < 0.5) return 'Lucknow';
  // Patna
  if ((lat - 25.5941).abs() < 0.5 && (lon - 85.1376).abs() < 0.5) return 'Patna';
  // Bhopal
  if ((lat - 23.2599).abs() < 0.5 && (lon - 77.4126).abs() < 0.5) return 'Bhopal';
  // Indore
  if ((lat - 22.7196).abs() < 0.5 && (lon - 75.8577).abs() < 0.5) return 'Indore';
  // Surat
  if ((lat - 21.1702).abs() < 0.5 && (lon - 72.8311).abs() < 0.5) return 'Surat';
  // Vadodara
  if ((lat - 22.3072).abs() < 0.5 && (lon - 73.1812).abs() < 0.5) return 'Vadodara';
  // Nagpur
  if ((lat - 21.1458).abs() < 0.5 && (lon - 79.0882).abs() < 0.5) return 'Nagpur';
  // Visakhapatnam
  if ((lat - 17.6868).abs() < 0.5 && (lon - 83.2185).abs() < 0.5) return 'Visakhapatnam';
  // Kochi
  if ((lat - 9.9312).abs() < 0.4 && (lon - 76.2673).abs() < 0.4) return 'Kochi';
  // Thiruvananthapuram
  if ((lat - 8.5241).abs() < 0.4 && (lon - 76.9366).abs() < 0.4) return 'Thiruvananthapuram';
  // Bhubaneswar
  if ((lat - 20.2961).abs() < 0.5 && (lon - 85.8245).abs() < 0.5) return 'Bhubaneswar';
  // Dehradun
  if ((lat - 30.3165).abs() < 0.4 && (lon - 78.0322).abs() < 0.4) return 'Dehradun';
  // Shimla
  if ((lat - 31.1048).abs() < 0.4 && (lon - 77.1734).abs() < 0.4) return 'Shimla';
  // Srinagar
  if ((lat - 34.0837).abs() < 0.5 && (lon - 74.7973).abs() < 0.5) return 'Srinagar';
  // Goa (Panaji)
  if ((lat - 15.4909).abs() < 0.4 && (lon - 73.8278).abs() < 0.4) return 'Goa';
  return null;
}

class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() {
    return const LocationState(
      savedLocations: defaultStarterLocations,
    );
  }

  Future<void> restorePersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_kActiveLat);
      final lon = prefs.getDouble(_kActiveLon);
      final name = prefs.getString(_kActiveName);
      final custom = prefs.getBool(_kCustomSelected) ?? false;
      if (lat != null && lon != null && name != null && name.isNotEmpty) {
        final cleanName = (name == 'Locating...' || name == 'Current Location')
            ? (_resolveRegionalCityName(lat, lon) ?? 'Current Location')
            : name;
        final cleanLat = (lat == 0.0 && lon == 0.0) ? 28.6139 : lat;
        final cleanLon = (lat == 0.0 && lon == 0.0) ? 77.2090 : lon;
        state = state.copyWith(
          activeLatitude: cleanLat,
          activeLongitude: cleanLon,
          activeCityName: (cleanLat == 28.6139 && cleanLon == 77.2090 && cleanName == 'Current Location')
              ? 'New Delhi'
              : cleanName,
          isCustomSelected: custom,
        );
      }

      final hasCustomized = prefs.getBool('has_customized_saved_locations') ?? false;
      final persistedLocations = prefs.getStringList('persisted_saved_locations');
      if (persistedLocations != null) {
        final loaded = persistedLocations.map((str) {
          final map = jsonDecode(str) as Map<String, dynamic>;
          return LocationItem(
            id: map['id']?.toString() ?? 'loc_${DateTime.now().millisecondsSinceEpoch}',
            name: map['name']?.toString() ?? '',
            latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
            longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
            placeName: map['placeName']?.toString(),
          );
        }).where((e) => e.name.isNotEmpty).toList();

        if (loaded.isNotEmpty) {
          state = state.copyWith(savedLocations: loaded);
        } else if (hasCustomized) {
          state = state.copyWith(savedLocations: const []);
        } else {
          state = state.copyWith(savedLocations: defaultStarterLocations);
        }
      } else if (!hasCustomized) {
        state = state.copyWith(savedLocations: defaultStarterLocations);
      } else {
        state = state.copyWith(savedLocations: const []);
      }
    } catch (_) {}
  }

  Future<void> _persistSavedLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = state.savedLocations.map((item) => jsonEncode({
        'id': item.id,
        'name': item.name,
        'latitude': item.latitude,
        'longitude': item.longitude,
        'placeName': item.placeName,
      })).toList();
      await prefs.setStringList('persisted_saved_locations', list);
    } catch (_) {}
  }

  Future<void> hydrateSavedLocations(ApiClient apiClient, String idToken) async {
    try {
      final savedRaw = await apiClient.fetchSavedLocations(idToken: idToken);
      final items = savedRaw.map((e) {
        final itemMap = e as Map<String, dynamic>;
        return LocationItem(
          id: itemMap['id'].toString(),
          name: itemMap['name'].toString(),
          latitude: (itemMap['latitude'] as num).toDouble(),
          longitude: (itemMap['longitude'] as num).toDouble(),
          placeName: itemMap['place_name'] as String?,
        );
      }).toList();
      if (items.isNotEmpty) {
        setSavedLocations(items);
      }
    } catch (_) {}
  }

  Future<void> _persistActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kActiveLat, state.activeLatitude);
      await prefs.setDouble(_kActiveLon, state.activeLongitude);
      await prefs.setString(_kActiveName, state.activeCityName);
      await prefs.setBool(_kCustomSelected, state.isCustomSelected);
    } catch (_) {}
  }

  Future<void> detectDeviceLocation(ApiClient apiClient, String idToken) async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
        debugPrint('Desktop Linux platform — using default coordinates.');
        setDeviceLocation(12.9716, 77.5946, state.deviceCityName ?? 'Bengaluru');
        await _fetchReverseGeocode(apiClient, 12.9716, 77.5946, idToken);
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services disabled on device.');
        _ensureValidCoordinatesFallback();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied.');
          _ensureValidCoordinatesFallback();
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied.');
        _ensureValidCoordinatesFallback();
        return;
      }

      // 1. FAST PATH: Instant fix using last known position (< 30ms)
      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      if (position != null) {
        final fastCity = _resolveRegionalCityName(position.latitude, position.longitude) ??
            (state.deviceCityName != null && state.deviceCityName != 'Locating...'
                ? state.deviceCityName!
                : 'Current Location');
        setDeviceLocation(position.latitude, position.longitude, fastCity);
        unawaited(_fetchReverseGeocode(apiClient, position.latitude, position.longitude, idToken));
      }

      // 2. FRESH POSITION: Fast network/cell/GPS fix with medium accuracy & 4s timeout
      try {
        final freshPos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 4),
        );
        final freshCity = _resolveRegionalCityName(freshPos.latitude, freshPos.longitude) ??
            (state.deviceCityName != null && state.deviceCityName != 'Locating...'
                ? state.deviceCityName!
                : 'Current Location');
        setDeviceLocation(freshPos.latitude, freshPos.longitude, freshCity);
        unawaited(_fetchReverseGeocode(apiClient, freshPos.latitude, freshPos.longitude, idToken));
      } catch (e) {
        debugPrint('getCurrentPosition quick fix error/timeout: $e');
        if (position == null) {
          _ensureValidCoordinatesFallback();
        }
      }
    } catch (e) {
      debugPrint('Device location detection error: $e');
      _ensureValidCoordinatesFallback();
    }
  }

  void _ensureValidCoordinatesFallback() {
    if (state.activeLatitude == 0.0 && state.activeLongitude == 0.0) {
      final starter = state.savedLocations.firstOrNull ?? defaultStarterLocations.first;
      setDeviceLocation(starter.latitude, starter.longitude, starter.name);
    }
  }

  Future<void> _fetchReverseGeocode(
    ApiClient apiClient,
    double lat,
    double lon,
    String idToken,
  ) async {
    // 1. Instant offline regional lookup
    final regionalCity = _resolveRegionalCityName(lat, lon);
    if (regionalCity != null && regionalCity.isNotEmpty) {
      setDeviceLocation(lat, lon, regionalCity);
    }

    // 2. Client-side reverse geocoding via free public BigDataCloud client API (< 1s)
    try {
      final onlineName = await _reverseGeocodeOnline(lat, lon);
      if (onlineName != null && onlineName.isNotEmpty) {
        setDeviceLocation(lat, lon, onlineName);
        return;
      }
    } catch (_) {}

    // 3. Fallback to backend reverse geocode if reachable
    try {
      final locData = await apiClient.fetchCurrentLocation(
        lat: lat,
        lon: lon,
        idToken: idToken,
      );
      final placeName = (locData['place_name'] as String?) ??
          (locData['city'] as String?) ??
          (locData['state_region'] as String?);

      if (placeName != null && placeName.isNotEmpty) {
        setDeviceLocation(lat, lon, placeName);
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
      // If no name yet, ensure fallback is clean coordinate format instead of Locating...
      if (state.deviceCityName == null || state.deviceCityName == 'Locating...') {
        setDeviceLocation(lat, lon, '${lat.toStringAsFixed(2)}° N, ${lon.toStringAsFixed(2)}° E');
      }
    }
  }

  Future<String?> _reverseGeocodeOnline(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=en',
      );
      final client = http.Client();
      try {
        final res = await client.get(uri).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final city = (data['city'] as String?)?.trim();
          final locality = (data['locality'] as String?)?.trim();
          final region = (data['principalSubdivision'] as String?)?.trim();
          if (locality != null && locality.isNotEmpty && locality != city) {
            return '$locality, ${city ?? region ?? ''}';
          }
          if (city != null && city.isNotEmpty) {
            return city;
          }
          if (region != null && region.isNotEmpty) {
            return region;
          }
        }
      } finally {
        client.close();
      }
    } catch (_) {}
    return null;
  }

  void setDeviceLocation(double lat, double lon, String city) {
    state = state.copyWith(
      deviceLatitude: lat,
      deviceLongitude: lon,
      deviceCityName: city,
      activeLatitude: state.isCustomSelected ? state.activeLatitude : lat,
      activeLongitude: state.isCustomSelected ? state.activeLongitude : lon,
      activeCityName: state.isCustomSelected ? state.activeCityName : city,
    );
    _persistActive();
  }

  void setLocation(double lat, double lon, String city) {
    setDeviceLocation(lat, lon, city);
  }

  void setActiveLocation(double lat, double lon, String city, {bool isCustom = true}) {
    state = state.copyWith(
      activeLatitude: lat,
      activeLongitude: lon,
      activeCityName: city,
      isCustomSelected: isCustom,
    );
    _persistActive();
  }

  void useCurrentLocation() {
    var lat = state.deviceLatitude ?? 0.0;
    var lon = state.deviceLongitude ?? 0.0;
    var city = state.deviceCityName ?? 'Current Location';

    if (city == 'Locating...') {
      city = _resolveRegionalCityName(lat, lon) ?? 'Current Location';
    }

    if (lat == 0.0 && lon == 0.0) {
      final firstSaved = state.savedLocations.firstOrNull ?? defaultStarterLocations.first;
      lat = firstSaved.latitude;
      lon = firstSaved.longitude;
      city = firstSaved.name;
    }

    state = state.copyWith(
      activeLatitude: lat,
      activeLongitude: lon,
      activeCityName: city,
      isCustomSelected: false,
    );
    _persistActive();
  }

  void setSavedLocations(List<LocationItem> items) {
    final list = items.isNotEmpty ? items : defaultStarterLocations;
    state = state.copyWith(savedLocations: list);
    _persistSavedLocations();
  }

  void addSavedLocation(LocationItem item) {
    final exists = state.savedLocations.any((loc) =>
        loc.id == item.id ||
        (loc.name.toLowerCase() == item.name.toLowerCase() &&
            (loc.latitude - item.latitude).abs() < 0.05 &&
            (loc.longitude - item.longitude).abs() < 0.05));
    if (exists) return;
    state = state.copyWith(savedLocations: [...state.savedLocations, item]);
    _persistSavedLocations();
  }

  /// Persist a geocoded place (best-effort) and make it the active location.
  /// Weather still updates even if the backend save fails.
  Future<LocationItem> saveAndSelect({
    required ApiClient apiClient,
    required String idToken,
    required String name,
    required double latitude,
    required double longitude,
    String? placeName,
  }) async {
    Map<String, dynamic>? created;
    try {
      created = await apiClient.saveLocation(
        name: name,
        latitude: latitude,
        longitude: longitude,
        idToken: idToken,
      );
    } catch (e) {
      debugPrint('saveLocation failed, activating locally: $e');
    }

    final item = LocationItem(
      id: (created?['id'] ?? 'local_${DateTime.now().millisecondsSinceEpoch}').toString(),
      name: (created?['name'] ?? name).toString(),
      latitude: (created?['latitude'] as num?)?.toDouble() ?? latitude,
      longitude: (created?['longitude'] as num?)?.toDouble() ?? longitude,
      placeName: (created?['place_name'] as String?) ?? placeName ?? name,
    );

    addSavedLocation(item);
    selectSavedLocation(item);
    return item;
  }

  Future<void> _persistCustomizedFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_customized_saved_locations', true);
    } catch (_) {}
  }

  void removeSavedLocation(String id) {
    final removed = state.savedLocations.where((loc) => loc.id == id).firstOrNull;
    final updatedList = state.savedLocations.where((loc) => loc.id != id).toList();

    // If the removed item was currently active, switch fallback to device GPS
    final wasActive = state.isCustomSelected &&
        removed != null &&
        ((state.activeLatitude - removed.latitude).abs() < 0.001 &&
            (state.activeLongitude - removed.longitude).abs() < 0.001);

    if (wasActive) {
      useCurrentLocation();
    }

    state = state.copyWith(
      savedLocations: updatedList,
    );
    _persistCustomizedFlag();
    _persistSavedLocations();
  }

  void insertSavedLocation(int index, LocationItem item) {
    final list = [...state.savedLocations];
    if (index >= 0 && index <= list.length) {
      list.insert(index, item);
    } else {
      list.add(item);
    }
    state = state.copyWith(savedLocations: list);
    _persistCustomizedFlag();
    _persistSavedLocations();
  }

  /// Select a saved location as the active location.
  /// Sets active coordinates and marks isCustomSelected so device GPS
  /// updates won't overwrite the user's explicit choice.
  void selectSavedLocation(LocationItem item) {
    setActiveLocation(
      item.latitude,
      item.longitude,
      item.placeName ?? item.name,
      isCustom: true,
    );
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);
