import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DebugNavigationDrawer extends StatelessWidget {
  const DebugNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF0F172A),
            ),
            child: Text(
              'Mausam PersonalAI Navigation',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.flight_takeoff),
            title: const Text('Onboarding'),
            onTap: () {
              Navigator.pop(context);
              context.go('/onboarding');
            },
          ),
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('Login'),
            onTap: () {
              Navigator.pop(context);
              context.go('/login');
            },
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              context.go('/');
            },
          ),
          ListTile(
            leading: const Icon(Icons.wb_sunny),
            title: const Text('Forecast'),
            onTap: () {
              Navigator.pop(context);
              context.go('/forecast');
            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: const Text('Saved Locations'),
            onTap: () {
              Navigator.pop(context);
              context.go('/saved-locations');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              context.go('/profile');
            },
          ),
        ],
      ),
    );
  }
}
