import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'auth_state.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth;
  AuthState _state = AuthState();
  AuthState get state => _state;

  AuthProvider({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance {
    _init();
  }

  void _init() {
    _handleAuthStateChange(_auth.currentUser);
    _auth.authStateChanges().listen(_handleAuthStateChange);
  }

  void _handleAuthStateChange(User? user) {
    if (user == null) {
      _updateAuthState(AuthState(
        status: AuthStatus.unauthenticated,
        isAuthenticated: false,
      ));
    } else {
      _updateAuthState(AuthState(
        status: AuthStatus.authenticated,
        isAuthenticated: true,
        user: user,
      ));
    }
  }

  void _updateAuthState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      _updateAuthState(_state.copyWith(status: AuthStatus.loading));
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      _updateAuthState(AuthState(
        status: AuthStatus.error,
        error: e.toString(),
        isAuthenticated: false,
      ));
      rethrow;
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    try {
      _updateAuthState(_state.copyWith(status: AuthStatus.loading));
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      _updateAuthState(AuthState(
        status: AuthStatus.error,
        error: e.toString(),
        isAuthenticated: false,
      ));
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      _updateAuthState(AuthState(
        status: AuthStatus.error,
        error: e.toString(),
        isAuthenticated: true,
      ));
      rethrow;
    }
  }

  Future<String?> getCurrentToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  // Permission-related methods
  bool hasPermission(String permission) {
    // TODO: Implement actual permission checking logic based on user claims
    // For now, return true if user is authenticated
    return state.isAuthenticated;
  }

  bool hasAllPermissions(List<String> permissions) {
    // Check if user has all specified permissions
    return permissions.every(hasPermission);
  }

  bool hasAnyPermission(List<String> permissions) {
    // Check if user has at least one of the specified permissions
    return permissions.any(hasPermission);
  }
}
