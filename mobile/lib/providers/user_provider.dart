import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences keys for session persistence.
const _kGuestSessionActive = 'guest_session_active';
const _kAuthSessionActive = 'auth_session_active';
const _kAuthUserId = 'auth_user_id';
const _kAuthEmail = 'auth_email';
const _kAuthDisplayName = 'auth_display_name';
const _kAuthIdToken = 'auth_id_token';
const _kOnboardingCompleted = 'onboarding_completed';
const _kSelectedPersona = 'selected_persona';
const _kGuestUserId = 'guest_user_id';
const _kNotifyRain = 'notify_rain';
const _kNotifyHeat = 'notify_heat';
const _kNotifyAqi = 'notify_aqi';
const _kUserAge = 'user_age';
const _kUserGender = 'user_gender';
const _kUserHeight = 'user_height';
const _kUserWeight = 'user_weight';
const _kUserHeightUnit = 'user_height_unit';
const _kUserWeightUnit = 'user_weight_unit';
const _kSelectedPersonas = 'selected_personas';
const _kWeatherTriggers = 'weather_triggers';
const _kHealthConcerns = 'health_concerns';
const _kWhatMattersMost = 'what_matters_most';
const _kActivityLevel = 'activity_level';

class UserState {
  final String? userId;
  final String? email;
  final String? displayName;
  final String? idToken;
  final String? selectedPersona;
  final List<String> selectedPersonas;
  final List<String> weatherTriggers;
  final List<String> healthConcerns;
  final List<String> whatMattersMost;
  final String activityLevel;
  final bool isAuthenticated;
  final bool onboardingCompleted;
  final bool isGuest;
  final bool notifyRain;
  final bool notifyHeat;
  final bool notifyAqi;
  final int? age;
  final String? gender;
  final double? height;
  final double? weight;
  final String heightUnit;
  final String weightUnit;

  const UserState({
    this.userId,
    this.email,
    this.displayName,
    this.idToken,
    this.selectedPersona,
    this.selectedPersonas = const [],
    this.weatherTriggers = const [],
    this.healthConcerns = const [],
    this.whatMattersMost = const ['Daily energy'],
    this.activityLevel = 'Low',
    this.isAuthenticated = false,
    this.onboardingCompleted = false,
    this.isGuest = false,
    this.notifyRain = true,
    this.notifyHeat = true,
    this.notifyAqi = true,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.heightUnit = 'cm',
    this.weightUnit = 'kg',
  });

