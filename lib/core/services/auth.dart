import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firebase user one-time fetch
  User? get getUser => _auth.currentUser;

  // Firebase user a realtime stream
  Stream<User?> get user => _auth.authStateChanges();

  Future<UserCredential> loginWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential> signupWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  /// Updates the User's data in Firestore on each new login
  // Future<void> updateUserData(User user) async {
  //   //  String? fcmToken = await _fcm.getToken();
  //   DocumentReference userProfileRef = _db.collection('profiles').doc(user.uid);

  //   return userProfileRef.set(userProfileRef);
  //   //      (
  //   //               uid: user.uid,
  //   //               lastActivity: Timestamp.now(),
  //   //               platform: Platform.operatingSystem,
  //   //               token: fcmToken)
  //   //           .toJson(),
  //   //       merge: true));

  // Sign out
  Future<void> signOut() {
    return _auth.signOut();
  }
}
