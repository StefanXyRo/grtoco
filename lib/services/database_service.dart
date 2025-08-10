import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:grtoco/models/comment.dart';
import 'package:grtoco/models/group.dart';
import 'package:grtoco/models/post.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _postsCollection =
      FirebaseFirestore.instance.collection('posts');
  final CollectionReference _groupsCollection =
      FirebaseFirestore.instance.collection('groups');

  Future<void> createPost({
    required String groupId,
    required PostType postType,
    String? textContent,
    String? contentUrl,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("No user logged in");
      }

      // Check if user is a member of the group
      DocumentSnapshot groupDoc = await _groupsCollection.doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception("Group not found");
      }
      Group group = Group.fromJson(groupDoc.data() as Map<String, dynamic>);
      if (!group.memberIds.contains(currentUser.uid)) {
        throw Exception("User is not a member of this group");
      }

      String postId = _postsCollection.doc().id;
      Post newPost = Post(
        postId: postId,
        groupId: groupId,
        authorId: currentUser.uid,
        postType: postType,
        textContent: textContent,
        contentUrl: contentUrl,
        timestamp: DateTime.now(),
      );

      await _postsCollection.doc(postId).set(newPost.toJson());
    } catch (e) {
      print("Error creating post: $e");
      throw Exception("Failed to create post");
    }
  }

  Future<void> likePost(String postId, String userId) async {
    try {
      DocumentReference postRef = _postsCollection.doc(postId);
      DocumentSnapshot postDoc = await postRef.get();
      if (postDoc.exists) {
        List<String> likes = List<String>.from(postDoc.get('likes') ?? []);
        if (likes.contains(userId)) {
          // Unlike
          await postRef.update({
            'likes': FieldValue.arrayRemove([userId])
          });
        } else {
          // Like
          await postRef.update({
            'likes': FieldValue.arrayUnion([userId])
          });
        }
      }
    } catch (e) {
      print("Error liking post: $e");
      throw Exception("Failed to like post");
    }
  }

  Future<void> sharePost(String postId, String userId) async {
    // For simplicity, we'll just increment a share count.
    // A more complex implementation could create a new post that references the original.
    try {
      DocumentReference postRef = _postsCollection.doc(postId);
      DocumentSnapshot postDoc = await postRef.get();
      if (postDoc.exists) {
        await postRef.update({
          'shares': FieldValue.arrayUnion([userId])
        });
      }
    } catch (e) {
      print("Error sharing post: $e");
      throw Exception("Failed to share post");
    }
  }

  Future<void> addComment({
    required String postId,
    required String textContent,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("No user logged in");
      }

      String commentId =
          _postsCollection.doc(postId).collection('comments').doc().id;
      Comment newComment = Comment(
        commentId: commentId,
        postId: postId,
        authorId: currentUser.uid,
        textContent: textContent,
        timestamp: DateTime.now(),
      );

      await _postsCollection
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .set(newComment.toJson());
    } catch (e) {
      print("Error adding comment: $e");
      throw Exception("Failed to add comment");
    }
  }

  Stream<List<Comment>> getComments(String postId) {
    return _postsCollection
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Comment.fromJson(doc.data())).toList();
    });
  }

  Future<void> reportItem({
    required String itemId,
    required String itemType,
    required String reporterId,
    String? reason,
  }) async {
    // Adaugă un raport în colecția 'reports'
    await _firestore.collection('reports').add({
      'itemId': itemId,
      'itemType': itemType,
      'reporterId': reporterId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Incrementează reportCount pentru postare sau comentariu
    final itemRef = _firestore.collection('${itemType}s').doc(itemId);
    final itemDoc = await itemRef.get();

    if (itemDoc.exists) {
      int currentReportCount = itemDoc.data()?['reportCount'] ?? 0;
      int newReportCount = currentReportCount + 1;

      await itemRef.update({'reportCount': newReportCount});

      // Marchează item-ul ca 'flagged' dacă atinge pragul
      if (newReportCount >= 5) {
        await itemRef.update({'isFlagged': true});
      }
    }
  }
}
