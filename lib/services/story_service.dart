import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:grtoco/models/story.dart';
import 'package:uuid/uuid.dart';

class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = Uuid();

  Future<void> uploadStory({
    required String groupId,
    required String authorId,
    required File mediaFile,
  }) async {
    try {
      final String storyId = _uuid.v4();
      final bool isVideo = mediaFile.path.endsWith('.mp4') || mediaFile.path.endsWith('.mov');
      final MediaType mediaType = isVideo ? MediaType.video : MediaType.image;
      final String fileExtension = mediaFile.path.split('.').last;
      final String storagePath = 'stories/$groupId/$storyId.$fileExtension';

      final Reference storageRef = _storage.ref().child(storagePath);
      final UploadTask uploadTask = storageRef.putFile(mediaFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String mediaUrl = await snapshot.ref.getDownloadURL();

      final Timestamp now = Timestamp.now();
      final Timestamp expiresAt = Timestamp.fromMillisecondsSinceEpoch(
          now.millisecondsSinceEpoch + 24 * 60 * 60 * 1000); // 24 hours

      final storyData = {
        'groupId': groupId,
        'authorId': authorId,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType.toString().split('.').last,
        'timestamp': now,
        'expiresAt': expiresAt,
        'viewers': [],
      };

      await _firestore.collection('stories').doc(storyId).set(storyData);
    } catch (e) {
      print("Error uploading story: $e");
      rethrow;
    }
  }

  Stream<List<Story>> getStoriesForGroup(String groupId) {
    return _firestore
        .collection('stories')
        .where('groupId', isEqualTo: groupId)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Story.fromDoc(doc)).toList();
    });
  }

  Future<void> markStoryAsViewed({
    required String storyId,
    required String userId,
  }) async {
    try {
      await _firestore.collection('stories').doc(storyId).update({
        'viewers': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      print("Error marking story as viewed: $e");
    }
  }
}
