// lib/models/user.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? profileImageUrl;
  final String? phoneNumber;
  final String? studentId;
  final String? bio;
  final List<String> skills;
  final List<String> programmingLanguages;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.profileImageUrl,
    this.phoneNumber,
    this.studentId,
    this.bio,
    required this.skills,
    required this.programmingLanguages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.empty() {
    return User(
      id: '',
      email: '',
      firstName: '',
      lastName: '',
      profileImageUrl: null,
      phoneNumber: null,
      studentId: null,
      bio: null,
      skills: [],
      programmingLanguages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      phoneNumber: data['phoneNumber'],
      studentId: data['studentId'] ?? "00000000",
      bio: data['bio'],
      skills: List<String>.from(data['skills'] ?? []),
      programmingLanguages:
          List<String>.from(data['programmingLanguages'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory User.fromMap(Map<String, dynamic>? data, String id) {
    if (data == null) {
      return User.empty();
    }

    return User(
      id: id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      phoneNumber: data['phoneNumber'],
      studentId: data['studentId'],
      bio: data['bio'],
      skills: List<String>.from(data['skills'] ?? []),
      programmingLanguages:
          List<String>.from(data['programmingLanguages'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'profileImageUrl': profileImageUrl,
      'phoneNumber': phoneNumber,
      'studentId': studentId,
      'bio': bio,
      'skills': skills,
      'programmingLanguages': programmingLanguages,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'profileImageUrl': profileImageUrl,
      'phoneNumber': phoneNumber,
      'studentId': studentId,
      'bio': bio,
      'skills': skills,
      'programmingLanguages': programmingLanguages,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  User copyWith({
    String? email,
    String? firstName,
    String? lastName,
    String? profileImageUrl,
    String? phoneNumber,
    String? studentId,
    String? bio,
    List<String>? skills,
    List<String>? programmingLanguages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      studentId: studentId ?? this.studentId,
      bio: bio ?? this.bio,
      skills: skills ?? List<String>.from(this.skills),
      programmingLanguages:
          programmingLanguages ?? List<String>.from(this.programmingLanguages),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get fullName => '$firstName $lastName';

  @override
  String toString() {
    return 'User(id: $id, email: $email, firstName: $firstName, lastName: $lastName)';
  }
}
