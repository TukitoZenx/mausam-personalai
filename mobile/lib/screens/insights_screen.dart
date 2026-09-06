import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/home_card.dart';
import '../models/weather_dashboard.dart';
import '../providers/homepage_provider.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';
import '../providers/weather_dashboard_provider.dart';
import '../theme/weather_palette.dart';
import '../widgets/navigation/shell_section_title.dart';
import '../widgets/staggered_item_wrapper.dart';
import '../widgets/weather/weather_intel.dart';
import '../widgets/weather/weather_sections.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homepageProvider);
    final userState = ref.watch(userProvider);
    final locationState = ref.watch(locationProvider);
    final weatherDash = ref.watch(weatherDashboardProvider);

    final activePersona = userState.selectedPersona ?? homeState.data?.persona ?? 'Fitness';
    final cards = homeState.data?.cards ?? [];
    final data = weatherDash.data;
    final locationLabel = locationState.cityName.isNotEmpty
        ? locationState.cityName
        : (data?.current.location ?? 'Active Location');

    final forYou = cards.isNotEmpty ? cards.first : null;
    final windows = data == null
        ? const <_BestWindow>[]
        : _computeBestWindows(persona: activePersona, hourly: data.hourly, current: data.current, aqi: data.aqi);

    return RefreshIndicator(
      color: MausamPalette.textPrimary,
      backgroundColor: MausamPalette.cardSurface,
      onRefresh: () async {
        await ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true);
        await ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 72, 16, 100),
        children: [
          const ShellSectionTitle('INSIGHTS'),
          StaggeredItemWrapper(
                index: 0,
                child: _MetaStrip(
                  persona: activePersona,
                  location: locationLabel,
                  summary: homeState.effectiveSummaryInsight,
                ),
              ),
              const SizedBox(height: 20),
              _sectionLabel('FOR YOU'),
              const SizedBox(height: 10),
              if (forYou != null)
                StaggeredItemWrapper(
                  index: 1,
                  child: _InsightPanel(
                    kicker: activePersona.toUpperCase(),
                    icon: Icons.auto_awesome_rounded,
                    title: forYou.title ?? 'Personalized recommendation',
                    body: [
                      if (forYou.subtitle != null && forYou.subtitle!.isNotEmpty) forYou.subtitle!,
                      if (forYou.effectiveReason.isNotEmpty) forYou.effectiveReason,
                    ].where((s) => s.isNotEmpty).join('\n'),
                  ),
                )
              else
                _emptyPanel('Live recommendation is updating for this location.'),
              if (data != null) ...[
                const SizedBox(height: 20),
                _sectionLabel('WHAT TO DO'),
                const SizedBox(height: 10),
                StaggeredItemWrapper(
                  index: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _InsightPanel(
                      kicker: 'COMMUTE',
                      icon: Icons.commute_rounded,
                      title: WeatherIntel.commuteStatus(data.current),
                      body: WeatherIntel.commuteAction(data.current),
                    ),
                  ),
                ),
                StaggeredItemWrapper(
                  index: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _InsightPanel(
                      kicker: 'OUTDOOR',
                      icon: Icons.directions_run_rounded,
                      title: WeatherIntel.outdoorTitle(data.current, data.aqi),
                      body: WeatherIntel.outdoorSupport(data.current, data.aqi),
                    ),
                  ),
                ),
                if (WeatherIntel.goldenHourWindow(data.current) != null)
                  StaggeredItemWrapper(
                    index: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _InsightPanel(
                        kicker: 'GOLDEN HOUR',
                        icon: Icons.wb_twilight_rounded,
                        title: WeatherIntel.goldenHourWindow(data.current)!,
                        body: 'Soft light before sunset. Better for walks than midday UV.',
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                _sectionLabel('HEALTH METRICS'),
                const SizedBox(height: 10),
                if (data.aqi != null)
                  StaggeredItemWrapper(
                    index: 5,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AqiGaugeCard(aqi: data.aqi!),
                    ),
                  ),
                StaggeredItemWrapper(
                  index: 6,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HealthPrecautionsCard(
                      aqi: data.aqi,
                      current: data.current,
                      triggers: userState.weatherTriggers,
                      concerns: userState.healthConcerns,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              _sectionLabel('BEST TIME'),
              const SizedBox(height: 10),
              if (windows.isEmpty)
                _emptyPanel('Hourly forecast is still loading for this location.')
              else
                for (int i = 0; i < windows.length; i++)
                  StaggeredItemWrapper(
                    index: 2 + i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _InsightPanel(
                        kicker: windows[i].kicker,
                        icon: Icons.schedule_rounded,
                        title: windows[i].title,
                        body: windows[i].reason,
                      ),
                    ),
                  ),
              const SizedBox(height: 10),
              _sectionLabel(activePersona.toUpperCase()),
              const SizedBox(height: 10),
              if (data != null)
                StaggeredItemWrapper(
                  index: 6,
                  child: _PersonaLayer(
                    persona: activePersona,
                    current: data.current,
                    aqi: data.aqi,
                    hourly: data.hourly,
                  ),
                ),
              const SizedBox(height: 20),
              if (cards.length > 1) ...[
                _sectionLabel('PERSONALIZED GUIDANCE'),
                const SizedBox(height: 10),
                for (int i = 1; i < cards.length; i++)
                  StaggeredItemWrapper(
                    index: 8 + i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _GuidanceCard(card: cards[i]),
                    ),
                  ),
              ],
            ],
          ),
    );
  }
}

