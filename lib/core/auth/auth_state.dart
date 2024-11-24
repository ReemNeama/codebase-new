import 'package:firebase_auth/firebase_auth.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final bool isAuthenticated;
  final User? user;
  final String? error;

  AuthState({
    this.status = AuthStatus.initial,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    bool? isAuthenticated,
    User? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}
