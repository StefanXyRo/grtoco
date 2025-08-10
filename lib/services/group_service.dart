import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:grtoco/models/group.dart';
import 'package:grtoco/models/post.dart';
import 'package:grtoco/models/user.dart' as model_user;

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _groupsCollection =
      FirebaseFirestore.instance.collection('groups');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createGroup({
    required String groupName,
    String? description,
    required GroupType groupType,
    required List<String> tags,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("No user logged in");
      }

      String groupId = _groupsCollection.doc().id;
      Group newGroup = Group(
        groupId: groupId,
        groupName: groupName,
        description: description,
        ownerId: currentUser.uid,
        adminIds: [currentUser.uid],
        memberIds: [currentUser.uid],
        createdAt: DateTime.now(),
        groupType: groupType,
        tags: tags,
      );

      await _groupsCollection.doc(groupId).set(newGroup.toJson());
    } catch (e) {
      // It's a good practice to handle errors, e.g., by logging them
      // or re-throwing a more specific exception.
      print("Error creating group: $e");
      throw Exception("Failed to create group");
    }
  }

  Future<Group?> getGroup(String groupId) async {
    try {
      DocumentSnapshot doc = await _groupsCollection.doc(groupId).get();
      if (doc.exists) {
        return Group.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("Error getting group: $e");
      return null;
    }
  }

  Future<List<model_user.User>> getGroupMembers(String groupId) async {
    try {
      DocumentSnapshot groupDoc = await _groupsCollection.doc(groupId).get();
      if (groupDoc.exists) {
        Group group = Group.fromJson(groupDoc.data() as Map<String, dynamic>);
        List<String> memberIds = group.memberIds;
        List<model_user.User> members = [];
        for (String memberId in memberIds) {
          DocumentSnapshot userDoc =
              await _firestore.collection('users').doc(memberId).get();
          if (userDoc.exists) {
            members.add(
                model_user.User.fromJson(userDoc.data() as Map<String, dynamic>));
          }
        }
        return members;
      }
      return [];
    } catch (e) {
      print("Error getting group members: $e");
      return [];
    }
  }

  Future<void> promoteToAdmin(String groupId, String userId) async {
    try {
      await _groupsCollection.doc(groupId).update({
        'adminIds': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      print("Error promoting user to admin: $e");
      throw Exception("Failed to promote user to admin");
    }
  }

  Future<void> demoteToMember(String groupId, String userId) async {
    try {
      await _groupsCollection.doc(groupId).update({
        'adminIds': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      print("Error demoting admin to member: $e");
      throw Exception("Failed to demote admin to member");
    }
  }

  Future<void> removeMember(String groupId, String userId) async {
    try {
      await _groupsCollection.doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
        'adminIds': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      print("Error removing member: $e");
      throw Exception("Failed to remove member");
    }
  }

  Future<List<Group>> getGroups() async {
    try {
      QuerySnapshot snapshot = await _groupsCollection.get();
      return snapshot.docs
          .map((doc) => Group.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error getting groups: $e");
      return [];
    }
  }

  Future<void> requestToJoinGroup(String groupId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("No user logged in");
      }
      await _groupsCollection.doc(groupId).update({
        'pendingJoinRequests': FieldValue.arrayUnion([currentUser.uid]),
      });
    } catch (e) {
      print("Error requesting to join group: $e");
      throw Exception("Failed to request to join group");
    }
  }

  Future<List<model_user.User>> getPendingRequests(String groupId) async {
    try {
      DocumentSnapshot groupDoc = await _groupsCollection.doc(groupId).get();
      if (groupDoc.exists) {
        Group group = Group.fromJson(groupDoc.data() as Map<String, dynamic>);
        List<String> pendingIds = group.pendingJoinRequests;
        List<model_user.User> users = [];
        for (String userId in pendingIds) {
          DocumentSnapshot userDoc =
              await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            users.add(
                model_user.User.fromJson(userDoc.data() as Map<String, dynamic>));
          }
        }
        return users;
      }
      return [];
    } catch (e) {
      print("Error getting pending requests: $e");
      return [];
    }
  }

  Future<void> acceptJoinRequest(String groupId, String userId) async {
    try {
      await _groupsCollection.doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'pendingJoinRequests': FieldValue.arrayRemove([userId]),
      });
      await _firestore.collection('users').doc(userId).update({
        'joinedGroupIds': FieldValue.arrayUnion([groupId]),
      });
    } catch (e) {
      print("Error accepting join request: $e");
      throw Exception("Failed to accept join request");
    }
  }

  Future<void> declineJoinRequest(String groupId, String userId) async {
    try {
      await _groupsCollection.doc(groupId).update({
        'pendingJoinRequests': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      print("Error declining join request: $e");
      throw Exception("Failed to decline join request");
    }
  }

  Future<List<Post>> getPostsForGroup(String groupId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .where('groupId', isEqualTo: groupId)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error getting posts for group: $e");
      return [];
    }
  }
}
