import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserState {
  final String? userId;
  final String? name;
  final String? selectedPersona;
  final bool isAuthenticated;

  const UserState({
    this.userId,
    this.name,
    this.selectedPersona,
    this.isAuthenticated = false,
  });
}

class UserNotifier extends Notifier<UserState> {
  @override
  UserState build() {
    return const UserState();
  }

  void setPersona(String persona) {
    state = UserState(
      userId: state.userId,
      name: state.name,
      selectedPersona: persona,
      isAuthenticated: state.isAuthenticated,
    );
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(UserNotifier.new);
