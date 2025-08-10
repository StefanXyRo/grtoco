import 'package.cloud_firestore/cloud_firestore.dart';

enum PostType { text, image, video }

class Post {
  final String postId;
  final String groupId;
  final String authorId;
  final PostType postType;
  final String? contentUrl;
  final String? textContent;
  final Timestamp timestamp;
  final List<String> likes;
  final List<String> comments;
  final int shares;
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
    required this.likes,
    required this.comments,
    required this.shares,
    required this.isFlagged,
    required this.reportCount,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      postId: json['postId'] as String,
      groupId: json['groupId'] as String,
      authorId: json['authorId'] as String,
      postType: PostType.values.firstWhere((e) => e.toString() == 'PostType.${json['postType']}'),
      contentUrl: json['contentUrl'] as String?,
      textContent: json['textContent'] as String?,
      timestamp: json['timestamp'] as Timestamp,
      likes: List<String>.from(json['likes'] ?? []),
      comments: List<String>.from(json['comments'] ?? []),
      shares: json['shares'] as int,
      isFlagged: json['isFlagged'] as bool,
      reportCount: json['reportCount'] as int,
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
      'timestamp': timestamp,
      'likes': likes,
      'comments': comments,
      'shares': shares,
      'isFlagged': isFlagged,
      'reportCount': reportCount,
    };
  }
}
