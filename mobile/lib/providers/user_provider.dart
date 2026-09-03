import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences keys for guest session persistence.
const _kGuestSessionActive = 'guest_session_active';
const _kOnboardingCompleted = 'onboarding_completed';
const _kSelectedPersona = 'selected_persona';
const _kGuestUserId = 'guest_user_id';

class UserState {
  final String? userId;
  final String? email;
  final String? idToken;
  final String? selectedPersona;
  final bool isAuthenticated;
  final bool onboardingCompleted;
  final bool isGuest;

  const UserState({
    this.userId,
    this.email,
    this.idToken,
    this.selectedPersona,
    this.isAuthenticated = false,
    this.onboardingCompleted = false,
    this.isGuest = false,
  });

  UserState copyWith({
    String? userId,
    String? email,
    String? idToken,
    String? selectedPersona,
    bool? isAuthenticated,
    bool? onboardingCompleted,
    bool? isGuest,
  }) {
    return UserState(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      idToken: idToken ?? this.idToken,
      selectedPersona: selectedPersona ?? this.selectedPersona,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}

class UserNotifier extends Notifier<UserState> {
  @override
  UserState build() {
    return const UserState();
  }

  void setAuthenticated({
    required String userId,
    required String email,
    String? idToken,
  }) {
    state = state.copyWith(
      userId: userId,
      email: email,
      idToken: idToken,
      isAuthenticated: true,
      isGuest: false,
    );
  }

  void setPersona(String persona) {
    state = state.copyWith(selectedPersona: persona);
    _persistPersona(persona);
  }

  void completeOnboarding() {
    state = state.copyWith(onboardingCompleted: true);
    _persistOnboardingCompleted();
  }

  /// Mark this session as a guest session and persist to SharedPreferences.
  void setGuestSession() {
    const guestId = 'guest_user';
    state = state.copyWith(
      userId: guestId,
      email: 'guest@mausam.ai',
      idToken: 'guest_token',
      isAuthenticated: true,
      isGuest: true,
    );
    _persistGuestSession(guestId);
  }

  /// Restore guest session from SharedPreferences.
  /// Returns true if a guest session was restored.
  Future<bool> restoreGuestSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool(_kGuestSessionActive) ?? false;
      final onboarded = prefs.getBool(_kOnboardingCompleted) ?? false;

      if (isGuest && onboarded) {
        final persona = prefs.getString(_kSelectedPersona) ?? 'Fitness';
        final guestId = prefs.getString(_kGuestUserId) ?? 'guest_user';
        state = state.copyWith(
          userId: guestId,
          email: 'guest@mausam.ai',
          idToken: 'guest_token',
          isAuthenticated: true,
          isGuest: true,
          onboardingCompleted: true,
          selectedPersona: persona,
        );
        return true;
      }
    } catch (_) {
      // SharedPreferences unavailable — fall through
    }
    return false;
  }

  void signOut() {
    state = const UserState();
    _clearPersistedSession();
  }

  // ---------------------------------------------------------------------------
  // Private persistence helpers
  // ---------------------------------------------------------------------------

  Future<void> _persistGuestSession(String guestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kGuestSessionActive, true);
      await prefs.setString(_kGuestUserId, guestId);
    } catch (_) {}
  }

  Future<void> _persistOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kOnboardingCompleted, true);
    } catch (_) {}
  }

  Future<void> _persistPersona(String persona) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSelectedPersona, persona);
    } catch (_) {}
  }

  Future<void> _clearPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kGuestSessionActive);
      await prefs.remove(_kOnboardingCompleted);
      await prefs.remove(_kSelectedPersona);
      await prefs.remove(_kGuestUserId);
    } catch (_) {}
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(UserNotifier.new);
