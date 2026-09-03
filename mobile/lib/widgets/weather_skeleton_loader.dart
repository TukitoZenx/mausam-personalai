import 'package:flutter/material.dart';

import '../theme/weather_palette.dart';

class WeatherSkeletonLoader extends StatefulWidget {
  const WeatherSkeletonLoader({super.key});

  @override
  State<WeatherSkeletonLoader> createState() => _WeatherSkeletonLoaderState();
}

class _WeatherSkeletonLoaderState extends State<WeatherSkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _box({required double width, required double height, double radius = 12}) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: MausamPalette.cardSurface.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: MausamPalette.cardBorder.withValues(alpha: 0.5)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        // Header bar skeleton
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _box(width: 100, height: 20, radius: 6),
            _box(width: 120, height: 28, radius: 20),
            _box(width: 36, height: 36, radius: 18),
          ],
        ),
        const SizedBox(height: 16),

        // Weather Hero Skeleton
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: MausamPalette.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: MausamPalette.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(width: 90, height: 16, radius: 4),
              const SizedBox(height: 12),
              Row(
                children: [
                  _box(width: 120, height: 60, radius: 12),
                  const Spacer(),
                  _box(width: 52, height: 52, radius: 26),
                ],
              ),
              const SizedBox(height: 12),
              _box(width: 140, height: 14, radius: 4),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _box(width: double.infinity, height: 32, radius: 8)),
                  const SizedBox(width: 8),
                  Expanded(child: _box(width: double.infinity, height: 32, radius: 8)),
                  const SizedBox(width: 8),
                  Expanded(child: _box(width: double.infinity, height: 32, radius: 8)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // FOR YOU Recommendation Section Skeleton
        Container(
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
              Row(
                children: [
                  _box(width: 16, height: 16, radius: 8),
                  const SizedBox(width: 8),
                  _box(width: 120, height: 14, radius: 4),
                ],
              ),
              const SizedBox(height: 12),
              _box(width: 200, height: 18, radius: 4),
              const SizedBox(height: 8),
              _box(width: double.infinity, height: 14, radius: 4),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Hourly Forecast Skeleton Strip
        Container(
          height: 104,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MausamPalette.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MausamPalette.cardBorder),
          ),
          child: Row(
            children: List.generate(
              5,
              (index) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _box(width: double.infinity, height: double.infinity, radius: 10),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // AQI Skeleton
        Container(
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
              _box(width: 80, height: 14, radius: 4),
              const SizedBox(height: 12),
              Row(
                children: [
                  _box(width: 70, height: 40, radius: 8),
                  const SizedBox(width: 12),
                  _box(width: 100, height: 18, radius: 4),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
