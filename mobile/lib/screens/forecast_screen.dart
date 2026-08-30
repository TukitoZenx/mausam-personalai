import 'package:flutter/material.dart';
import '../widgets/debug_navigation_drawer.dart';

class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forecast'),
      ),
      drawer: const DebugNavigationDrawer(),
      body: const Center(
        child: Text(
          'Forecast Screen',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
