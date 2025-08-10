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
  final DateTime createdAt;
  final GroupType groupType;
  final bool isJoinable;
  final bool isPrivate;
  final List<String> invitedUserIds;
  final List<String> pendingJoinRequests;
  final List<String> tags;
  final String? liveStreamId;
  final String? videoCallId;
  final String postingPermissions;
  final List<String> rules;
  final String? pinnedPostId;

  Group({
    required this.groupId,
    required this.groupName,
    this.description,
    this.groupProfileImageUrl,
    required this.ownerId,
    this.adminIds = const [],
    this.memberIds = const [],
    required this.createdAt,
    this.groupType = GroupType.public,
    this.isJoinable = true,
    this.isPrivate = false,
    this.invitedUserIds = const [],
    this.pendingJoinRequests = const [],
    this.tags = const [],
    this.liveStreamId,
    this.videoCallId,
    this.postingPermissions = 'allMembers',
    this.rules = const [],
    this.pinnedPostId,
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
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      groupType: GroupType.values.firstWhere(
        (e) => e.toString() == 'GroupType.${json['groupType']}',
        orElse: () => GroupType.public,
      ),
      isJoinable: json['isJoinable'] as bool? ?? true,
      isPrivate: json['isPrivate'] as bool? ?? false,
      invitedUserIds: List<String>.from(json['invitedUserIds'] ?? []),
      pendingJoinRequests: List<String>.from(json['pendingJoinRequests'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      liveStreamId: json['liveStreamId'] as String?,
      videoCallId: json['videoCallId'] as String?,
      postingPermissions: json['postingPermissions'] as String? ?? 'allMembers',
      rules: List<String>.from(json['rules'] ?? []),
      pinnedPostId: json['pinnedPostId'] as String?,
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
      'createdAt': Timestamp.fromDate(createdAt),
      'groupType': groupType.toString().split('.').last,
      'isJoinable': isJoinable,
      'isPrivate': isPrivate,
      'invitedUserIds': invitedUserIds,
      'pendingJoinRequests': pendingJoinRequests,
      'tags': tags,
      'liveStreamId': liveStreamId,
      'videoCallId': videoCallId,
      'postingPermissions': postingPermissions,
      'rules': rules,
      'pinnedPostId': pinnedPostId,
    };
  }
}