  UserState copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? idToken,
    String? selectedPersona,
    List<String>? selectedPersonas,
    List<String>? weatherTriggers,
    List<String>? healthConcerns,
    List<String>? whatMattersMost,
    String? activityLevel,
    bool? isAuthenticated,
    bool? onboardingCompleted,
    bool? isGuest,
    bool? notifyRain,
    bool? notifyHeat,
    bool? notifyAqi,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? heightUnit,
    String? weightUnit,
  }) {
    return UserState(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      idToken: idToken ?? this.idToken,
      selectedPersona: selectedPersona ?? this.selectedPersona,
      selectedPersonas: selectedPersonas ?? this.selectedPersonas,
      weatherTriggers: weatherTriggers ?? this.weatherTriggers,
      healthConcerns: healthConcerns ?? this.healthConcerns,
      whatMattersMost: whatMattersMost ?? this.whatMattersMost,
      activityLevel: activityLevel ?? this.activityLevel,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      isGuest: isGuest ?? this.isGuest,
      notifyRain: notifyRain ?? this.notifyRain,
      notifyHeat: notifyHeat ?? this.notifyHeat,
      notifyAqi: notifyAqi ?? this.notifyAqi,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      heightUnit: heightUnit ?? this.heightUnit,
      weightUnit: weightUnit ?? this.weightUnit,
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
    String? displayName,
    String? idToken,
  }) {
    state = state.copyWith(
      userId: userId,
      email: email,
      displayName: displayName,
      idToken: idToken,
      isAuthenticated: true,
      isGuest: false,
    );
    _persistAuthSession(
      userId: userId,
      email: email,
      displayName: displayName,
      idToken: idToken,
    );
  }

  void setPersona(String persona) {
    state = state.copyWith(
      selectedPersona: persona,
      selectedPersonas: [persona],
    );
    _persistPersona(persona);
    _persistPersonas([persona]);
  }

  void setPersonas(List<String> personas) {
    state = state.copyWith(
      selectedPersona: personas.isNotEmpty ? personas.first : null,
      selectedPersonas: personas,
    );
    if (personas.isNotEmpty) {
      _persistPersona(personas.first);
    }
    _persistPersonas(personas);
  }

  void setTriggersAndConcerns({
    required List<String> triggers,
    required List<String> concerns,
  }) {
    state = state.copyWith(
      weatherTriggers: triggers,
      healthConcerns: concerns,
    );
    _persistTriggersAndConcerns(triggers, concerns);
  }

  void completeOnboarding() {
    state = state.copyWith(onboardingCompleted: true);
    _persistOnboardingCompleted();
  }

  void setAlertPreferences({
    required bool rain,
    required bool heat,
    required bool aqi,
  }) {
    state = state.copyWith(notifyRain: rain, notifyHeat: heat, notifyAqi: aqi);
    _persistAlertPreferences(rain: rain, heat: heat, aqi: aqi);
  }

  void setUserProfileDetails({
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? heightUnit,
    String? weightUnit,
  }) {
    state = state.copyWith(
      age: age ?? state.age,
      gender: gender ?? state.gender,
      height: height ?? state.height,
      weight: weight ?? state.weight,
      heightUnit: heightUnit ?? state.heightUnit,
      weightUnit: weightUnit ?? state.weightUnit,
    );
    _persistUserProfileDetails();
  }

  void setRhythmPreferences({
    required List<String> whatMattersMost,
    required String activityLevel,
  }) {
    state = state.copyWith(
      whatMattersMost: whatMattersMost,
      activityLevel: activityLevel,
    );
    _persistRhythmPreferences(whatMattersMost, activityLevel);
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
        final personas = prefs.getStringList(_kSelectedPersonas) ?? [persona];
        final triggers = prefs.getStringList(_kWeatherTriggers) ?? const [];
        final concerns = prefs.getStringList(_kHealthConcerns) ?? const [];
        final matters = prefs.getStringList(_kWhatMattersMost) ?? const ['Daily energy'];
        final activity = prefs.getString(_kActivityLevel) ?? 'Low';
        state = state.copyWith(
          userId: guestId,
          email: 'guest@mausam.ai',
          idToken: 'guest_token',
          isAuthenticated: true,
          isGuest: true,
          onboardingCompleted: true,
          selectedPersona: persona,
          selectedPersonas: personas,
          weatherTriggers: triggers,
          healthConcerns: concerns,
          whatMattersMost: matters,
          activityLevel: activity,
          notifyRain: prefs.getBool(_kNotifyRain) ?? true,
          notifyHeat: prefs.getBool(_kNotifyHeat) ?? true,
          notifyAqi: prefs.getBool(_kNotifyAqi) ?? true,
          age: prefs.getInt(_kUserAge),
          gender: prefs.getString(_kUserGender),
          height: prefs.getDouble(_kUserHeight),
          weight: prefs.getDouble(_kUserWeight),
          heightUnit: prefs.getString(_kUserHeightUnit) ?? 'cm',
          weightUnit: prefs.getString(_kUserWeightUnit) ?? 'kg',
        );
        return true;
      }
    } catch (_) {
      // SharedPreferences unavailable — fall through
    }
    return false;
  }

  /// Restore authenticated session from SharedPreferences.
  /// Returns true if an authenticated user session was restored.
  Future<bool> restoreAuthSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAuth = prefs.getBool(_kAuthSessionActive) ?? false;
      final userId = prefs.getString(_kAuthUserId);
      final email = prefs.getString(_kAuthEmail);

      if (isAuth && userId != null && email != null) {
        final displayName = prefs.getString(_kAuthDisplayName);
        final idToken = prefs.getString(_kAuthIdToken);
        final persona = prefs.getString(_kSelectedPersona) ?? 'Fitness';
        final personas = prefs.getStringList(_kSelectedPersonas) ?? [persona];
        final triggers = prefs.getStringList(_kWeatherTriggers) ?? const [];
        final concerns = prefs.getStringList(_kHealthConcerns) ?? const [];
        final matters = prefs.getStringList(_kWhatMattersMost) ?? const ['Daily energy'];
        final activity = prefs.getString(_kActivityLevel) ?? 'Low';
        final onboarded = prefs.getBool(_kOnboardingCompleted) ?? false;

        state = state.copyWith(
          userId: userId,
          email: email,
          displayName: displayName,
          idToken: idToken,
          isAuthenticated: true,
          isGuest: false,
          onboardingCompleted: onboarded,
          selectedPersona: persona,
          selectedPersonas: personas,
          weatherTriggers: triggers,
          healthConcerns: concerns,
          whatMattersMost: matters,
          activityLevel: activity,
          notifyRain: prefs.getBool(_kNotifyRain) ?? true,
          notifyHeat: prefs.getBool(_kNotifyHeat) ?? true,
          notifyAqi: prefs.getBool(_kNotifyAqi) ?? true,
          age: prefs.getInt(_kUserAge),
          gender: prefs.getString(_kUserGender),
          height: prefs.getDouble(_kUserHeight),
          weight: prefs.getDouble(_kUserWeight),
          heightUnit: prefs.getString(_kUserHeightUnit) ?? 'cm',
          weightUnit: prefs.getString(_kUserWeightUnit) ?? 'kg',
        );
        return true;
      }
    } catch (_) {}
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

  Future<void> _persistAlertPreferences({
    required bool rain,
    required bool heat,
    required bool aqi,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kNotifyRain, rain);
      await prefs.setBool(_kNotifyHeat, heat);
      await prefs.setBool(_kNotifyAqi, aqi);
    } catch (_) {}
  }

  Future<void> _persistUserProfileDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (state.age != null) {
        await prefs.setInt(_kUserAge, state.age!);
      } else {
        await prefs.remove(_kUserAge);
      }
      if (state.gender != null) {
        await prefs.setString(_kUserGender, state.gender!);
      } else {
        await prefs.remove(_kUserGender);
      }
      if (state.height != null) {
        await prefs.setDouble(_kUserHeight, state.height!);
      } else {
        await prefs.remove(_kUserHeight);
      }
      if (state.weight != null) {
        await prefs.setDouble(_kUserWeight, state.weight!);
      } else {
        await prefs.remove(_kUserWeight);
      }
      await prefs.setString(_kUserHeightUnit, state.heightUnit);
      await prefs.setString(_kUserWeightUnit, state.weightUnit);
    } catch (_) {}
  }

  Future<void> _persistPersonas(List<String> personas) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kSelectedPersonas, personas);
    } catch (_) {}
  }

  Future<void> _persistTriggersAndConcerns(List<String> triggers, List<String> concerns) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kWeatherTriggers, triggers);
      await prefs.setStringList(_kHealthConcerns, concerns);
    } catch (_) {}
  }

  Future<void> _persistRhythmPreferences(List<String> whatMattersMost, String activityLevel) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kWhatMattersMost, whatMattersMost);
      await prefs.setString(_kActivityLevel, activityLevel);
    } catch (_) {}
  }

  Future<void> _persistAuthSession({
    required String userId,
    required String email,
    String? displayName,
    String? idToken,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kAuthSessionActive, true);
      await prefs.remove(_kGuestSessionActive);
      await prefs.setString(_kAuthUserId, userId);
      await prefs.setString(_kAuthEmail, email);
      if (displayName != null) {
        await prefs.setString(_kAuthDisplayName, displayName);
      } else {
        await prefs.remove(_kAuthDisplayName);
      }
      if (idToken != null) {
        await prefs.setString(_kAuthIdToken, idToken);
      } else {
        await prefs.remove(_kAuthIdToken);
      }
    } catch (_) {}
  }

  Future<void> _clearPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kAuthSessionActive);
      await prefs.remove(_kAuthUserId);
      await prefs.remove(_kAuthEmail);
      await prefs.remove(_kAuthDisplayName);
      await prefs.remove(_kAuthIdToken);
      await prefs.remove(_kGuestSessionActive);
      await prefs.remove(_kOnboardingCompleted);
      await prefs.remove(_kSelectedPersona);
      await prefs.remove(_kSelectedPersonas);
      await prefs.remove(_kWeatherTriggers);
      await prefs.remove(_kHealthConcerns);
      await prefs.remove(_kWhatMattersMost);
      await prefs.remove(_kActivityLevel);
      await prefs.remove(_kGuestUserId);
      await prefs.remove(_kUserAge);
      await prefs.remove(_kUserGender);
      await prefs.remove(_kUserHeight);
      await prefs.remove(_kUserWeight);
      await prefs.remove(_kUserHeightUnit);
      await prefs.remove(_kUserWeightUnit);
    } catch (_) {}
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(UserNotifier.new);
