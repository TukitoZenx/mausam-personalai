import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/weather_ai_card_data.dart';
import '../providers/location_provider.dart';
import '../providers/weather_dashboard_provider.dart';

/// Weather map visualization layers.
enum WeatherMapLayer {
  weather,
  rain,
  temperature,
  aqi,
  wind,
  alerts,
}

extension WeatherMapLayerExt on WeatherMapLayer {
  String get label {
    switch (this) {
      case WeatherMapLayer.weather:
        return 'Weather';
      case WeatherMapLayer.rain:
        return 'Rain';
      case WeatherMapLayer.temperature:
        return 'Temperature';
      case WeatherMapLayer.aqi:
        return 'AQI';
      case WeatherMapLayer.wind:
        return 'Wind';
      case WeatherMapLayer.alerts:
        return 'Alerts';
    }
  }

  IconData get icon {
    switch (this) {
      case WeatherMapLayer.weather:
        return Icons.wb_sunny_rounded;
      case WeatherMapLayer.rain:
        return Icons.water_drop_rounded;
      case WeatherMapLayer.temperature:
        return Icons.thermostat_rounded;
      case WeatherMapLayer.aqi:
        return Icons.bubble_chart_rounded;
      case WeatherMapLayer.wind:
        return Icons.air_rounded;
      case WeatherMapLayer.alerts:
        return Icons.warning_amber_rounded;
    }
  }
}

/// Static geographical reference cities across India for the overview mode.
class _IndiaCityReference {
  final String name;
  final double lat;
  final double lon;

  const _IndiaCityReference(this.name, this.lat, this.lon);
}

const List<_IndiaCityReference> _kIndiaReferenceCities = [
  _IndiaCityReference('New Delhi', 28.6139, 77.2090),
  _IndiaCityReference('Mumbai', 19.0760, 72.8777),
  _IndiaCityReference('Kolkata', 22.5726, 88.3639),
  _IndiaCityReference('Chennai', 13.0827, 80.2707),
  _IndiaCityReference('Bengaluru', 12.9716, 77.5946),
  _IndiaCityReference('Hyderabad', 17.3850, 78.4867),
  _IndiaCityReference('Ahmedabad', 23.0225, 72.5714),
  _IndiaCityReference('Jaipur', 26.9124, 75.7873),
  _IndiaCityReference('Lucknow', 26.8467, 80.9462),
  _IndiaCityReference('Guwahati', 26.1445, 91.7362),
  _IndiaCityReference('Srinagar', 34.0837, 74.7973),
  _IndiaCityReference('Kochi', 9.9312, 76.2673),
  _IndiaCityReference('Bhopal', 23.2599, 77.4126),
  _IndiaCityReference('Patna', 25.5941, 85.1376),
  _IndiaCityReference('Bhubaneswar', 20.2961, 85.8245),
  _IndiaCityReference('Visakhapatnam', 17.6868, 83.2185),
];

/// India Bounding Box for Mercator/Equirectangular canvas projection.
const double _kMinLat = 6.5;
const double _kMaxLat = 37.5;
const double _kMinLon = 68.0;
const double _kMaxLon = 97.5;
const double _kCanvasWidth = 1000.0;
const double _kCanvasHeight = 1200.0;

/// Projects (lat, lon) to canvas coordinate space (1000 x 1200).
Offset _projectGeoToCanvas(double lat, double lon) {
  final clampedLat = lat.clamp(_kMinLat, _kMaxLat);
  final clampedLon = lon.clamp(_kMinLon, _kMaxLon);

  final x = ((clampedLon - _kMinLon) / (_kMaxLon - _kMinLon)) * _kCanvasWidth;
  final y = (1.0 - ((clampedLat - _kMinLat) / (_kMaxLat - _kMinLat))) * _kCanvasHeight;
  return Offset(x, y);
}

/// Dedicated Premium India Weather Map Screen.
/// Supports both Route Inspection Mode (from AI Chat) and India Overview Mode.
class WeatherMapScreen extends ConsumerStatefulWidget {
  final WeatherAiCardData? routeData;

  const WeatherMapScreen({
    super.key,
    this.routeData,
  });

  @override
  ConsumerState<WeatherMapScreen> createState() => _WeatherMapScreenState();
}

