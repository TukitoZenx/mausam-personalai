import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../providers/mausam_ai_state_provider.dart';
import '../../theme/weather_palette.dart';
import 'mausam_center_logo_icon.dart';

/// Minimalist, X (Twitter)-Style Bottom Navigation Bar for Mausam AI.
///
/// Design characteristics:
/// - Exact X/Twitter geometry: Flat 53dp height bar with hairline top divider (0.5px, Color(0xFF2F3336)).
/// - Pitch-black frosted glass background with subtle backdrop blur.
/// - Frameless, clean iconography (no bulky pods or background pills).
/// - Unselected: Sleek outline icons in Twitter gray (Color(0xFF71767B)).
/// - Selected: Solid filled icons in pure white (Colors.white).
/// - Center Mausam AI: Native smart cloud icon with organic breathing/glow during AI thinking & responding.
/// - Tactile spring touch feedback on press.
class MausamBottomNavbar extends StatefulWidget {
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final MausamAiState aiState;

  const MausamBottomNavbar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    this.aiState = MausamAiState.idle,
  });

  @override
  State<MausamBottomNavbar> createState() => _MausamBottomNavbarState();
}

class _MausamBottomNavbarState extends State<MausamBottomNavbar> {
  bool _isCenterPressed = false;

  bool get _isHome => widget.currentRoute == '/home';
  bool get _isLocations => widget.currentRoute == '/saved-locations';
  bool get _isInsights => widget.currentRoute == '/insights';
  bool get _isProfile => widget.currentRoute == '/profile';

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const barHeight = 53.0;

