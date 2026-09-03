import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/weather_dashboard.dart';
import 'auth_provider.dart';
import 'location_provider.dart';
import 'user_provider.dart';

class WeatherDashboardState {
  final bool isLoading;
  final String? errorMessage;
  final WeatherDashboard? data;

  const WeatherDashboardState({
    this.isLoading = false,
    this.errorMessage,
    this.data,
  });

  WeatherDashboardState copyWith({
    bool? isLoading,
    String? errorMessage,
    WeatherDashboard? data,
    bool clearError = false,
  }) {
    return WeatherDashboardState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      data: data ?? this.data,
    );
  }
}

class WeatherDashboardNotifier extends Notifier<WeatherDashboardState> {
  @override
  WeatherDashboardState build() {
    ref.listen(
      locationProvider.select((l) => '${l.activeLatitude},${l.activeLongitude}'),
      (prev, next) {
        if (prev != next) {
          fetchDashboard();
        }
      },
    );
    return const WeatherDashboardState();
  }

  Future<void> fetchDashboard({bool forceRefresh = false}) async {
    final locationState = ref.read(locationProvider);
    final userState = ref.read(userProvider);
    final apiClient = ref.read(apiClientProvider);
    final idToken = userState.idToken ?? 'test_token';
    double lat = locationState.activeLatitude;
    double lon = locationState.activeLongitude;
    if (lat == 0.0 && lon == 0.0) {
      lat = 28.6139;
      lon = 77.2090;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      Map<String, dynamic>? aqiJson;
      final forecastJson = await apiClient.fetchWeatherForecast(
        lat: lat,
        lon: lon,
        idToken: idToken,
      );
      try {
        aqiJson = await apiClient.fetchCurrentAqi(lat: lat, lon: lon, idToken: idToken);
      } catch (_) {
        aqiJson = null;
      }
      state = WeatherDashboardState(
        isLoading: false,
        data: WeatherDashboard.fromForecastJson(forecastJson, aqiJson: aqiJson),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final weatherDashboardProvider =
    NotifierProvider<WeatherDashboardNotifier, WeatherDashboardState>(WeatherDashboardNotifier.new);
