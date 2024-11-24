import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../base/base_crud.dart';
import '../models/project.dart';
import '../services/storage.dart';

class CRUDProject extends BaseCRUD<Project> {
  final StorageService _storageService = StorageService();

  CRUDProject() : super("projects");

  @override
  Map<String, dynamic> toJson(Project item) => item.toJson();

  @override
  Project fromJson(Map<String, dynamic>? data, String id) =>
      Project.fromMap(data, id);

  Future<String> uploadFile(XFile file, String path) async {
    return await _storageService.uploadFile(path, File(file.path));
  }

  Future<bool> isProjectNameUnique(String projectName) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('projects')
        .where('name', isEqualTo: projectName)
        .get();
    return querySnapshot.docs.isEmpty;
  }

  Future<List<Project>> getProjectsByUserId(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Project.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting projects by user ID: $e');
      return [];
    }
  }

  Future<List<Project>> getCollaboratedProjects(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .where('collaborators', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Project.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting collaborated projects: $e');
      return [];
    }
  }

  Future<void> incrementViews(String projectId) async {
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .update({'views': FieldValue.increment(1)});
    } catch (e) {
      print('Error incrementing views: $e');
    }
  }

  Future<void> incrementDownloads(String projectId) async {
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .update({'downloads': FieldValue.increment(1)});
    } catch (e) {
      print('Error incrementing downloads: $e');
    }
  }

  Future<void> updateStars(String projectId, int stars) async {
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .update({'stars': stars});
    } catch (e) {
      print('Error updating stars: $e');
    }
  }

  Future<List<Project>> searchProjects(String query) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      return querySnapshot.docs
          .map((doc) => Project.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error searching projects: $e');
      return [];
    }
  }
}
