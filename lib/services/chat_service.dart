import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grtoco/models/conversation.dart';
import 'package:grtoco/models/message.dart';
import 'package:grtoco/models/comment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:grtoco/services/encryption_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EncryptionService _encryptionService = EncryptionService();

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
  Stream<List<Message>> getMessages(String conversationId, {bool isGroupChat = false}) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        var message = Message.fromJson(doc.data());
        // Decrypt message content if it's not a group chat and has text
        if (!isGroupChat && message.textContent != null && message.textContent!.isNotEmpty) {
          final decryptedText = _encryptionService.decryptText(message.textContent!);
          message = Message(
            messageId: message.messageId,
            conversationId: message.conversationId,
            senderId: message.senderId,
            textContent: decryptedText,
            timestamp: message.timestamp,
            isMedia: message.isMedia,
            mediaUrl: message.mediaUrl,
            mediaType: message.mediaType,
            readBy: message.readBy,
            isReplyTo: message.isReplyTo,
            mentions: message.mentions,
            isFlagged: message.isFlagged,
            reportCount: message.reportCount,
            isEdited: message.isEdited,
            reactions: message.reactions,
            isPinned: message.isPinned,
            disappearAfter: message.disappearAfter
          );
        }
        return message;
      }).toList();
    });
  }

  // Send a message
  Future<void> sendMessage(String conversationId, Message message, {bool isGroupChat = false}) async {
    Message messageToSend = message;
    // Encrypt message content if it's not a group chat and has text
    if (!isGroupChat && message.textContent != null && message.textContent!.isNotEmpty) {
      final encryptedText = _encryptionService.encryptText(message.textContent!);
      messageToSend = Message(
        messageId: message.messageId,
        conversationId: message.conversationId,
        senderId: message.senderId,
        textContent: encryptedText,
        timestamp: message.timestamp,
        isMedia: message.isMedia,
        mediaUrl: message.mediaUrl,
        mediaType: message.mediaType,
        readBy: message.readBy,
        isReplyTo: message.isReplyTo,
        mentions: message.mentions,
        isFlagged: message.isFlagged,
        reportCount: message.reportCount,
        isEdited: message.isEdited,
        reactions: message.reactions,
        isPinned: message.isPinned,
        disappearAfter: message.disappearAfter
      );
    }

    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    await messageRef.set(messageToSend.toJson()..['messageId'] = messageRef.id);

    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': messageToSend.toJson(),
      'lastActivity': messageToSend.timestamp,
    });
  }

  // Edit a message
  Future<void> editMessage(String conversationId, String messageId, String newText) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
      'textContent': _encryptionService.encryptText(newText),
      'isEdited': true,
    });
  }

  // Delete a message
  Future<void> deleteMessage(String conversationId, String messageId) async {
    // Note: The 5-minute rule should be enforced on the client-side
    // by checking the message timestamp before calling this method.
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // React to a message
  Future<void> toggleReaction(String conversationId, String messageId, String reaction, String userId) async {
    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);

    final doc = await messageRef.get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final reactions = Map<String, List<String>>.from(
        (data['reactions'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(key, List<String>.from(value)),
            ) ??
            {},
      );

      if (reactions.containsKey(reaction) && reactions[reaction]!.contains(userId)) {
        // User has already reacted with this emoji, so remove the reaction
        reactions[reaction]!.remove(userId);
        if (reactions[reaction]!.isEmpty) {
          reactions.remove(reaction);
        }
      } else {
        // User has not reacted with this emoji, so add the reaction
        reactions.putIfAbsent(reaction, () => []).add(userId);
      }

      await messageRef.update({'reactions': reactions});
    }
  }

  // Pin a message
  Future<void> pinMessage(String conversationId, String messageId) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'isPinned': true});
  }

    // Unpin a message
  Future<void> unpinMessage(String conversationId, String messageId) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'isPinned': false});
  }

  // Get pinned messages
  Stream<List<Message>> getPinnedMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('isPinned', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromJson(doc.data())).toList();
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
