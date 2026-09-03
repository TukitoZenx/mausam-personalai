import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/weather_palette.dart';

Future<void> showSearchOverlay({
  required BuildContext context,
  required WidgetRef ref,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (context) => const SearchOverlayModal(),
  );
}

class SearchOverlayModal extends ConsumerStatefulWidget {
  const SearchOverlayModal({super.key});

  @override
  ConsumerState<SearchOverlayModal> createState() => _SearchOverlayModalState();
}

class _SearchOverlayModalState extends ConsumerState<SearchOverlayModal> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSearchSubmitted(String query) async {
    final text = query.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);
    final apiClient = ref.read(apiClientProvider);
    final userState = ref.read(userProvider);
    final idToken = userState.idToken ?? 'test_token';

    try {
      final created = await apiClient.saveLocation(
        name: text,
        latitude: 19.0760, // Default coordinates for named search
        longitude: 72.8777,
        idToken: idToken,
      );

      final newItem = LocationItem(
        id: created['id'] as String,
        name: created['name'] as String,
        latitude: (created['latitude'] as num).toDouble(),
        longitude: (created['longitude'] as num).toDouble(),
        placeName: created['place_name'] as String?,
      );

      ref.read(locationProvider.notifier).addSavedLocation(newItem);
      ref.read(locationProvider.notifier).selectSavedLocation(newItem);

      if (mounted) {
        Navigator.pop(context);
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to locate $text. $e'),
            backgroundColor: MausamPalette.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locState = ref.watch(locationProvider);
    final saved = locState.savedLocations;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        decoration: const BoxDecoration(
          color: MausamPalette.cardSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: MausamPalette.cardBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: MausamPalette.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'SEARCH LOCATION',
              style: GoogleFonts.inter(
                color: MausamPalette.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Search Bar Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: MausamPalette.cardSurfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MausamPalette.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: MausamPalette.accentBlue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Enter city or place name...',
                        hintStyle: GoogleFonts.inter(color: MausamPalette.textTertiary, fontSize: 15),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _handleSearchSubmitted,
                    ),
                  ),
                  if (_isSubmitting)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: MausamPalette.accentBlue),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, color: MausamPalette.textPrimary),
                      onPressed: () => _handleSearchSubmitted(_searchController.text),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (saved.isNotEmpty) ...[
              Text(
                'QUICK SELECT',
                style: GoogleFonts.inter(
                  color: MausamPalette.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: saved.map((item) {
                  return ActionChip(
                    backgroundColor: MausamPalette.cardSurfaceLight,
                    side: const BorderSide(color: MausamPalette.cardBorder),
                    label: Text(
                      item.name,
                      style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontSize: 12),
                    ),
                    onPressed: () {
                      ref.read(locationProvider.notifier).selectSavedLocation(item);
                      Navigator.pop(context);
                      context.go('/home');
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