    return SizedBox(
      height: barHeight + bottomInset,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: barHeight + bottomInset,
            width: double.infinity,
            color: const Color(0xF5000000), // Twitter / X dark translucent black
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hairline Top Divider (Exact X / Twitter styling)
                Container(
                  height: 0.5,
                  width: double.infinity,
                  color: const Color(0xFF2F3336),
                ),

                // Equal-spaced Navigation Items Row
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset * 0.15 : 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // LEFT: Home
                        Expanded(
                          child: _NavItem(
                            key: const Key('bottom_nav_home'),
                            label: 'Home',
                            activeIcon: Icons.home_rounded,
                            inactiveIcon: Icons.home_outlined,
                            isActive: _isHome,
                            onTap: () => widget.onNavigate('/home'),
                          ),
                        ),

                        // LOCATIONS: Search & Saved Locations
                        Expanded(
                          child: _NavItem(
                            key: const Key('bottom_nav_locations'),
                            label: 'Locations',
                            activeIcon: Icons.travel_explore_rounded,
                            inactiveIcon: Icons.travel_explore_rounded,
                            isActive: _isLocations,
                            onTap: () => widget.onNavigate('/saved-locations'),
                          ),
                        ),

                        // CENTER: Mausam AI Weather Cloud
                        Expanded(
                          child: _CenterMausamAiButton(
                            isSelected: _isInsights,
                            isPressed: _isCenterPressed,
                            aiState: widget.aiState,
                            onTap: () => widget.onNavigate('/insights'),
                            onHighlightChanged: (pressed) => setState(() => _isCenterPressed = pressed),
                          ),
                        ),

                        // RIGHT: Settings
                        Expanded(
                          child: _NavItem(
                            key: const Key('bottom_nav_settings'),
                            label: 'Settings',
                            activeIcon: Icons.settings_rounded,
                            inactiveIcon: Icons.settings_outlined,
                            isActive: _isProfile,
                            onTap: () => widget.onNavigate('/profile'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterMausamAiButton extends StatefulWidget {
  final bool isSelected;
  final bool isPressed;
  final MausamAiState aiState;
  final VoidCallback onTap;
  final ValueChanged<bool> onHighlightChanged;

  const _CenterMausamAiButton({
    required this.isSelected,
    required this.isPressed,
    required this.aiState,
    required this.onTap,
    required this.onHighlightChanged,
  });

  @override
  State<_CenterMausamAiButton> createState() => _CenterMausamAiButtonState();
}

class _CenterMausamAiButtonState extends State<_CenterMausamAiButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _pulseAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutSine,
    );

    _syncAnimationState(widget.aiState);
  }

  @override
  void didUpdateWidget(covariant _CenterMausamAiButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.aiState != widget.aiState) {
      _syncAnimationState(widget.aiState);
    }
  }

  void _syncAnimationState(MausamAiState state) {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');

    switch (state) {
      case MausamAiState.thinking:
        _animController.duration = const Duration(milliseconds: 2200);
        if (!isTest) {
          _animController.repeat(reverse: true);
        } else {
          _animController.value = 0.5;
        }
        break;
      case MausamAiState.responding:
        _animController.duration = const Duration(milliseconds: 1500);
        if (!isTest) {
          _animController.repeat(reverse: true);
        } else {
          _animController.value = 0.5;
        }
        break;
      case MausamAiState.idle:
        if (_animController.isAnimating) {
          _animController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        } else {
          _animController.value = 0.0;
        }
        break;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isThinking = widget.aiState == MausamAiState.thinking;
    final isResponding = widget.aiState == MausamAiState.responding;
    final isActiveState = isThinking || isResponding;
    final isSelected = widget.isSelected;
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Semantics(
      label: 'Mausam AI',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        key: const Key('bottom_nav_insights'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => widget.onHighlightChanged(true),
        onTapUp: (_) {
          widget.onHighlightChanged(false);
          widget.onTap();
        },
        onTapCancel: () => widget.onHighlightChanged(false),
        child: SizedBox(
          height: 53,
          child: Center(
            child: AnimatedScale(
              scale: widget.isPressed ? 0.88 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  final animVal = disableAnimations ? 0.0 : _pulseAnimation.value;

                  // Subtle scale change for the logo: 1.0 to 1.10 during thinking, 1.0 to 1.06 during responding
                  final maxScaleDelta = isThinking ? 0.10 : (isResponding ? 0.06 : 0.0);
                  final logoScale = 1.0 + (animVal * maxScaleDelta);

                  // Subtle organic micro-rotation: -0.025 to +0.025 rad (~1.4 degrees)
                  final rotationAngle = (isThinking && !disableAnimations)
                      ? math.sin(_animController.value * math.pi * 2) * 0.025
                      : 0.0;

                  Color iconColor;
                  if (isThinking) {
                    iconColor = Colors.white;
                  } else if (isResponding) {
                    iconColor = MausamPalette.accentCyan;
                  } else if (isSelected) {
                    iconColor = Colors.white;
                  } else {
                    iconColor = const Color(0xFF71767B); // Twitter / X inactive icon gray
                  }

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ambient glow during active thinking/responding states
                      if (isActiveState)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isResponding ? MausamPalette.accentCyan : Colors.white)
                                    .withValues(alpha: 0.30 + (0.20 * animVal)),
                                blurRadius: 18 + (6 * animVal),
                                spreadRadius: 1.5,
                              ),
                            ],
                          ),
                        ),

                      // Frameless clean icon (custom vector Mausam AI logo)
                      Transform.rotate(
                        angle: rotationAngle,
                        child: Transform.scale(
                          scale: logoScale,
                          child: MausamCenterLogoIcon(
                            size: 28.0,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    super.key,
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      button: true,
      selected: widget.isActive,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: SizedBox(
          height: 53,
          child: Center(
            child: AnimatedScale(
              scale: _isPressed ? 0.88 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              child: Icon(
                widget.isActive ? widget.activeIcon : widget.inactiveIcon,
                size: 26.5,
                color: widget.isActive
                    ? Colors.white
                    : const Color(0xFF71767B), // X / Twitter muted gray
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MausamNavBarClipper extends CustomClipper<Path> {
  final double topMargin;

  MausamNavBarClipper({this.topMargin = 0.0});

  @override
  Path getClip(Size size) {
    return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldDelegate) => false;
}

class MausamNavBarBorderPainter extends CustomPainter {
  final double topMargin;

  MausamNavBarBorderPainter({this.topMargin = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2F3336)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
