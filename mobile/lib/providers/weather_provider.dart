import 'package:flutter_riverpod/flutter_riverpod.dart';

class WeatherState {
  final double? temperature;
  final String? condition;
  final int? aqi;
  final bool isLoading;

  const WeatherState({
    this.temperature,
    this.condition,
    this.aqi,
    this.isLoading = false,
  });
}

class WeatherNotifier extends Notifier<WeatherState> {
  @override
  WeatherState build() {
    return const WeatherState();
  }

  void setWeather(double temp, String cond, int aqiVal) {
    state = WeatherState(
      temperature: temp,
      condition: cond,
      aqi: aqiVal,
      isLoading: false,
    );
  }
}

final weatherProvider = NotifierProvider<WeatherNotifier, WeatherState>(WeatherNotifier.new);
