import 'package:flutter/material.dart';
import '../widgets/debug_navigation_drawer.dart';

class SavedLocationsScreen extends StatelessWidget {
  const SavedLocationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Locations'),
      ),
      drawer: const DebugNavigationDrawer(),
      body: const Center(
        child: Text(
          'Saved Locations Screen',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
