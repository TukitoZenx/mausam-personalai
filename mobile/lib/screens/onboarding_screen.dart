import 'package:flutter/material.dart';
import '../widgets/debug_navigation_drawer.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding'),
      ),
      drawer: const DebugNavigationDrawer(),
      body: const Center(
        child: Text(
          'Onboarding Screen',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
