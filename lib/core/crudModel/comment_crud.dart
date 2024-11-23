// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/project.dart';
import '../models/comment.dart';
import '../models/user.dart';
import '../services/api.dart';

class CRUDComment extends ChangeNotifier {
  final Api _api = Api("comment");
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late List<Comment> comments;

  // Fetch all comments
  Future<List<Comment>> fetchComments() async {
    var result = await _api.getDataCollection();
    comments = result.docs
        .map((doc) => Comment.fromMap(doc.data() as Map<String, dynamic>?, doc.id))
        .toList();
    return comments;
  }

  Stream<QuerySnapshot> fetchCommentsAsStream() {
    return _api.streamDataCollection();
  }

  // Fetch comments by project ID
  Future<List<Comment>> getCommentsByProjectId(String projectId) async {
    var result = await _firestore
        .collection('comment')
        .where('projectId', isEqualTo: projectId)
        .get();
    return result.docs
        .map((doc) => Comment.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Fetch comments by user ID
  Future<List<Comment>> getCommentsByUserId(String userId) async {
    var result = await _firestore
        .collection('comment')
        .where('userId', isEqualTo: userId)
        .get();
    return result.docs
        .map((doc) => Comment.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Fetch comments for a list of projects
  Future<List<Comment>> fetchCommentsForProjects(List<Project> projects) async {
    List<Comment> comments = [];
    for (var project in projects) {
      var projectComments = await getCommentsByProjectId(project.id);
      comments.addAll(projectComments);
    }
    return comments;
  }

  // Fetch comments by user
  Future<List<Comment>> fetchCommentsByUser(User? currentUser) async {
    if (currentUser == null) return [];
    // Filter comments based on projects owned by the user
    var comments = await fetchComments();
    return comments.where((comment) => comment.userId == currentUser.id).toList();
  }

  // Add a comment
  Future<String> addComment(Comment data) async {
    var result = await _api.addDocument(data.toMap());
    return result.id;
  }

  // Update a comment
  Future<void> updateComment(Comment data, String id) async {
    await _api.updateDocument(data.toMap(), id);
  }

  // Delete a comment
  Future<void> removeComment(String id) async {
    await _api.removeDocument(id);
  }

  // Get a comment by ID
  Future<Comment?> getComment(String id) async {
    var doc = await _api.getDocumentById(id);
    return doc.exists ? Comment.fromMap(doc.data() as Map<String, dynamic>?, doc.id) : null;
  }

  // Check if a user has already commented on a project
  Future<bool> hasUserCommentedOnProject(String userId, String projectId) async {
    var result = await _firestore
        .collection('comment')
        .where('userId', isEqualTo: userId)
        .where('projectId', isEqualTo: projectId)
        .get();
    return result.docs.isNotEmpty;
  }

  // Get average rating for a project
  Future<double> getAverageRating(String projectId) async {
    var comments = await getCommentsByProjectId(projectId);
    if (comments.isEmpty) return 0.0;
    var total = comments.fold(0, (total, comment) => total + comment.stars);
    return total / comments.length;
  }

  // Get total number of comments for a project
  Future<int> getCommentCount(String projectId) async {
    var result = await _firestore
        .collection('comment')
        .where('projectId', isEqualTo: projectId)
        .count()
        .get();
    return result.count ?? 0;
  }
}
