import 'package:flutter/material.dart';
import '../widgets/debug_navigation_drawer.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      drawer: const DebugNavigationDrawer(),
      body: const Center(
        child: Text(
          'Profile Screen',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
