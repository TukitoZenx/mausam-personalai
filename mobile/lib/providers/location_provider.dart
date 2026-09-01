import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    this.activeLatitude = 12.9716, // Default: Bengaluru
    this.activeLongitude = 77.5946,
    this.activeCityName = 'Bengaluru',
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

  void setDeviceLocation(double lat, double lon, String city) {
    state = state.copyWith(
      deviceLatitude: lat,
      deviceLongitude: lon,
      deviceCityName: city,
      // If user hasn't explicitly selected a saved location, set active location to device GPS
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
    if (state.deviceLatitude != null && state.deviceLongitude != null) {
      state = state.copyWith(
        activeLatitude: state.deviceLatitude,
        activeLongitude: state.deviceLongitude,
        activeCityName: state.deviceCityName ?? 'Current Location',
        isCustomSelected: false,
      );
    } else {
      state = state.copyWith(
        activeLatitude: 12.9716,
        activeLongitude: 77.5946,
        activeCityName: 'Bengaluru',
        isCustomSelected: false,
      );
    }
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
}

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);
