// ignore_for_file: unnecessary_null_comparison, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

import '../base/base_crud.dart';
import '../models/user.dart';
import '../services/auth.dart';
import '../services/storage.dart';

class CRUDUser extends BaseCRUD<User> {
  CRUDUser() : super("users");
  final AuthService authenticator = AuthService();
  User? currentUser;

  @override
  Map<String, dynamic> toJson(User item) => item.toJson();

  @override
  User fromJson(Map<String, dynamic>? data, String id) =>
      User.fromMap(data, id);

  Future<User?> getCurrentUser() async {
    try {
      var user = authenticator.currentUser;
      if (user == null) return null;

      currentUser = await getItem(user.uid);
      notifyListeners();
      return currentUser;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  List<String> getIDS() {
    if (items.isNotEmpty) {
      return items
          .map((e) => e.studentId ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    }
    fetchItems();
    return [];
  }

  User? getUserByStudentID(String id) {
    var ls = items.where((element) => element.studentId == id).toList();
    return ls.isNotEmpty ? ls[0] : User.empty();
  }

  Future<String> updateUserImage(dynamic imageData) async {
    final storageService = StorageService();
    return await storageService.uploadProfilePicture(
        currentUser?.id ?? '', imageData);
  }

  Future<User?> getUserById(String userId) async {
    try {
      return await getItem(userId);
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return User.fromFirestore(doc);
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }

  Future<User?> getItemsById(String id) async {
    return getUserById(id);
  }
}
