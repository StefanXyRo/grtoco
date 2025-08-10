import 'package:agora_uikit/agora_uikit.dart';
import 'package:flutter/material.dart';
import 'package:grtoco/services/video_call_service.dart';
import 'package:grtoco/services/auth_service.dart';
import 'package:grtoco/services/group_service.dart';
import 'package:provider/provider.dart';
import 'package:grtoco/models/group.dart';
import 'package:grtoco/models/user.dart' as model_user;


class VideoCallScreen extends StatefulWidget {
  final String groupId;

  const VideoCallScreen({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final VideoCallService _videoCallService = VideoCallService();
  final GroupService _groupService = GroupService();
  AgoraClient? _agoraClient;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
    _checkIfOwner();
  }

  Future<void> _initAgora() async {
    _agoraClient = AgoraClient(
      agoraConnectionData: AgoraConnectionData(
        appId: _videoCallService.agoraAppId,
        channelName: widget.groupId,
        tempToken: null, // In a real app, you would generate a user-specific token from your server
      ),
      enabledPermission: [
        Permission.camera,
        Permission.microphone,
      ],
      agoraChannelData: AgoraChannelData(
        clientRole: ClientRole.Broadcaster, // Everyone is a host
      ),
    );
    await _agoraClient!.initialize();
  }

  Future<void> _checkIfOwner() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    if (currentUser != null) {
      final group = await _groupService.getGroup(widget.groupId);
      if (group != null && group.ownerId == currentUser.uid) {
        if (mounted) {
          setState(() {
            _isOwner = true;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    // If the owner closes the app without ending the call, end it.
    if (_isOwner) {
      _videoCallService.endVideoCall(widget.groupId);
    }
    _agoraClient?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isOwner) {
          await _videoCallService.endVideoCall(widget.groupId);
        }
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: _agoraClient == null
              ? Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    AgoraVideoViewer(client: _agoraClient!),
                    AgoraVideoButtons(
                      client: _agoraClient!,
                      disconnectButtonChild: IconButton(
                        onPressed: () async {
                          if (_isOwner) {
                            await _videoCallService.endVideoCall(widget.groupId);
                          }
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.call_end, color: Colors.red),
                      ),
                      extraButtons: [
                        IconButton(
                          onPressed: () => _showInviteDialog(),
                          icon: Icon(Icons.person_add, color: Colors.white),
                        )
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Invite Members'),
          content: Container(
            width: double.maxFinite,
            child: FutureBuilder<Group?>(
              future: _groupService.getGroup(widget.groupId),
              builder: (context, groupSnapshot) {
                if (!groupSnapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final group = groupSnapshot.data!;
                final authService = Provider.of<AuthService>(context, listen: false);

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: group.memberIds.length,
                  itemBuilder: (context, index) {
                    final memberId = group.memberIds[index];
                    return FutureBuilder<model_user.User?>(
                      future: authService.getUser(memberId),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return ListTile(
                            title: Text('Loading...'),
                          );
                        }
                        final user = userSnapshot.data!;
                        return ListTile(
                          title: Text(user.displayName ?? 'Unknown'),
                          // Here you could add a button to send a notification
                          // For now, it just lists the members
                          trailing: Icon(Icons.person),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
