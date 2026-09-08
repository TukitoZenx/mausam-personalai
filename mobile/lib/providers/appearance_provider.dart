import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/environment_theme.dart';

const String _kWidgetTransparency = 'widget_transparency_percent';
const String _kWallpaperTheme = 'home_wallpaper_theme';

class AppearanceState {
  /// Transparency percentage from 0 (0% transparent / fully opaque) to 100 (100% max translucent glass)
  final int transparencyPercent;

  /// Selected home wallpaper. Defaults to Mausam Dynamic (Live Wallpaper).
  final WallpaperTheme wallpaperTheme;

  /// Optional hour override for live time-of-day testing in Profile settings (null = real local time)
  final int? previewHour;

  const AppearanceState({
    this.transparencyPercent = 25,
    this.wallpaperTheme = WallpaperTheme.dynamic,
    this.previewHour,
  });

  /// Map 0-100% transparency to background surface alpha multiplier (1.0 down to 0.22)
  double get cardOpacity {
    return (1.0 - (transparencyPercent / 100.0) * 0.78).clamp(0.22, 1.0);
  }

  AppearanceState copyWith({
    int? transparencyPercent,
    WallpaperTheme? wallpaperTheme,
    int? previewHour,
    bool clearPreview = false,
  }) {
    return AppearanceState(
      transparencyPercent: transparencyPercent ?? this.transparencyPercent,
      wallpaperTheme: wallpaperTheme ?? this.wallpaperTheme,
      previewHour: clearPreview ? null : (previewHour ?? this.previewHour),
    );
  }
}

class AppearanceNotifier extends Notifier<AppearanceState> {
  @override
  AppearanceState build() {
    _loadFromPrefs();
    return const AppearanceState();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTransparency = prefs.getInt(_kWidgetTransparency);
      final savedThemeName = prefs.getString(_kWallpaperTheme);

      final parsedTheme = savedThemeName == null ? null : WallpaperTheme.parse(savedThemeName);

      state = state.copyWith(
        transparencyPercent: savedTransparency?.clamp(0, 100),
        wallpaperTheme: parsedTheme,
      );
    } catch (_) {}
  }

  Future<void> setTransparency(int percent) async {
    final clamped = percent.clamp(0, 100);
    state = state.copyWith(transparencyPercent: clamped);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kWidgetTransparency, clamped);
    } catch (_) {}
  }

  Future<void> setWallpaperTheme(WallpaperTheme theme) async {
    state = state.copyWith(wallpaperTheme: theme, clearPreview: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kWallpaperTheme, theme.name);
    } catch (_) {}
  }

  void setPreviewHour(int? hour) {
    state = state.copyWith(
      previewHour: hour,
      clearPreview: hour == null,
    );
  }

  Future<void> toggleWallpaperTheme() async {
    final nextTheme = state.wallpaperTheme.isDynamic
        ? WallpaperTheme.wallpaper2
        : WallpaperTheme.dynamic;
    await setWallpaperTheme(nextTheme);
  }
}

final appearanceProvider = NotifierProvider<AppearanceNotifier, AppearanceState>(AppearanceNotifier.new);

/// Convenience provider for widget card surface opacity
final cardSurfaceOpacityProvider = Provider<double>((ref) {
  return ref.watch(appearanceProvider).cardOpacity;
});
