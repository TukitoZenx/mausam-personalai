import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../services/firebase_bootstrap.dart';
import 'auth_provider.dart';
import 'homepage_provider.dart';
import 'location_provider.dart';
import 'user_provider.dart';
import 'weather_dashboard_provider.dart';

enum LaunchStepStatus { pending, running, done, blocked, failed }

enum LaunchDestination { home, login, stay }

class BootstrapState {
  final LaunchStepStatus initializing;
  final LaunchStepStatus restoringSession;
  final LaunchStepStatus gettingLocation;
  final LaunchStepStatus loadingWeather;
  final bool ready;
  final LaunchDestination destination;
  final bool locationPermissionNeeded;
  final String? errorMessage;
  final bool ran;

  const BootstrapState({
    this.initializing = LaunchStepStatus.pending,
    this.restoringSession = LaunchStepStatus.pending,
    this.gettingLocation = LaunchStepStatus.pending,
    this.loadingWeather = LaunchStepStatus.pending,
    this.ready = false,
    this.destination = LaunchDestination.stay,
    this.locationPermissionNeeded = false,
    this.errorMessage,
    this.ran = false,
  });

  BootstrapState copyWith({
    LaunchStepStatus? initializing,
    LaunchStepStatus? restoringSession,
    LaunchStepStatus? gettingLocation,
    LaunchStepStatus? loadingWeather,
    bool? ready,
    LaunchDestination? destination,
    bool? locationPermissionNeeded,
    String? errorMessage,
    bool clearError = false,
    bool? ran,
  }) {
    return BootstrapState(
      initializing: initializing ?? this.initializing,
      restoringSession: restoringSession ?? this.restoringSession,
      gettingLocation: gettingLocation ?? this.gettingLocation,
      loadingWeather: loadingWeather ?? this.loadingWeather,
      ready: ready ?? this.ready,
      destination: destination ?? this.destination,
      locationPermissionNeeded: locationPermissionNeeded ?? this.locationPermissionNeeded,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      ran: ran ?? this.ran,
    );
  }
}

class BootstrapNotifier extends Notifier<BootstrapState> {
  bool _running = false;

  @override
  BootstrapState build() => const BootstrapState();

  Future<void> run() async {
    if (_running || state.ready) return;
    _running = true;
    state = state.copyWith(ran: true, initializing: LaunchStepStatus.running, clearError: true);

    try {
      await _waitForFirebase();
      state = state.copyWith(initializing: LaunchStepStatus.done, restoringSession: LaunchStepStatus.running);

      final signedIn = await _restoreSession();
      if (!signedIn) {
        state = state.copyWith(
          restoringSession: LaunchStepStatus.done,
          destination: LaunchDestination.login,
        );
        return;
      }
      state = state.copyWith(restoringSession: LaunchStepStatus.done, gettingLocation: LaunchStepStatus.running);

      final locationOk = await _resolveLocation();
      if (!locationOk) {
        state = state.copyWith(
          gettingLocation: LaunchStepStatus.blocked,
          locationPermissionNeeded: true,
        );
        // Continue with cached/default coords if we have any usable point.
      } else {
        state = state.copyWith(gettingLocation: LaunchStepStatus.done, locationPermissionNeeded: false);
      }

      state = state.copyWith(loadingWeather: LaunchStepStatus.running);
      final weatherOk = await _loadWeather();
      final hasWeather = ref.read(weatherDashboardProvider).data != null;
      final hasCoords = ref.read(locationProvider).activeLatitude != 0.0 ||
          ref.read(locationProvider).activeLongitude != 0.0;
      if (!weatherOk && !hasWeather && hasCoords) {
        state = state.copyWith(
          loadingWeather: LaunchStepStatus.failed,
          errorMessage: "Mausam couldn't refresh the latest weather.",
        );
        return;
      }
      state = state.copyWith(
        loadingWeather: hasWeather ? LaunchStepStatus.done : LaunchStepStatus.blocked,
      );

      // Insights feed is non-blocking.
      ref.read(homepageProvider.notifier).fetchHomeFeed();

      state = state.copyWith(ready: true, destination: LaunchDestination.home);
    } catch (e) {
      debugPrint('Bootstrap failed: $e');
      final cached = ref.read(weatherDashboardProvider).data != null;
      state = state.copyWith(
        errorMessage: cached ? null : "Mausam couldn't refresh the latest weather.",
        loadingWeather: state.loadingWeather == LaunchStepStatus.running
            ? (cached ? LaunchStepStatus.done : LaunchStepStatus.failed)
            : state.loadingWeather,
        ready: cached,
        destination: cached ? LaunchDestination.home : state.destination,
      );
    } finally {
      _running = false;
    }
  }

