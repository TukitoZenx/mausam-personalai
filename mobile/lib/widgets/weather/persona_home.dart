import 'package:flutter/material.dart';

import '../../models/weather_dashboard.dart';
import 'weather_intel.dart';

/// SIH personas Mausam can actually personalize from live weather/AQI.
/// Beach/surf modules stay out until tide/wave/water-temp sources exist.
class PersonaHome {
  static const fitness = 'Fitness';
  static const health = 'Health';
  static const traveler = 'Traveler';
  static const commuter = 'Commuter';
  static const family = 'Family';
  static const garden = 'Garden';
  static const events = 'Events';

  static String normalize(String? raw) {
    final v = (raw ?? fitness).trim();
    switch (v.toLowerCase()) {
      case 'health':
      case 'health-conscious':
      case 'health sensitive':
        return health;
      case 'traveler':
      case 'travel':
        return traveler;
      case 'commuter':
      case 'commute':
        return commuter;
      case 'family':
      case 'parents':
      case 'parent':
        return family;
      case 'garden':
      case 'agriculture':
      case 'gardener':
        return garden;
      case 'events':
      case 'event':
      case 'event planner':
        return events;
      case 'beach':
      case 'surf':
        return fitness;
      default:
        return fitness;
    }
  }

  static bool showCommute(String persona) {
    final p = normalize(persona);
    return p == traveler || p == commuter || p == family;
  }

  static List<PersonaMetric> todayMetrics(String? persona, WeatherDashboard d) {
    final p = normalize(persona);
    final c = d.current;
    final uv = c.uvIndex;
    final rainMm = (c.rainMm1h != null && c.rainMm1h! > 0)
        ? c.rainMm1h!
        : (d.precipNext24hMm ?? 0);
    final rainP = d.daily.firstOrNull?.rainProbabilityPercent ?? 0;
    final feels = c.feelsLikeCelsius ?? c.temperatureCelsius;
    final low = c.lowCelsius ?? d.daily.firstOrNull?.lowCelsius;

    PersonaMetric uvCard() => PersonaMetric(
          title: 'UV INDEX',
          value: uv.toStringAsFixed(1),
          subtitle: uvCategory(uv),
          icon: Icons.wb_sunny_rounded,
          semantic: PersonaSemantic.sun,
        );
    PersonaMetric rainCard() => PersonaMetric(
          title: 'RAINFALL',
          value: '${rainMm.toStringAsFixed(1)} mm',
          subtitle: rainP > 0 ? '$rainP% chance' : 'Dry',
          icon: Icons.water_drop_rounded,
          semantic: PersonaSemantic.rain,
        );
    PersonaMetric heatCard() => PersonaMetric(
          title: 'HEAT',
          value: 'Feels ${feels.round()}°',
          subtitle: WeatherIntel.heatSupport(c),
          icon: Icons.thermostat_rounded,
          semantic: PersonaSemantic.sun,
        );
    PersonaMetric outdoorCard() => PersonaMetric(
          title: 'OUTDOOR',
          value: WeatherIntel.outdoorTitle(c, d.aqi),
          subtitle: WeatherIntel.outdoorSupport(c, d.aqi),
          icon: Icons.directions_run_rounded,
        );
    PersonaMetric humidityCard() => PersonaMetric(
          title: 'HUMIDITY',
          value: '${c.humidityPercent}%',
          subtitle: c.dewPointCelsius != null ? 'Dew ${c.dewPointCelsius!.round()}°' : 'Relative',
          icon: Icons.water_drop_outlined,
          semantic: PersonaSemantic.rain,
        );
    PersonaMetric visCard() => PersonaMetric(
          title: 'VISIBILITY',
          value: '${c.visibilityKm?.toStringAsFixed(1) ?? '--'} km',
          subtitle: visibilityLine(c.visibilityKm),
          icon: Icons.visibility_rounded,
        );
    PersonaMetric frostCard() => PersonaMetric(
          title: 'FROST RISK',
          value: (low != null && low <= 2) ? 'Watch' : 'Low',
          subtitle: low == null ? 'Overnight low pending' : 'Low ${low.round()}°',
          icon: Icons.ac_unit_rounded,
        );

    switch (p) {
      case health:
        return [uvCard(), humidityCard()];
      case traveler:
      case commuter:
        return [visCard(), rainCard()];
      case family:
        return [rainCard(), heatCard()];
      case garden:
        return [rainCard(), frostCard()];
      case events:
        return [rainCard(), heatCard()];
      default:
        return [uvCard(), outdoorCard()];
    }
  }

