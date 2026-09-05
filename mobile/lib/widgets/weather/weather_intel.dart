import '../../models/weather_dashboard.dart';

/// Derived labels from live dashboard fields only. Never invents readings.
class WeatherIntel {
  WeatherIntel._();

  static String _fmtUnix(int? unix, int? offsetSec) {
    if (unix == null) return '--';
    final dt = DateTime.fromMillisecondsSinceEpoch(unix * 1000, isUtc: true)
        .add(Duration(seconds: offsetSec ?? 0));
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _fmtHm(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static DateTime? _localFromUnix(int? unix, int? offsetSec) {
    if (unix == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(unix * 1000, isUtc: true)
        .add(Duration(seconds: offsetSec ?? 0));
  }

  /// Evening golden hour is the ~50 minutes before sunset.
  static String? goldenHourWindow(CurrentConditions current) {
    final sunset = _localFromUnix(current.sunsetUnix, current.timezoneOffsetSec);
    if (sunset == null) return null;
    final start = sunset.subtract(const Duration(minutes: 50));
    return '${_fmtHm(start)}–${_fmtHm(sunset)}';
  }

  static String? sunriseLabel(CurrentConditions current) =>
      current.sunriseUnix == null ? null : _fmtUnix(current.sunriseUnix, current.timezoneOffsetSec);

  static String? sunsetLabel(CurrentConditions current) =>
      current.sunsetUnix == null ? null : _fmtUnix(current.sunsetUnix, current.timezoneOffsetSec);

  static bool isWet(CurrentConditions current) {
    final rain = current.rainMm1h ?? 0;
    final cond = current.condition.toLowerCase();
    return rain > 0 ||
        cond.contains('rain') ||
        cond.contains('drizzle') ||
        cond.contains('shower') ||
        cond.contains('thunder');
  }

  static String commuteStatus(CurrentConditions current) {
    final rain = current.rainMm1h ?? 0;
    if (isWet(current) && rain >= 3.0) return 'DISRUPTED';
    if (isWet(current)) return 'WET ROADS';
    if (current.visibilityKm != null && current.visibilityKm! < 4.0) return 'LOW VIS';
    if (current.windSpeedKmh >= 35) return 'GUSTY';
    return 'CLEAR';
  }

  static bool commuteIsSevere(CurrentConditions current) {
    final status = commuteStatus(current);
    return status == 'DISRUPTED';
  }

  static bool commuteIsCaution(CurrentConditions current) {
    final status = commuteStatus(current);
    return status == 'WET ROADS' || status == 'LOW VIS' || status == 'GUSTY';
  }

  static String commuteAction(CurrentConditions current) {
    switch (commuteStatus(current)) {
      case 'DISRUPTED':
        return 'Allow extra time. Roads are wet and visibility is reduced.';
      case 'WET ROADS':
        return 'Carry cover and add a few minutes for slower traffic.';
      case 'LOW VIS':
        return 'Reduce speed. Sight distance is shorter than usual.';
      case 'GUSTY':
        return 'Expect crosswinds. Secure loose items if you are outdoors.';
      default:
        return 'Travel conditions are stable under ${current.condition}.';
    }
  }

  static String outdoorTitle(CurrentConditions current, AqiSnapshot? aqi) {
    if (isWet(current)) return 'Indoor';
    if (current.temperatureCelsius >= 33) return 'Early / late';
    if (aqi != null && aqi.aqiValue >= 150) return 'Limit outdoor';
    return 'Good to go';
  }

  static String outdoorSupport(CurrentConditions current, AqiSnapshot? aqi) {
    if (isWet(current)) return current.condition;
    if (current.temperatureCelsius >= 33) {
      return '${current.temperatureCelsius.round()}° heat';
    }
    if (aqi != null && aqi.aqiValue >= 150) return 'AQI ${aqi.aqiValue}';
    return '${current.temperatureCelsius.round()}° · UV ${current.uvIndex.toStringAsFixed(1)}';
  }

  static String airTitle(AqiSnapshot? aqi) {
    if (aqi == null) return '—';
    return aqi.category;
  }

  static String airSupport(AqiSnapshot? aqi) {
    if (aqi == null) return 'Air quality unavailable';
    return 'AQI ${aqi.aqiValue} · ${aqi.mainPollutantLabel}';
  }

  static String heatSupport(CurrentConditions current) {
    final feels = current.feelsLikeCelsius ?? current.temperatureCelsius;
    final delta = (feels - current.temperatureCelsius).round();
    if (delta.abs() >= 1) {
      return '${delta.abs()}° ${delta > 0 ? 'warmer' : 'cooler'} than actual';
    }
    return 'Matches actual temperature';
  }
}
