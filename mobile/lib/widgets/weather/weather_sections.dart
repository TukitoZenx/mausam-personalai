import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/weather_dashboard.dart';
import '../../providers/appearance_provider.dart';
import '../../theme/weather_palette.dart';
import 'persona_home.dart';
import 'weather_card_atmosphere.dart';
import 'weather_glyphs.dart';
import 'weather_intel.dart';

class HeroCurrentCard extends ConsumerStatefulWidget {
  final CurrentConditions current;
  final List<HourlyForecastItem> hourly;

  const HeroCurrentCard({
    super.key,
    required this.current,
    required this.hourly,
  });

  @override
  ConsumerState<HeroCurrentCard> createState() => _HeroCurrentCardState();
}

class _HeroCurrentCardState extends ConsumerState<HeroCurrentCard> {
  bool _bannerDismissed = false;

  @override
  Widget build(BuildContext context) {
    final current = widget.current;
    final temp = current.temperatureCelsius.round();
    final high = current.highCelsius?.round();
    final low = current.lowCelsius?.round();
    final feels = current.feelsLikeCelsius?.round();
    final banner = precipBannerText(current: current, hourly: widget.hourly);

    final surfaceOpacity = ref.watch(cardSurfaceOpacityProvider);

    final detectedType = resolveAtmosphereType(current.condition, icon: current.conditionIcon);
    final isYellow = detectedType == WeatherAtmosphereType.sun;
    final isRain = detectedType == WeatherAtmosphereType.rain;
    final isThunder = detectedType == WeatherAtmosphereType.thunder;

    return WeatherCardAtmosphere(
      type: detectedType,
      isYellowTheme: isYellow,
      surfaceOpacity: surfaceOpacity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Condition Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isYellow
                        ? const Color(0x33F59E0B)
                        : (isRain
                            ? const Color(0x223B82F6)
                            : (isThunder ? const Color(0x26FACC15) : MausamPalette.cardSurfaceLight)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isYellow
                          ? const Color(0x88F59E0B)
                          : (isRain
                              ? const Color(0x4460A5FA)
                              : (isThunder ? const Color(0x55FACC15) : MausamPalette.cardBorderSubtle)),
                    ),
                  ),
                  child: Text(
                    isYellow
                        ? '☀️ SUNNY'
                        : (isRain
                            ? '🌧️ RAINING NOW'
                            : (isThunder ? '⚡ THUNDERSTORM' : current.condition.toUpperCase())),
                    style: GoogleFonts.inter(
                      color: isYellow
                          ? const Color(0xFFFDE047)
                          : (isRain
                              ? const Color(0xFF93C5FD)
                              : (isThunder ? const Color(0xFFFDE047) : MausamPalette.textSecondary)),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Main Temp & Animated Weather Icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$temp°',
                  style: MausamTypography.largeTitle.copyWith(
                    color: isYellow ? const Color(0xFFFFFBEB) : MausamPalette.textPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (high != null)
                        Text(
                          'H: $high°',
                          style: GoogleFonts.inter(
                            color: isYellow ? const Color(0xFFFDE047) : MausamPalette.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFeatures: MausamTypography.tabularFeatures,
                          ),
                        ),
                      if (low != null)
                        Text(
                          'L: $low°',
                          style: GoogleFonts.inter(
                            color: isYellow ? const Color(0xFFFCD34D).withValues(alpha: 0.8) : MausamPalette.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            fontFeatures: MausamTypography.tabularFeatures,
                          ),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isYellow
                        ? const Color(0x33F59E0B)
                        : (isRain ? const Color(0x1F3B82F6) : Colors.transparent),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isYellow ? Icons.wb_sunny_rounded : weatherGlyph(current.condition, icon: current.conditionIcon),
                    color: isYellow ? const Color(0xFFFBBF24) : weatherGlyphColor(current.condition),
                    size: 48,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stat Chips: Feels like | Humidity | Wind
            Row(
              children: [
                _statChip('FEELS LIKE', feels == null ? '--' : '$feels°', isYellow: isYellow),
                _statChip('HUMIDITY', '${current.humidityPercent}%', isYellow: isYellow),
                _statChip('WIND', '${current.windSpeedKmh.round()} km/h', isYellow: isYellow),
              ],
            ),

            if (!_bannerDismissed) ...[
              const SizedBox(height: 12),
              Dismissible(
                key: const Key('precip_banner'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => setState(() => _bannerDismissed = true),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isYellow
                        ? const Color(0x33261C04)
                        : MausamPalette.bgDeep,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isYellow
                          ? const Color(0x66F59E0B)
                          : MausamPalette.cardBorderSubtle,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isYellow ? Icons.wb_sunny_outlined : Icons.water_drop_outlined,
                        color: isYellow ? const Color(0xFFFBBF24) : MausamPalette.textSecondary,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isYellow ? 'Sunny solar conditions · Warm bright weather' : banner,
                          style: GoogleFonts.inter(
                            color: isYellow ? const Color(0xFFFEF08A) : MausamPalette.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.close_rounded,
                        color: isYellow ? const Color(0xFFFBBF24) : MausamPalette.textTertiary,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, String value, {bool isYellow = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: isYellow ? const Color(0xFFFBBF24) : MausamPalette.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              color: MausamPalette.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              fontFeatures: MausamTypography.tabularFeatures,
            ),
          ),
        ],
      ),
    );
  }
}

class HourlyForecastStrip extends StatelessWidget {
  final List<HourlyForecastItem> hourly;
  final VoidCallback? onMore;

  const HourlyForecastStrip({super.key, required this.hourly, this.onMore});

  @override
  Widget build(BuildContext context) {
    final items = hourly.take(16).toList();
    return _sectionCard(
      title: 'HOURLY FORECAST',
      trailing: onMore == null
          ? null
          : TextButton(
              onPressed: onMore,
              child: Text(
                'Full Forecast',
                style: GoogleFonts.inter(
                  color: MausamPalette.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
      child: SizedBox(
        height: 104,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final slot = items[index];
            final isFirst = index == 0;
            return Container(
              width: 62,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: isFirst
                    ? MausamPalette.cardSurfaceLight
                    : MausamPalette.cardSurface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFirst ? MausamPalette.cardBorder : MausamPalette.cardBorderSubtle,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isFirst ? 'Now' : slot.hourLabel,
                    style: GoogleFonts.inter(
                      color: isFirst ? MausamPalette.textPrimary : MausamPalette.textTertiary,
                      fontSize: 11,
                      fontWeight: isFirst ? FontWeight.w600 : FontWeight.w500,
                      fontFeatures: MausamTypography.tabularFeatures,
                    ),
                  ),
                  Icon(
                    weatherGlyph(slot.condition, icon: slot.conditionIcon),
                    color: weatherGlyphColor(slot.condition),
                    size: 20,
                  ),
                  if (slot.rainProbabilityPercent > 0)
                    Text(
                      '${slot.rainProbabilityPercent}%',
                      style: GoogleFonts.inter(
                        color: MausamPalette.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFeatures: MausamTypography.tabularFeatures,
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                  Text(
                    '${slot.temperatureCelsius.round()}°',
                    style: GoogleFonts.inter(
                      color: MausamPalette.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      fontFeatures: MausamTypography.tabularFeatures,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class DailyForecastPanel extends StatefulWidget {
  final List<DailyForecastItem> days;
  final bool initiallyExpanded;

  const DailyForecastPanel({
    super.key,
    required this.days,
    this.initiallyExpanded = false,
  });

  @override
  State<DailyForecastPanel> createState() => _DailyForecastPanelState();
}

class _DailyForecastPanelState extends State<DailyForecastPanel> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _expanded || widget.days.length <= 7 ? widget.days : widget.days.take(7).toList();

    double minAll = 100;
    double maxAll = -100;
    for (final d in widget.days) {
      if (d.lowCelsius < minAll) minAll = d.lowCelsius;
      if (d.highCelsius > maxAll) maxAll = d.highCelsius;
    }
    if (maxAll <= minAll) maxAll = minAll + 1;

    return _sectionCard(
      title: '7-DAY FORECAST',
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: i == visible.length - 1 ? Colors.transparent : MausamPalette.cardBorderSubtle,
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      i == 0
                          ? 'Today'
                          : _shortWeekday(visible[i].weekday ?? visible[i].day),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: i == 0 ? MausamPalette.textPrimary : MausamPalette.textSecondary,
                        fontSize: 12.5,
                        fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 22,
                    child: Center(
                      child: Icon(
                        weatherGlyph(visible[i].condition, icon: visible[i].conditionIcon),
                        color: weatherGlyphColor(visible[i].condition),
                        size: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      visible[i].condition,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: MausamPalette.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 32,
                    child: visible[i].rainProbabilityPercent > 0
                        ? FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${visible[i].rainProbabilityPercent}%',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF60A5FA),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFeatures: MausamTypography.tabularFeatures,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 28,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${visible[i].lowCelsius.round()}°',
                        style: GoogleFonts.inter(
                          color: MausamPalette.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFeatures: MausamTypography.tabularFeatures,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 46,
                    height: 4,
                    child: CustomPaint(
                      painter: _TempRangeBarPainter(
                        minAll: minAll,
                        maxAll: maxAll,
                        lowDay: visible[i].lowCelsius,
                        highDay: visible[i].highCelsius,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 28,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${visible[i].highCelsius.round()}°',
                        style: GoogleFonts.inter(
                          color: MausamPalette.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFeatures: MausamTypography.tabularFeatures,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _shortWeekday(String name) {
    if (name.length <= 3) return name;
    return name.substring(0, 3);
  }
}

class AqiGaugeCard extends StatelessWidget {
  final AqiSnapshot aqi;

  const AqiGaugeCard({super.key, required this.aqi});

  @override
  Widget build(BuildContext context) {
    final pos = (aqi.aqiValue / 300).clamp(0.0, 1.0);
    const keys = ['no2', 'o3', 'pm10', 'pm2_5', 'co', 'so2'];
    const labels = ['NO₂', 'O₃', 'PM10', 'PM2.5', 'CO', 'SO₂'];

    final Color categoryColor = aqi.aqiValue <= 50
        ? MausamPalette.textPrimary
        : aqi.aqiValue <= 100
            ? MausamPalette.textSecondary
            : MausamPalette.textTertiary;

    return _sectionCard(
      title: 'AIR QUALITY INDEX',
      trailing: IconButton(
        tooltip: 'AQI scale',
        onPressed: () => _showAqiInfo(context),
        icon: const Icon(Icons.info_outline_rounded, color: MausamPalette.textTertiary, size: 16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${aqi.aqiValue}',
                style: GoogleFonts.inter(
                  color: MausamPalette.textPrimary,
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  fontFeatures: MausamTypography.tabularFeatures,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      aqi.category.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: categoryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Main pollutant: ${aqi.mainPollutantLabel}',
                    style: GoogleFonts.inter(color: MausamPalette.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 14,
            width: double.infinity,
            child: CustomPaint(
              painter: _GradientMarkerPainter(position: pos),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              for (var i = 0; i < keys.length; i++)
                SizedBox(
                  width: 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(labels[i], style: GoogleFonts.inter(color: MausamPalette.textTertiary, fontSize: 10)),
                      Text(
                        (aqi.pollutants[keys[i]] ?? 0).toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          color: MausamPalette.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          fontFeatures: MausamTypography.tabularFeatures,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAqiInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: MausamPalette.cardSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('AQI Scale Reference', style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          content: Text(
            'Good (0–50) • Fair (51–100) • Moderate (101–150) • Poor (151–200) • Severe (201+).\n\n'
            'Air pollution data sourced live from OpenWeatherMap Air Pollution API.',
            style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Got it', style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }
}

String windDirectionAbbr(double? deg) {
  if (deg == null) return '--';
  const directions = [
    'N', 'NNE', 'NE', 'ENE',
    'E', 'ESE', 'SE', 'SSE',
    'S', 'SSW', 'SW', 'WSW',
    'W', 'WNW', 'NW', 'NNW'
  ];
  final idx = ((deg + 11.25) / 22.5).floor() % 16;
  return directions[idx];
}

class TodayMetricCard extends ConsumerWidget {
  final String title;
  final String? pillLabel;
  final String value;
  final String subtitle;
  final IconData? icon;
  final Color? iconColor;

  const TodayMetricCard({
    super.key,
    required this.title,
    this.pillLabel,
    required this.value,
    required this.subtitle,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surfaceOpacity = ref.watch(cardSurfaceOpacityProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: MausamPalette.cardSurface.withValues(alpha: surfaceOpacity),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MausamPalette.cardBorder),
        boxShadow: MausamPalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: iconColor ?? MausamPalette.textTertiary),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: MausamPalette.textTertiary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (pillLabel != null && pillLabel!.isNotEmpty)
                Text(
                  pillLabel!.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: MausamPalette.textTertiary,
                    fontWeight: FontWeight.w600,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: MausamPalette.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 21,
              height: 1.1,
              letterSpacing: -0.3,
              fontFeatures: MausamTypography.tabularFeatures,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: MausamPalette.textSecondary,
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class TodaysMetricsGrid extends StatelessWidget {
  final WeatherDashboard dashboard;
  final String? persona;

  const TodaysMetricsGrid({super.key, required this.dashboard, this.persona});

  @override
  Widget build(BuildContext context) {
    final c = dashboard.current;
    final uv = c.uvIndex;
    final rainMm = (c.rainMm1h != null && c.rainMm1h! > 0)
        ? c.rainMm1h!
        : (dashboard.precipNext24hMm ?? 0.0);
    final rainP = dashboard.daily.firstOrNull?.rainProbabilityPercent ?? 0;
    final feels = (c.feelsLikeCelsius ?? c.temperatureCelsius).round();

    String uvCat;
    if (uv < 3) {
      uvCat = 'LOW';
    } else if (uv < 6) {
      uvCat = 'MODERATE';
    } else if (uv < 8) {
      uvCat = 'HIGH';
    } else if (uv < 11) {
      uvCat = 'VERY HIGH';
    } else {
      uvCat = 'EXTREME';
    }

    final card1 = TodayMetricCard(
      title: 'UV INDEX',
      icon: Icons.wb_sunny_rounded,
      iconColor: const Color(0xFFFBBF24),
      value: uv.toStringAsFixed(1),
      subtitle: uvCat,
    );
    final isHealth = persona != null && persona!.toLowerCase().contains('health');
    final card2 = (isHealth && dashboard.aqi != null)
        ? TodayMetricCard(
            title: 'AIR QUALITY',
            icon: Icons.air_rounded,
            iconColor: const Color(0xFF34D399),
            value: 'AQI ${dashboard.aqi!.aqiValue}',
            subtitle: dashboard.aqi!.category.toUpperCase(),
          )
        : TodayMetricCard(
            title: 'BEST OUTDOOR TIME',
            icon: Icons.directions_run_rounded,
            iconColor: const Color(0xFF34D399),
            value: (persona != null && persona!.isNotEmpty) ? persona!.toUpperCase() : 'OPTIMAL',
            subtitle: 'Morning window',
          );
    final card3 = TodayMetricCard(
      title: 'RAINFALL TODAY',
      icon: Icons.water_drop_rounded,
      iconColor: const Color(0xFF60A5FA),
      value: '${rainMm.toStringAsFixed(1)} mm',
      subtitle: '$rainP% PROB',
    );
    final card4 = TodayMetricCard(
      title: 'HEAT & COMFORT',
      icon: Icons.thermostat_rounded,
      iconColor: const Color(0xFFF97316),
      value: 'Feels $feels°',
      subtitle: WeatherIntel.heatSupport(c),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            "TODAY'S METRICS",
            style: GoogleFonts.inter(
              color: MausamPalette.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: card1),
            const SizedBox(width: 12),
            Expanded(child: card2),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: card3),
            const SizedBox(width: 12),
            Expanded(child: card4),
          ],
        ),
      ],
    );
  }
}


class StatGrid extends StatelessWidget {
  final WeatherDashboard dashboard;

  const StatGrid({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return TodaysMetricsGrid(dashboard: dashboard);
  }
}

class SunMoonCard extends StatelessWidget {
  final CurrentConditions current;
  final DailyForecastItem? today;

  const SunMoonCard({super.key, required this.current, this.today});

  @override
  Widget build(BuildContext context) {
    final rise = current.sunriseUnix;
    final set = current.sunsetUnix;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    double t = 0.5;
    if (rise != null && set != null && set > rise) {
      t = ((now - rise) / (set - rise)).clamp(0.0, 1.0);
    }
    final daylight = (rise != null && set != null) ? Duration(seconds: set - rise) : null;
    final daylightLabel = daylight == null
        ? '--'
        : '${daylight.inHours}h ${daylight.inMinutes.remainder(60)}m';
    final golden = WeatherIntel.goldenHourWindow(current);

    return _sectionCard(
      title: 'SUN & MOON',
      child: Column(
        children: [
          SizedBox(
            height: 98,
            width: double.infinity,
            child: CustomPaint(
              painter: _SunArcPainter(t: t),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        daylightLabel,
                        style: GoogleFonts.inter(
                          color: MausamPalette.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          fontFeatures: MausamTypography.tabularFeatures,
                        ),
                      ),
                      Text(
                        'Daylight duration',
                        style: GoogleFonts.inter(
                          color: MausamPalette.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wb_sunny_rounded, size: 13, color: Color(0xFFFBBF24)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Sunrise ${_fmtUnix(rise, current.timezoneOffsetSec)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.nightlight_round, size: 13, color: Color(0xFF93C5FD)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Sunset ${_fmtUnix(set, current.timezoneOffsetSec)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (golden != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.wb_twilight_rounded, size: 13, color: Color(0xFFFBBF24)),
                const SizedBox(width: 6),
                Text(
                  'Golden hour $golden',
                  style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 11.5),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          const Divider(color: MausamPalette.cardBorderSubtle, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(moonVectorIcon(today?.moonPhase), size: 22, color: const Color(0xFF93C5FD)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moonPhaseName(today?.moonPhase),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: MausamPalette.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                    Text(
                      today?.moonriseUnix != null
                          ? 'Rise ${_fmtUnix(today?.moonriseUnix, current.timezoneOffsetSec)} • Set ${_fmtUnix(today?.moonsetUnix, current.timezoneOffsetSec)}'
                          : 'Moon phase details',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: MausamPalette.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AdditionalConditionsSection extends StatelessWidget {
  final WeatherDashboard dashboard;
  final String? persona;

  const AdditionalConditionsSection({super.key, required this.dashboard, this.persona});

  @override
  Widget build(BuildContext context) {
    final c = dashboard.current;
    final today = dashboard.daily.firstOrNull;
    final windDir = PersonaHome.windDir(c.windDirectionDeg);
    final hpa = (c.pressureHpa ?? 1013).round();
    final vis = c.visibilityKm != null ? '${c.visibilityKm!.toStringAsFixed(1)} km' : '--';
    final dew = c.dewPointCelsius != null ? 'Dew point ${c.dewPointCelsius!.round()}°' : 'Relative';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            'ADDITIONAL CONDITIONS',
            style: GoogleFonts.inter(
              color: MausamPalette.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
        SunMoonCard(current: c, today: today),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TodayMetricCard(
                title: 'WIND',
                icon: Icons.air_rounded,
                iconColor: const Color(0xFF93C5FD),
                value: '${c.windSpeedKmh.round()} km/h',
                subtitle: c.windDirectionDeg != null ? '${c.windDirectionDeg!.round()}° $windDir' : 'Calm',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TodayMetricCard(
                title: 'PRESSURE',
                icon: Icons.speed_rounded,
                iconColor: const Color(0xFFFBBF24),
                value: '$hpa hPa',
                subtitle: hpa < 1005 ? 'Falling' : (hpa > 1020 ? 'Rising' : 'Steady'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TodayMetricCard(
                title: 'VISIBILITY',
                icon: Icons.visibility_rounded,
                iconColor: const Color(0xFF34D399),
                value: vis,
                subtitle: visibilityLine(c.visibilityKm),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TodayMetricCard(
                title: 'HUMIDITY',
                icon: Icons.water_drop_outlined,
                iconColor: const Color(0xFF60A5FA),
                value: '${c.humidityPercent}%',
                subtitle: dew,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ConditionsAroundYouSection extends StatelessWidget {
  final WeatherDashboard dashboard;
  final String? persona;

  const ConditionsAroundYouSection({super.key, required this.dashboard, this.persona});

  @override
  Widget build(BuildContext context) {
    final c = dashboard.current;
    final statusColor = WeatherIntel.commuteIsSevere(c)
        ? const Color(0xFFEF4444)
        : (WeatherIntel.commuteIsCaution(c) ? const Color(0xFFFBBF24) : MausamPalette.textSecondary);

    final locationLabel = (persona != null && persona!.isNotEmpty)
        ? persona!
        : (c.location.isNotEmpty ? c.location : 'LOCAL AREA');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            'CONDITIONS AROUND YOU',
            style: GoogleFonts.inter(
              color: MausamPalette.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
        _CommuteStatusCard(
          location: locationLabel,
          status: WeatherIntel.commuteStatus(c),
          statusColor: statusColor,
          roadSurface: WeatherIntel.isWet(c) ? 'Wet' : 'Dry',
          sightDist: c.visibilityKm != null ? '${c.visibilityKm!.toStringAsFixed(1)} km' : '--',
          windSpeed: '${c.windSpeedKmh.round()} km/h',
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TodayMetricCard(
                title: 'OUTDOOR ACTIVITY',
                icon: Icons.directions_run_rounded,
                iconColor: const Color(0xFF34D399),
                value: WeatherIntel.outdoorTitle(c, dashboard.aqi),
                subtitle: WeatherIntel.outdoorSupport(c, dashboard.aqi),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TodayMetricCard(
                title: 'ENVIRONMENT & SOIL',
                icon: Icons.grass_rounded,
                iconColor: const Color(0xFF60A5FA),
                value: WeatherIntel.isWet(c) ? 'Wet surface' : 'Stable surface',
                subtitle: c.humidityPercent > 70 ? 'High ground moisture' : 'Comfortable balance',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CommuteStatusCard extends StatelessWidget {
  final String location;
  final String status;
  final Color statusColor;
  final String roadSurface;
  final String sightDist;
  final String windSpeed;

  const _CommuteStatusCard({
    required this.location,
    required this.status,
    required this.statusColor,
    required this.roadSurface,
    required this.sightDist,
    required this.windSpeed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: MausamPalette.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MausamPalette.cardBorder),
        boxShadow: MausamPalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.commute_rounded, size: 14, color: Color(0xFF60A5FA)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'COMMUTE STATUS · ${location.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: MausamPalette.textTertiary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 9.5,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _col(
                  icon: Icons.directions_car_rounded,
                  iconColor: const Color(0xFF93C5FD),
                  title: 'Roads',
                  value: roadSurface,
                ),
              ),
              Container(width: 1, height: 36, color: MausamPalette.cardBorderSubtle),
              Expanded(
                child: _col(
                  icon: Icons.visibility_rounded,
                  title: 'Sight',
                  value: sightDist,
                ),
              ),
              Container(width: 1, height: 36, color: MausamPalette.cardBorderSubtle),
              Expanded(
                child: _col(
                  icon: Icons.air_rounded,
                  iconColor: const Color(0xFF93C5FD),
                  title: 'Wind',
                  value: windSpeed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _col({
    required IconData icon,
    Color iconColor = MausamPalette.textTertiary,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: MausamPalette.textTertiary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: MausamPalette.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class WindCard extends StatelessWidget {
  final double speed;
  final double? deg;
  const WindCard({super.key, required this.speed, this.deg});

  @override
  Widget build(BuildContext context) {
    return TodayMetricCard(
      title: 'WIND',
      pillLabel: windDirectionAbbr(deg),
      value: '${speed.round()} km/h',
      subtitle: deg != null ? 'Direction · ${deg!.round()}°' : 'Calm breeze',
    );
  }
}

class PressureCard extends StatelessWidget {
  final double? hpa;
  const PressureCard({super.key, this.hpa});

  @override
  Widget build(BuildContext context) {
    final value = (hpa ?? 1013).round();
    return TodayMetricCard(
      title: 'PRESSURE',
      pillLabel: value < 1005 ? 'LOW' : (value > 1020 ? 'HIGH' : 'STEADY'),
      value: '$value mbar',
      subtitle: 'Normal · Steady',
    );
  }
}

class VisibilityCard extends StatelessWidget {
  final double? km;
  const VisibilityCard({super.key, this.km});

  @override
  Widget build(BuildContext context) {
    return TodayMetricCard(
      title: 'VISIBILITY',
      value: '${km?.toStringAsFixed(1) ?? '--'} km',
      subtitle: visibilityLine(km),
    );
  }
}

class HumidityCard extends StatelessWidget {
  final int percent;
  final double? dew;
  const HumidityCard({super.key, required this.percent, this.dew});

  @override
  Widget build(BuildContext context) {
    final dewPoint = dew;
    return TodayMetricCard(
      title: 'HUMIDITY',
      value: '$percent%',
      subtitle: dewPoint == null ? 'Dew point --' : 'Dew point ${dewPoint.round()}°',
    );
  }
}

class UvCard extends StatelessWidget {
  final double uv;
  const UvCard({super.key, required this.uv});

  @override
  Widget build(BuildContext context) {
    return TodayMetricCard(
      title: 'UV INDEX',
      pillLabel: uvCategory(uv),
      value: uv.toStringAsFixed(1),
      subtitle: uv >= 6 ? 'Use SPF 30+' : 'Moderate exposure',
    );
  }
}

class PrecipCard extends StatelessWidget {
  final double? lastMm;
  final double? nextMm;
  const PrecipCard({super.key, this.lastMm, this.nextMm});

  @override
  Widget build(BuildContext context) {
    return TodayMetricCard(
      title: 'PRECIPITATION',
      value: '${(nextMm ?? lastMm ?? 0).toStringAsFixed(1)} mm',
      subtitle: 'Precipitation outlook',
    );
  }
}

class SectionCard extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  const SectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surfaceOpacity = ref.watch(cardSurfaceOpacityProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: MausamPalette.cardSurface.withValues(alpha: surfaceOpacity),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MausamPalette.cardBorder),
        boxShadow: MausamPalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: MausamPalette.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

Widget _sectionCard({
  required String title,
  String? subtitle,
  Widget? trailing,
  required Widget child,
}) {
  return SectionCard(
    title: title,
    subtitle: subtitle,
    trailing: trailing,
    child: child,
  );
}

class MiniCard extends ConsumerWidget {
  final String title;
  final Widget child;

  const MiniCard({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surfaceOpacity = ref.watch(cardSurfaceOpacityProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MausamPalette.cardSurface.withValues(alpha: surfaceOpacity),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MausamPalette.cardBorder),
        boxShadow: MausamPalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: MausamPalette.textTertiary,
              fontWeight: FontWeight.w600,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

String _fmtUnix(int? unix, int? offsetSec) {
  if (unix == null) return '--';
  final dt = DateTime.fromMillisecondsSinceEpoch(unix * 1000, isUtc: true)
      .add(Duration(seconds: offsetSec ?? 0));
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

class _GradientMarkerPainter extends CustomPainter {
  final double position;
  _GradientMarkerPainter({
    required this.position,
  });

  static const List<Color> _colors = [
    Color(0xFFE4E4E7),
    Color(0xFFA1A1AA),
    Color(0xFF71717A),
    Color(0xFF3F3F46),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromLTRBR(0, size.height * 0.35, size.width, size.height * 0.65, const Radius.circular(99));
    final paint = Paint()
      ..shader = const LinearGradient(colors: _colors).createShader(Offset.zero & size);
    canvas.drawRRect(rect, paint);
    final x = position * size.width;
    canvas.drawCircle(Offset(x, size.height / 2), 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _GradientMarkerPainter oldDelegate) => oldDelegate.position != position;
}

class _SunArcPainter extends CustomPainter {
  final double t;
  _SunArcPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(16, 20, size.width - 32, (size.height - 10) * 2);
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = MausamPalette.cardBorder;
    canvas.drawArc(rect, math.pi, math.pi, false, arcPaint);
    final angle = math.pi + t * math.pi;
    final cx = rect.center.dx + rect.width / 2 * math.cos(angle);
    final cy = rect.center.dy + rect.height / 2 * math.sin(angle);
    canvas.drawCircle(Offset(cx, cy), 6, Paint()..color = MausamPalette.textPrimary);
  }

  @override
  bool shouldRepaint(covariant _SunArcPainter oldDelegate) => oldDelegate.t != t;
}

class _TempRangeBarPainter extends CustomPainter {
  final double minAll;
  final double maxAll;
  final double lowDay;
  final double highDay;

  const _TempRangeBarPainter({
    required this.minAll,
    required this.maxAll,
    required this.lowDay,
    required this.highDay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.height / 2),
    );
    final bgPaint = Paint()..color = MausamPalette.cardBorderSubtle;
    canvas.drawRRect(rrect, bgPaint);

    final span = maxAll - minAll;
    if (span <= 0) return;
    final leftFraction = ((lowDay - minAll) / span).clamp(0.0, 1.0);
    final rightFraction = ((highDay - minAll) / span).clamp(0.0, 1.0);

    final startX = leftFraction * size.width;
    final endX = math.max(startX + 4.0, rightFraction * size.width);

    final barRRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(startX, 0, endX, size.height),
      Radius.circular(size.height / 2),
    );

    final barPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF71717A), Color(0xFFE4E4E7)],
      ).createShader(Rect.fromLTRB(startX, 0, endX, size.height));

    canvas.drawRRect(barRRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant _TempRangeBarPainter oldDelegate) {
    return oldDelegate.minAll != minAll ||
        oldDelegate.maxAll != maxAll ||
        oldDelegate.lowDay != lowDay ||
        oldDelegate.highDay != highDay;
  }
}