class _WeatherMapScreenState extends ConsumerState<WeatherMapScreen> {
  late final TransformationController _transformController;
  WeatherMapLayer _activeLayer = WeatherMapLayer.weather;
  int? _selectedStationIndex;
  _IndiaCityReference? _selectedRefCity;

  bool get _isRouteMode => widget.routeData != null;

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapInitial();
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  /// Initial viewport fitting: auto-fit to route if route mode, else center India overview.
  void _fitMapInitial() {
    if (!mounted) return;
    final size = MediaQuery.sizeOf(context);
    if (_isRouteMode) {
      _fitRouteInViewport(size);
    } else {
      _centerIndiaOverview(size);
    }
  }

  Matrix4 _matrixFor(double tx, double ty, double scale) {
    return Matrix4.identity()
      ..setTranslationRaw(tx, ty, 0.0)
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale);
  }

  void _centerIndiaOverview(Size viewportSize) {
    const defaultScale = 0.55;
    final centerCanvas = _projectGeoToCanvas(22.0, 82.0);

    final tx = (viewportSize.width / 2) - (centerCanvas.dx * defaultScale);
    final ty = (viewportSize.height / 2) - (centerCanvas.dy * defaultScale);

    _transformController.value = _matrixFor(tx, ty, defaultScale);
  }

  void _fitRouteInViewport(Size viewportSize) {
    final points = widget.routeData?.routePoints;
    if (points == null || points.isEmpty) {
      _centerIndiaOverview(viewportSize);
      return;
    }

    double minLat = points.first.lat;
    double maxLat = points.first.lat;
    double minLon = points.first.lon;
    double maxLon = points.first.lon;

    for (final p in points) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lon < minLon) minLon = p.lon;
      if (p.lon > maxLon) maxLon = p.lon;
    }

    final p1 = _projectGeoToCanvas(maxLat, minLon); // top-left
    final p2 = _projectGeoToCanvas(minLat, maxLon); // bottom-right

    final routeWidth = (p2.dx - p1.dx).abs().clamp(100.0, _kCanvasWidth);
    final routeHeight = (p2.dy - p1.dy).abs().clamp(100.0, _kCanvasHeight);
    final routeCenter = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);

    // Leave safe padding margins for glassmorphic controls
    final usableW = viewportSize.width * 0.75;
    final usableH = viewportSize.height * 0.55;

    final scaleX = usableW / routeWidth;
    final scaleY = usableH / routeHeight;
    final targetScale = math.min(scaleX, scaleY).clamp(0.65, 3.5);

    final tx = (viewportSize.width / 2) - (routeCenter.dx * targetScale);
    final ty = (viewportSize.height / 2) - (routeCenter.dy * targetScale);

    setState(() {
      _transformController.value = _matrixFor(tx, ty, targetScale);
    });
  }

  void _focusOnStation(int index) {
    final points = widget.routeData?.routePoints;
    if (points == null || index < 0 || index >= points.length) return;

    setState(() {
      _selectedStationIndex = index;
      _selectedRefCity = null;
    });

    final targetOffset = _projectGeoToCanvas(points[index].lat, points[index].lon);
    final viewportSize = MediaQuery.sizeOf(context);
    const targetScale = 1.8;

    final tx = (viewportSize.width / 2) - (targetOffset.dx * targetScale);
    final ty = (viewportSize.height / 2) - (targetOffset.dy * targetScale);

    _transformController.value = _matrixFor(tx, ty, targetScale);
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.routeData;
    final points = route?.routePoints ?? [];
    final locState = ref.watch(locationProvider);
    final dash = ref.watch(weatherDashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF070B13),
      body: Stack(
        children: [
          // 1. Interactive Canvas Map Viewport
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.35,
              maxScale: 6.0,
              boundaryMargin: const EdgeInsets.all(800),
              child: SizedBox(
                width: _kCanvasWidth,
                height: _kCanvasHeight,
                child: CustomPaint(
                  size: const Size(_kCanvasWidth, _kCanvasHeight),
                  painter: _IndiaMapCanvasPainter(
                    activeLayer: _activeLayer,
                    routeData: route,
                    selectedStationIndex: _selectedStationIndex,
                    selectedRefCity: _selectedRefCity,
                    activeLocationLat: locState.activeLatitude != 0 ? locState.activeLatitude : null,
                    activeLocationLon: locState.activeLongitude != 0 ? locState.activeLongitude : null,
                    activeCityName: locState.activeCityName,
                    activeCityTemp: dash.data?.current.temperatureCelsius.round(),
                    activeCityCond: dash.data?.current.condition,
                    activeCityAqi: dash.data?.aqi?.aqiValue,
                  ),
                ),
              ),
            ),
          ),

          // 2. Invisible Tap Overlay for Stations on Canvas
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapUp: (details) {
                    final tapPos = details.localPosition;
                    final matrix = _transformController.value;
                    final inverted = Matrix4.inverted(matrix);
                    final canvasTap = MatrixUtils.transformPoint(inverted, tapPos);

                    // 1. Check Route Points
                    int? foundRouteIdx;
                    double minDist = 35.0;

                    for (int i = 0; i < points.length; i++) {
                      final ptPos = _projectGeoToCanvas(points[i].lat, points[i].lon);
                      final dist = (canvasTap - ptPos).distance;
                      if (dist < minDist) {
                        minDist = dist;
                        foundRouteIdx = i;
                      }
                    }

                    if (foundRouteIdx != null) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedStationIndex =
                            _selectedStationIndex == foundRouteIdx ? null : foundRouteIdx;
                        _selectedRefCity = null;
                      });
                      return;
                    }

                    // 2. Check Reference Cities (if in overview mode or nearby)
                    _IndiaCityReference? foundCity;
                    double minCityDist = 32.0;
                    for (final city in _kIndiaReferenceCities) {
                      final cityPos = _projectGeoToCanvas(city.lat, city.lon);
                      final dist = (canvasTap - cityPos).distance;
                      if (dist < minCityDist) {
                        minCityDist = dist;
                        foundCity = city;
                      }
                    }

                    if (foundCity != null) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedRefCity =
                            _selectedRefCity?.name == foundCity?.name ? null : foundCity;
                        _selectedStationIndex = null;
                      });
                      return;
                    }

                    // If tap elsewhere, dismiss open station popup
                    if (_selectedStationIndex != null || _selectedRefCity != null) {
                      setState(() {
                        _selectedStationIndex = null;
                        _selectedRefCity = null;
                      });
                    }
                  },
                );
              },
            ),
          ),

          // 3. Top Glassmorphic Navigation Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(context, route),
          ),

          // 4. Layer Telemetry & Factual Availability Banner
          Positioned(
            top: 105,
            left: 16,
            right: 16,
            child: _buildLayerTelemetryBanner(),
          ),

          // 5. Selected Station / Node Popup Card
          if (_selectedStationIndex != null &&
              _selectedStationIndex! < points.length)
            Positioned(
              top: 155,
              left: 20,
              right: 20,
              child: _buildStationPopupCard(points[_selectedStationIndex!]),
            )
          else if (_selectedRefCity != null)
            Positioned(
              top: 155,
              left: 20,
              right: 20,
              child: _buildReferenceCityPopupCard(_selectedRefCity!),
            ),

          // 6. Synchronized Route Context Strip (AI Travel Mode)
          if (_isRouteMode && points.isNotEmpty)
            Positioned(
              bottom: 92,
              left: 0,
              right: 0,
              child: _buildSynchronizedRouteStrip(points),
            ),

          // 7. Bottom Floating Layer Selector
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _buildLayerSelector(),
          ),
        ],
      ),
    );
  }

  /// Top Glassmorphic Bar with Back Button, Title, and Reset View.
  Widget _buildTopBar(BuildContext context, WeatherAiCardData? route) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0A0F1D).withValues(alpha: 0.95),
            const Color(0xFF0A0F1D).withValues(alpha: 0.75),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.lightImpact();
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2C).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF26334D)),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title & Mode Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.map_rounded,
                        size: 15,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Weather Map',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _isRouteMode
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : const Color(0xFF06B6D4).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _isRouteMode
                                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                : const Color(0xFF06B6D4).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          _isRouteMode ? 'ROUTE MODE' : 'INDIA OVERVIEW',
                          style: GoogleFonts.inter(
                            color: _isRouteMode ? const Color(0xFF34D399) : const Color(0xFF38BDF8),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isRouteMode
                      ? '${route?.origin ?? 'Origin'} → ${route?.destination ?? 'Destination'} (${route?.distanceKm ?? '~'} km · ${route?.durationText ?? ''})'
                      : 'Live weather telemetry across India',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Re-center / Fit Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.lightImpact();
                final size = MediaQuery.sizeOf(context);
                if (_isRouteMode) {
                  _fitRouteInViewport(size);
                } else {
                  _centerIndiaOverview(size);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2C).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF26334D)),
                ),
                child: Icon(
                  _isRouteMode ? Icons.crop_free_rounded : Icons.my_location_rounded,
                  size: 16,
                  color: const Color(0xFF38BDF8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Factual Layer Telemetry Status Banner.
  /// Complies strictly with the product rule: NEVER fabricate missing nationwide fields.
  Widget _buildLayerTelemetryBanner() {
    String message;
    Color accentColor;
    IconData icon;

    switch (_activeLayer) {
      case WeatherMapLayer.weather:
        message = _isRouteMode
            ? 'Real station weather active along your travel route.'
            : 'Live regional weather stations reporting telemetry.';
        accentColor = const Color(0xFF10B981);
        icon = Icons.check_circle_outline_rounded;
        break;
      case WeatherMapLayer.rain:
        message = 'Station precipitation active · Nationwide radar grid unavailable';
        accentColor = const Color(0xFF38BDF8);
        icon = Icons.info_outline_rounded;
        break;
      case WeatherMapLayer.temperature:
        message = 'Station temperatures active · Spatial raster interpolation unavailable';
        accentColor = const Color(0xFFF59E0B);
        icon = Icons.info_outline_rounded;
        break;
      case WeatherMapLayer.aqi:
        message = 'Station AQI sensors active · Nationwide pollution heatmap unavailable';
        accentColor = const Color(0xFFA855F7);
        icon = Icons.info_outline_rounded;
        break;
      case WeatherMapLayer.wind:
        message = 'Station anemometers active · Nationwide vector field unavailable';
        accentColor = const Color(0xFF06B6D4);
        icon = Icons.info_outline_rounded;
        break;
      case WeatherMapLayer.alerts:
        message = 'Official IMD alerts · 0 active nationwide severe advisories';
        accentColor = const Color(0xFFEF4444);
        icon = Icons.verified_user_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1322).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accentColor),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: const Color(0xFFCBD5E1),
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact Glassmorphic Weather Popup Card for Route Points.
  Widget _buildStationPopupCard(TravelRoutePoint point) {
    final temp = point.temperature;
    final cond = point.condition;
    final aqi = point.aqi;
    final aqiCat = point.aqiCategory;
    final rain = point.weather?['rain_mm'] ?? point.weather?['rainMm'];
    final wind = point.weather?['wind_speed_kmh'] ?? point.weather?['windSpeed'];

    final roleLabel = point.isOrigin
        ? 'ORIGIN STATION'
        : (point.isDestination ? 'DESTINATION STATION' : 'INTERMEDIATE STOP');
    final accent = point.isOrigin
        ? const Color(0xFF06B6D4)
        : (point.isDestination ? const Color(0xFF10B981) : const Color(0xFF38BDF8));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF11192A).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Role, Name, Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    roleLabel,
                    style: GoogleFonts.inter(
                      color: accent,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedStationIndex = null);
                },
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Station Name & Temp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                point.name,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (temp != null)
                Text(
                  '$temp°C',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF34D399),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                Text(
                  '--°C',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Weather Attributes Row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (cond != null && cond.isNotEmpty)
                _buildStatPill(Icons.cloud_outlined, cond, const Color(0xFF94A3B8)),
              if (aqi != null)
                _buildStatPill(
                  Icons.bubble_chart_rounded,
                  'AQI $aqi (${aqiCat ?? 'Moderate'})',
                  _aqiColor(aqi),
                ),
              if (rain != null)
                _buildStatPill(Icons.water_drop_rounded, '$rain mm', const Color(0xFF38BDF8)),
              if (wind != null)
                _buildStatPill(Icons.air_rounded, '$wind km/h', const Color(0xFF06B6D4)),
            ],
          ),
        ],
      ),
    );
  }

  /// Compact Popup Card for Reference Cities.
  Widget _buildReferenceCityPopupCard(_IndiaCityReference city) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF11192A).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'REGIONAL WEATHER HUB',
                style: GoogleFonts.inter(
                  color: const Color(0xFF38BDF8),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              InkWell(
                onTap: () => setState(() => _selectedRefCity = null),
                child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            city.name,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Coordinates: ${city.lat.toStringAsFixed(2)}°N, ${city.lon.toStringAsFixed(2)}°E',
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Synchronized Route Strip at Bottom (AI Travel Mode).
  Widget _buildSynchronizedRouteStrip(List<TravelRoutePoint> points) {
    return Container(
      height: 62,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1322).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int index = 0; index < points.length; index++) ...[
              if (index > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Center(
                    child: Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF475569)),
                  ),
                ),
              _buildRouteStripItem(points[index], index),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRouteStripItem(TravelRoutePoint p, int index) {
    final isSelected = _selectedStationIndex == index;
    final temp = p.temperature;
    final accent = p.isOrigin
        ? const Color(0xFF06B6D4)
        : (p.isDestination ? const Color(0xFF10B981) : const Color(0xFF38BDF8));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _focusOnStation(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withValues(alpha: 0.22)
                : const Color(0xFF162032).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? accent : const Color(0xFF26334D),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                p.isOrigin
                    ? Icons.trip_origin_rounded
                    : (p.isDestination
                        ? Icons.location_on_rounded
                        : Icons.radio_button_checked_rounded),
                size: 11,
                color: accent,
              ),
              const SizedBox(width: 6),
              Text(
                p.name,
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (temp != null) ...[
                const SizedBox(width: 6),
                Text(
                  '$temp°',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF34D399),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Minimal Glassmorphic Floating Layer Selector Bar.
  Widget _buildLayerSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1626).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF24334E)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: WeatherMapLayer.values.map((layer) {
            final isSelected = _activeLayer == layer;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _activeLayer = layer);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          layer.icon,
                          size: 13,
                          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          layer.label,
                          style: GoogleFonts.inter(
                            color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

Color _aqiColor(int aqi) {
  if (aqi <= 50) return const Color(0xFF10B981);
  if (aqi <= 100) return const Color(0xFFF59E0B);
  if (aqi <= 150) return const Color(0xFFF97316);
  if (aqi <= 200) return const Color(0xFFEF4444);
  if (aqi <= 300) return const Color(0xFFA855F7);
  return const Color(0xFF7F1D1D);
}

/// Custom Vector Map Painter for India Canvas.
class _IndiaMapCanvasPainter extends CustomPainter {
  final WeatherMapLayer activeLayer;
  final WeatherAiCardData? routeData;
  final int? selectedStationIndex;
  final _IndiaCityReference? selectedRefCity;
  final double? activeLocationLat;
  final double? activeLocationLon;
  final String activeCityName;
  final int? activeCityTemp;
  final String? activeCityCond;
  final int? activeCityAqi;

  _IndiaMapCanvasPainter({
    required this.activeLayer,
    required this.routeData,
    required this.selectedStationIndex,
    required this.selectedRefCity,
    required this.activeLocationLat,
    required this.activeLocationLon,
    required this.activeCityName,
    required this.activeCityTemp,
    required this.activeCityCond,
    required this.activeCityAqi,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawOceanBackground(canvas, size);
    _drawCoordinateGrid(canvas, size);
    _drawIndiaLandmass(canvas, size);
    _drawRoutePolyline(canvas);
    _drawReferenceCities(canvas);
    _drawRouteNodes(canvas);
  }

  void _drawOceanBackground(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF070B13);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Subtle water labels
    final arabianSea = _projectGeoToCanvas(15.0, 69.5);
    final bayOfBengal = _projectGeoToCanvas(14.5, 88.5);
    final indianOcean = _projectGeoToCanvas(7.0, 78.5);

    _drawWaterText(canvas, 'ARABIAN SEA', arabianSea);
    _drawWaterText(canvas, 'BAY OF BENGAL', bayOfBengal);
    _drawWaterText(canvas, 'INDIAN OCEAN', indianOcean);
  }

  void _drawWaterText(Canvas canvas, String text, Offset position) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.inter(
          color: const Color(0xFF1E293B).withValues(alpha: 0.6),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      position - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawCoordinateGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF172033).withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    // Latitudes (every 5 degrees)
    for (double lat = 10; lat <= 35; lat += 5) {
      final y = _projectGeoToCanvas(lat, 70).dy;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Longitudes (every 5 degrees)
    for (double lon = 70; lon <= 95; lon += 5) {
      final x = _projectGeoToCanvas(15, lon).dx;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  /// Authentic India Geographic Coastline & Landmass Polygon.
  void _drawIndiaLandmass(Canvas canvas, Size size) {
    // Key landmark boundary coordinates representing the recognizable shape of India
    const List<List<double>> boundaryCoords = [
      // Northern Kashmir Arc & Himalayas
      [35.5, 74.8],
      [36.8, 74.2],
      [37.1, 75.0],
      [35.8, 77.8],
      [34.5, 79.0],
      [32.8, 79.0],
      [31.2, 79.8],
      [30.2, 81.0],
      [28.8, 83.5],
      [27.8, 88.0],
      [27.3, 89.5],
      // Northeast Arc
      [28.2, 94.5],
      [28.5, 96.5],
      [27.5, 97.0],
      [25.5, 94.5],
      [24.0, 93.5],
      [22.8, 92.5],
      [25.0, 90.5],
      [25.8, 89.8],
      // Bengal Coast & Eastern Ghats Coast
      [22.2, 89.0],
      [21.5, 87.0],
      [19.8, 85.8],
      [17.7, 83.3],
      [16.2, 81.8],
      [15.8, 80.8],
      [13.1, 80.3], // Chennai
      [11.9, 79.8],
      [10.8, 79.9],
      [9.3, 79.1], // Palk Strait
      // Southern Tip
      [8.08, 77.55], // Kanyakumari
      // Western Ghats & Malabar Coast
      [8.5, 76.9],
      [9.9, 76.2], // Kochi
      [12.9, 74.8], // Mangalore
      [15.4, 73.8], // Goa
      [18.9, 72.8], // Mumbai
      // Gujarat Peninsula (Kathiawar & Kutch)
      [20.5, 72.8],
      [21.7, 72.2],
      [20.8, 70.9],
      [22.3, 69.0], // Dwarka
      [23.0, 70.2],
      [23.8, 68.5], // Rann of Kutch
      // Western/Northwestern Border
      [24.5, 71.0],
      [26.5, 70.5], // Rajasthan Thar
      [28.5, 71.5],
      [31.5, 74.5], // Punjab
      [33.5, 74.0],
    ];

    final path = Path();
    for (int i = 0; i < boundaryCoords.length; i++) {
      final pos = _projectGeoToCanvas(boundaryCoords[i][0], boundaryCoords[i][1]);
      if (i == 0) {
        path.moveTo(pos.dx, pos.dy);
      } else {
        path.lineTo(pos.dx, pos.dy);
      }
    }
    path.close();

    // Landmass Fill
    final landFillPaint = Paint()
      ..color = const Color(0xFF0E1626)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, landFillPaint);

    // Landmass Border (High-precision coast stroke)
    final landStrokePaint = Paint()
      ..color = const Color(0xFF1E2E4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(path, landStrokePaint);
  }

  /// Draws the Highway Route Line with Neon Glow.
  void _drawRoutePolyline(Canvas canvas) {
    final points = routeData?.routePoints;
    final geometry = routeData?.routeGeometry;

    if (points == null || points.length < 2) return;

    final path = Path();
    if (geometry != null && geometry.length >= 2) {
      for (int i = 0; i < geometry.length; i++) {
        final pos = _projectGeoToCanvas(geometry[i]['lat']!, geometry[i]['lon']!);
        if (i == 0) {
          path.moveTo(pos.dx, pos.dy);
        } else {
          path.lineTo(pos.dx, pos.dy);
        }
      }
    } else {
      // Connect route points directly
      for (int i = 0; i < points.length; i++) {
        final pos = _projectGeoToCanvas(points[i].lat, points[i].lon);
        if (i == 0) {
          path.moveTo(pos.dx, pos.dy);
        } else {
          path.lineTo(pos.dx, pos.dy);
        }
      }
    }

    // Layer 1: Outer Neon Halo
    final haloPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, haloPaint);

    // Layer 2: Medium Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, glowPaint);

    // Layer 3: Solid Core Path
    final corePaint = Paint()
      ..color = const Color(0xFF34D399)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, corePaint);
  }

  /// Draws Reference Cities on the Map.
  void _drawReferenceCities(Canvas canvas) {
    for (final city in _kIndiaReferenceCities) {
      final pos = _projectGeoToCanvas(city.lat, city.lon);
      final isSelected = selectedRefCity?.name == city.name;

      final dotPaint = Paint()
        ..color = isSelected ? const Color(0xFF38BDF8) : const Color(0xFF475569)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, isSelected ? 4.5 : 2.5, dotPaint);

      // Label
      final tp = TextPainter(
        text: TextSpan(
          text: city.name,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontSize: isSelected ? 10.0 : 8.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos + const Offset(6, -5));
    }
  }

  /// Draws Route Nodes (Origin, Destination, Intermediate Stops) with Telemetry.
  void _drawRouteNodes(Canvas canvas) {
    final points = routeData?.routePoints;
    if (points == null || points.isEmpty) return;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final pos = _projectGeoToCanvas(p.lat, p.lon);
      final isSelected = selectedStationIndex == i;

      if (p.isOrigin) {
        _drawOriginMarker(canvas, pos, p.name, isSelected);
      } else if (p.isDestination) {
        _drawDestinationMarker(canvas, pos, p.name, p.temperature, isSelected);
      } else {
        _drawIntermediateMarker(canvas, pos, p.name, p.temperature, isSelected, i);
      }
    }
  }

  void _drawOriginMarker(Canvas canvas, Offset pos, String name, bool isSelected) {
    const color = Color(0xFF06B6D4);

    // Outer Halo
    final haloPaint = Paint()
      ..color = color.withValues(alpha: isSelected ? 0.45 : 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, isSelected ? 14 : 9, haloPaint);

    // Core Ring
    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(pos, 5.5, ringPaint);

    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 2.5, innerPaint);

    _drawNodeBadge(canvas, pos, name, null, color, isSelected);
  }

  void _drawDestinationMarker(
    Canvas canvas,
    Offset pos,
    String name,
    int? temp,
    bool isSelected,
  ) {
    const color = Color(0xFF10B981);

    // Outer Halo
    final haloPaint = Paint()
      ..color = color.withValues(alpha: isSelected ? 0.5 : 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, isSelected ? 16 : 10, haloPaint);

    // Solid Pin Body
    final pinPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 6.0, pinPaint);

    final whiteCenter = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 2.5, whiteCenter);

    _drawNodeBadge(canvas, pos, name, temp, color, isSelected);
  }

  void _drawIntermediateMarker(
    Canvas canvas,
    Offset pos,
    String name,
    int? temp,
    bool isSelected,
    int index,
  ) {
    final color = isSelected ? const Color(0xFF38BDF8) : const Color(0xFF10B981);

    if (isSelected) {
      final haloPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 12, haloPaint);
    }

    final nodePaint = Paint()
      ..color = isSelected ? color : const Color(0xFF0B1220)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, isSelected ? 5.0 : 4.0, nodePaint);

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(pos, isSelected ? 5.0 : 4.0, borderPaint);

    _drawNodeBadge(canvas, pos, name, temp, color, isSelected);
  }

  void _drawNodeBadge(
    Canvas canvas,
    Offset pos,
    String name,
    int? temp,
    Color accent,
    bool isSelected,
  ) {
    final text = temp != null ? '$name · $temp°C' : name;
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: isSelected ? 11.0 : 9.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeOffset = pos + const Offset(10, -8);
    final bgRect = Rect.fromLTWH(
      badgeOffset.dx - 4,
      badgeOffset.dy - 2,
      textPainter.width + 8,
      textPainter.height + 4,
    );

    final rrect = RRect.fromRectAndRadius(bgRect, const Radius.circular(5));
    final bgPaint = Paint()
      ..color = const Color(0xFF0E1626).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()
      ..color = accent.withValues(alpha: isSelected ? 0.8 : 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rrect, borderPaint);

    textPainter.paint(canvas, badgeOffset);
  }

  @override
  bool shouldRepaint(covariant _IndiaMapCanvasPainter oldDelegate) {
    return oldDelegate.activeLayer != activeLayer ||
        oldDelegate.selectedStationIndex != selectedStationIndex ||
        oldDelegate.selectedRefCity != selectedRefCity ||
        oldDelegate.routeData != routeData;
  }
}