Widget _sectionLabel(String text) {
  return Text(
    text,
    style: GoogleFonts.inter(
      color: MausamPalette.textTertiary,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
  );
}

Widget _emptyPanel(String message) {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: MausamPalette.cardSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: MausamPalette.cardBorder),
    ),
    child: Text(message, style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 13)),
  );
}

class _MetaStrip extends StatelessWidget {
  final String persona;
  final String location;
  final String summary;

  const _MetaStrip({required this.persona, required this.location, required this.summary});

  @override
  Widget build(BuildContext context) {
    final icon = persona == 'Health'
        ? Icons.favorite_rounded
        : persona == 'Traveler'
            ? Icons.flight_takeoff_rounded
            : Icons.directions_run_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MausamPalette.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MausamPalette.cardBorder),
        boxShadow: MausamPalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: MausamPalette.textPrimary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$persona intelligence',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: MausamPalette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  final String kicker;
  final IconData icon;
  final String title;
  final String body;

  const _InsightPanel({
    required this.kicker,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MausamPalette.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MausamPalette.cardBorder),
        boxShadow: MausamPalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: MausamPalette.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  kicker,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: MausamPalette.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.inter(
              color: MausamPalette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              body,
              style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 13, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  final RankedHomeCard card;
  const _GuidanceCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MausamPalette.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MausamPalette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (card.category != null && card.category!.isNotEmpty)
            Text(
              card.category!.toUpperCase(),
              style: GoogleFonts.inter(
                color: MausamPalette.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          if (card.title != null && card.title!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              card.title!,
              style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
          if (card.subtitle != null && card.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(card.subtitle!, style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 13)),
          ],
          if (card.effectiveReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(card.effectiveReason, style: GoogleFonts.inter(color: MausamPalette.textTertiary, fontSize: 12, height: 1.35)),
          ],
        ],
      ),
    );
  }
}

class _PersonaLayer extends StatelessWidget {
  final String persona;
  final CurrentConditions current;
  final AqiSnapshot? aqi;
  final List<HourlyForecastItem> hourly;

  const _PersonaLayer({
    required this.persona,
    required this.current,
    required this.aqi,
    required this.hourly,
  });

