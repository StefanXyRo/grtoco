import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grtoco/models/group.dart';

class LiveStreamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _groupsCollection =
      FirebaseFirestore.instance.collection('groups');

  // IMPORTANT: Replace with your Agora App ID
  final String _agoraAppId = 'YOUR_AGORA_APP_ID';
  // IMPORTANT: Replace with your token server URL
  final String _tokenServerUrl = 'YOUR_TOKEN_SERVER_URL';

  Future<void> startLiveStream(String groupId) async {
    try {
      // In a real app, you would generate a unique channel name here
      String channelName = groupId;
      await _groupsCollection.doc(groupId).update({
        'liveStreamId': channelName,
      });
    } catch (e) {
      print("Error starting live stream: $e");
      throw Exception("Failed to start live stream");
    }
  }

  Future<void> endLiveStream(String groupId) async {
    try {
      await _groupsCollection.doc(groupId).update({
        'liveStreamId': null,
      });
    } catch (e) {
      print("Error ending live stream: $e");
      throw Exception("Failed to end live stream");
    }
  }

  String get agoraAppId => _agoraAppId;
  String get tokenServerUrl => _tokenServerUrl;
}
