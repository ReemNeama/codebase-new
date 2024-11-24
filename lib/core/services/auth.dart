import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw e.toString();
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw e.toString();
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw e.toString();
    }
  }

  // Update user profile
  Future<void> updateUserProfile({String? displayName, String? photoURL}) async {
    try {
      if (_auth.currentUser != null) {
        await _auth.currentUser!.updateProfile(
          displayName: displayName,
          photoURL: photoURL,
        );
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Check if user has permission
  Future<bool> hasPermission(String permission) async {
    try {
      if (_auth.currentUser == null) return false;
      
      final userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      
      if (!userDoc.exists) return false;
      
      final permissions = userDoc.data()?['permissions'] as List<dynamic>?;
      return permissions?.contains(permission) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Check if user has all permissions
  Future<bool> hasAllPermissions(List<String> permissions) async {
    for (var permission in permissions) {
      if (!await hasPermission(permission)) return false;
    }
    return true;
  }

  // Check if user has any of the permissions
  Future<bool> hasAnyPermission(List<String> permissions) async {
    for (var permission in permissions) {
      if (await hasPermission(permission)) return true;
    }
    return false;
  }
}
