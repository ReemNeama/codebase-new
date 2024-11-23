import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/project.dart';
import '../services/api.dart';

class CRUDProject extends ChangeNotifier {
  final Api _api = Api("project");

  late List<Project> items = [Project.empty()];

  Future<List<Project>> fetchItems() async {
    var result = await _api.getDataCollection();
    items = result.docs
        .map((doc) => Project.fromMap(doc.data() as Map<String, dynamic>?, doc.id))
        .toList();
    return items;
  }

  Stream<QuerySnapshot> fetchItemsAsStream() {
    return _api.streamDataCollection();
  }

  Future<Project> getItem(String id) async {
    var doc = await _api.getDocumentById(id);
    return Project.fromMap(doc.data() as Map<String, dynamic>?, doc.id);
  }

  Future removeItem(String id) async {
    await _api.removeDocument(id);
    return;
  }

  Future<Project> addItem(Project item) async {
    var docRef = await _api.addDocument(item.toJson());
    var doc = await docRef.get();
    return Project.fromMap(doc.data() as Map<String, dynamic>?, doc.id);
  }

  Future<Project> updateItem(Project item, String id) async {
    await _api.updateDocument(item.toJson(), id);
    var doc = await _api.getDocumentById(id);
    return Project.fromMap(doc.data() as Map<String, dynamic>?, doc.id);
  }

  Future<String> uploadFile(XFile file, String path) async {
    final storageRef = FirebaseStorage.instance.ref().child(path);
    final uploadTask = storageRef.putFile(File(file.path));
    final snapshot = await uploadTask.whenComplete(() {});
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<bool> isProjectNameUnique(String projectName) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('projects')
        .where('name', isEqualTo: projectName)
        .get();
    return querySnapshot.docs.isEmpty;
  }
}
