import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String userId;
  final String userFirstName;
  final String userLastName;
  final String projectId;
  final String content;
  final int stars;
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    required this.id,
    required this.userId,
    required this.userFirstName,
    required this.userLastName,
    required this.projectId,
    required this.content,
    required this.stars,
    required this.createdAt,
    required this.updatedAt,
  });

  double get rating => stars.toDouble();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userFirstName': userFirstName,
      'userLastName': userLastName,
      'projectId': projectId,
      'content': content,
      'stars': stars,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Comment.fromMap(Map<String, dynamic>? data, String id) {
    if (data == null) {
      return Comment.empty(id);
    }
    
    return Comment(
      id: id,
      userId: data['userId'] ?? '',
      userFirstName: data['userFirstName'] ?? '',
      userLastName: data['userLastName'] ?? '',
      projectId: data['projectId'] ?? '',
      content: data['content'] ?? '',
      stars: data['stars'] ?? 0,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory Comment.empty(String id) {
    return Comment(
      id: id,
      userId: '',
      userFirstName: '',
      userLastName: '',
      projectId: '',
      content: '',
      stars: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = Map<String, dynamic>.from(doc.data() as Map<dynamic, dynamic>);
    return Comment.fromMap(data, doc.id);
  }

  Comment copyWith({
    String? userId,
    String? userFirstName,
    String? userLastName,
    String? projectId,
    String? content,
    int? stars,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Comment(
      id: id,
      userId: userId ?? this.userId,
      userFirstName: userFirstName ?? this.userFirstName,
      userLastName: userLastName ?? this.userLastName,
      projectId: projectId ?? this.projectId,
      content: content ?? this.content,
      stars: stars ?? this.stars,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Comment(id: $id, userId: $userId, content: $content, stars: $stars)';
  }
}
