import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String userId;
  final String email;
  final String displayName;
  final String? profileImageUrl;
  final String? bio;
  final List<String> joinedGroupIds;
  final int followersCount;
  final int followingCount;
  final bool isPrivate;
  final List<String> blockedUsers;

  User({
    required this.userId,
    required this.email,
    required this.displayName,
    this.profileImageUrl,
    this.bio,
    required this.joinedGroupIds,
    required this.followersCount,
    required this.followingCount,
    required this.isPrivate,
    required this.blockedUsers,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      bio: json['bio'] as String?,
      joinedGroupIds: List<String>.from(json['joinedGroupIds'] ?? []),
      followersCount: json['followersCount'] as int,
      followingCount: json['followingCount'] as int,
      isPrivate: json['isPrivate'] as bool,
      blockedUsers: List<String>.from(json['blockedUsers'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'joinedGroupIds': joinedGroupIds,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'isPrivate': isPrivate,
      'blockedUsers': blockedUsers,
    };
  }
}
