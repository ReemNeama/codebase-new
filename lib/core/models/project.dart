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

      // Validate required fields
      if (data['userId'] == null || data['name'] == null) {
        throw DatabaseException('Missing required fields');
      }

      return Project(
        id: doc.id,
        userId: data['userId'] ?? '',
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        logoUrl: data['logoUrl'],
        screenshotsUrl: List<String>.from(data['screenshotsUrl'] ?? []),
        downloadUrl: data['downloadUrl'],
        downloadUrlForIphone: data['downloadUrlForIphone'],
        status: data['status'] ?? 'Pending',
       
        isGraduation: data['isGraduation'] ?? false,
      
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        collaborators: List<String>.from(data['collaborators'] ?? []),
        downloadUrls: Map<String, String>.from(data['downloadUrls'] ?? {}),
       
        category: data['category'] ?? '',
      );
    } catch (e) {
      throw DatabaseException('Failed to parse project data: ${e.toString()}');
    }
  }

  // Factory constructor for creating a Project from a Map
  factory Project.fromMap(Map<String, dynamic>? map, String id) {
    if (map == null) {
      return Project.empty();
    }
    
    return Project(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      logoUrl: map['logoUrl'],
      screenshotsUrl: List<String>.from(map['screenshotsUrl'] ?? []),
      downloadUrl: map['downloadUrl'],
      downloadUrlForIphone: map['downloadUrlForIphone'],
      status: map['status'] ?? 'Pending',
     
      isGraduation: map['isGraduation'] ?? false,
      
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      collaborators: List<String>.from(map['collaborators'] ?? []),
      downloadUrls: Map<String, String>.from(map['downloadUrls'] ?? {}),
     
      category: map['category'] ?? '',
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