  @override
  Widget build(BuildContext context) {
    final lines = switch (persona) {
      'Health' => _healthLines(),
      'Traveler' => _travelerLines(),
      'Commuter' => _commuterLines(),
      'Family' => _familyLines(),
      'Garden' => _gardenLines(),
      'Events' => _eventsLines(),
      _ => _fitnessLines(),
    };

    return Column(
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _InsightPanel(
              kicker: persona.toUpperCase(),
              icon: line.icon,
              title: line.title,
              body: line.body,
            ),
          ),
      ],
    );
  }

  List<_Line> _fitnessLines() {
    final temp = current.temperatureCelsius;
    final rain = current.rainMm1h ?? 0;
    final humidity = current.humidityPercent;
    final cond = current.condition.toLowerCase();
    final raining = rain > 0 || cond.contains('rain') || cond.contains('drizzle');

    String suitability;
    String detail;
    if (raining) {
      suitability = 'Indoor session preferred';
      detail = '${current.condition} with ${rain.toStringAsFixed(1)} mm recently. Shift the workout inside and keep intensity moderate.';
    } else if (temp >= 33) {
      suitability = 'Heat-limited outdoor effort';
      detail = 'Air is ${temp.round()}°C with $humidity% humidity. Shorten the outdoor block, hydrate, and avoid peak sun.';
    } else if (temp <= 12) {
      suitability = 'Cold-weather warm-up required';
      detail = '${temp.round()}°C outside. Extend the warm-up and prefer a layered run or indoor strength.';
    } else {
      suitability = 'Outdoor training is viable';
      detail = '${temp.round()}°C, $humidity% humidity, wind ${current.windSpeedKmh.round()} km/h. A steady outdoor session is reasonable now.';
    }

    final uv = current.uvIndex;
    final uvLine = uv >= 6
        ? 'UV is ${uv.toStringAsFixed(1)}. Use SPF and avoid bare-skin intervals at midday.'
        : 'UV is ${uv.toStringAsFixed(1)} — sun load is manageable for a standard session.';

    return [
      _Line(Icons.directions_run_rounded, suitability, detail),
      _Line(Icons.wb_sunny_outlined, 'Exposure', uvLine),
    ];
  }

  List<_Line> _healthLines() {
    final aqiVal = aqi?.aqiValue ?? 0;
    final cat = aqi?.category ?? 'unknown';
    String aqiTitle;
    String aqiBody;
    if (aqiVal >= 150) {
      aqiTitle = 'Stay indoor if sensitive';
      aqiBody = 'AQI $aqiVal ($cat). Limit outdoor exertion and consider a mask if you must go out.';
    } else if (aqiVal >= 80) {
      aqiTitle = 'Shorten outdoor exposure';
      aqiBody = 'AQI $aqiVal ($cat). Keep outdoor time brief and avoid heavy breathing workouts.';
    } else {
      aqiTitle = 'Air quality is acceptable';
      aqiBody = 'AQI $aqiVal ($cat). Outdoor time is reasonable for most people right now.';
    }

    final temp = current.temperatureCelsius;
    final humidity = current.humidityPercent;
    final heat = temp >= 32
        ? 'Heat stress risk at ${temp.round()}°C and $humidity% humidity. Hydrate and rest in shade.'
        : 'Thermal load is moderate at ${temp.round()}°C. Maintain usual hydration.';

    return [
      _Line(Icons.air_rounded, aqiTitle, aqiBody),
      _Line(Icons.thermostat_rounded, 'Weather precaution', heat),
    ];
  }

  List<_Line> _travelerLines() {
    final cond = current.condition.toLowerCase();
    final rain = current.rainMm1h ?? 0;
    final raining = rain > 0 || cond.contains('rain') || cond.contains('drizzle') || cond.contains('thunder');
    final temp = current.temperatureCelsius;
    final wind = current.windSpeedKmh;

    final commute = raining
        ? 'Expect wet travel. Carry an umbrella and add buffer for slower roads.'
        : wind >= 25
            ? 'Gusts at ${wind.round()} km/h. Allow extra time and secure loose items.'
            : 'Travel conditions are relatively stable under ${current.condition}.';

    String packing;
    if (raining) {
      packing = 'Umbrella, waterproof layer, closed shoes.';
    } else if (temp >= 32) {
      packing = 'Cap, sunscreen, water bottle. Avoid long midday walks.';
    } else if (temp <= 16) {
      packing = 'Light jacket. Evenings will feel cooler than the afternoon reading.';
    } else {
      packing = 'Standard day kit. Sunglasses if you will be outdoors through noon.';
    }

    return [
      _Line(Icons.directions_transit_rounded, 'Travel guidance', commute),
      _Line(Icons.work_outline_rounded, 'What to carry', packing),
    ];
  }

  List<_Line> _commuterLines() {
    return [
      _Line(Icons.commute_rounded, WeatherIntel.commuteStatus(current), WeatherIntel.commuteAction(current)),
      _Line(
        Icons.visibility_rounded,
        visibilityLine(current.visibilityKm),
        'Wind ${current.windSpeedKmh.round()} km/h. Leave extra time if fog or rain is in the next hours.',
      ),
    ];
  }

  List<_Line> _familyLines() {
    final rain = current.rainMm1h ?? 0;
    final wet = WeatherIntel.isWet(current);
    return [
      _Line(
        Icons.school_rounded,
        wet ? 'Wet school run' : 'School run is clear',
        wet
            ? 'Rain ${rain.toStringAsFixed(1)} mm. Pack covers and allow extra drop-off time.'
            : 'Roads look stable. Keep a light layer for the afternoon.',
      ),
      _Line(
        Icons.warning_amber_rounded,
        current.temperatureCelsius >= 36 ? 'Heat caution for kids' : 'Outdoor play is reasonable',
        'Air ${current.temperatureCelsius.round()}° · UV ${current.uvIndex.toStringAsFixed(1)}.',
      ),
    ];
  }

  List<_Line> _gardenLines() {
    final low = current.lowCelsius;
    final rain = current.rainMm1h ?? 0;
    return [
      _Line(
        Icons.grass_rounded,
        rain > 0 ? 'Soils are receiving rain' : 'Open, drier air',
        rain > 0
            ? '${rain.toStringAsFixed(1)} mm recently. Skip extra watering today.'
            : 'Humidity ${current.humidityPercent}%. Water only if beds are dry.',
      ),
      _Line(
        Icons.ac_unit_rounded,
        (low != null && low <= 2) ? 'Frost watch overnight' : 'Frost risk is low',
        low == null ? 'Overnight low still updating.' : 'Expected low ${low.round()}°.',
      ),
    ];
  }

  List<_Line> _eventsLines() {
    final rainP = hourly.isEmpty
        ? 0
        : hourly.take(8).map((e) => e.rainProbabilityPercent).fold<int>(0, (a, b) => a > b ? a : b);
    return [
      _Line(
        Icons.event_rounded,
        rainP >= 40 ? 'Cover the outdoor plan' : 'Outdoor event looks viable',
        '$rainP% rain in the next hours. Comfort around ${(current.feelsLikeCelsius ?? current.temperatureCelsius).round()}°.',
      ),
      _Line(
        Icons.wb_sunny_outlined,
        'UV ${current.uvIndex.toStringAsFixed(1)}',
        current.uvIndex >= 6 ? 'Provide shade for midday guests.' : 'Sun load is moderate for an outdoor gathering.',
      ),
    ];
  }
}

