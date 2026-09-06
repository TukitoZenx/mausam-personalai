import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/weather_dashboard.dart';
import '../services/open_meteo_weather_service.dart';
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

const _kWeatherCache = 'weather_dashboard_cache_v1';

class WeatherDashboardNotifier extends Notifier<WeatherDashboardState> {
  bool _cacheHydrated = false;

  @override
  WeatherDashboardState build() {
    ref.listen(
      locationProvider.select((l) => '${l.activeLatitude},${l.activeLongitude}'),
      (prev, next) {
        if (prev != next && next != '0.0,0.0') {
          fetchDashboard();
        }
      },
    );
    _hydrateCache();
    return const WeatherDashboardState();
  }

  Future<void> _hydrateCache() async {
    if (_cacheHydrated) return;
    _cacheHydrated = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kWeatherCache);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final map = Map<String, dynamic>.from(decoded);
      final forecast = map['forecast'];
      if (forecast is! Map) return;
      final aqi = map['aqi'];
      state = state.copyWith(
        data: WeatherDashboard.fromForecastJson(
          Map<String, dynamic>.from(forecast),
          aqiJson: aqi is Map ? Map<String, dynamic>.from(aqi) : null,
        ),
      );
    } catch (_) {}
  }

  Future<void> _persistCache({
    required Map<String, dynamic> forecast,
    Map<String, dynamic>? aqi,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kWeatherCache,
        jsonEncode({'forecast': forecast, 'aqi': aqi}),
      );
    } catch (_) {}
  }

  Future<void> fetchDashboard({bool forceRefresh = false}) async {
    await _hydrateCache();
    final locationState = ref.read(locationProvider);
    final userState = ref.read(userProvider);
    final apiClient = ref.read(apiClientProvider);
    final idToken = userState.idToken ?? 'test_token';
    var lat = locationState.activeLatitude;
    var lon = locationState.activeLongitude;
    if (lat == 0.0 && lon == 0.0) {
      await ref.read(locationProvider.notifier).restorePersisted();
      lat = ref.read(locationProvider).activeLatitude;
      lon = ref.read(locationProvider).activeLongitude;
    }
    if (lat == 0.0 && lon == 0.0) {
      lat = 28.6139;
      lon = 77.2090;
    }

    final hasData = state.data != null;
    if (!hasData) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      Map<String, dynamic>? aqiJson;
      Map<String, dynamic> forecastJson;
      try {
        forecastJson = await apiClient.fetchWeatherForecast(
          lat: lat,
          lon: lon,
          idToken: idToken,
        );
        try {
          aqiJson = await apiClient.fetchCurrentAqi(lat: lat, lon: lon, idToken: idToken);
        } catch (_) {
          aqiJson = null;
        }
      } catch (_) {
        final remote = OpenMeteoWeatherService();
        final name = ref.read(locationProvider).cityName;
        forecastJson = await remote.fetchForecast(
          lat: lat,
          lon: lon,
          locationName: name.isNotEmpty ? name : 'Active Location',
        );
        aqiJson = await remote.fetchAqi(lat: lat, lon: lon);
      }
      if (aqiJson == null) {
        try {
          aqiJson = await OpenMeteoWeatherService().fetchAqi(lat: lat, lon: lon);
        } catch (_) {}
      }
      state = WeatherDashboardState(
        isLoading: false,
        data: WeatherDashboard.fromForecastJson(forecastJson, aqiJson: aqiJson),
      );
      await _persistCache(forecast: forecastJson, aqi: aqiJson);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: hasData ? null : e.toString(),
      );
    }
  }
}

final weatherDashboardProvider =
    NotifierProvider<WeatherDashboardNotifier, WeatherDashboardState>(WeatherDashboardNotifier.new);
