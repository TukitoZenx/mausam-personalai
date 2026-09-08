import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Luxury animated Mausam AI logo shown initially in the chatbot screen.
/// Features a smooth entrance transition, multi-layered atmospheric aura glow,
/// gentle micro-floating translation, and breathing radiance.
class InitialChatAnimatedLogo extends StatefulWidget {
  const InitialChatAnimatedLogo({
    super.key,
    this.logoSize = 72.0,
  });

  final double logoSize;

  @override
  State<InitialChatAnimatedLogo> createState() => _InitialChatAnimatedLogoState();
}

class _InitialChatAnimatedLogoState extends State<InitialChatAnimatedLogo>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;
  late final Animation<double> _entranceFade;
  late final Animation<double> _entranceScale;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _pulseScale;

  static bool get _isTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation (fade + scale in)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _entranceScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );

    // 2. Continuous breathing aura & micro-scale
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _glowAnimation = Tween<double>(begin: 0.12, end: 0.32).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.035).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    if (!_isTest) {
      _entranceController.forward();
      _pulseController.repeat(reverse: true);
    } else {
      _entranceController.value = 1.0;
      _pulseController.value = 0.5;
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.logoSize;
    final double cornerRadius = size * 0.28;

    return FadeTransition(
      opacity: _entranceFade,
      child: ScaleTransition(
        scale: _entranceScale,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final glow = _glowAnimation.value;
            final scale = _pulseScale.value;
            final floatOffset = math.sin(_pulseController.value * math.pi) * -4.0;

            return Transform.translate(
              offset: Offset(0, floatOffset),
              child: Center(
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: size + 16,
                    height: size + 16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(cornerRadius + 4),
                      boxShadow: [
                        // Outer Indigo/Purple atmospheric aura
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: glow * 0.75),
                          blurRadius: 36,
                          spreadRadius: 3,
                        ),
                        // Secondary Cyan accent aura
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withValues(alpha: glow * 0.40),
                          blurRadius: 20,
                          spreadRadius: -1,
                        ),
                        // Core white light halo
                        BoxShadow(
                          color: Colors.white.withValues(alpha: glow * 0.35),
                          blurRadius: 10,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Container(
                      width: size + 10,
                      height: size + 10,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(cornerRadius + 2),
                        color: const Color(0xFF09090D),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12 + (glow * 0.25)),
                          width: 1.2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(cornerRadius),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: size,
                          height: size,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              color: const Color(0xFF14141A),
                              borderRadius: BorderRadius.circular(cornerRadius),
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: size * 0.55,
                              color: const Color(0xFFFAFAFA),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
