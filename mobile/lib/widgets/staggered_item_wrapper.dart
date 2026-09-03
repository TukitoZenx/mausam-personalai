import 'package:flutter/material.dart';

/// Staggered Entrance animation wrapper providing sequential fade + slight slide-up.
class StaggeredItemWrapper extends StatefulWidget {
  final int index;
  final Widget child;

  const StaggeredItemWrapper({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<StaggeredItemWrapper> createState() => _StaggeredItemWrapperState();
}

class _StaggeredItemWrapperState extends State<StaggeredItemWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Stagger delay based on section index (~70ms per section)
    Future.delayed(Duration(milliseconds: widget.index * 70), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
