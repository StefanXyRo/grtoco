import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';

class AuthService {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get current user
  fb_auth.User? get currentUser => _auth.currentUser;

  // Get user data from Firestore
  Future<User?> getUser(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return User.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Sign up with email and password
  Future<fb_auth.UserCredential?> signUpWithEmailAndPassword(
      String email, String password, String displayName) async {
    try {
      fb_auth.UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create a new user document in Firestore
      await _createUserDocument(userCredential.user, displayName);

      return userCredential;
    } on fb_auth.FirebaseAuthException catch (e) {
      // Handle errors
      print(e.message);
      return null;
    }
  }

  // Create a user document in Firestore
  Future<void> _createUserDocument(fb_auth.User? user, String displayName) async {
    if (user == null) return;

    User newUser = User(
      userId: user.uid,
      email: user.email,
      displayName: displayName,
      profileImageUrl: '',
      bio: '',
      followersCount: 0,
      followingCount: 0,
      isPrivate: false,
      followers: [],
      following: [],
      joinedGroupIds: [],
      blockedUsers: [],
    );

    await _firestore.collection('users').doc(user.uid).set(newUser.toJson());
  }

  // Sign in with email and password
  Future<fb_auth.UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      // Handle errors
      print(e.message);
      return null;
    }
  }

  // Reset password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on fb_auth.FirebaseAuthException catch (e) {
      // Handle errors
      print(e.message);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    required String displayName,
    required String bio,
    XFile? image,
  }) async {
    try {
      String photoURL = '';
      if (image != null) {
        photoURL = await _uploadImageToStorage(uid, image);
      }

      Map<String, dynamic> userData = {
        'displayName': displayName,
        'bio': bio,
      };

      if (photoURL.isNotEmpty) {
        userData['profileImageUrl'] = photoURL;
      }

      await _firestore.collection('users').doc(uid).update(userData);
    } catch (e) {
      print(e.toString());
    }
  }

  // Upload image to Firebase Storage
  Future<String> _uploadImageToStorage(String uid, XFile image) async {
    try {
      Reference ref = _storage.ref().child('profile_pictures').child(uid);
      UploadTask uploadTask = ref.putFile(File(image.path));
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print(e.toString());
      return '';
    }
  }

  // Follow a user
  Future<void> followUser(String uid, String followId) async {
    try {
      // Add followId to current user's following list
      await _firestore.collection('users').doc(uid).update({
        'following': FieldValue.arrayUnion([followId]),
        'followingCount': FieldValue.increment(1),
      });

      // Add current user to the other user's followers list
      await _firestore.collection('users').doc(followId).update({
        'followers': FieldValue.arrayUnion([uid]),
        'followersCount': FieldValue.increment(1),
      });
    } catch (e) {
      print(e.toString());
    }
  }

  // Unfollow a user
  Future<void> unfollowUser(String uid, String unfollowId) async {
    try {
      // Remove unfollowId from current user's following list
      await _firestore.collection('users').doc(uid).update({
        'following': FieldValue.arrayRemove([unfollowId]),
        'followingCount': FieldValue.increment(-1),
      });

      // Remove current user from the other user's followers list
      await _firestore.collection('users').doc(unfollowId).update({
        'followers': FieldValue.arrayRemove([unfollowId]),
        'followersCount': FieldValue.increment(-1),
      });
    } catch (e) {
      print(e.toString());
    }
  }

  // Send follow request
  Future<void> sendFollowRequest(String uid, String targetId) async {
    try {
      await _firestore
          .collection('users')
          .doc(targetId)
          .collection('follow_requests')
          .doc(uid)
          .set({'from': uid});
    } catch (e) {
      print(e.toString());
    }
  }

  // Accept follow request
  Future<void> acceptFollowRequest(String uid, String requesterId) async {
    try {
      // Add users to each other's lists
      await followUser(requesterId, uid);

      // Delete the follow request
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('follow_requests')
          .doc(requesterId)
          .delete();
    } catch (e) {
      print(e.toString());
    }
  }

  // Decline follow request
  Future<void> declineFollowRequest(String uid, String requesterId) async {
    try {
      // Delete the follow request
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('follow_requests')
          .doc(requesterId)
          .delete();
    } catch (e) {
      print(e.toString());
    }
  }

  // Get follow requests
  Stream<QuerySnapshot> getFollowRequests(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('follow_requests')
        .snapshots();
  }

  // Check for pending follow request
  Future<bool> hasPendingFollowRequest(String uid, String targetId) async {
    try {
      final request = await _firestore
          .collection('users')
          .doc(targetId)
          .collection('follow_requests')
          .doc(uid)
          .get();
      return request.exists;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }
}
