import 'package:cloud_firestore/cloud_firestore.dart';

enum GroupType { public, secret }

class Group {
  final String groupId;
  final String groupName;
  final String? description;
  final String? groupProfileImageUrl;
  final String ownerId;
  final List<String> adminIds;
  final List<String> memberIds;
  final Timestamp createdAt;
  final GroupType groupType;
  final bool isJoinable;
  final bool isPrivate;
  final List<String> invitedUserIds;
  final List<String> pendingJoinRequests;
  final List<String> tags;

  Group({
    required this.groupId,
    required this.groupName,
    this.description,
    this.groupProfileImageUrl,
    required this.ownerId,
    required this.adminIds,
    required this.memberIds,
    required this.createdAt,
    required this.groupType,
    required this.isJoinable,
    required this.isPrivate,
    required this.invitedUserIds,
    required this.pendingJoinRequests,
    required this.tags,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String,
      description: json['description'] as String?,
      groupProfileImageUrl: json['groupProfileImageUrl'] as String?,
      ownerId: json['ownerId'] as String,
      adminIds: List<String>.from(json['adminIds'] ?? []),
      memberIds: List<String>.from(json['memberIds'] ?? []),
      createdAt: json['createdAt'] as Timestamp,
      groupType: GroupType.values.firstWhere((e) => e.toString() == 'GroupType.${json['groupType']}'),
      isJoinable: json['isJoinable'] as bool,
      isPrivate: json['isPrivate'] as bool,
      invitedUserIds: List<String>.from(json['invitedUserIds'] ?? []),
      pendingJoinRequests: List<String>.from(json['pendingJoinRequests'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'description': description,
      'groupProfileImageUrl': groupProfileImageUrl,
      'ownerId': ownerId,
      'adminIds': adminIds,
      'memberIds': memberIds,
      'createdAt': createdAt,
      'groupType': groupType.toString().split('.').last,
      'isJoinable': isJoinable,
      'isPrivate': isPrivate,
      'invitedUserIds': invitedUserIds,
      'pendingJoinRequests': pendingJoinRequests,
      'tags': tags,
    };
  }
}
