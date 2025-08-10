import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String commentId;
  final String postId;
  final String authorId;
  final String textContent;
  final DateTime timestamp;
  final List<String> likes;
  final bool isFlagged;
  final int reportCount;

  Comment({
    required this.commentId,
    required this.postId,
    required this.authorId,
    required this.textContent,
    required this.timestamp,
    this.likes = const [],
    this.isFlagged = false,
    this.reportCount = 0,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['commentId'] as String,
      postId: json['postId'] as String,
      authorId: json['authorId'] as String,
      textContent: json['textContent'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      likes: List<String>.from(json['likes'] ?? []),
      isFlagged: json['isFlagged'] as bool? ?? false,
      reportCount: json['reportCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'postId': postId,
      'authorId': authorId,
      'textContent': textContent,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'isFlagged': isFlagged,
      'reportCount': reportCount,
    };
  }
}
