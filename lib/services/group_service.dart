import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:grtoco/models/group.dart';

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
}
