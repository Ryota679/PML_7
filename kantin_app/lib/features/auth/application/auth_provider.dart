
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. The State (data) class
class AuthState {
  final bool isAuthenticated;
  AuthState({this.isAuthenticated = false});
}

// 2. The Notifier class
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  void login(String email, String password) {
    // TODO: Implement actual API call
    state = AuthState(isAuthenticated: true);
  }

  void logout() {
    // TODO: Implement actual API call
    state = AuthState(isAuthenticated: false);
  }
}

// 3. The Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
