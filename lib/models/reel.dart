import 'package:cloud_firestore/cloud_firestore.dart';

class Reel {
  final String reelId;
  final String groupId;
  final String authorId;
  final String videoUrl;
  final String? caption;
  final DateTime timestamp;
  final List<String> likes;
  final List<String> shares;
  // For simplicity, we'll store comment count. A full implementation would have a Comment model.
  final int commentCount;

  Reel({
    required this.reelId,
    required this.groupId,
    required this.authorId,
    required this.videoUrl,
    this.caption,
    required this.timestamp,
    this.likes = const [],
    this.shares = const [],
    this.commentCount = 0,
  });

  factory Reel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Reel(
      reelId: doc.id,
      groupId: data['groupId'] ?? '',
      authorId: data['authorId'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      caption: data['caption'] as String?,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      likes: List<String>.from(data['likes'] ?? []),
      shares: List<String>.from(data['shares'] ?? []),
      commentCount: data['commentCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'authorId': authorId,
      'videoUrl': videoUrl,
      'caption': caption,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'shares': shares,
      'commentCount': commentCount,
    };
  }
}
