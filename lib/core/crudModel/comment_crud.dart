// ignore_for_file: avoid_print

import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../base/base_crud.dart';
import '../models/comment.dart';
import '../models/project.dart';
import '../models/user.dart';

class CRUDComment extends BaseCRUD<Comment> {
  CRUDComment() : super("comments");

  @override
  Map<String, dynamic> toJson(Comment item) => item.toMap();

  @override
  Comment fromJson(Map<String, dynamic>? data, String id) =>
      Comment.fromMap(data, id);

  Future<List<Comment>> getCommentsByProjectId(String projectId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('comments')
          .where('projectId', isEqualTo: projectId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Comment.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting comments by project ID: $e');
      throw e;
    }
  }

  Future<List<Comment>> getCommentsByUserId(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('comments')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Comment.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting comments by user ID: $e');
      throw e;
    }
  }

  Future<List<Comment>> fetchCommentsForProjects(List<Project> projects) async {
    try {
      List<Comment> allComments = [];
      for (var project in projects) {
        var projectComments = await getCommentsByProjectId(project.id);
        allComments.addAll(projectComments);
      }
      return allComments;
    } catch (e) {
      print('Error fetching comments for projects: $e');
      throw e;
    }
  }

  Future<List<Comment>> fetchCommentsByUser(User? currentUser) async {
    if (currentUser == null) return [];
    try {
      return await getCommentsByUserId(currentUser.id);
    } catch (e) {
      print('Error fetching comments by user: $e');
      throw e;
    }
  }

  Future<bool> hasUserCommentedOnProject(
      String userId, String projectId) async {
    try {
      var result = await FirebaseFirestore.instance
          .collection('comments')
          .where('userId', isEqualTo: userId)
          .where('projectId', isEqualTo: projectId)
          .get();
      return result.docs.isNotEmpty;
    } catch (e) {
      print('Error checking user comment: $e');
      throw e;
    }
  }

  Future<double> getAverageRating(String projectId) async {
    try {
      var comments = await getCommentsByProjectId(projectId);
      if (comments.isEmpty) return 0.0;
      var total =
          comments.fold(0, (sum, comment) => sum + (comment.stars ?? 0));
      return total / comments.length;
    } catch (e) {
      print('Error getting average rating: $e');
      throw e;
    }
  }

  Future<int> getCommentCount(String projectId) async {
    if (projectId.isEmpty) {
      throw ArgumentError('projectId cannot be empty');
    }

    try {
      final result = await FirebaseFirestore.instance
          .collection('comments')
          .where('projectId', isEqualTo: projectId)
          .count()
          .get();

      return result.count ?? 0;
    } on FirebaseException catch (e) {
      log('Error getting comment count for project $projectId: $e',
          name: 'CommentCRUD');
      rethrow;
    } catch (e) {
      log('Unexpected error getting comment count: $e', name: 'CommentCRUD');
      throw FirebaseException(
        plugin: 'firestore',
        message: 'Failed to get comment count: $e',
      );
    }
  }

  Future<Comment> addComment(Comment comment) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('comments')
          .add(comment.toMap());

      return comment.copyWith();
    } catch (e) {
      print('Error adding comment: $e');
      throw e;
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('comments')
          .doc(commentId)
          .delete();
    } catch (e) {
      print('Error deleting comment: $e');
      throw e;
    }
  }

  Future<void> updateComment(Comment comment) async {
    try {
      await FirebaseFirestore.instance
          .collection('comments')
          .doc(comment.id)
          .update(comment.toMap());
    } catch (e) {
      print('Error updating comment: $e');
      throw e;
    }
  }

  Future<List<Comment>> fetchComments() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Comment.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching comments: $e');
      throw e;
    }
  }
}