class _Line {
  final IconData icon;
  final String title;
  final String body;
  const _Line(this.icon, this.title, this.body);
}

class _BestWindow {
  final String kicker;
  final String title;
  final String reason;
  const _BestWindow({required this.kicker, required this.title, required this.reason});
}

List<_BestWindow> _computeBestWindows({
  required String persona,
  required List<HourlyForecastItem> hourly,
  required CurrentConditions current,
  AqiSnapshot? aqi,
}) {
  if (hourly.isEmpty) return const [];
  final scored = <({HourlyForecastItem slot, double score, String why})>[];

  for (final slot in hourly.take(16)) {
    final temp = slot.temperatureCelsius;
    final rainP = slot.rainProbabilityPercent;
    final cond = slot.condition.toLowerCase();
    var score = 50.0;
    final reasons = <String>[];

    if (persona == 'Fitness') {
      if (temp >= 16 && temp <= 28) {
        score += 25;
        reasons.add('${temp.round()}°C is a workable training range');
      } else if (temp > 32) {
        score -= 25;
        reasons.add('heat at ${temp.round()}°C');
      } else {
        reasons.add('${temp.round()}°C');
      }
      if (rainP < 25 && !cond.contains('rain')) {
        score += 15;
      } else {
        score -= 20;
        reasons.add('$rainP% rain chance');
      }
    } else if (persona == 'Health') {
      if (temp < 32) {
        score += 15;
        reasons.add('${temp.round()}°C thermal load');
      } else {
        score -= 20;
        reasons.add('heat stress at ${temp.round()}°C');
      }
      if (rainP < 40) {
        score += 8;
      }
      final aqiVal = aqi?.aqiValue ?? 80;
      if (aqiVal < 80) {
        score += 12;
        reasons.add('current AQI $aqiVal');
      } else {
        score -= 10;
        reasons.add('AQI $aqiVal — keep exposure shorter');
      }
    } else {
      if (rainP < 20 && !cond.contains('rain')) {
        score += 22;
        reasons.add('dry window');
      } else {
        score -= 22;
        reasons.add('$rainP% rain chance');
      }
      if (temp >= 18 && temp <= 30) {
        score += 16;
        reasons.add('${temp.round()}°C for outdoor time');
      } else {
        reasons.add('${temp.round()}°C');
      }
    }
    scored.add((slot: slot, score: score, why: reasons.join(' · ')));
  }

  scored.sort((a, b) => b.score.compareTo(a.score));
  final best = scored.take(2).toList();
  return [
    for (final item in best)
      _BestWindow(
        kicker: persona.toUpperCase(),
        title: item.slot.hourLabel,
        reason: item.why,
      ),
  ];
}

