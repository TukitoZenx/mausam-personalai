import 'package:flutter/material.dart';
import '../widgets/debug_navigation_drawer.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      drawer: const DebugNavigationDrawer(),
      body: const Center(
        child: Text(
          'Login Screen',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
