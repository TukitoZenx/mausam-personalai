import 'package:flutter/material.dart';
import '../widgets/debug_navigation_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      drawer: const DebugNavigationDrawer(),
      body: const Center(
        child: Text(
          'Home Screen',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
