import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BouncingDotsWidget extends StatefulWidget {
  const BouncingDotsWidget({super.key});

  @override
  State<BouncingDotsWidget> createState() => _BouncingDotsWidgetState();
}

class _BouncingDotsWidgetState extends State<BouncingDotsWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final delayFraction = index * 0.15; // 0ms, 150ms, 300ms stagger
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = (_controller.value - delayFraction) % 1.0;
            // Bounce up and down curve
            final bounce = (t < 0.5)
                ? (t * 2)
                : ((1.0 - t) * 2);
            final offsetY = -6.0 * (bounce < 0 ? 0 : bounce);

            return Transform.translate(
              offset: Offset(0, offsetY),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF3FA9F5),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class LoadingTextPulseWidget extends StatefulWidget {
  const LoadingTextPulseWidget({super.key});

  @override
  State<LoadingTextPulseWidget> createState() => _LoadingTextPulseWidgetState();
}

class _LoadingTextPulseWidgetState extends State<LoadingTextPulseWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Text(
            'Loading your sky...',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF6B7A93),
              letterSpacing: 0.5,
            ),
          ),
        );
      },
    );
  }
}

class ShimmerProgressBar extends StatefulWidget {
  const ShimmerProgressBar({
    super.key,
    required this.progress,
  });

  final double progress; // 0.0 to 1.0

  @override
  State<ShimmerProgressBar> createState() => _ShimmerProgressBarState();
}

class _ShimmerProgressBarState extends State<ShimmerProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 2,
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A40),
        borderRadius: BorderRadius.circular(1),
      ),
      child: Stack(
        children: [
          // Animated width 0% to 100% with gradient #3FA9F5 to #00D4FF
          FractionallySizedBox(
            widthFactor: widget.progress.clamp(0.0, 1.0),
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF3FA9F5),
                        Color(0xFF00D4FF),
                      ],
                    ),
                  ),
                  child: ShaderMask(
                    blendMode: BlendMode.srcATop,
                    shaderCallback: (bounds) {
                      final dx = _shimmerController.value * bounds.width * 2 - bounds.width;
                      return LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: const [0.0, 0.5, 1.0],
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                        transform: _GradientTranslate(dx),
                      ).createShader(bounds);
                    },
                    child: Container(
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientTranslate extends GradientTransform {
  const _GradientTranslate(this.dx);
  final double dx;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0, 0);
  }
}
