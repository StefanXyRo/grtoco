import 'package:cloud_firestore/cloud_firestore.dart';

class VideoCallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _groupsCollection =
      FirebaseFirestore.instance.collection('groups');

  // IMPORTANT: Replace with your Agora App ID
  final String _agoraAppId = 'YOUR_AGORA_APP_ID';
  // IMPORTANT: Replace with your token server URL
  final String _tokenServerUrl = 'YOUR_TOKEN_SERVER_URL';

  Future<void> startVideoCall(String groupId) async {
    try {
      // Using the groupId as the channel name for simplicity
      String channelName = groupId;
      await _groupsCollection.doc(groupId).update({
        'videoCallId': channelName,
      });
    } catch (e) {
      print("Error starting video call: $e");
      throw Exception("Failed to start video call");
    }
  }

  Future<void> endVideoCall(String groupId) async {
    try {
      await _groupsCollection.doc(groupId).update({
        'videoCallId': null,
      });
    } catch (e) {
      print("Error ending video call: $e");
      throw Exception("Failed to end video call");
    }
  }

  String get agoraAppId => _agoraAppId;
  String get tokenServerUrl => _tokenServerUrl;
}
