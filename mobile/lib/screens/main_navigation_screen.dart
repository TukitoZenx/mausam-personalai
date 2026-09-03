import 'package:flutter/material.dart';
import 'home_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
