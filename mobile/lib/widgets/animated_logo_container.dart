import 'package:flutter/material.dart';

class AnimatedLogoContainer extends StatefulWidget {
  const AnimatedLogoContainer({super.key, this.height = 64});

  final double height;

  @override
  State<AnimatedLogoContainer> createState() => _AnimatedLogoContainerState();
}

class _AnimatedLogoContainerState extends State<AnimatedLogoContainer>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  late final AnimationController _sunPulseController;
  late final Animation<double> _sunPulseAnimation;

  late final AnimationController _rainController;

  @override
  void initState() {
    super.initState();

    // 1. Floating Y offset -3px to +3px 3s infinite
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // 2. Sun pulse brightness/scale 1.0 to 1.3 2s loop
    _sunPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _sunPulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _sunPulseController, curve: Curves.easeInOut),
    );

    // 3. Raindrops falling loop
    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _sunPulseController.dispose();
    _rainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double logoHeight = widget.height;

    return SizedBox(
      height: logoHeight + 12,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _floatAnimation,
          _sunPulseAnimation,
          _rainController,
        ]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Sun pulse glow top-right
                Positioned(
                  top: 2,
                  right: MediaQuery.of(context).size.width * 0.38,
                  child: Transform.scale(
                    scale: _sunPulseAnimation.value,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFC107).withValues(alpha: 0.35),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFC107).withValues(alpha: 0.55),
                            blurRadius: 14,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Transparent logo PNG
                Image.asset(
                  'assets/images/logo.png',
                  height: logoHeight,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.cloud_queue,
                    size: logoHeight,
                    color: const Color(0xFF3FA9F5),
                  ),
                ),

                // 3 small blue pill raindrops falling from cloud bottom with stagger
                Positioned(
                  bottom: -4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      final staggerOffset = (index * 0.33);
                      final progress =
                          (_rainController.value + staggerOffset) % 1.0;
                      final dropY = progress * 12;
                      final opacity = (1.0 - progress).clamp(0.0, 1.0);

                      return Transform.translate(
                        offset: Offset((index - 1) * 10.0, dropY),
                        child: Opacity(
                          opacity: opacity,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 3.0,
                            height: 7.0,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3FA9F5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
