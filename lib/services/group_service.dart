import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:grtoco/models/group.dart';
import 'package:grtoco/models/message.dart';
import 'package:grtoco/models/post.dart';
import 'package:grtoco/models/user.dart' as model_user;

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final CollectionReference _groupsCollection =
      FirebaseFirestore.instance.collection('groups');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createGroup({
    required String groupName,
    String? description,
    required GroupType groupType,
    required List<String> tags,
    required String postingPermissions,
    required List<String> rules,
    File? profileImage,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("No user logged in");
      }

      String groupId = _groupsCollection.doc().id;
      String? groupProfileImageUrl;

      if (profileImage != null) {
        groupProfileImageUrl = await _uploadGroupProfileImage(profileImage, groupId);
      }

      Group newGroup = Group(
        groupId: groupId,
        groupName: groupName,
        description: description,
        groupProfileImageUrl: groupProfileImageUrl,
        ownerId: currentUser.uid,
        adminIds: [currentUser.uid],
        memberIds: [currentUser.uid],
        createdAt: DateTime.now(),
        groupType: groupType,
        tags: tags,
        postingPermissions: postingPermissions,
        rules: rules,
      );

      await _groupsCollection.doc(groupId).set(newGroup.toJson());
    } catch (e) {
      print("Error creating group: $e");
      throw Exception("Failed to create group");
    }
  }

  Future<String?> _uploadGroupProfileImage(File image, String groupId) async {
    try {
      String fileName = 'group_profile_images/$groupId';
      Reference ref = _storage.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading group profile image: $e");
      return null;
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

  Future<List<Group>> getUserGroups(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return [];
      }
      List<String> groupIds =
          List<String>.from(userDoc.get('joinedGroupIds') ?? []);

      if (groupIds.isEmpty) {
        return [];
      }

      List<Group> groups = [];
      for (String groupId in groupIds) {
        DocumentSnapshot groupDoc = await _groupsCollection.doc(groupId).get();
        if (groupDoc.exists) {
          groups.add(Group.fromJson(groupDoc.data() as Map<String, dynamic>));
        }
      }
      return groups;
    } catch (e) {
      print("Error getting user groups: $e");
      return [];
    }
  }

  Future<List<Group>> getGroupRecommendations() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      List<Group> userGroups = await getUserGroups(currentUser.uid);
      Set<String> userTags = userGroups.expand((group) => group.tags).toSet();
      List<String> userGroupIds = userGroups.map((g) => g.groupId).toList();

      if (userTags.isEmpty) {
        return [];
      }

      QuerySnapshot publicGroupsSnapshot =
          await _groupsCollection.where('groupType', isEqualTo: 'public').get();

      List<Group> allPublicGroups = publicGroupsSnapshot.docs
          .map((doc) => Group.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      Map<Group, int> scoredGroups = {};
      for (var group in allPublicGroups) {
        if (!userGroupIds.contains(group.groupId)) {
          int commonTags =
              group.tags.where((tag) => userTags.contains(tag)).length;
          if (commonTags > 0) {
            scoredGroups[group] = commonTags;
          }
        }
      }

      var sortedEntries = scoredGroups.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedEntries.map((entry) => entry.key).toList();
    } catch (e) {
      print("Error getting group recommendations: $e");
      return [];
    }
  }

  Future<List<Post>> getPostsForUserGroups() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      List<Group> userGroups = await getUserGroups(currentUser.uid);
      List<String> groupIds = userGroups.map((g) => g.groupId).toList();

      if (groupIds.isEmpty) {
        return [];
      }

      List<Post> allPosts = [];
      for (var i = 0; i < groupIds.length; i += 10) {
        var chunk = groupIds.sublist(
            i, i + 10 > groupIds.length ? groupIds.length : i + 10);
        QuerySnapshot postsSnapshot = await _firestore
            .collection('posts')
            .where('groupId', whereIn: chunk)
            .get();

        var posts = postsSnapshot.docs
            .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        allPosts.addAll(posts);
      }

      allPosts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return allPosts;
    } catch (e) {
      print("Error getting posts for user groups: $e");
      return [];
    }
  }

  // Group Chat Methods

  Future<String?> _uploadMedia(File file, String groupId) async {
    try {
      String fileName =
          'group_chats/$groupId/media/${DateTime.now().millisecondsSinceEpoch}';
      Reference ref = _storage.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading media: $e");
      return null;
    }
  }

  Future<void> sendMessage({
    required String groupId,
    String? textContent,
    File? mediaFile,
    String? replyToMessageId,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("No user logged in");
      }

      String? mediaUrl;
      if (mediaFile != null) {
        mediaUrl = await _uploadMedia(mediaFile, groupId);
      }

      if (textContent == null && mediaUrl == null) {
        // Don't send empty messages
        return;
      }

      List<String> mentions = [];
      if (textContent != null) {
        // Simple mention parsing: @username
        // A more robust solution would involve checking if the username exists
        RegExp exp = RegExp(r"\B@\w+");
        Iterable<RegExpMatch> matches = exp.allMatches(textContent);
        for (final m in matches) {
          // In a real app, you'd resolve this username to a userId
          // For now, we'll just store the username
          mentions.add(m[0]!);
        }
      }

      CollectionReference messagesCollection =
          _groupsCollection.doc(groupId).collection('messages');
      String messageId = messagesCollection.doc().id;

      Message newMessage = Message(
        messageId: messageId,
        conversationId: groupId,
        senderId: currentUser.uid,
        textContent: textContent,
        timestamp: DateTime.now(),
        isMedia: mediaFile != null,
        mediaUrl: mediaUrl,
        isReplyTo: replyToMessageId,
        mentions: mentions,
      );

      await messagesCollection.doc(messageId).set(newMessage.toJson());

      // Placeholder for sending notifications for mentions
      if (mentions.isNotEmpty) {
        // TODO: Implement notification sending logic
        print("Sending notifications to: ${mentions.join(', ')}");
      }
    } catch (e) {
      print("Error sending message: $e");
      throw Exception("Failed to send message");
    }
  }

  Stream<List<Message>> getMessages(String groupId) {
    return _groupsCollection
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Message.fromJson(doc.data());
      }).toList();
    });
  }

  Future<void> deleteMessage(String groupId, String messageId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("No user logged in");
      }

      Group? group = await getGroup(groupId);
      if (group == null) {
        throw Exception("Group not found");
      }

      bool isOwner = group.ownerId == currentUser.uid;
      bool isAdmin = group.adminIds.contains(currentUser.uid);

      if (!isOwner && !isAdmin) {
        throw Exception("User is not authorized to delete messages");
      }

      await _groupsCollection
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      print("Error deleting message: $e");
      throw Exception("Failed to delete message");
    }
  }

  // Interactive Post Methods

  Future<void> createInteractivePost({
    required String groupId,
    required String postType,
    String? question,
    List<String>? options,
    String? eventName,
    String? eventDescription,
    String? eventLocation,
    DateTime? eventDate,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("No user logged in");
      }

      CollectionReference postsCollection =
          _firestore.collection('interactive_posts');
      String postId = postsCollection.doc().id;

      Map<String, dynamic> postData = {
        'postId': postId,
        'groupId': groupId,
        'authorId': currentUser.uid,
        'postType': postType,
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (postType == 'poll') {
        postData.addAll({
          'question': question,
          'options': options,
          'votes': {for (var option in options!) option: []},
          'isClosed': false,
        });
      } else if (postType == 'event') {
        postData.addAll({
          'eventName': eventName,
          'eventDescription': eventDescription,
          'eventLocation': eventLocation,
          'eventDate': eventDate,
          'rsvpStatus': {'going': [], 'interested': [], 'notGoing': []},
        });
      } else if (postType == 'qa') {
        postData.addAll({
          'question': question,
          'answers': [],
        });
      }

      await postsCollection.doc(postId).set(postData);

      // Also create a regular post to mark its existence in the main feed
      await _firestore.collection('posts').doc(postId).set({
        'postId': postId,
        'groupId': groupId,
        'authorId': currentUser.uid,
        'postType': 'interactive',
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'shares': [],
        'isFlagged': false,
        'reportCount': 0,
      });
    } catch (e) {
      print("Error creating interactive post: $e");
      throw Exception("Failed to create interactive post");
    }
  }

  Future<void> voteOnPoll(String postId, String option) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("No user logged in");
      }

      DocumentReference postRef =
          _firestore.collection('interactive_posts').doc(postId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(postRef);
        if (!snapshot.exists) {
          throw Exception("Post does not exist!");
        }

        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        Map<String, List<dynamic>> votes =
            Map<String, List<dynamic>>.from(data['votes']);

        // Remove user's previous vote if any
        votes.forEach((key, value) {
          value.remove(currentUser.uid);
        });

        // Add new vote
        votes[option]!.add(currentUser.uid);

        transaction.update(postRef, {'votes': votes});
      });
    } catch (e) {
      print("Error voting on poll: $e");
      throw Exception("Failed to vote on poll");
    }
  }

  Future<void> updateRsvpStatus(String postId, String status) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("No user logged in");
      }

      DocumentReference postRef =
          _firestore.collection('interactive_posts').doc(postId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(postRef);
        if (!snapshot.exists) {
          throw Exception("Post does not exist!");
        }

        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        Map<String, List<dynamic>> rsvpStatus =
            Map<String, List<dynamic>>.from(data['rsvpStatus']);

        // Remove user's ID from all lists
        rsvpStatus.forEach((key, value) {
          value.remove(currentUser.uid);
        });

        // Add user's ID to the new status list
        if (rsvpStatus.containsKey(status)) {
          rsvpStatus[status]!.add(currentUser.uid);
        }

        transaction.update(postRef, {'rsvpStatus': rsvpStatus});
      });
    } catch (e) {
      print("Error updating RSVP status: $e");
      throw Exception("Failed to update RSVP status");
    }
  }

  Future<void> answerQuestion(String postId, String answerContent) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("No user logged in");
      }

      Map<String, dynamic> newAnswer = {
        'authorId': currentUser.uid,
        'answerContent': answerContent,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('interactive_posts').doc(postId).update({
        'answers': FieldValue.arrayUnion([newAnswer]),
      });
    } catch (e) {
      print("Error answering question: $e");
      throw Exception("Failed to answer question");
    }
  }

  Future<DocumentSnapshot?> getInteractivePost(String postId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('interactive_posts').doc(postId).get();
      if (doc.exists) {
        return doc;
      }
      return null;
    } catch (e) {
      print("Error getting interactive post: $e");
      return null;
    }
  }

  Future<bool> isUserAdmin(String groupId, String userId) async {
    try {
      Group? group = await getGroup(groupId);
      if (group != null) {
        return group.adminIds.contains(userId) || group.ownerId == userId;
      }
      return false;
    } catch (e) {
      print("Error checking admin status: $e");
      return false;
    }
  }

  Future<void> pinPost(String groupId, String postId) async {
    try {
      WriteBatch batch = _firestore.batch();

      DocumentReference groupRef = _groupsCollection.doc(groupId);
      DocumentReference postRef = _firestore.collection('posts').doc(postId);

      // First, unpin any currently pinned post
      Group? group = await getGroup(groupId);
      if (group?.pinnedPostId != null) {
        DocumentReference oldPinnedPostRef = _firestore.collection('posts').doc(group!.pinnedPostId!);
        batch.update(oldPinnedPostRef, {'isPinned': false});
      }

      // Then, pin the new post
      batch.update(postRef, {'isPinned': true});
      batch.update(groupRef, {'pinnedPostId': postId});

      await batch.commit();
    } catch (e) {
      print("Error pinning post: $e");
      throw Exception("Failed to pin post");
    }
  }

  Future<void> unpinPost(String groupId, String postId) async {
    try {
      WriteBatch batch = _firestore.batch();

      DocumentReference groupRef = _groupsCollection.doc(groupId);
      DocumentReference postRef = _firestore.collection('posts').doc(postId);

      batch.update(postRef, {'isPinned': false});
      batch.update(groupRef, {'pinnedPostId': FieldValue.delete()});

      await batch.commit();
    } catch (e) {
      print("Error unpinning post: $e");
      throw Exception("Failed to unpin post");
    }
  }

  Future<void> createPost({
    required String groupId,
    required String textContent,
    // TODO: Add support for image/video uploads
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("No user logged in");
      }

      CollectionReference postsCollection = _firestore.collection('posts');
      String postId = postsCollection.doc().id;

      Post newPost = Post(
        postId: postId,
        groupId: groupId,
        authorId: currentUser.uid,
        postType: PostType.text, // Default to text post
        textContent: textContent,
        timestamp: DateTime.now(),
      );

      await postsCollection.doc(postId).set(newPost.toJson());
    } catch (e) {
      print("Error creating post: $e");
      throw Exception("Failed to create post");
    }
  }
}
