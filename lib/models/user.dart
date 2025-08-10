class User {
  final String userId;
  final String? email;
  final String? displayName;
  final String? profileImageUrl;
  final String? bio;
  final List<String> joinedGroupIds;
  final int followersCount;
  final int followingCount;
  final bool isPrivate;
  final List<String> blockedUsers;
  final List<String> followers;
  final List<String> following;

  User({
    required this.userId,
    this.email,
    this.displayName,
    this.profileImageUrl,
    this.bio,
    this.joinedGroupIds = const [],
    this.followersCount = 0,
    this.followingCount = 0,
    this.isPrivate = false,
    this.blockedUsers = const [],
    this.followers = const [],
    this.following = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      bio: json['bio'] as String?,
      joinedGroupIds: List<String>.from(json['joinedGroupIds'] ?? []),
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      isPrivate: json['isPrivate'] as bool? ?? false,
      blockedUsers: List<String>.from(json['blockedUsers'] ?? []),
      followers: List<String>.from(json['followers'] ?? []),
      following: List<String>.from(json['following'] ?? []),
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
      'followers': followers,
      'following': following,
    };
  }
}
