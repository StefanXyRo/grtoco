import 'package:cloud_firestore/cloud_firestore.dart';

enum MediaType {
  image,
  video,
}

class Story {
  final String storyId;
  final String groupId;
  final String authorId;
  final String mediaUrl;
  final MediaType mediaType;
  final Timestamp timestamp;
  final Timestamp expiresAt;
  final List<String> viewers;

  Story({
    required this.storyId,
    required this.groupId,
    required this.authorId,
    required this.mediaUrl,
    required this.mediaType,
    required this.timestamp,
    required this.expiresAt,
    required this.viewers,
  });

  factory Story.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Story(
      storyId: doc.id,
      groupId: data['groupId'] ?? '',
      authorId: data['authorId'] ?? '',
      mediaUrl: data['mediaUrl'] ?? '',
      mediaType: (data['mediaType'] == 'video') ? MediaType.video : MediaType.image,
      timestamp: data['timestamp'] ?? Timestamp.now(),
      expiresAt: data['expiresAt'] ?? Timestamp.now(),
      viewers: List<String>.from(data['viewers'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'authorId': authorId,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType == MediaType.video ? 'video' : 'image',
      'timestamp': timestamp,
      'expiresAt': expiresAt,
      'viewers': viewers,
    };
  }
}