class _HealthPrecautionsCard extends StatelessWidget {
  final AqiSnapshot? aqi;
  final CurrentConditions current;
  final List<String> triggers;
  final List<String> concerns;

  const _HealthPrecautionsCard({
    required this.aqi,
    required this.current,
    required this.triggers,
    required this.concerns,
  });

  @override
  Widget build(BuildContext context) {
    final aqiVal = aqi?.aqiValue ?? 0;
    final cat = aqi?.category ?? 'Good';
    final temp = current.temperatureCelsius.round();
    final humidity = current.humidityPercent;
    final uv = current.uvIndex;

    final precautions = <Map<String, dynamic>>[];

    // AQI / Respiratory check
    if (aqiVal >= 150 || concerns.contains('Asthma')) {
      precautions.add({
        'icon': Icons.air_rounded,
        'title': 'Air Quality: $cat (AQI $aqiVal)',
        'detail': 'High particle load. Asthmatics and sensitive groups should limit strenuous outdoor efforts.',
        'isWarn': aqiVal >= 100,
      });
    } else {
      precautions.add({
        'icon': Icons.air_rounded,
        'title': 'Air Quality: $cat (AQI $aqiVal)',
        'detail': 'Normal outdoor breathing conditions. Low risk for healthy individuals.',
        'isWarn': false,
      });
    }

    // Thermal / Heat check
    if (temp >= 33 || triggers.contains('Heat')) {
      precautions.add({
        'icon': Icons.thermostat_rounded,
        'title': 'Thermal Load: $temp°C · Feels ${(current.feelsLikeCelsius ?? temp).round()}°C',
        'detail': 'Heat stress risk elevated. Stay hydrated and avoid sustained direct sunlight.',
        'isWarn': temp >= 33,
      });
    }

    // Humidity / Allergies / Dust
    if (humidity >= 75 || triggers.contains('Humidity') || triggers.contains('Dust')) {
      precautions.add({
        'icon': Icons.water_drop_outlined,
        'title': 'Humidity & Allergens: $humidity%',
        'detail': 'Damp air slows perspiration. Dust & mold spores may linger in still air.',
        'isWarn': humidity >= 80,
      });
    }

    // UV Index check
    if (uv >= 6 || triggers.contains('UV / sun') || concerns.contains('Skin sensitivity')) {
      precautions.add({
        'icon': Icons.wb_sunny_outlined,
        'title': 'UV Radiation: ${uv.toStringAsFixed(1)} (High Exposure)',
        'detail': 'Apply SPF 30+ sunscreen and wear sunglasses between 11 AM and 4 PM.',
        'isWarn': uv >= 7,
      });
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MausamPalette.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MausamPalette.cardBorder),
        boxShadow: MausamPalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.health_and_safety_rounded, color: MausamPalette.textPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Personalized Health Guard',
                style: GoogleFonts.inter(
                  color: MausamPalette.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < precautions.length; i++) ...[
            if (i > 0) const Divider(color: MausamPalette.cardBorderSubtle, height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  precautions[i]['icon'] as IconData,
                  size: 16,
                  color: (precautions[i]['isWarn'] as bool)
                      ? const Color(0xFFFBBF24)
                      : MausamPalette.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        precautions[i]['title'] as String,
                        style: GoogleFonts.inter(
                          color: MausamPalette.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        precautions[i]['detail'] as String,
                        style: GoogleFonts.inter(
                          color: MausamPalette.textSecondary,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

