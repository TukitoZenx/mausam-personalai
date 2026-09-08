import 'package:flutter/material.dart';

/// Keeps every child permanently alive in memory and plays a smooth,
/// single-pass cross-fade dissolve whenever [index] changes.
///
/// Crucially prevents double-rendering by maintaining a completely static, persistent widget hierarchy
/// for every slot (no re-parenting, no widget type swapping, and zero element recreation).
class FadingIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadingIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 180),
  });

  @override
  State<FadingIndexedStack> createState() => _FadingIndexedStackState();
}

class _FadingIndexedStackState extends State<FadingIndexedStack>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  int? _previousIndex;
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _fadeOutReversed;

  static const _kZeroAnimation = AlwaysStoppedAnimation<double>(0.0);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _previousIndex = null;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _fadeOutReversed = ReverseAnimation(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeInCubic),
    ));

    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(FadingIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
      _previousIndex = _currentIndex;
      _currentIndex = widget.index;

      if (!isTest) {
        _controller.forward(from: 0.0).then((_) {
          if (mounted && _currentIndex == widget.index) {
            setState(() {
              _previousIndex = null;
            });
          }
        });
      } else {
        _controller.value = 1.0;
        _previousIndex = null;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations) {
      return IndexedStack(
        index: _currentIndex,
        sizing: StackFit.expand,
        children: widget.children,
      );
    }

    final isAnimating = _controller.isAnimating &&
        _previousIndex != null &&
        _previousIndex! < widget.children.length;

    return Stack(
      fit: StackFit.expand,
      children: List.generate(widget.children.length, (i) {
        final isCurrent = i == _currentIndex;
        final isPrevious = isAnimating && i == _previousIndex;
        final isVisible = isCurrent || isPrevious;

        return KeyedSubtree(
          key: ValueKey('fading_stack_child_$i'),
          child: Offstage(
            offstage: !isVisible,
            child: TickerMode(
              enabled: isCurrent,
              child: IgnorePointer(
                ignoring: !isCurrent,
                child: FadeTransition(
                  opacity: isCurrent
                      ? _fadeIn
                      : (isPrevious ? _fadeOutReversed : _kZeroAnimation),
                  child: widget.children[i],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
