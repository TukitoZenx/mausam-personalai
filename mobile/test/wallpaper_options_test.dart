import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/providers/appearance_provider.dart';
import 'package:mobile/screens/profile_screen.dart';
import 'package:mobile/theme/environment_theme.dart';
import 'package:mobile/widgets/navigation/app_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Appearance & Wallpaper State Unit Tests', () {
    test('Default state has Dynamic Live Wallpaper active', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(appearanceProvider);
      expect(state.wallpaperTheme, WallpaperTheme.dynamic);
      expect(state.wallpaperTheme.isDynamic, isTrue);
      expect(state.wallpaperTheme.isFixedBlack, isFalse);
      expect(state.previewHour, isNull);
    });

    test('Switching to Fixed Obsidian Black updates state and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appearanceProvider.notifier);
      await notifier.setWallpaperTheme(WallpaperTheme.wallpaper2);

      final state = container.read(appearanceProvider);
      expect(state.wallpaperTheme, WallpaperTheme.wallpaper2);
      expect(state.wallpaperTheme.isDynamic, isFalse);
      expect(state.wallpaperTheme.isFixedBlack, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('home_wallpaper_theme'), 'wallpaper2');
    });

    test('toggleWallpaperTheme flips between Dynamic and Fixed Black', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appearanceProvider.notifier);
      expect(container.read(appearanceProvider).wallpaperTheme, WallpaperTheme.dynamic);

      await notifier.toggleWallpaperTheme();
      expect(container.read(appearanceProvider).wallpaperTheme, WallpaperTheme.wallpaper2);

      await notifier.toggleWallpaperTheme();
      expect(container.read(appearanceProvider).wallpaperTheme, WallpaperTheme.dynamic);
    });

    test('Preview hour sets and clears cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appearanceProvider.notifier);
      notifier.setPreviewHour(8);
      expect(container.read(appearanceProvider).previewHour, 8);

      notifier.setPreviewHour(null);
      expect(container.read(appearanceProvider).previewHour, isNull);
    });
  });

  group('ProfileScreen Wallpaper Selection Widget Tests', () {
    testWidgets('Displays 2 choices with Dynamic Live Wallpaper active by default', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProfileScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Option 1: Dynamic Live Wallpaper
      expect(find.byKey(const Key('wallpaper_option_dynamic')), findsOneWidget);
      expect(find.text('Dynamic Live Wallpaper'), findsOneWidget);
      expect(find.text('DEFAULT'), findsOneWidget);

      // Verify Option 2: Fixed Obsidian Black
      expect(find.byKey(const Key('wallpaper_option_fixed')), findsOneWidget);
      expect(find.text('Fixed Obsidian Black'), findsOneWidget);

      // Verify 4 Time stage chips
      expect(find.text('Morning'), findsWidgets);
      expect(find.text('Afternoon'), findsWidgets);
      expect(find.text('Evening'), findsWidgets);
      expect(find.text('Night'), findsWidgets);

      // Verify Time previewer buttons
      expect(find.byKey(const Key('preview_time_live')), findsOneWidget);
      expect(find.byKey(const Key('preview_time_am')), findsOneWidget);
      expect(find.byKey(const Key('preview_time_noon')), findsOneWidget);
      expect(find.byKey(const Key('preview_time_eve')), findsOneWidget);
      expect(find.byKey(const Key('preview_time_night')), findsOneWidget);
    });

    testWidgets('Tapping Fixed Obsidian Black selects it and switches ACTIVE status', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ProfileScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(container.read(appearanceProvider).wallpaperTheme, WallpaperTheme.dynamic);

      // Tap Option 2: Fixed Obsidian Black
      await tester.tap(find.byKey(const Key('wallpaper_option_fixed')));
      await tester.pumpAndSettle();

      expect(container.read(appearanceProvider).wallpaperTheme, WallpaperTheme.wallpaper2);
      expect(find.text('Fixed Obsidian Black active'), findsOneWidget);

      // Tap Option 1: Dynamic Live Wallpaper
      await tester.tap(find.byKey(const Key('wallpaper_option_dynamic')));
      await tester.pumpAndSettle();

      expect(container.read(appearanceProvider).wallpaperTheme, WallpaperTheme.dynamic);
      expect(find.text('Live Dynamic Wallpaper active'), findsOneWidget);
    });
  });

  group('MausamAppDrawer Quick-Switch Widget Tests', () {
    testWidgets('Renders Live Sky and Fixed Black quick switcher and toggles cleanly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              drawer: MausamAppDrawer(currentRoute: '/home'),
              body: Center(child: Text('Home Content')),
            ),
          ),
        ),
      );

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('drawer_switch_dynamic')), findsOneWidget);
      expect(find.byKey(const Key('drawer_switch_fixed')), findsOneWidget);
      expect(find.text('Live Sky'), findsOneWidget);
      expect(find.text('Fixed Black'), findsOneWidget);

      // Tap Fixed Black in Drawer
      await tester.tap(find.byKey(const Key('drawer_switch_fixed')));
      await tester.pumpAndSettle();
      expect(container.read(appearanceProvider).wallpaperTheme, WallpaperTheme.wallpaper2);

      // Tap Live Sky in Drawer
      await tester.tap(find.byKey(const Key('drawer_switch_dynamic')));
      await tester.pumpAndSettle();
      expect(container.read(appearanceProvider).wallpaperTheme, WallpaperTheme.dynamic);
    });
  });
}
