import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const List<Map<String, String>> personas = [
    {
      'id': 'Fitness',
      'title': 'Fitness Enthusiast',
      'description': 'Prioritizes outdoor workout windows, ideal running temp & humidity.',
      'icon': 'directions_run',
    },
    {
      'id': 'Health',
      'title': 'Health Sensitive',
      'description': 'Prioritizes air quality alerts (AQI), UV index warnings & heat advisories.',
      'icon': 'health_and_safety',
    },
    {
      'id': 'Traveler',
      'title': 'Active Traveler',
      'description': 'Prioritizes destination weather, trip packing checklists & rain alerts.',
      'icon': 'flight_takeoff',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final activePersona = userState.selectedPersona ?? 'Fitness';

    return Scaffold(
      backgroundColor: const Color(0xFF0A1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1220),
        elevation: 0,
        title: Text(
          'User Profile & Persona',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF152238),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF233554)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF3FA9F5),
                    child: Text(
                      (userState.email ?? 'U').substring(0, 1).toUpperCase(),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userState.email ?? 'User',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Active Persona: $activePersona',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF3FA9F5),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Select Personalization Focus',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Changing persona updates homepage card ranking live.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: personas.length,
                itemBuilder: (context, index) {
                  final p = personas[index];
                  final isSelected = activePersona.toLowerCase() == p['id']!.toLowerCase();

                  IconData iconData = Icons.person;
                  if (p['icon'] == 'directions_run') iconData = Icons.directions_run_rounded;
                  if (p['icon'] == 'health_and_safety') iconData = Icons.health_and_safety_rounded;
                  if (p['icon'] == 'flight_takeoff') iconData = Icons.flight_takeoff_rounded;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1C2C4E) : const Color(0xFF111E35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF3FA9F5) : const Color(0xFF1E2F4F),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF3FA9F5).withOpacity(0.2)
                              : const Color(0xFF1A2A44),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          iconData,
                          color: isSelected ? const Color(0xFF3FA9F5) : Colors.grey,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        p['title']!,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          p['description']!,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF3FA9F5))
                          : null,
                      onTap: () async {
                        final newPersona = p['id']!;
                        ref.read(userProvider.notifier).setPersona(newPersona);

                        // Save persona to backend
                        final idToken = userState.idToken ?? 'test_token';
                        try {
                          await ref.read(apiClientProvider).postUser(
                                idToken: idToken,
                                email: userState.email ?? '',
                                persona: newPersona,
                              );
                        } catch (_) {}

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Persona updated to $newPersona. Homepage refetched.'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: const Color(0xFF152238),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
