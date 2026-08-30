import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationState {
  final double? latitude;
  final double? longitude;
  final String? cityName;
  final bool isLoading;

  const LocationState({
    this.latitude,
    this.longitude,
    this.cityName,
    this.isLoading = false,
  });
}

class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() {
    return const LocationState();
  }

  void setLocation(double lat, double lon, String city) {
    state = LocationState(
      latitude: lat,
      longitude: lon,
      cityName: city,
      isLoading: false,
    );
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);
