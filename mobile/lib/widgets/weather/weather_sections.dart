import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/weather_dashboard.dart';
import '../../providers/appearance_provider.dart';
import '../../theme/weather_palette.dart';
import 'weather_glyphs.dart';

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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: MausamPalette.cardSurface.withValues(alpha: surfaceOpacity),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MausamPalette.cardBorder),
        boxShadow: MausamPalette.heroShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            current.condition.toUpperCase(),
            style: GoogleFonts.inter(
              color: MausamPalette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),

          // Main Temp & Icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$temp°',
                style: MausamTypography.largeTitle,
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
                          color: MausamPalette.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFeatures: MausamTypography.tabularFeatures,
                        ),
                      ),
                    if (low != null)
                      Text(
                        'L: $low°',
                        style: GoogleFonts.inter(
                          color: MausamPalette.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFeatures: MausamTypography.tabularFeatures,
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(
                weatherGlyph(current.condition, icon: current.conditionIcon),
                color: weatherGlyphColor(current.condition),
                size: 52,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stat Chips: Feels like | Humidity | Wind
          Row(
            children: [
              _statChip('FEELS LIKE', feels == null ? '--' : '$feels°'),
              _statChip('HUMIDITY', '${current.humidityPercent}%'),
              _statChip('WIND', '${current.windSpeedKmh.round()} km/h'),
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
                  color: MausamPalette.bgDeep,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MausamPalette.cardBorderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.water_drop_outlined, color: MausamPalette.textSecondary, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        banner,
                        style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 12),
                      ),
                    ),
                    const Icon(Icons.close_rounded, color: MausamPalette.textTertiary, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: MausamPalette.textTertiary,
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
            return Container(
              width: 68,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: MausamPalette.cardSurfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: MausamPalette.cardBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    slot.hourLabel,
                    style: GoogleFonts.inter(
                      color: MausamPalette.textTertiary,
                      fontSize: 11,
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
    final visible = _expanded || widget.days.length <= 5 ? widget.days : widget.days.take(5).toList();
    return _sectionCard(
      title: '7-DAY FORECAST',
      subtitle: dailyHeadline(widget.days),
      trailing: widget.days.length > 5
          ? TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Less' : 'More',
                style: GoogleFonts.inter(
                  color: MausamPalette.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            )
          : null,
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: i == visible.length - 1 ? Colors.transparent : MausamPalette.cardBorderSubtle,
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      visible[i].date != null && visible[i].date!.length >= 10
                          ? '${visible[i].weekday ?? visible[i].day} ${visible[i].date!.substring(8)}'
                          : (visible[i].weekday ?? visible[i].day),
                      style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Icon(
                    weatherGlyph(visible[i].condition, icon: visible[i].conditionIcon),
                    color: weatherGlyphColor(visible[i].condition),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text(
                      visible[i].rainProbabilityPercent > 0 ? '${visible[i].rainProbabilityPercent}%' : '—',
                      style: GoogleFonts.inter(
                        color: MausamPalette.textSecondary,
                        fontSize: 11,
                        fontFeatures: MausamTypography.tabularFeatures,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      visible[i].condition,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 12),
                    ),
                  ),
                  Text(
                    '${visible[i].highCelsius.round()}° / ${visible[i].lowCelsius.round()}°',
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
    );
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

class StatGrid extends StatelessWidget {
  final WeatherDashboard dashboard;

  const StatGrid({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final c = dashboard.current;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _PressureCard(hpa: c.pressureHpa)),
            const SizedBox(width: 10),
            Expanded(child: _WindCard(speed: c.windSpeedKmh, deg: c.windDirectionDeg)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _UvCard(uv: c.uvIndex)),
            const SizedBox(width: 10),
            Expanded(child: _VisibilityCard(km: c.visibilityKm)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PrecipCard(
                lastMm: c.rainMm1h,
                nextMm: dashboard.precipNext24hMm,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _HumidityCard(percent: c.humidityPercent, dew: c.dewPointCelsius)),
          ],
        ),
      ],
    );
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

    return _sectionCard(
      title: 'SUN & MOON',
      child: Column(
        children: [
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: _SunArcPainter(t: t),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 28),
                  child: Text(
                    daylightLabel,
                    style: GoogleFonts.inter(
                      color: MausamPalette.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      fontFeatures: MausamTypography.tabularFeatures,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sunrise ${_fmtUnix(rise, current.timezoneOffsetSec)}',
                  style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 12)),
              Text('Sunset ${_fmtUnix(set, current.timezoneOffsetSec)}',
                  style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(moonGlyph(today?.moonPhase), style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moonPhaseName(today?.moonPhase),
                      style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      'Rise ${_fmtUnix(today?.moonriseUnix, current.timezoneOffsetSec)} • Set ${_fmtUnix(today?.moonsetUnix, current.timezoneOffsetSec)}',
                      style: GoogleFonts.inter(color: MausamPalette.textTertiary, fontSize: 11),
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

class _PressureCard extends StatelessWidget {
  final double? hpa;
  const _PressureCard({this.hpa});

  @override
  Widget build(BuildContext context) {
    final value = hpa ?? 1013;
    final t = ((value - 980) / 60).clamp(0.0, 1.0);
    return _miniCard(
      title: 'PRESSURE',
      child: Column(
        children: [
          SizedBox(
            height: 70,
            width: double.infinity,
            child: CustomPaint(
              painter: _PressureGaugePainter(t: t),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    hpa == null ? '--' : '${hpa!.round()}',
                    style: GoogleFonts.inter(
                      color: MausamPalette.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      fontFeatures: MausamTypography.tabularFeatures,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text('mbar', style: GoogleFonts.inter(color: MausamPalette.textTertiary, fontSize: 10)),
        ],
      ),
    );
  }
}

class _WindCard extends StatelessWidget {
  final double speed;
  final double? deg;
  const _WindCard({required this.speed, this.deg});

  @override
  Widget build(BuildContext context) {
    return _miniCard(
      title: 'WIND',
      child: SizedBox(
        height: 84,
        width: double.infinity,
        child: CustomPaint(
          painter: _CompassPainter(deg: deg ?? 0),
          child: Center(
            child: Text(
              '${speed.round()}\nkm/h',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: MausamPalette.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                height: 1.1,
                fontFeatures: MausamTypography.tabularFeatures,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UvCard extends StatelessWidget {
  final double uv;
  const _UvCard({required this.uv});

  @override
  Widget build(BuildContext context) {
    return _miniCard(
      title: 'UV INDEX',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${uv.toStringAsFixed(1)} ${uvCategory(uv)}',
            style: GoogleFonts.inter(
              color: MausamPalette.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              fontFeatures: MausamTypography.tabularFeatures,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 10,
            width: double.infinity,
            child: CustomPaint(
              painter: _GradientMarkerPainter(
                position: (uv / 12).clamp(0.0, 1.0),
                colors: const [
                  Color(0xFFE4E4E7),
                  Color(0xFFA1A1AA),
                  Color(0xFF71717A),
                  Color(0xFF3F3F46),
                ],
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilityCard extends StatelessWidget {
  final double? km;
  const _VisibilityCard({this.km});

  @override
  Widget build(BuildContext context) {
    return _miniCard(
      title: 'VISIBILITY',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            km == null ? '--' : '${km!.toStringAsFixed(1)} km',
            style: GoogleFonts.inter(
              color: MausamPalette.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              fontFeatures: MausamTypography.tabularFeatures,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            visibilityLine(km),
            style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _PrecipCard extends StatelessWidget {
  final double? lastMm;
  final double? nextMm;
  const _PrecipCard({this.lastMm, this.nextMm});

  @override
  Widget build(BuildContext context) {
    return _miniCard(
      title: 'PRECIPITATION',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${(nextMm ?? 0).toStringAsFixed(1)} mm',
            style: GoogleFonts.inter(
              color: MausamPalette.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              fontFeatures: MausamTypography.tabularFeatures,
            ),
          ),
          const SizedBox(height: 4),
          Text('Next 24h forecast', style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _HumidityCard extends StatelessWidget {
  final int percent;
  final double? dew;
  const _HumidityCard({required this.percent, this.dew});

  @override
  Widget build(BuildContext context) {
    return _miniCard(
      title: 'HUMIDITY',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$percent%',
            style: GoogleFonts.inter(
              color: MausamPalette.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              fontFeatures: MausamTypography.tabularFeatures,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dew == null ? 'Dew point --' : 'Dew point ${dew!.round()}°',
            style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 11),
          ),
        ],
      ),
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
      margin: const EdgeInsets.only(bottom: 12),
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

Widget _miniCard({required String title, required Widget child}) {
  return MiniCard(
    title: title,
    child: child,
  );
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
  final List<Color> colors;
  _GradientMarkerPainter({
    required this.position,
    this.colors = const [
      Color(0xFFE4E4E7),
      Color(0xFFA1A1AA),
      Color(0xFF71717A),
      Color(0xFF3F3F46),
    ],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromLTRBR(0, size.height * 0.35, size.width, size.height * 0.65, const Radius.circular(99));
    final paint = Paint()
      ..shader = LinearGradient(colors: colors).createShader(Offset.zero & size);
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

class _PressureGaugePainter extends CustomPainter {
  final double t;
  _PressureGaugePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.7);
    final rect = Rect.fromCircle(center: center, radius: 32);
    canvas.drawArc(rect, math.pi, math.pi, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = MausamPalette.cardBorder);
    canvas.drawArc(
      rect,
      math.pi,
      math.pi * t,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = MausamPalette.textPrimary,
    );
  }

  @override
  bool shouldRepaint(covariant _PressureGaugePainter oldDelegate) => oldDelegate.t != t;
}

class _CompassPainter extends CustomPainter {
  final double deg;
  _CompassPainter({required this.deg});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(c, 34, Paint()
      ..style = PaintingStyle.stroke
      ..color = MausamPalette.cardBorder
      ..strokeWidth = 1.5);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(deg * math.pi / 180);
    final path = Path()
      ..moveTo(0, -24)
      ..lineTo(5, 12)
      ..lineTo(0, 6)
      ..lineTo(-5, 12)
      ..close();
    canvas.drawPath(path, Paint()..color = MausamPalette.textPrimary);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) => oldDelegate.deg != deg;
}
