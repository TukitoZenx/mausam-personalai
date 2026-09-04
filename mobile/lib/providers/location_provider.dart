import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
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

class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() {
    return const LocationState();
  }

  Future<void> restorePersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_kActiveLat);
      final lon = prefs.getDouble(_kActiveLon);
      final name = prefs.getString(_kActiveName);
      final custom = prefs.getBool(_kCustomSelected) ?? false;
      if (lat != null && lon != null && name != null && name.isNotEmpty) {
        state = state.copyWith(
          activeLatitude: lat,
          activeLongitude: lon,
          activeCityName: name,
          isCustomSelected: custom,
        );
      }
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
      setSavedLocations(items);
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
        state = state.copyWith(activeCityName: 'Current Location');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied.');
          state = state.copyWith(activeCityName: 'Current Location');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied.');
        state = state.copyWith(activeCityName: 'Current Location');
        return;
      }

      // First check last known position for fast initial fix
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        setDeviceLocation(position.latitude, position.longitude, state.deviceCityName ?? 'Locating...');
        await _fetchReverseGeocode(apiClient, position.latitude, position.longitude, idToken);
      }

      // Fetch fresh high accuracy current GPS position
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
        setDeviceLocation(
          position.latitude,
          position.longitude,
          state.deviceCityName ?? 'Locating...',
        );
        await _fetchReverseGeocode(apiClient, position.latitude, position.longitude, idToken);
      } catch (e) {
        debugPrint('getCurrentPosition error: $e');
      }
    } catch (e) {
      debugPrint('Device location detection error: $e');
    }
  }

  Future<void> _fetchReverseGeocode(
    ApiClient apiClient,
    double lat,
    double lon,
    String idToken,
  ) async {
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
    }
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
    state = state.copyWith(
      activeLatitude: state.deviceLatitude ?? 0.0,
      activeLongitude: state.deviceLongitude ?? 0.0,
      activeCityName: state.deviceCityName ?? 'Current Location',
      isCustomSelected: false,
    );
    _persistActive();
  }

  void setSavedLocations(List<LocationItem> items) {
    state = state.copyWith(savedLocations: items);
  }

  void addSavedLocation(LocationItem item) {
    final exists = state.savedLocations.any((loc) =>
        loc.id == item.id ||
        (loc.name.toLowerCase() == item.name.toLowerCase() &&
            (loc.latitude - item.latitude).abs() < 0.05 &&
            (loc.longitude - item.longitude).abs() < 0.05));
    if (exists) return;
    state = state.copyWith(savedLocations: [...state.savedLocations, item]);
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

  void removeSavedLocation(String id) {
    state = state.copyWith(
      savedLocations: state.savedLocations.where((loc) => loc.id != id).toList(),
    );
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
