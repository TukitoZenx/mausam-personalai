import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

CustomTransitionPage<void> mausamFadePage({
  required LocalKey key,
  required Widget child,
  Duration duration = const Duration(milliseconds: 380),
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.016),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

NoTransitionPage<void> mausamNoMovePage({required Widget child}) {
  return NoTransitionPage<void>(child: child);
}
