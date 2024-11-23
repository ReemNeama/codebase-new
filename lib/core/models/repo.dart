// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'storage_file.dart';
import 'exceptions.dart';

class Repo {
  final String id;
  final String storageUrl;
  final String userId;
  final String name;
  final String description;
  final List<String> collabs;
  final List<StorageFile> files;
  final String status;
  final List<String> languages;
  final List<String> categories;
  final String? url;
  final DateTime createdAt;
  final DateTime updatedAt;

  Repo({
    required this.id,
    required this.storageUrl,
    required this.userId,
    required this.name,
    required this.categories,
    required this.languages,
    required this.status,
    required this.description,
    required this.collabs,
    this.files = const [],
    this.url,
    required this.createdAt,
    required this.updatedAt,
  });

  void validate() {
    if (name.trim().isEmpty) {
      throw DatabaseException('Repository name cannot be empty');
    }
    if (description.trim().isEmpty) {
      throw DatabaseException('Repository description cannot be empty');
    }
    if (userId.isEmpty) {
      throw DatabaseException('User ID is required');
    }
  }

  factory Repo.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Parse files if they exist
      List<StorageFile> files = [];
      if (data['files'] != null) {
        files = (data['files'] as List)
            .map((file) => StorageFile.fromMap(file as Map<String, dynamic>))
            .toList();
      }

      // Handle timestamps with default values if missing
      DateTime createdAt = DateTime.now();
      DateTime updatedAt = DateTime.now();
      
      try {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } catch (e) {
        print('Error parsing createdAt: $e');
      }
      
      try {
        updatedAt = (data['updatedAt'] as Timestamp).toDate();
      } catch (e) {
        print('Error parsing updatedAt: $e');
      }

      return Repo(
        id: doc.id,
        storageUrl: data['storageUrl'] ?? '',
        userId: data['userId'] ?? '',
        name: data['name'] ?? 'Untitled Repository',
        description: data['description'] ?? 'No description provided',
        collabs: List<String>.from(data['collabs'] ?? []),
        status: data['status'] ?? 'private',
        languages: List<String>.from(data['languages'] ?? []),
        categories: List<String>.from(data['categories'] ?? []),
        files: files,
        url: data['url'],
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      print('Detailed parsing error: $e');
      throw DatabaseException('Failed to parse repository data: ${e.toString()}');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'storageUrl': storageUrl,
      'userId': userId,
      'name': name,
      'description': description,
      'collabs': collabs,
      'status': status,
      'languages': languages,
      'categories': categories,
      'files': files.map((file) => file.toMap()).toList(),
      'url': url,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Repo copyWith({
    String? name,
    String? description,
    List<String>? collabs,
    List<StorageFile>? files,
    String? url,
    DateTime? updatedAt,
  }) {
    return Repo(
      id: id,
      storageUrl: storageUrl,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      collabs: collabs ?? this.collabs,
      status: status,
      languages: languages,
      categories: categories,
      files: files ?? this.files,
      url: url ?? this.url,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Repo(id: $id, name: $name, userId: $userId)';
  }
}
