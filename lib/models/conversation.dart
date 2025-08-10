import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grtoco/models/message.dart';

class Conversation {
  final String conversationId;
  final List<String> members;
  final Message? lastMessage;
  final Timestamp lastActivity;
  final List<String> typing;

  Conversation({
    required this.conversationId,
    required this.members,
    this.lastMessage,
    required this.lastActivity,
    this.typing = const [],
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      conversationId: json['conversationId'] as String,
      members: List<String>.from(json['members'] ?? []),
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      lastActivity: json['lastActivity'] as Timestamp,
      typing: List<String>.from(json['typing'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'members': members,
      'lastMessage': lastMessage?.toJson(),
      'lastActivity': lastActivity,
      'typing': typing,
    };
  }
}
