import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String messageId;
  final String conversationId;
  final String senderId;
  final String? textContent;
  final DateTime timestamp;
  final bool isMedia;
  final String? mediaUrl;
  final String? isReplyTo; // messageId of the message being replied to
  final List<String> mentions;
  final bool isFlagged;
  final int reportCount;

  Message({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    this.textContent,
    required this.timestamp,
    this.isMedia = false,
    this.mediaUrl,
    this.isReplyTo,
    this.mentions = const [],
    this.isFlagged = false,
    this.reportCount = 0,
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
      isReplyTo: json['isReplyTo'] as String?,
      mentions: List<String>.from(json['mentions'] ?? []),
      isFlagged: json['isFlagged'] as bool? ?? false,
      reportCount: json['reportCount'] as int? ?? 0,
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
      'isReplyTo': isReplyTo,
      'mentions': mentions,
      'isFlagged': isFlagged,
      'reportCount': reportCount,
    };
  }
}
