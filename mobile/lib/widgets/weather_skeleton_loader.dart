import 'package:flutter/material.dart';
import '../theme/weather_palette.dart';

/// Shimmer skeleton loader replacing spinners during weather data fetching.
class WeatherSkeletonLoader extends StatefulWidget {
  const WeatherSkeletonLoader({super.key});

  @override
  State<WeatherSkeletonLoader> createState() => _WeatherSkeletonLoaderState();
}

class _WeatherSkeletonLoaderState extends State<WeatherSkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shimmerGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            MausamPalette.cardSurface,
            MausamPalette.cardSurfaceLight,
            MausamPalette.cardSurface,
          ],
          stops: [
            (_controller.value - 0.3).clamp(0.0, 1.0),
            _controller.value,
            (_controller.value + 0.3).clamp(0.0, 1.0),
          ],
        );

        return ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
          children: [
            // Hero card skeleton
            _SkeletonBox(
              height: 200,
              radius: 24,
              gradient: shimmerGradient,
            ),
            const SizedBox(height: 14),

            // Hourly strip skeleton
            _SkeletonBox(
              height: 110,
              radius: 20,
              gradient: shimmerGradient,
            ),
            const SizedBox(height: 14),

            // Daily forecast skeleton
            _SkeletonBox(
              height: 220,
              radius: 20,
              gradient: shimmerGradient,
            ),
            const SizedBox(height: 14),

            // AQI card skeleton
            _SkeletonBox(
              height: 140,
              radius: 20,
              gradient: shimmerGradient,
            ),
          ],
        );
      },
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;
  final double radius;
  final LinearGradient gradient;

  const _SkeletonBox({
    required this.height,
    required this.radius,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: MausamPalette.cardShadow,
      ),
    );
  }
}
