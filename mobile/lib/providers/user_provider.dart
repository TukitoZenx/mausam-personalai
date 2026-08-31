import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserState {
  final String? userId;
  final String? email;
  final String? idToken;
  final String? selectedPersona;
  final bool isAuthenticated;
  final bool onboardingCompleted;

  const UserState({
    this.userId,
    this.email,
    this.idToken,
    this.selectedPersona,
    this.isAuthenticated = false,
    this.onboardingCompleted = false,
  });

  UserState copyWith({
    String? userId,
    String? email,
    String? idToken,
    String? selectedPersona,
    bool? isAuthenticated,
    bool? onboardingCompleted,
  }) {
    return UserState(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      idToken: idToken ?? this.idToken,
      selectedPersona: selectedPersona ?? this.selectedPersona,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
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
    );
  }

  void setPersona(String persona) {
    state = state.copyWith(selectedPersona: persona);
  }

  void completeOnboarding() {
    state = state.copyWith(onboardingCompleted: true);
  }

  void signOut() {
    state = const UserState();
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(UserNotifier.new);
