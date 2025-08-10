import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final String? bio;
  final int? followersCount;
  final int? followingCount;
  final bool? isPrivate;
  final List<String>? followers;
  final List<String>? following;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.bio,
    this.followersCount,
    this.followingCount,
    this.isPrivate,
    this.followers,
    this.following,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'],
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      bio: data['bio'],
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      isPrivate: data['isPrivate'] ?? false,
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'bio': bio,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'isPrivate': isPrivate,
      'followers': followers,
      'following': following,
    };
  }
}
