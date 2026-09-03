import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/homepage_provider.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';
import '../providers/weather_dashboard_provider.dart';
import '../theme/weather_palette.dart';
import '../widgets/cards/card_registry.dart';
import '../widgets/staggered_item_wrapper.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homepageProvider);
    final userState = ref.watch(userProvider);
    final locationState = ref.watch(locationProvider);
    final weatherDash = ref.watch(weatherDashboardProvider);

    final activePersona = userState.selectedPersona ?? homeState.data?.persona ?? 'Fitness';
    final cards = homeState.data?.cards ?? [];

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: MausamPalette.accentGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'INSIGHTS',
              style: GoogleFonts.inter(
                color: MausamPalette.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: MausamPalette.textPrimary),
            tooltip: 'Profile & Settings',
            onPressed: () => context.push('/profile'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: MausamPalette.accentBlue,
          backgroundColor: MausamPalette.cardSurface,
          onRefresh: () async {
            await ref.read(homepageProvider.notifier).fetchHomeFeed(forceRefresh: true);
            await ref.read(weatherDashboardProvider.notifier).fetchDashboard(forceRefresh: true);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              // Persona Switcher Header Strip
              StaggeredItemWrapper(
                index: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: MausamPalette.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: MausamPalette.cardBorder),
                    boxShadow: MausamPalette.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            activePersona == 'Fitness'
                                ? Icons.directions_run_rounded
                                : activePersona == 'Health'
                                    ? Icons.favorite_rounded
                                    : Icons.flight_takeoff_rounded,
                            color: activePersona == 'Fitness'
                                ? MausamPalette.personaFitness
                                : activePersona == 'Health'
                                    ? MausamPalette.personaHealth
                                    : MausamPalette.personaTraveler,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$activePersona Insights',
                            style: GoogleFonts.inter(
                              color: MausamPalette.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: MausamPalette.cardSurfaceLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: MausamPalette.cardBorder),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  locationState.cityName.isNotEmpty
                                      ? locationState.cityName
                                      : (weatherDash.data?.current.location ?? 'Active Location'),
                                  style: GoogleFonts.inter(
                                    color: MausamPalette.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        homeState.effectiveSummaryInsight,
                        style: GoogleFonts.inter(
                          color: MausamPalette.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'PERSONALIZED GUIDANCE',
                style: GoogleFonts.inter(
                  color: MausamPalette.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 12),

              if (homeState.isLoading && cards.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: MausamPalette.accentBlue, strokeWidth: 2),
                  ),
                ),
              ] else if (cards.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: MausamPalette.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: MausamPalette.cardBorder),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.insights_rounded, color: MausamPalette.textTertiary, size: 36),
                      const SizedBox(height: 12),
                      Text(
                        'Live insights updating...',
                        style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                for (int i = 0; i < cards.length; i++)
                  StaggeredItemWrapper(
                    index: i + 1,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CardRegistry.buildCardWidget(
                        card: cards[i],
                        showRankBadge: false,
                        onTap: () => ref.read(homepageProvider.notifier).logCardClick(cards[i]),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
