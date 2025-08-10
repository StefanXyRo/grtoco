import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grtoco/models/conversation.dart';
import 'package:grtoco/models/message.dart';
import 'package:grtoco/models/comment.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get stream of conversations for a user
  Stream<List<Conversation>> getConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Conversation.fromJson(doc.data()))
          .toList();
    });
  }

  // Get stream of messages for a conversation
  Stream<List<Message>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromJson(doc.data())).toList();
    });
  }

  // Send a message
  Future<void> sendMessage(String conversationId, Message message) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add(message.toJson());

    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': message.toJson(),
      'lastActivity': message.timestamp,
    });
  }

  // Create or get a conversation between two users
  Future<String> createOrGetConversation(String userId1, String userId2) async {
    List<String> members = [userId1, userId2];
    members.sort(); // Sort the list to ensure the query is consistent
    QuerySnapshot snapshot = await _firestore
        .collection('conversations')
        .where('members', isEqualTo: members)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    } else {
      DocumentReference newConversation =
          await _firestore.collection('conversations').add({
        'members': members,
        'lastActivity': FieldValue.serverTimestamp(),
      });
      return newConversation.id;
    }
  }

    // Update typing status
  Future<void> updateTypingStatus(
      String conversationId, String userId, bool isTyping) async {
    if (isTyping) {
      await _firestore.collection('conversations').doc(conversationId).update({
        'typing': FieldValue.arrayUnion([userId])
      });
    } else {
      await _firestore.collection('conversations').doc(conversationId).update({
        'typing': FieldValue.arrayRemove([userId])
      });
    }
  }
    // Mark message as read
  Future<void> markMessageAsRead(
      String conversationId, String messageId, String userId) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
      'readBy.$userId': Timestamp.now(),
    });
  }

  // Group Chat Methods

  CollectionReference getGroupCommentsCollection(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('comments');
  }

  Future<void> sendGroupComment({
    required String groupId,
    required String textContent,
  }) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("No user logged in");
      }

      String commentId = getGroupCommentsCollection(groupId).doc().id;
      Comment newComment = Comment(
        commentId: commentId,
        postId: groupId, // Using groupId as postId for simplicity
        authorId: currentUser.uid,
        textContent: textContent,
        timestamp: DateTime.now(),
      );

      await getGroupCommentsCollection(groupId)
          .doc(commentId)
          .set(newComment.toJson());
    } catch (e) {
      print("Error sending comment: $e");
      throw Exception("Failed to send comment");
    }
  }

  Stream<List<Comment>> getGroupComments(String groupId) {
    return getGroupCommentsCollection(groupId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Comment.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> hideGroupComment(String groupId, String commentId) async {
    try {
      await getGroupCommentsCollection(groupId).doc(commentId).update({
        'hidden': true,
      });
    } catch (e) {
      print("Error hiding comment: $e");
      throw Exception("Failed to hide comment");
    }
  }
}
