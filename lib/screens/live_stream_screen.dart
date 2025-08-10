import 'package:agora_uikit/agora_uikit.dart';
import 'package:flutter/material.dart';
import 'package:grtoco/models/comment.dart';
import 'package:grtoco/models/group.dart';
import 'package:grtoco/services/auth_service.dart';
import 'package:grtoco/services/chat_service.dart';
import 'package:grtoco/services/live_stream_service.dart';
import 'package:provider/provider.dart';
import 'package:grtoco/models/user.dart' as model_user;


class LiveStreamScreen extends StatefulWidget {
  final String groupId;
  final bool isHost;

  const LiveStreamScreen({
    Key? key,
    required this.groupId,
    required this.isHost,
  }) : super(key: key);

  @override
  _LiveStreamScreenState createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  final LiveStreamService _liveStreamService = LiveStreamService();
  final ChatService _chatService = ChatService();
  AgoraClient? _agoraClient;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    _agoraClient = AgoraClient(
      agoraConnectionData: AgoraConnectionData(
        appId: _liveStreamService.agoraAppId,
        channelName: widget.groupId,
        // In a real app, you would generate a user-specific token from your server
        tempToken: null,
      ),
      enabledPermission: [
        Permission.camera,
        Permission.microphone,
      ],
      agoraChannelData: AgoraChannelData(
        clientRole: widget.isHost ? ClientRole.Broadcaster : ClientRole.Audience,
      ),
    );
    await _agoraClient!.initialize();
  }

  @override
  void dispose() {
    _agoraClient?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _agoraClient == null
            ? Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  AgoraVideoViewer(client: _agoraClient!),
                  AgoraVideoButtons(client: _agoraClient!),
                  _buildChat(),
                ],
              ),
      ),
    );
  }

  Widget _buildChat() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 300,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Comment>>(
                stream: _chatService.getGroupComments(widget.groupId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                        child: Text('No comments yet.',
                            style: TextStyle(color: Colors.white)));
                  }
                  final comments = snapshot.data!
                      .where((comment) => !comment.hidden)
                      .toList();
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return _buildCommentItem(comment);
                    },
                  );
                },
              ),
            ),
            _buildCommentInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return GestureDetector(
      onLongPress: () {
        if (widget.isHost) {
          _chatService.hideGroupComment(widget.groupId, comment.commentId);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<model_user.User?>(
              future: Provider.of<AuthService>(context, listen: false)
                  .getUser(comment.authorId),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    '${snapshot.data!.displayName ?? 'Unknown'}: ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }
                return SizedBox.shrink();
              },
            ),
            Expanded(
              child: Text(
                comment.textContent,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.black.withOpacity(0.5),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                hintStyle: TextStyle(color: Colors.white),
                border: InputBorder.none,
              ),
              style: TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.white),
            onPressed: _sendComment,
          ),
        ],
      ),
    );
  }

  void _sendComment() {
    if (_commentController.text.isNotEmpty) {
      _chatService.sendGroupComment(
        groupId: widget.groupId,
        textContent: _commentController.text,
      );
      _commentController.clear();
    }
  }
}
