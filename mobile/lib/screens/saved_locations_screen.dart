import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/user_provider.dart';
import '../theme/weather_palette.dart';
import '../widgets/app_drawer.dart';

class SavedLocationsScreen extends ConsumerStatefulWidget {
  const SavedLocationsScreen({super.key});

  @override
  ConsumerState<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends ConsumerState<SavedLocationsScreen> {
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _addLocationDialog() async {
    _nameController.clear();
    _latController.clear();
    _lonController.clear();

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MausamPalette.cardSurface,
        title: Text(
          'Add Saved Destination',
          style: GoogleFonts.inter(color: MausamPalette.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                style: const TextStyle(color: MausamPalette.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'City / Location Name',
                  labelStyle: TextStyle(color: MausamPalette.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: MausamPalette.cardBorder)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: MausamPalette.accentBlue)),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _latController,
                style: const TextStyle(color: MausamPalette.textPrimary),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(
                  labelText: 'Latitude (e.g. 12.9716)',
                  labelStyle: TextStyle(color: MausamPalette.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: MausamPalette.cardBorder)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: MausamPalette.accentBlue)),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _lonController,
                style: const TextStyle(color: MausamPalette.textPrimary),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(
                  labelText: 'Longitude (e.g. 77.5946)',
                  labelStyle: TextStyle(color: MausamPalette.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: MausamPalette.cardBorder)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: MausamPalette.accentBlue)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: MausamPalette.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MausamPalette.accentBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = _nameController.text.trim();
              final lat = double.tryParse(_latController.text.trim());
              final lon = double.tryParse(_lonController.text.trim());

              if (name.isEmpty || lat == null || lon == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid name, latitude, and longitude.')),
                );
                return;
              }

              Navigator.of(ctx).pop();
              setState(() => _isSaving = true);

              try {
                final apiClient = ref.read(apiClientProvider);
                final userState = ref.read(userProvider);
                final idToken = userState.idToken ?? 'test_token';

                final savedMap = await apiClient.saveLocation(
                  name: name,
                  latitude: lat,
                  longitude: lon,
                  idToken: idToken,
                );

                final newItem = LocationItem(
                  id: savedMap['id'] as String,
                  name: savedMap['name'] as String,
                  latitude: (savedMap['latitude'] as num).toDouble(),
                  longitude: (savedMap['longitude'] as num).toDouble(),
                  placeName: savedMap['place_name'] as String?,
                );

                final currentList = ref.read(locationProvider).savedLocations;
                ref.read(locationProvider.notifier).setSavedLocations([...currentList, newItem]);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added $name to saved destinations!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save location: $e')),
                  );
                }
              } finally {
                if (mounted) setState(() => _isSaving = false);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLocation(LocationItem item) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final userState = ref.read(userProvider);
      final idToken = userState.idToken ?? 'test_token';

      await apiClient.deleteSavedLocation(id: item.id, idToken: idToken);
      final currentList = ref.read(locationProvider).savedLocations;
      ref.read(locationProvider.notifier).setSavedLocations(
        currentList.where((l) => l.id != item.id).toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed ${item.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete location: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locState = ref.watch(locationProvider);
    final savedList = locState.savedLocations;

    return Scaffold(
      backgroundColor: MausamPalette.bgPrimary,
      drawer: const AppDrawer(currentRoute: '/saved-locations'),
      appBar: AppBar(
        backgroundColor: MausamPalette.bgDeep,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: MausamPalette.textPrimary, size: 24),
            tooltip: 'Open navigation',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'Saved Destinations',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: MausamPalette.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_rounded, color: MausamPalette.accentBlue),
            onPressed: _addLocationDialog,
            tooltip: 'Add Destination',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Locations',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: MausamPalette.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a location to switch active weather forecast view.',
              style: GoogleFonts.inter(fontSize: 12, color: MausamPalette.textSecondary),
            ),
            const SizedBox(height: 16),
            if (_isSaving)
              const LinearProgressIndicator(color: MausamPalette.accentBlue, backgroundColor: MausamPalette.cardSurface),
            Expanded(
              child: savedList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_off_rounded, color: MausamPalette.textMuted, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'No saved destinations yet.',
                            style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MausamPalette.accentBlue,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _addLocationDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Location'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: savedList.length,
                      itemBuilder: (context, index) {
                        final item = savedList[index];
                        final isActive = (locState.activeLatitude == item.latitude &&
                            locState.activeLongitude == item.longitude);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isActive ? MausamPalette.cardSurfaceLight : MausamPalette.cardSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isActive ? MausamPalette.accentBlue : MausamPalette.cardBorder,
                              width: isActive ? 1.5 : 1.0,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            leading: CircleAvatar(
                              backgroundColor: isActive ? MausamPalette.accentBlue : MausamPalette.bgSurface,
                              child: Icon(
                                isActive ? Icons.my_location_rounded : Icons.location_city_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              item.name,
                              style: GoogleFonts.inter(
                                color: MausamPalette.textPrimary,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${item.latitude.toStringAsFixed(4)}, ${item.longitude.toStringAsFixed(4)}',
                              style: GoogleFonts.inter(color: MausamPalette.textSecondary, fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isActive)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: Icon(Icons.check_circle_rounded, color: MausamPalette.accentBlue, size: 20),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  onPressed: () => _deleteLocation(item),
                                ),
                              ],
                            ),
                            onTap: () {
                              ref.read(locationProvider.notifier).selectSavedLocation(item);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Switched location to ${item.name}')),
                              );
                            },
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
