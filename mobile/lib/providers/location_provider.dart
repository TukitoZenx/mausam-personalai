import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

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

class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() {
    return const LocationState();
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
  }

  void useCurrentLocation() {
    state = state.copyWith(
      activeLatitude: state.deviceLatitude ?? 0.0,
      activeLongitude: state.deviceLongitude ?? 0.0,
      activeCityName: state.deviceCityName ?? 'Current Location',
      isCustomSelected: false,
    );
  }

  void setSavedLocations(List<LocationItem> items) {
    state = state.copyWith(savedLocations: items);
  }

  void addSavedLocation(LocationItem item) {
    state = state.copyWith(savedLocations: [...state.savedLocations, item]);
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
