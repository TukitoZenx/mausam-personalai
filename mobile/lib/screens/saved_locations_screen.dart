import 'package:flutter/material.dart';

class SavedLocationsScreen extends StatelessWidget {
  const SavedLocationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Locations'),
      ),
      body: const Center(
        child: Text(
          'Saved Locations Screen',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
