import 'package:flutter/material.dart';
import 'navigation/mausam_center_logo_icon.dart';

/// Ultra-premium monochrome logo container inspired by Grok and Kimi design language.
/// Features a subtle breathing monochrome aura and vector-level crispness.
class AnimatedLogoContainer extends StatefulWidget {
  const AnimatedLogoContainer({super.key, this.height = 56});

  final double height;

  @override
  State<AnimatedLogoContainer> createState() => _AnimatedLogoContainerState();
}

class _AnimatedLogoContainerState extends State<AnimatedLogoContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Subtle 3.2s breathing cycle (ambient white aura and micro-scale)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.value = 0.5;
    }

    _glowAnimation = Tween<double>(begin: 0.08, end: 0.22).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double logoSize = widget.height;

    final double cornerRadius = logoSize * 0.26;

    final Widget logoImage = Center(
      child: MausamCenterLogoIcon(
        size: logoSize * 0.65,
        color: Colors.white,
      ),
    );

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final glowOpacity = _glowAnimation.value;
          final scale = _scaleAnimation.value;

          return Transform.scale(
            scale: scale,
            child: Container(
              width: logoSize + 12,
              height: logoSize + 12,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cornerRadius + 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: glowOpacity),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: glowOpacity * 0.4),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Container(
                width: logoSize + 6,
                height: logoSize + 6,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cornerRadius + 2),
                  color: const Color(0xFF09090B),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14 + (glowOpacity * 0.28)),
                    width: 1.1,
                  ),
                ),
                child: Center(child: logoImage),
              ),
            ),
          );
        },
      ),
    );
  }
}
