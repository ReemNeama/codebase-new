// lib/models/project.dart

// ignore_for_file: avoid_types_as_parameter_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show Color, Colors;
import '../../utils/exceptions.dart';

class Project {
  final String id;
  final String userId;
  final String name;
  final String description;
  final String? logoUrl;
  final List<String> screenshotsUrl;
  final String? downloadUrl;
  final String? downloadUrlForIphone;
  final String status;
  
  final bool isGraduation;

  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> collaborators;
  final Map<String, String> downloadUrls;

  final String category;
  final int stars;
  final int views;
  final int downloads;

  static const List<String> statusOptions = [
    'Pending',
    'In Review',
    'Approved',
    'Rejected',
  ];

  Project({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    this.logoUrl,
    required this.screenshotsUrl,
    this.downloadUrl,
    this.downloadUrlForIphone,
    required this.status,

    required this.isGraduation,
    required this.createdAt,
    required this.updatedAt,
    required this.collaborators,
    required this.downloadUrls,
 
    required this.category,
    this.stars = 0,
    this.views = 0,
    this.downloads = 0,
  });

  // Factory constructor for creating an empty project
  factory Project.empty() {
    return Project(
      id: '',
      userId: '',
      name: '',
      description: '',
      screenshotsUrl: [],
      status: statusOptions[0], // Default to 'Pending'
      isGraduation: false,

      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      collaborators: [],
      downloadUrls: {},

      category: '',
      stars: 0,
      views: 0,
      downloads: 0,
    );
  }

  void validate() {
    if (name.isEmpty) {
      throw DatabaseException('Project name cannot be empty');
    }
    if (description.isEmpty) {
      throw DatabaseException('Project description cannot be empty');
    }
    if (!statusOptions.contains(status)) {
      throw DatabaseException('Invalid project status');
    }
  }

  factory Project.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      return Project(
        id: doc.id,
        userId: data['userId'] ?? '',
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        logoUrl: data['logoUrl'],
        screenshotsUrl: List<String>.from(data['screenshotsUrl'] ?? []),
        downloadUrl: data['downloadUrl'],
        downloadUrlForIphone: data['downloadUrlForIphone'],
        status: data['status'] ?? statusOptions[0], // Default to 'Pending'
        isGraduation: data['isGraduation'] ?? false,
        createdAt: data['createdAt'] != null 
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null 
            ? (data['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
        collaborators: List<String>.from(data['collaborators'] ?? []),
        downloadUrls: Map<String, String>.from(data['downloadUrls'] ?? {}),
        category: data['category'] ?? '',
        stars: data['stars'] ?? 0,
        views: data['views'] ?? 0,
        downloads: data['downloads'] ?? 0,
      );
    } catch (e) {
      print('Error parsing project data: $e');
      return Project.empty();
    }
  }

  factory Project.fromMap(Map<String, dynamic>? data, String id) {
    if (data == null) {
      return Project.empty();
    }

    return Project(
      id: id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      logoUrl: data['logoUrl'],
      screenshotsUrl: List<String>.from(data['screenshotsUrl'] ?? []),
      downloadUrl: data['downloadUrl'],
      downloadUrlForIphone: data['downloadUrlForIphone'],
      status: data['status'] ?? statusOptions[0], // Default to 'Pending'
      isGraduation: data['isGraduation'] ?? false,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      collaborators: List<String>.from(data['collaborators'] ?? []),
      downloadUrls: Map<String, String>.from(data['downloadUrls'] ?? {}),
      category: data['category'] ?? '',
      stars: data['stars'] ?? 0,
      views: data['views'] ?? 0,
      downloads: data['downloads'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'screenshotsUrl': screenshotsUrl,
      'downloadUrl': downloadUrl,
      'downloadUrlForIphone': downloadUrlForIphone,
      'status': status,
     
      'isGraduation': isGraduation,

      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'collaborators': collaborators,
      'downloadUrls': downloadUrls,
 
      'category': category,
      'stars': stars,
      'views': views,
      'downloads': downloads,
    };
  }

  Project copyWith({
    String? name,
    String? description,
    String? logoUrl,
    List<String>? screenshotsUrl,
    String? downloadUrl,
    String? downloadUrlForIphone,
    String? status,

    bool? isGraduation,
    List<String>? collaborators,
    Map<String, String>? downloadUrls,
    String? category,
    int? stars,
    int? views,
    int? downloads,
  }) {
    return Project(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      screenshotsUrl: screenshotsUrl ?? this.screenshotsUrl,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      downloadUrlForIphone: downloadUrlForIphone ?? this.downloadUrlForIphone,
      status: status ?? this.status,
     
      isGraduation: isGraduation ?? this.isGraduation,
     
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      collaborators: collaborators ?? this.collaborators,
      downloadUrls: downloadUrls ?? this.downloadUrls,
      
      category: category ?? this.category,
      stars: stars ?? this.stars,
      views: views ?? this.views,
      downloads: downloads ?? this.downloads,
    );
  }

  @override
  String toString() {
    return 'Project(id: $id, name: $name, userId: $userId, status: $status)';
  }

  Color getStatusColor() {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'In Review':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  
}
