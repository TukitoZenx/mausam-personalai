import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/weather_palette.dart';
import '../navigation/mausam_center_logo_icon.dart';

/// Capability model describing what Mausam AI chatbot can do.
class AICapability {
  final String title;
  final String description;
  final String prompt;
  final String badge;
  final IconData icon;
  final Color accentColor;

  const AICapability({
    required this.title,
    required this.description,
    required this.prompt,
    required this.badge,
    required this.icon,
    required this.accentColor,
  });
}

/// Luxury animated Mausam AI capability showcase shown initially in the chatbot screen.
/// Features a rotating particle orbit, multi-layered atmospheric aura glow,
/// and an auto-cycling animated video-like capability reel demonstrating what the AI chatbot does.
class InitialChatAnimatedLogo extends StatefulWidget {
  const InitialChatAnimatedLogo({
    super.key,
    this.logoSize = 72.0,
    this.onPromptSelected,
  });

  final double logoSize;
  final ValueChanged<String>? onPromptSelected;

  @override
  State<InitialChatAnimatedLogo> createState() => _InitialChatAnimatedLogoState();
}

class _InitialChatAnimatedLogoState extends State<InitialChatAnimatedLogo>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;
  late final AnimationController _orbitController;
  late final Animation<double> _entranceFade;
  late final Animation<double> _entranceScale;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _pulseScale;

  Timer? _carouselTimer;
  int _currentCapabilityIndex = 0;

  static const List<AICapability> _capabilities = [
    AICapability(
      title: 'Smart Day & Workout Planning',
      description: 'Calculates optimal outdoor workout windows, rain timing, and peak temperature risk.',
      prompt: 'What is the best time for an outdoor run today?',
      badge: 'AI REASONING',
      icon: Icons.directions_run_rounded,
      accentColor: Color(0xFF38BDF8),
    ),
    AICapability(
      title: 'Weather Alarms & Reminders',
      description: 'Set smart weather reminders like "Alert me if rain starts at 5 PM" or high AQI warnings.',
      prompt: 'Remind me at 5 PM if rain is likely today',
      badge: 'SMART ALERTS',
      icon: Icons.notifications_active_rounded,
      accentColor: Color(0xFFF59E0B),
    ),
    AICapability(
      title: 'Air Quality & Health Guidance',
      description: 'Monitors AQI, pollen, and humidity tailored to your personal health & allergy profile.',
      prompt: 'How is the air quality and pollen count for my morning walk?',
      badge: 'HEALTH INTEL',
      icon: Icons.health_and_safety_rounded,
      accentColor: Color(0xFF34D399),
    ),
    AICapability(
      title: 'Travel & Packing Advisor',
      description: 'Provides intelligent clothing advice, packing checklists, and forecasts for any city.',
      prompt: 'What should I pack for a 3-day trip to Mumbai?',
      badge: 'TRAVEL INTEL',
      icon: Icons.flight_takeoff_rounded,
      accentColor: Color(0xFFA855F7),
    ),
  ];

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

    // 3. Rotating particle orbit controller
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    if (!_isTest) {
      _entranceController.forward();
      _pulseController.repeat(reverse: true);
      _orbitController.repeat();

      _carouselTimer = Timer.periodic(const Duration(milliseconds: 3800), (_) {
        if (mounted) {
          setState(() {
            _currentCapabilityIndex = (_currentCapabilityIndex + 1) % _capabilities.length;
          });
        }
      });
    } else {
      _entranceController.value = 1.0;
      _pulseController.value = 0.5;
      _orbitController.value = 0.25;
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _entranceController.dispose();
    _pulseController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  void _onSelectCapability(int index) {
    setState(() {
      _currentCapabilityIndex = index;
    });
    _carouselTimer?.cancel();
    if (!_isTest) {
      _carouselTimer = Timer.periodic(const Duration(milliseconds: 4500), (_) {
        if (mounted) {
          setState(() {
            _currentCapabilityIndex = (_currentCapabilityIndex + 1) % _capabilities.length;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.logoSize;
    final double cornerRadius = size * 0.28;
    final currentCap = _capabilities[_currentCapabilityIndex];

    return FadeTransition(
      opacity: _entranceFade,
      child: ScaleTransition(
        scale: _entranceScale,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseController, _orbitController]),
          builder: (context, child) {
            final glow = _glowAnimation.value;
            final scale = _pulseScale.value;
            final orbitAngle = _orbitController.value * 2 * math.pi;
            final floatOffset = math.sin(_pulseController.value * math.pi) * -4.0;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Central Animated Logo with Glowing Orbit Particles
                Transform.translate(
                  offset: Offset(0, floatOffset),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Orbit Ring & Rotating Particles
                        CustomPaint(
                          size: Size(size + 48, size + 48),
                          painter: _OrbitRingPainter(
                            angle: orbitAngle,
                            accentColor: currentCap.accentColor,
                          ),
                        ),
                        // Logo Container with Multi-layered Aura Glow
                        Transform.scale(
                          scale: scale,
                          child: Container(
                            width: size + 16,
                            height: size + 16,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(cornerRadius + 4),
                              boxShadow: [
                                BoxShadow(
                                  color: currentCap.accentColor.withValues(alpha: glow * 0.85),
                                  blurRadius: 36,
                                  spreadRadius: 3,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: glow * 0.35),
                                  blurRadius: 20,
                                  spreadRadius: -1,
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: glow * 0.30),
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
                                  color: currentCap.accentColor.withValues(alpha: 0.25 + (glow * 0.35)),
                                  width: 1.2,
                                ),
                              ),
                              child: Center(
                                child: MausamCenterLogoIcon(
                                  size: size * 0.65,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Greeting Header
                Text(
                  'Mausam AI Assistant',
                  style: GoogleFonts.inter(
                    color: MausamPalette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Intelligent weather reasoning & personal day planning',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: MausamPalette.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 20),

                // Animated Capability Showcase Card (Auto-cycling reel)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_currentCapabilityIndex),
                      child: GestureDetector(
                        onTap: () {
                          if (widget.onPromptSelected != null) {
                            widget.onPromptSelected!(currentCap.prompt);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131317),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: currentCap.accentColor.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: currentCap.accentColor.withValues(alpha: 0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: currentCap.accentColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      currentCap.icon,
                                      color: currentCap.accentColor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      currentCap.title,
                                      style: GoogleFonts.inter(
                                        color: MausamPalette.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: currentCap.accentColor.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: currentCap.accentColor.withValues(alpha: 0.4),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      currentCap.badge,
                                      style: GoogleFonts.inter(
                                        color: currentCap.accentColor,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                currentCap.description,
                                style: GoogleFonts.inter(
                                  color: MausamPalette.textSecondary,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1C24),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      color: currentCap.accentColor,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '"${currentCap.prompt}"',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: MausamPalette.textPrimary,
                                          fontSize: 11.5,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: currentCap.accentColor,
                                      size: 13,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Reel Dots Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_capabilities.length, (index) {
                    final isSelected = index == _currentCapabilityIndex;
                    final cap = _capabilities[index];

                    return GestureDetector(
                      onTap: () => _onSelectCapability(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3.5),
                        width: isSelected ? 22 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: isSelected
                              ? cap.accentColor
                              : const Color(0xFF3F3F46),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Custom painter that draws a subtle rotating orbital ring with glowing particle nodes around the AI logo.
class _OrbitRingPainter extends CustomPainter {
  final double angle;
  final Color accentColor;

  _OrbitRingPainter({required this.angle, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;

    // 1. Dotted orbital path
    final pathPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, radius, pathPaint);

    // 2. Rotating particle node 1
    final particle1X = center.dx + radius * math.cos(angle);
    final particle1Y = center.dy + radius * math.sin(angle);

    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final nodePaint = Paint()..color = Colors.white;

    canvas.drawCircle(Offset(particle1X, particle1Y), 5, glowPaint);
    canvas.drawCircle(Offset(particle1X, particle1Y), 2.5, nodePaint);

    // 3. Rotating particle node 2 (opposite phase)
    final particle2X = center.dx + radius * math.cos(angle + math.pi);
    final particle2Y = center.dy + radius * math.sin(angle + math.pi);

    canvas.drawCircle(Offset(particle2X, particle2Y), 4, glowPaint);
    canvas.drawCircle(Offset(particle2X, particle2Y), 2.0, nodePaint);
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.accentColor != accentColor;
  }
}

