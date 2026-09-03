import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/weather_dashboard.dart';
import '../../theme/weather_palette.dart';
import 'weather_glyphs.dart';

class HeroCurrentCard extends StatefulWidget {
  final CurrentConditions current;
  final List<HourlyForecastItem> hourly;
  final String locationName;
  final VoidCallback onLocationTap;
  final VoidCallback onSearchTap;

  const HeroCurrentCard({
    super.key,
    required this.current,
    required this.hourly,
    required this.locationName,
    required this.onLocationTap,
    required this.onSearchTap,
  });

  @override
  State<HeroCurrentCard> createState() => _HeroCurrentCardState();
}

class _HeroCurrentCardState extends State<HeroCurrentCard> {
  bool _bannerDismissed = false;

  @override
  Widget build(BuildContext context) {
    final current = widget.current;
    final hour = DateTime.now().hour;
    final temp = current.temperatureCelsius.round();
    final high = current.highCelsius?.round();
    final low = current.lowCelsius?.round();
    final feels = current.feelsLikeCelsius?.round();
    final banner = precipBannerText(current: current, hourly: widget.hourly);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        gradient: MausamPalette.heroGradient(hour: hour, condition: current.condition),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                tooltip: 'Open navigation',
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: widget.onLocationTap,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.locationName,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                    ],
                  ),
                ),
              ),
              IconButton(
                key: const Key('location_search_button'),
                tooltip: 'Saved locations',
                onPressed: widget.onSearchTap,
                icon: const Icon(Icons.search_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            current.condition,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$temp',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 72,
                  height: 1.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  '°',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (high != null)
                      Text('▲ $high°', style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
                    if (low != null)
                      Text('▼ $low°', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const Spacer(),
              Icon(
                weatherGlyph(current.condition, icon: current.conditionIcon),
                color: weatherGlyphColor(current.condition),
                size: 56,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statChip('Feels Like', feels == null ? '--' : '$feels°'),
              _statChip('Humidity', '${current.humidityPercent}%'),
              _statChip('Wind', '${current.windSpeedKmh.round()} km/h'),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.water_drop_outlined, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        banner,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 12.5),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white54),
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
          Text(label, style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
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
      title: 'Hourly',
      trailing: onMore == null
          ? null
          : TextButton(
              onPressed: onMore,
              child: Text('More', style: GoogleFonts.inter(color: MausamPalette.accentBlue, fontWeight: FontWeight.w700)),
            ),
      child: SizedBox(
        height: 112,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final slot = items[index];
            return Container(
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MausamPalette.cardBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(slot.hourLabel, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                  Icon(
                    weatherGlyph(slot.condition, icon: slot.conditionIcon),
                    color: weatherGlyphColor(slot.condition),
                    size: 22,
                  ),
                  if (slot.rainProbabilityPercent > 0)
                    Text(
                      '${slot.rainProbabilityPercent}%',
                      style: GoogleFonts.inter(color: MausamPalette.accentBlue, fontSize: 10),
                    )
                  else
                    const SizedBox(height: 12),
                  Text(
                    '${slot.temperatureCelsius.round()}°',
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700),
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
      title: 'Daily',
      subtitle: dailyHeadline(widget.days),
      trailing: widget.days.length > 5
          ? TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Less' : 'More',
                style: GoogleFonts.inter(color: MausamPalette.accentBlue, fontWeight: FontWeight.w700),
              ),
            )
          : null,
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(
                color: i.isOdd ? Colors.white.withValues(alpha: 0.03) : Colors.transparent,
                border: Border(
                  bottom: BorderSide(color: MausamPalette.cardBorder.withValues(alpha: 0.7)),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 86,
                    child: Text(
                      visible[i].date != null && visible[i].date!.length >= 10
                          ? '${visible[i].weekday ?? visible[i].day} ${visible[i].date!.substring(8)}'
                          : (visible[i].weekday ?? visible[i].day),
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  Icon(
                    weatherGlyph(visible[i].condition, icon: visible[i].conditionIcon),
                    color: weatherGlyphColor(visible[i].condition),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text(
                      visible[i].rainProbabilityPercent > 0 ? '${visible[i].rainProbabilityPercent}%' : '—',
                      style: GoogleFonts.inter(color: MausamPalette.accentBlue, fontSize: 11),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      visible[i].condition,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                  Text(
                    '${visible[i].highCelsius.round()}° / ${visible[i].lowCelsius.round()}°',
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
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
    return _sectionCard(
      title: 'Air Quality',
      trailing: IconButton(
        tooltip: 'AQI scale',
        onPressed: () => _showAqiInfo(context),
        icon: const Icon(Icons.info_outline, color: Colors.white70, size: 18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${aqi.aqiValue}',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Text(aqiMoodGlyph(aqi.category), style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(aqi.category, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
                  Text(
                    aqi.mainPollutantLabel,
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 18,
            width: double.infinity,
            child: CustomPaint(
              painter: _GradientMarkerPainter(position: pos),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              for (var i = 0; i < keys.length; i++)
                SizedBox(
                  width: 96,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(labels[i], style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
                      Text(
                        (aqi.pollutants[keys[i]] ?? 0).toStringAsFixed(1),
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      Container(
                        height: 3,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: [
                            MausamPalette.accentBlue,
                            WeatherPalette.teal,
                            WeatherPalette.amber,
                            const Color(0xFF94A3B8),
                            const Color(0xFFA78BFA),
                            const Color(0xFF34D399),
                          ][i],
                          borderRadius: BorderRadius.circular(99),
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
          title: Text('AQI scale', style: GoogleFonts.outfit(color: Colors.white)),
          content: Text(
            'Good 0–50. Fair 51–100. Moderate 101–150. Poor 151–200. Very Poor 201+.\n\n'
            'Values come from OpenWeatherMap Air Pollution (mapped to a US-style midpoint).',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
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
      title: 'Sun & Moon',
      child: Column(
        children: [
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: _SunArcPainter(t: t),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 36),
                  child: Text(
                    daylightLabel,
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sunrise ${_fmtUnix(rise, current.timezoneOffsetSec)}',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
              Text('Sunset ${_fmtUnix(set, current.timezoneOffsetSec)}',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(moonGlyph(today?.moonPhase), style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moonPhaseName(today?.moonPhase),
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Rise ${_fmtUnix(today?.moonriseUnix, current.timezoneOffsetSec)}  •  Set ${_fmtUnix(today?.moonsetUnix, current.timezoneOffsetSec)}',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
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
      title: 'Pressure',
      child: Column(
        children: [
          SizedBox(
            height: 90,
            width: double.infinity,
            child: CustomPaint(
              painter: _PressureGaugePainter(t: t),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Text(
                    hpa == null ? '--' : '${hpa!.round()}',
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
          Text('mbar', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Low', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
              Text('High', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
            ],
          ),
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
      title: 'Wind',
      child: SizedBox(
        height: 120,
        width: double.infinity,
        child: CustomPaint(
          painter: _CompassPainter(deg: deg ?? 0),
          child: Center(
            child: Text(
              '${speed.round()}\nkm/h',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, height: 1.1),
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
      title: 'UV Index',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${uv.toStringAsFixed(1)}  ${uvCategory(uv)}',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 10),
          SizedBox(
            height: 14,
            width: double.infinity,
            child: CustomPaint(
              painter: _GradientMarkerPainter(
                position: (uv / 12).clamp(0.0, 1.0),
                colors: const [
                  Color(0xFF22C55E),
                  Color(0xFFFACC15),
                  Color(0xFFF97316),
                  Color(0xFFEF4444),
                  Color(0xFF7C3AED),
                ],
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 10),
          Text(uvGuidance(uv), style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
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
      title: 'Visibility',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            km == null ? '--' : '${km!.toStringAsFixed(1)} km',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22),
          ),
          const SizedBox(height: 8),
          Text(visibilityLine(km), style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
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
      title: 'Precipitation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${(nextMm ?? 0).toStringAsFixed(1)} mm',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22),
          ),
          const SizedBox(height: 6),
          Text('Next 24h (forecast)', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
          if (lastMm != null) ...[
            const SizedBox(height: 6),
            Text('Recent 1h ${lastMm!.toStringAsFixed(1)} mm',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
          ] else
            Text('Last 24h not provided by the current weather endpoint',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
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
      title: 'Humidity',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$percent%', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            dew == null ? 'Dew point unavailable' : 'Dew point ${dew!.round()}°',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
          ),
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
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
    decoration: BoxDecoration(
      color: MausamPalette.cardSurface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: MausamPalette.cardBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  if (subtitle != null)
                    Text(subtitle, style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

Widget _miniCard({required String title, required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: MausamPalette.cardSurface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: MausamPalette.cardBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        child,
      ],
    ),
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
      Color(0xFF22C55E),
      Color(0xFFFACC15),
      Color(0xFFF97316),
      Color(0xFFEF4444),
      Color(0xFF7C3AED),
    ],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromLTRBR(0, size.height * 0.35, size.width, size.height * 0.65, const Radius.circular(99));
    final paint = Paint()
      ..shader = LinearGradient(colors: colors).createShader(Offset.zero & size);
    canvas.drawRRect(rect, paint);
    final x = position * size.width;
    canvas.drawCircle(Offset(x, size.height / 2), 6, Paint()..color = Colors.white);
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
      ..strokeWidth = 3
      ..color = MausamPalette.accentOrange.withValues(alpha: 0.7);
    canvas.drawArc(rect, math.pi, math.pi, false, arcPaint);
    final angle = math.pi + t * math.pi;
    final cx = rect.center.dx + rect.width / 2 * math.cos(angle);
    final cy = rect.center.dy + rect.height / 2 * math.sin(angle);
    canvas.drawCircle(Offset(cx, cy), 8, Paint()..color = MausamPalette.accentOrange);
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
    final rect = Rect.fromCircle(center: center, radius: 42);
    canvas.drawArc(rect, math.pi, math.pi, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = MausamPalette.cardBorder);
    canvas.drawArc(
      rect,
      math.pi,
      math.pi * t,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = MausamPalette.accentCyan,
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
    canvas.drawCircle(c, 46, Paint()
      ..style = PaintingStyle.stroke
      ..color = MausamPalette.cardBorder
      ..strokeWidth = 2);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(deg * math.pi / 180);
    final path = Path()
      ..moveTo(0, -34)
      ..lineTo(7, 16)
      ..lineTo(0, 8)
      ..lineTo(-7, 16)
      ..close();
    canvas.drawPath(path, Paint()..color = MausamPalette.accentBlue);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) => oldDelegate.deg != deg;
}
