import 'package:cloud_firestore/cloud_firestore.dart';

enum PostType { text, image, video }

class Post {
  final String postId;
  final String groupId;
  final String authorId;
  final PostType postType;
  final String? contentUrl;
  final String? textContent;
  final DateTime timestamp;
  final List<String> likes;
  final List<String> comments;
  final List<String> shares;
  final bool isFlagged;
  final int reportCount;

  Post({
    required this.postId,
    required this.groupId,
    required this.authorId,
    required this.postType,
    this.contentUrl,
    this.textContent,
    required this.timestamp,
    this.likes = const [],
    this.comments = const [],
    this.shares = const [],
    this.isFlagged = false,
    this.reportCount = 0,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      postId: json['postId'] as String,
      groupId: json['groupId'] as String,
      authorId: json['authorId'] as String,
      postType: PostType.values.firstWhere(
        (e) => e.toString() == 'PostType.${json['postType']}',
        orElse: () => PostType.text,
      ),
      contentUrl: json['contentUrl'] as String?,
      textContent: json['textContent'] as String?,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      likes: List<String>.from(json['likes'] ?? []),
      comments: List<String>.from(json['comments'] ?? []),
      shares: List<String>.from(json['shares'] ?? []),
      isFlagged: json['isFlagged'] as bool? ?? false,
      reportCount: json['reportCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'groupId': groupId,
      'authorId': authorId,
      'postType': postType.toString().split('.').last,
      'contentUrl': contentUrl,
      'textContent': textContent,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'isFlagged': isFlagged,
      'reportCount': reportCount,
    };
  }
}