  static List<PersonaMetric> extraConditions(String? persona, WeatherDashboard d) {
    final p = normalize(persona);
    final c = d.current;
    final windDir = PersonaHome.windDir(c.windDirectionDeg);
    PersonaMetric wind() => PersonaMetric(
          title: 'WIND',
          value: '${c.windSpeedKmh.round()} km/h',
          subtitle: c.windDirectionDeg != null ? '${c.windDirectionDeg!.round()}° $windDir' : 'Calm',
          icon: Icons.air_rounded,
        );
    PersonaMetric pressure() {
      final hpa = (c.pressureHpa ?? 1013).round();
      return PersonaMetric(
        title: 'PRESSURE',
        value: '$hpa mbar',
        subtitle: hpa < 1005 ? 'Falling' : (hpa > 1020 ? 'Rising' : 'Steady'),
        icon: Icons.speed_rounded,
      );
    }

    PersonaMetric humidity() => PersonaMetric(
          title: 'HUMIDITY',
          value: '${c.humidityPercent}%',
          subtitle: c.dewPointCelsius != null ? 'Dew ${c.dewPointCelsius!.round()}°' : 'Relative',
          icon: Icons.water_drop_outlined,
          semantic: PersonaSemantic.rain,
        );

    switch (p) {
      case health:
        return [pressure(), wind()];
      case commuter:
      case traveler:
      case family:
        return [wind(), PersonaMetric(
          title: 'VISIBILITY',
          value: '${c.visibilityKm?.toStringAsFixed(1) ?? '--'} km',
          subtitle: visibilityLine(c.visibilityKm),
          icon: Icons.visibility_rounded,
        )];
      case garden:
        return [wind(), pressure()];
      default:
        return [wind(), humidity()];
    }
  }

  static List<PersonaMetric> contextual(String? persona, WeatherDashboard d) {
    final p = normalize(persona);
    final c = d.current;
    final items = <PersonaMetric>[];

    if (showCommute(p)) {
      items.add(PersonaMetric(
        title: p == family ? 'SCHOOL RUN' : 'COMMUTE',
        value: WeatherIntel.commuteStatus(c),
        subtitle: WeatherIntel.isWet(c) ? 'Wet roads' : '${c.visibilityKm?.toStringAsFixed(1) ?? '--'} km sight',
        icon: Icons.commute_rounded,
        semantic: WeatherIntel.commuteIsSevere(c)
            ? PersonaSemantic.severe
            : (WeatherIntel.commuteIsCaution(c) ? PersonaSemantic.warn : PersonaSemantic.none),
        wide: true,
      ));
    }

    switch (p) {
      case health:
        if (d.aqi != null) {
          items.add(PersonaMetric(
            title: 'AIR',
            value: WeatherIntel.airTitle(d.aqi),
            subtitle: WeatherIntel.airSupport(d.aqi),
            icon: Icons.air_rounded,
          ));
        }
        break;
      case fitness:
        items.add(PersonaMetric(
          title: 'WORKOUT',
          value: WeatherIntel.outdoorTitle(c, d.aqi),
          subtitle: WeatherIntel.outdoorSupport(c, d.aqi),
          icon: Icons.directions_run_rounded,
        ));
        break;
      case garden:
        final low = c.lowCelsius ?? d.daily.firstOrNull?.lowCelsius;
        items.add(PersonaMetric(
          title: 'GROWING DAY',
          value: WeatherIntel.isWet(c) ? 'Wet soils' : 'Open air',
          subtitle: low != null && low <= 2 ? 'Frost watch overnight' : '${c.humidityPercent}% humidity',
          icon: Icons.grass_rounded,
        ));
        break;
      case events:
        final rainP = d.daily.firstOrNull?.rainProbabilityPercent ?? 0;
        items.add(PersonaMetric(
          title: 'OUTDOOR EVENT',
          value: rainP >= 40 ? 'Cover needed' : 'Go ahead',
          subtitle: '$rainP% rain · feels ${(c.feelsLikeCelsius ?? c.temperatureCelsius).round()}°',
          icon: Icons.event_rounded,
        ));
        break;
      default:
        break;
    }

    return items.take(3).toList();
  }

  static String windDir(double? deg) {
    if (deg == null) return '--';
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return dirs[(((deg + 22.5) % 360) / 45).floor() % 8];
  }
}

enum PersonaSemantic { none, sun, rain, moon, warn, severe }

class PersonaMetric {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final PersonaSemantic semantic;
  final bool wide;

  const PersonaMetric({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.semantic = PersonaSemantic.none,
    this.wide = false,
  });
}
