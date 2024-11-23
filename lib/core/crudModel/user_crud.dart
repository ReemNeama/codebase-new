// ignore_for_file: unnecessary_null_comparison, avoid_print

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/user.dart';
import '../services/api.dart';
import '../services/auth.dart';

class CRUDUser extends ChangeNotifier {
  final Api _api = Api("users");
  final AuthService authenticator = AuthService();

  late List<User> items;
  User currentUser = User.empty();

  Future<List<User>> fetchItems() async {
    var result = await _api.getDataCollection();
    items = result.docs
        .map((doc) => User.fromMap(doc.data() as Map<String, dynamic>?, doc.id))
        .toList();
    return items;
  }

  Future<User?> getCurrentUser() async {
    try {
      // Check if the user is authenticated first
      var user = authenticator.getUser;
      if (user == null) {
        return null;
      }

      var uid = user.uid;
      currentUser = await getItemsById(uid);
      notifyListeners();
      return currentUser;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  Stream<QuerySnapshot> fetchItemsAsStream() {
    return _api.streamDataCollection();
  }

  Future<User> getItemsById(String id) async {
    var doc = await _api.getDocumentById(id);
    return User.fromMap(doc.data() as Map<String, dynamic>?, doc.id);
  }

  Future removeItem(String id) async {
    await _api.removeDocument(id);
    return;
  }

  Future updateItem(User data, String id) async {
    await _api.updateDocument(data.toJson(), id);
    return;
  }

  Future addItem(User data) async {
    await _api.addDocument(data.toJson());
    return;
  }

  List<String> getIDS() {
    if (items.isNotEmpty) {
      return items.map((e) => e.studentId ?? '').where((id) => id.isNotEmpty).toList();
    }
    fetchItems();
    return [];
  }

  User? getUserByStudentID(String id) {
    var ls = items.where((element) => element.studentId == id).toList();
    if (ls.isNotEmpty) {
      return ls[0];
    } else {
      return User.empty();
    }
  }

  Future<String> updateUserImage(Uint8List image) async {
    final storage = FirebaseStorage.instance;
    final fileName = 'profile/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = storage.ref().child(fileName);
    
    // Create upload task
    final uploadTask = ref.putData(image);
    
    // Wait for upload to complete
    final snapshot = await uploadTask.whenComplete(() => null);
    
    // Get download URL
    final url = await snapshot.ref.getDownloadURL();
    
    return url;
  }

  Future<User?> getUserById(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (snapshot.exists) {
        return User.fromMap(snapshot.data()!, userId);
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }
}
