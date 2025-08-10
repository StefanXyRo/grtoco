import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String commentId;
  final String postId;
  final String authorId;
  final String textContent;
  final Timestamp timestamp;
  final List<String> likes;

  Comment({
    required this.commentId,
    required this.postId,
    required this.authorId,
    required this.textContent,
    required this.timestamp,
    required this.likes,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['commentId'] as String,
      postId: json['postId'] as String,
      authorId: json['authorId'] as String,
      textContent: json['textContent'] as String,
      timestamp: json['timestamp'] as Timestamp,
      likes: List<String>.from(json['likes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'postId': postId,
      'authorId': authorId,
      'textContent': textContent,
      'timestamp': timestamp,
      'likes': likes,
    };
  }
}