  Future<void> retryWeather() async {
    state = state.copyWith(loadingWeather: LaunchStepStatus.running, clearError: true);
    final ok = await _loadWeather();
    if (ok || ref.read(weatherDashboardProvider).data != null) {
      ref.read(homepageProvider.notifier).fetchHomeFeed();
      state = state.copyWith(
        loadingWeather: LaunchStepStatus.done,
        ready: true,
        destination: LaunchDestination.home,
      );
    } else {
      state = state.copyWith(
        loadingWeather: LaunchStepStatus.failed,
        errorMessage: "Mausam couldn't refresh the latest weather.",
      );
    }
  }

  Future<void> continueWithoutGps() async {
    state = state.copyWith(
      gettingLocation: LaunchStepStatus.done,
      locationPermissionNeeded: false,
      loadingWeather: LaunchStepStatus.running,
      clearError: true,
    );
    final ok = await _loadWeather();
    ref.read(homepageProvider.notifier).fetchHomeFeed();
    state = state.copyWith(
      loadingWeather: ok ? LaunchStepStatus.done : LaunchStepStatus.failed,
      ready: true,
      destination: LaunchDestination.home,
    );
  }

  Future<void> _waitForFirebase() async {
    try {
      await FirebaseBootstrap.ensureInitialized();
    } catch (e) {
      debugPrint('Firebase not ready during launch: $e');
    }
  }

  Future<bool> _restoreSession() async {
    try {
      User? user;
      try {
        final authService = ref.read(authServiceProvider);
        user = authService.currentUser ?? FirebaseAuth.instance.currentUser;
      } catch (_) {}

      if (user != null) {
        String? idToken;
        try {
          idToken = await user.getIdToken();
        } catch (_) {}
        final userNotifier = ref.read(userProvider.notifier);
        userNotifier.setAuthenticated(
          userId: user.uid,
          email: user.email ?? 'user@mausam.ai',
          idToken: idToken ?? 'test_token',
        );
        if (ref.read(userProvider).selectedPersona == null) {
          try {
            final me = await ref.read(apiClientProvider).getMe(idToken: idToken ?? 'test_token');
            final persona = me['persona'] as String? ?? me['persona_type'] as String? ?? 'Fitness';
            userNotifier.setPersona(persona);
          } catch (_) {
            userNotifier.setPersona('Fitness');
          }
        }
        userNotifier.completeOnboarding();
        return true;
      }

      final restoredAuth = await ref.read(userProvider.notifier).restoreAuthSession();
      if (restoredAuth) {
        final userState = ref.read(userProvider);
        if (userState.selectedPersona == null) {
          try {
            final me = await ref.read(apiClientProvider).getMe(idToken: userState.idToken ?? 'test_token');
            final persona = me['persona'] as String? ?? me['persona_type'] as String? ?? 'Fitness';
            ref.read(userProvider.notifier).setPersona(persona);
          } catch (_) {
            ref.read(userProvider.notifier).setPersona('Fitness');
          }
        }
        return true;
      }

      return await ref.read(userProvider.notifier).restoreGuestSession();
    } catch (e) {
      debugPrint('Session restore failed: $e');
      return false;
    }
  }

  Future<bool> _resolveLocation() async {
    final apiClient = ref.read(apiClientProvider);
    final idToken = ref.read(userProvider).idToken ?? 'test_token';
    final location = ref.read(locationProvider.notifier);

    await location.restorePersisted();
    await location.hydrateSavedLocations(apiClient, idToken);

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
        await location.detectDeviceLocation(apiClient, idToken);
        return true;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      var permission = await Geolocator.checkPermission();
      if (!serviceEnabled) {
        return ref.read(locationProvider).activeLatitude != 0.0;
      }
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return ref.read(locationProvider).activeLatitude != 0.0;
      }

      await location.detectDeviceLocation(apiClient, idToken);
      return true;
    } catch (e) {
      debugPrint('Location resolve failed: $e');
      return ref.read(locationProvider).activeLatitude != 0.0;
    }
  }

  Future<bool> _loadWeather() async {
    try {
      await ref.read(weatherDashboardProvider.notifier).fetchDashboard();
      return ref.read(weatherDashboardProvider).data != null;
    } catch (_) {
      return ref.read(weatherDashboardProvider).data != null;
    }
  }
}

final bootstrapProvider = NotifierProvider<BootstrapNotifier, BootstrapState>(BootstrapNotifier.new);
