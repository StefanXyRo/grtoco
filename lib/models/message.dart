import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String messageId;
  final String conversationId;
  final String senderId;
  final String? textContent;
  final DateTime timestamp;
  final bool isMedia;
  final String? mediaUrl;
  final String? mediaType; // e.g., 'image', 'video', 'voice'
  final Map<String, dynamic> readBy;
  final String? isReplyTo; // messageId of the message being replied to
  final List<String> mentions;
  final bool isFlagged;
  final int reportCount;
  final bool isEdited;
  final Map<String, List<String>> reactions;
  final bool isPinned;
  final int? disappearAfter; // in hours

  Message({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    this.textContent,
    required this.timestamp,
    this.isMedia = false,
    this.mediaUrl,
    this.mediaType,
    this.readBy = const {},
    this.isReplyTo,
    this.mentions = const [],
    this.isFlagged = false,
    this.reportCount = 0,
    this.isEdited = false,
    this.reactions = const {},
    this.isPinned = false,
    this.disappearAfter,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['messageId'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      textContent: json['textContent'] as String?,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      isMedia: json['isMedia'] as bool? ?? false,
      mediaUrl: json['mediaUrl'] as String?,
      mediaType: json['mediaType'] as String?,
      readBy: Map<String, dynamic>.from(json['readBy'] ?? {}),
      isReplyTo: json['isReplyTo'] as String?,
      mentions: List<String>.from(json['mentions'] ?? []),
      isFlagged: json['isFlagged'] as bool? ?? false,
      reportCount: json['reportCount'] as int? ?? 0,
      isEdited: json['isEdited'] as bool? ?? false,
      reactions: (json['reactions'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          ) ??
          {},
      isPinned: json['isPinned'] as bool? ?? false,
      disappearAfter: json['disappearAfter'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'conversationId': conversationId,
      'senderId': senderId,
      'textContent': textContent,
      'timestamp': Timestamp.fromDate(timestamp),
      'isMedia': isMedia,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'readBy': readBy,
      'isReplyTo': isReplyTo,
      'mentions': mentions,
      'isFlagged': isFlagged,
      'reportCount': reportCount,
      'isEdited': isEdited,
      'reactions': reactions,
      'isPinned': isPinned,
      'disappearAfter': disappearAfter,
    };
  }
}
