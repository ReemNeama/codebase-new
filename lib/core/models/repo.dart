// ignore_for_file: avoid_print

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'storage_file.dart';

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

  factory Repo.empty() {
    return Repo(
      id: '',
      storageUrl: '',
      userId: '',
      name: '',
      description: '',
      collabs: [],
      files: [],
      status: 'Public', // Default to Public
      languages: [],
      categories: [],
      url: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory Repo.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Parse files if they exist
      List<StorageFile> files = [];
      if (data['files'] != null) {
        try {
          files = (data['files'] as List)
              .map((file) => StorageFile.fromMap(file as Map<String, dynamic>))
              .toList();
        } catch (e) {
          log('Error parsing files: $e');
        }
      }

      return Repo(
        id: doc.id,
        storageUrl: data['storageUrl'] ?? '',
        userId: data['userId'] ?? '',
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        collabs: List<String>.from(data['collabs'] ?? []),
        files: files,
        status: data['status'] ?? 'Public',
        languages: List<String>.from(data['languages'] ?? []),
        categories: List<String>.from(data['categories'] ?? []),
        url: data['url'],
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      log('Error parsing repository data: $e');
      return Repo.empty();
    }
  }

  factory Repo.fromMap(Map<String, dynamic>? data, String id) {
    if (data == null) {
      return Repo.empty();
    }

    List<StorageFile> files = [];
    if (data['files'] != null) {
      try {
        files = (data['files'] as List)
            .map((file) => StorageFile.fromMap(file as Map<String, dynamic>))
            .toList();
      } catch (e) {
        log('Error parsing files: $e');
      }
    }

    return Repo(
      id: id,
      storageUrl: data['storageUrl'] ?? '',
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      collabs: List<String>.from(data['collabs'] ?? []),
      files: files,
      status: data['status'] ?? 'Public',
      languages: List<String>.from(data['languages'] ?? []),
      categories: List<String>.from(data['categories'] ?? []),
      url: data['url'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
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
