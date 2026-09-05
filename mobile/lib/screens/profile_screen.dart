import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/appearance_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../theme/environment_theme.dart';
import '../theme/weather_palette.dart';
import '../widgets/navigation/shell_section_title.dart';
import '../widgets/staggered_item_wrapper.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notifications = true;
  bool _locationAccess = true;

  Future<void> _updatePersona(String persona) async {
    final userNotifier = ref.read(userProvider.notifier);
    final apiClient = ref.read(apiClientProvider);
    final userState = ref.read(userProvider);
    final idToken = userState.idToken ?? 'test_token';

    userNotifier.setPersona(persona);

    try {
      await apiClient.postUser(
        idToken: idToken,
        email: userState.email ?? 'guest@mausam.ai',
        personaType: persona,
        notificationsEnabled: _notifications,
        locationAccess: _locationAccess,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched persona to $persona'),
            backgroundColor: MausamPalette.cardSurface,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      // Persona updated locally in Riverpod even if backend network call fails
    }
  }

  Future<void> _logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.signOut();
    if (!mounted) return;
    ref.read(userProvider.notifier).signOut();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final activePersona = userState.selectedPersona ?? 'Fitness';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 72, 16, 100),
      children: [
        const ShellSectionTitle('PROFILE & SETTINGS'),
            // Account Badge Card
            StaggeredItemWrapper(
              index: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: MausamPalette.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MausamPalette.cardBorder),
                  boxShadow: MausamPalette.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: MausamPalette.cardSurfaceLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: MausamPalette.cardBorder),
                      ),
                      child: const Icon(Icons.person_rounded, color: MausamPalette.textPrimary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userState.email?.split('@').first ?? 'Mausam User',
                            style: GoogleFonts.inter(
                              color: MausamPalette.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userState.email ?? 'guest@mausam.ai',
                            style: GoogleFonts.inter(
                              color: MausamPalette.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Persona Selection Section
            Text(
              'ACTIVE PERSONA',
              style: GoogleFonts.inter(
                color: MausamPalette.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            StaggeredItemWrapper(
              index: 1,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MausamPalette.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MausamPalette.cardBorder),
                ),
                child: Column(
                  children: [
                    _personaTile(
                      title: 'Fitness Persona',
                      subtitle: 'Optimized for running windows, outdoor exercise & UV exposure.',
                      icon: Icons.directions_run_rounded,
                      color: MausamPalette.personaFitness,
                      isSelected: activePersona == 'Fitness',
                      onTap: () => _updatePersona('Fitness'),
                    ),
                    const Divider(color: MausamPalette.cardBorderSubtle, height: 16),
                    _personaTile(
                      title: 'Health Focus',
                      subtitle: 'Focuses on air quality precautions, AQI alerts & respiratory safety.',
                      icon: Icons.favorite_rounded,
                      color: MausamPalette.personaHealth,
                      isSelected: activePersona == 'Health',
                      onTap: () => _updatePersona('Health'),
                    ),
                    const Divider(color: MausamPalette.cardBorderSubtle, height: 16),
                    _personaTile(
                      title: 'Traveler Persona',
                      subtitle: 'Sightseeing comfort, commute rain warnings & packing essentials.',
                      icon: Icons.flight_takeoff_rounded,
                      color: MausamPalette.personaTraveler,
                      isSelected: activePersona == 'Traveler',
                      onTap: () => _updatePersona('Traveler'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'HOME WALLPAPER',
              style: GoogleFonts.inter(
                color: MausamPalette.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            StaggeredItemWrapper(
              index: 2,
              child: Consumer(
                builder: (context, ref, child) {
                  final selected = ref.watch(appearanceProvider).wallpaperTheme;
                  return Column(
                    children: [
                      for (int i = 0; i < WallpaperCatalog.all.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        _wallpaperRow(
                          spec: WallpaperCatalog.all[i],
                          isSelected: selected == WallpaperCatalog.all[i].id,
                          onTap: () => ref
                              .read(appearanceProvider.notifier)
                              .setWallpaperTheme(WallpaperCatalog.all[i].id),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Appearance & Widget Transparency
            Text(
              'WIDGET TRANSPARENCY',
              style: GoogleFonts.inter(
                color: MausamPalette.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            StaggeredItemWrapper(
              index: 2,
              child: Consumer(
                builder: (context, ref, child) {
                  final appearance = ref.watch(appearanceProvider);
                  final opacity = ref.watch(cardSurfaceOpacityProvider);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: MausamPalette.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: MausamPalette.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Widget Transparency',
                              style: GoogleFonts.inter(
                                color: MausamPalette.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: MausamPalette.cardSurfaceLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${appearance.transparencyPercent}%',
                                style: GoogleFonts.inter(
                                  color: MausamPalette.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: MausamTypography.tabularFeatures,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Opaque', style: GoogleFonts.inter(color: MausamPalette.textTertiary, fontSize: 11)),
                            Text('Transparent', style: GoogleFonts.inter(color: MausamPalette.textTertiary, fontSize: 11)),
                          ],
                        ),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: MausamPalette.textSecondary,
                            inactiveTrackColor: MausamPalette.cardBorder,
                            thumbColor: MausamPalette.textPrimary,
                            overlayColor: MausamPalette.textPrimary.withValues(alpha: 0.12),
                          ),
                          child: Slider(
                            value: appearance.transparencyPercent.toDouble(),
                            min: 0,
                            max: 100,
                            divisions: 20,
                            onChanged: (val) {
                              ref.read(appearanceProvider.notifier).setTransparency(val.round());
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Live Preview Widget
                        Text(
                          'LIVE PREVIEW WIDGET',
                          style: GoogleFonts.inter(
                            color: MausamPalette.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: MausamPalette.cardSurface.withValues(alpha: opacity),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: MausamPalette.cardBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.wb_sunny_rounded, color: MausamPalette.textPrimary, size: 28),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '28°C • Clear Sky',
                                    style: GoogleFonts.inter(
                                      color: MausamPalette.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      fontFeatures: MausamTypography.tabularFeatures,
                                    ),
                                  ),
                                  Text(
                                    'Surface opacity ${(opacity * 100).round()}%',
                                    style: GoogleFonts.inter(
                                      color: MausamPalette.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // App Preferences
            Text(
              'PREFERENCES',
              style: GoogleFonts.inter(
                color: MausamPalette.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            StaggeredItemWrapper(
              index: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: MausamPalette.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MausamPalette.cardBorder),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _notifications,
                        onChanged: (val) => setState(() => _notifications = val),
                        activeThumbColor: MausamPalette.textPrimary,
                        title: Text(
                          'Weather Notifications',
                          style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Receive severe rain and high AQI advisories',
                          style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 12),
                        ),
                      ),
                      const Divider(color: MausamPalette.cardBorderSubtle, height: 1),
                      SwitchListTile(
                        value: _locationAccess,
                        onChanged: (val) => setState(() => _locationAccess = val),
                        activeThumbColor: MausamPalette.textPrimary,
                        title: Text(
                          'GPS Location Access',
                          style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Automatically detect local weather for current coordinates',
                          style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Logout Button
            StaggeredItemWrapper(
              index: 3,
              child: Center(
                child: TextButton.icon(
                  onPressed: _logout,
                  style: TextButton.styleFrom(
                    foregroundColor: MausamPalette.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(
                    'Sign Out',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _personaTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: MausamPalette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 12, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: isSelected ? color : MausamPalette.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wallpaperRow({
    required WallpaperSpec spec,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? MausamPalette.cardSurfaceLight : MausamPalette.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? MausamPalette.textSecondary : MausamPalette.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected ? MausamPalette.cardShadow : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? MausamPalette.textPrimary : MausamPalette.textTertiary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          spec.title,
                          style: GoogleFonts.inter(
                            color: MausamPalette.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (spec.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: MausamPalette.bgDeep,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: MausamPalette.cardBorder),
                          ),
                          child: Text(
                            'DEFAULT',
                            style: GoogleFonts.inter(
                              color: MausamPalette.textSecondary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    spec.subtitle,
                    style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 72,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: spec.previewColors,
                ),
                border: Border.all(color: MausamPalette.cardBorder),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
