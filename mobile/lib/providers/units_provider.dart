import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnitsState {
  final bool isCelsius;
  final bool isKmh;

  const UnitsState({
    this.isCelsius = true,
    this.isKmh = true,
  });

  UnitsState copyWith({
    bool? isCelsius,
    bool? isKmh,
  }) {
    return UnitsState(
      isCelsius: isCelsius ?? this.isCelsius,
      isKmh: isKmh ?? this.isKmh,
    );
  }

  /// Converts Celsius temperature to active unit and returns integer rounded value.
  int formatTemp(double? celsius) {
    if (celsius == null) return 0;
    if (isCelsius) {
      return celsius.round();
    } else {
      return ((celsius * 9 / 5) + 32).round();
    }
  }

  String formatTempString(double? celsius) {
    if (celsius == null) return '--°';
    return '${formatTemp(celsius)}°';
  }

  String get tempUnitLabel => isCelsius ? '°C' : '°F';

  /// Converts km/h wind speed to active unit and returns formatted string.
  String formatWind(double? kmh) {
    if (kmh == null) return isKmh ? '0 km/h' : '0 mph';
    if (isKmh) {
      return '${kmh.round()} km/h';
    } else {
      final mph = (kmh * 0.621371).round();
      return '$mph mph';
    }
  }

  String get windUnitLabel => isKmh ? 'km/h' : 'mph';
}

class UnitsNotifier extends Notifier<UnitsState> {
  static const _kPrefTempCelsius = 'pref_temp_celsius';
  static const _kPrefWindKmh = 'pref_wind_kmh';

  @override
  UnitsState build() {
    _loadFromPrefs();
    return const UnitsState();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isCelsius = prefs.getBool(_kPrefTempCelsius) ?? true;
      final isKmh = prefs.getBool(_kPrefWindKmh) ?? true;
      state = UnitsState(isCelsius: isCelsius, isKmh: isKmh);
    } catch (_) {}
  }

  Future<void> setTempCelsius(bool isCelsius) async {
    state = state.copyWith(isCelsius: isCelsius);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPrefTempCelsius, isCelsius);
    } catch (_) {}
  }

  Future<void> setWindKmh(bool isKmh) async {
    state = state.copyWith(isKmh: isKmh);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPrefWindKmh, isKmh);
    } catch (_) {}
  }
}

final unitsProvider = NotifierProvider<UnitsNotifier, UnitsState>(UnitsNotifier.new);
