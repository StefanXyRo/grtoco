import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String messageId;
  final String conversationId;
  final String senderId;
  final String? textContent;
  final Timestamp timestamp;
  final bool isMedia;
  final String? mediaUrl;
  final String? isReplyTo;
  final bool isFlagged;
  final int reportCount;

  Message({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    this.textContent,
    required this.timestamp,
    required this.isMedia,
    this.mediaUrl,
    this.isReplyTo,
    required this.isFlagged,
    required this.reportCount,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['messageId'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      textContent: json['textContent'] as String?,
      timestamp: json['timestamp'] as Timestamp,
      isMedia: json['isMedia'] as bool,
      mediaUrl: json['mediaUrl'] as String?,
      isReplyTo: json['isReplyTo'] as String?,
      isFlagged: json['isFlagged'] as bool,
      reportCount: json['reportCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'conversationId': conversationId,
      'senderId': senderId,
      'textContent': textContent,
      'timestamp': timestamp,
      'isMedia': isMedia,
      'mediaUrl': mediaUrl,
      'isReplyTo': isReplyTo,
      'isFlagged': isFlagged,
      'reportCount': reportCount,
    };
  }
}
