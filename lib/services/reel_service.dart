import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:grtoco/models/reel.dart';

class ReelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _reelsCollection =
      FirebaseFirestore.instance.collection('reels');

  Future<void> likeReel(String reelId, String userId) async {
    await _reelsCollection.doc(reelId).update({
      'likes': FieldValue.arrayUnion([userId])
    });
  }

  Future<void> unlikeReel(String reelId, String userId) async {
    await _reelsCollection.doc(reelId).update({
      'likes': FieldValue.arrayRemove([userId])
    });
  }

  Future<void> addComment(String reelId) async {
    await _reelsCollection.doc(reelId).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  Future<void> shareReel(String reelId) async {
    await _reelsCollection.doc(reelId).update({
      'shares': FieldValue.increment(1),
    });
  }

  Stream<List<Reel>> getReels() {
    return _reelsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Reel.fromFirestore(doc)).toList();
    });
  }

  Future<void> createReel({
    required String videoPath,
    required String groupId,
    required String authorId,
    String? caption,
  }) async {
    try {
      File videoFile = File(videoPath);
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef =
          FirebaseStorage.instance.ref().child('reels/$fileName');
      UploadTask uploadTask = storageRef.putFile(videoFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      String reelId = _reelsCollection.doc().id;
      Reel newReel = Reel(
        reelId: reelId,
        groupId: groupId,
        authorId: authorId,
        videoUrl: downloadUrl,
        caption: caption,
        timestamp: DateTime.now(),
      );

      await _reelsCollection.doc(reelId).set(newReel.toJson());
    } catch (e) {
      print("Error creating reel: $e");
      throw Exception("Failed to create reel");
    }
  }
}
