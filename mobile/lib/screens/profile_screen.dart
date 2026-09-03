import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/appearance_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../theme/environment_theme.dart';
import '../theme/weather_palette.dart';
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

    return Scaffold(
      backgroundColor: MausamPalette.bgPrimary,
      appBar: AppBar(
        backgroundColor: MausamPalette.bgDeep,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: MausamPalette.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'PROFILE & SETTINGS',
          style: GoogleFonts.inter(
            color: MausamPalette.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
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

            // Home Wallpaper Selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'HOME WALLPAPER',
                  style: GoogleFonts.inter(
                    color: MausamPalette.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Choose your atmosphere',
                  style: GoogleFonts.inter(
                    color: MausamPalette.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            StaggeredItemWrapper(
              index: 2,
              child: Consumer(
                builder: (context, ref, child) {
                  final appearance = ref.watch(appearanceProvider);
                  final selected = appearance.wallpaperTheme;

                  return Column(
                    children: [
                      // Grid 1: Auto & Horizon
                      Row(
                        children: [
                          Expanded(
                            child: _wallpaperCard(
                              title: 'Auto',
                              subtitle: 'Smart dynamic',
                              theme: WallpaperTheme.auto,
                              isSelected: selected == WallpaperTheme.auto,
                              previewGradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF18181B), Color(0xFF3F3F46), Color(0xFF71717A)],
                              ),
                              onTap: () => ref.read(appearanceProvider.notifier).setWallpaperTheme(WallpaperTheme.auto),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _wallpaperCard(
                              title: 'Horizon',
                              subtitle: 'Natural daylight (Default)',
                              theme: WallpaperTheme.horizon,
                              isSelected: selected == WallpaperTheme.horizon,
                              previewGradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF27272A), Color(0xFF3F3F46), Color(0xFF52525B)],
                              ),
                              onTap: () => ref.read(appearanceProvider.notifier).setWallpaperTheme(WallpaperTheme.horizon),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Grid 2: Aurora & Clouds
                      Row(
                        children: [
                          Expanded(
                            child: _wallpaperCard(
                              title: 'Aurora',
                              subtitle: 'Atmospheric teal',
                              theme: WallpaperTheme.aurora,
                              isSelected: selected == WallpaperTheme.aurora,
                              previewGradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF1C1C1F), Color(0xFF3F3F46), Color(0xFF52525B)],
                              ),
                              onTap: () => ref.read(appearanceProvider.notifier).setWallpaperTheme(WallpaperTheme.aurora),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _wallpaperCard(
                              title: 'Clouds',
                              subtitle: 'Cloud haze',
                              theme: WallpaperTheme.clouds,
                              isSelected: selected == WallpaperTheme.clouds,
                              previewGradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF27272A), Color(0xFF3F3F46), Color(0xFF71717A)],
                              ),
                              onTap: () => ref.read(appearanceProvider.notifier).setWallpaperTheme(WallpaperTheme.clouds),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Grid 3: Nightfall
                      _wallpaperCard(
                        title: 'Nightfall',
                        subtitle: 'Moody dark nightfall lighting',
                        theme: WallpaperTheme.nightfall,
                        isSelected: selected == WallpaperTheme.nightfall,
                        previewGradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF09090B), Color(0xFF141417), Color(0xFF1C1C1F)],
                        ),
                        onTap: () => ref.read(appearanceProvider.notifier).setWallpaperTheme(WallpaperTheme.nightfall),
                      ),
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
        ),
      ),
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

  Widget _wallpaperCard({
    required String title,
    required String subtitle,
    required WallpaperTheme theme,
    required bool isSelected,
    required LinearGradient previewGradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? MausamPalette.cardSurfaceLight
              : MausamPalette.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? MausamPalette.textSecondary : MausamPalette.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected ? MausamPalette.cardShadow : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Box
            Container(
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: previewGradient,
                border: Border.all(color: MausamPalette.cardBorderSubtle),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PREVIEW',
                        style: GoogleFonts.inter(
                          color: MausamPalette.textPrimary,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                      color: isSelected ? MausamPalette.textPrimary : Colors.white54,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Text(
              title,
              style: GoogleFonts.inter(
                color: MausamPalette.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: MausamPalette.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
