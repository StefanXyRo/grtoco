import 'dart:io';

import 'package:flutter/material.dart';
import 'package:grtoco/models/group.dart';
import 'package:grtoco/models/message.dart';
import 'package:grtoco/models/story.dart';
import 'package:grtoco/models/user.dart' as model_user;
import 'package:grtoco/services/auth_service.dart';
import 'package:grtoco/services/group_service.dart';
import 'package:grtoco/services/story_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:grtoco/screens/live_stream_screen.dart';
import 'package:grtoco/services/live_stream_service.dart';
import 'package:grtoco/screens/video_call_screen.dart';
import 'package:grtoco/services/video_call_service.dart';
import 'package:grtoco/screens/story_view_screen.dart';
import 'package:grtoco/screens/confirm_story_screen.dart';

import 'manage_members_screen.dart';

class GroupScreen extends StatefulWidget {
  final String groupId;

  const GroupScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _GroupScreenState createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final GroupService _groupService = GroupService();
  final StoryService _storyService = StoryService();
  final LiveStreamService _liveStreamService = LiveStreamService();
  final VideoCallService _videoCallService = VideoCallService();
  final TextEditingController _messageController = TextEditingController();
  Message? _replyingTo;
  File? _mediaFile;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Group?>(
          future: _groupService.getGroup(widget.groupId),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data!.groupName);
            }
            return Text('Group Chat');
          },
        ),
        actions: [
          _buildVideoCallButton(),
          _buildLiveStreamButton(currentUser?.uid),
          FutureBuilder<Group?>(
            future: _groupService.getGroup(widget.groupId),
            builder: (context, snapshot) {
              if (snapshot.hasData &&
                  (snapshot.data!.ownerId == currentUser?.uid ||
                      snapshot.data!.adminIds.contains(currentUser?.uid))) {
                return IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ManageMembersScreen(groupId: widget.groupId),
                      ),
                    );
                  },
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStoriesBar(widget.groupId, currentUser?.uid),
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _groupService.getMessages(widget.groupId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No messages yet.'));
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessage(message, currentUser?.uid);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildStoriesBar(String groupId, String? currentUserId) {
    return Container(
      height: 120,
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: StreamBuilder<List<Story>>(
        stream: _storyService.getStoriesForGroup(groupId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: _buildAddStoryButton(context, currentUserId),
            );
          }

          final stories = snapshot.data!;
          final Map<String, List<Story>> storiesByAuthor = {};
          for (var story in stories) {
            if (storiesByAuthor.containsKey(story.authorId)) {
              storiesByAuthor[story.authorId]!.add(story);
            } else {
              storiesByAuthor[story.authorId] = [story];
            }
          }

          final storyAuthors = storiesByAuthor.keys.toList();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: storyAuthors.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAddStoryButton(context, currentUserId);
              }
              final authorId = storyAuthors[index - 1];
              final userStories = storiesByAuthor[authorId]!;
              return _buildStoryAvatar(context, authorId, userStories, currentUserId);
            },
          );
        },
      ),
    );
  }

  Widget _buildAddStoryButton(BuildContext context, String? currentUserId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
        onTap: () {
          if (currentUserId == null) return;
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return SafeArea(
                child: Wrap(
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.photo_library),
                      title: Text('Image from Gallery'),
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickMedia(ImageSource.gallery, isVideo: false, currentUserId: currentUserId);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.video_library),
                      title: Text('Video from Gallery'),
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickMedia(ImageSource.gallery, isVideo: true, currentUserId: currentUserId);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.add, size: 28, color: Colors.black),
            ),
            SizedBox(height: 8),
            Text("Add Story", style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source, {required bool isVideo, required String currentUserId}) async {
    final picker = ImagePicker();
    final pickedFile = isVideo
        ? await picker.pickVideo(source: source)
        : await picker.pickImage(source: source);

    if (pickedFile == null) return;

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmStoryScreen(
            mediaFile: File(pickedFile.path),
            groupId: widget.groupId,
          ),
        ),
      );
    }
  }

  Widget _buildStoryAvatar(BuildContext context, String authorId, List<Story> stories, String? currentUserId) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final hasUnseen = stories.any((s) => !s.viewers.contains(currentUserId));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryViewScreen(
              stories: stories,
              authorId: authorId,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasUnseen ? Colors.pinkAccent : Colors.grey,
                  width: 2.5,
                ),
              ),
              child: FutureBuilder<model_user.User?>(
                future: authService.getUser(authorId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return CircleAvatar(radius: 32, backgroundColor: Colors.grey[200]);
                  }
                  final user = userSnapshot.data!;
                  return CircleAvatar(
                    radius: 32,
                    backgroundImage: user.profileImageUrl != null
                        ? NetworkImage(user.profileImageUrl!)
                        : null,
                    child: user.profileImageUrl == null
                        ? Text(user.displayName?.substring(0, 1).toUpperCase() ?? 'U', style: TextStyle(fontSize: 24))
                        : null,
                  );
                },
              ),
            ),
            SizedBox(height: 8),
            FutureBuilder<model_user.User?>(
              future: authService.getUser(authorId),
              builder: (context, userSnapshot) {
                return Text(
                  userSnapshot.data?.displayName ?? 'User',
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(Message message, String? currentUserId) {
    final bool isMe = message.senderId == currentUserId;
    return GestureDetector(
      onLongPress: () => _showMessageOptions(message, isMe),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            FutureBuilder<model_user.User?>(
              future:
                  Provider.of<AuthService>(context, listen: false).getUser(message.senderId),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    snapshot.data!.displayName ?? 'Unknown User',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  );
                }
                return SizedBox.shrink();
              },
            ),
            if (message.isReplyTo != null) _buildReplyPreview(message.isReplyTo!),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isMedia && message.mediaUrl != null)
                    _buildMediaPreview(message.mediaUrl!),
                  if (message.textContent != null)
                    Text(message.textContent!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview(String messageId) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(bottom: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        'Replying to message...',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildMediaPreview(String url) {
    if (url.contains('.mp4') || url.contains('.mov')) {
      return _VideoPlayerWidget(url: url);
    } else {
      return Image.network(url,
          width: 200, height: 200, fit: BoxFit.cover);
    }
  }

  void _showMessageOptions(Message message, bool isMe) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return FutureBuilder<Group?>(
          future: _groupService.getGroup(widget.groupId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return SizedBox.shrink();
            }
            final group = snapshot.data!;
            final currentUser =
                Provider.of<AuthService>(context, listen: false).currentUser;
            final isOwner = group.ownerId == currentUser?.uid;
            final isAdmin = group.adminIds.contains(currentUser?.uid);

            return Wrap(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.reply),
                  title: Text('Reply'),
                  onTap: () {
                    setState(() {
                      _replyingTo = message;
                    });
                    Navigator.pop(context);
                  },
                ),
                if (isOwner || isAdmin)
                  ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('Delete'),
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteDialog(message.messageId);
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Message'),
        content: Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Delete'),
            onPressed: () async {
              try {
                await _groupService.deleteMessage(widget.groupId, messageId);
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(e.toString())));
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.white,
      child: Column(
        children: [
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Replying to: ${_replyingTo!.textContent ?? "Media"}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _replyingTo = null;
                      });
                    },
                  )
                ],
              ),
            ),
          if (_mediaFile != null)
            Container(
              height: 100,
              child: Stack(
                children: [
                  Image.file(_mediaFile!),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _mediaFile = null;
                        });
                      },
                    ),
                  )
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.attach_file),
                onPressed: _pickImage,
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _mediaFile = File(pickedFile.path);
      });
    }
  }

  void _sendMessage() {
    if (_messageController.text.isEmpty && _mediaFile == null) return;

    _groupService.sendMessage(
      groupId: widget.groupId,
      textContent: _messageController.text,
      mediaFile: _mediaFile,
      replyToMessageId: _replyingTo?.messageId,
    );

    _messageController.clear();
    setState(() {
      _replyingTo = null;
      _mediaFile = null;
    });
  }

  Widget _buildLiveStreamButton(String? currentUserId) {
    return FutureBuilder<Group?>(
      future: _groupService.getGroup(widget.groupId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }
        final group = snapshot.data!;
        final isOwner = group.ownerId == currentUserId;
        final isLive = group.liveStreamId != null;

        if (isLive) {
          return TextButton.icon(
            icon: Icon(Icons.live_tv, color: Colors.red),
            label: Text('Join Live', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LiveStreamScreen(
                    groupId: widget.groupId,
                    isHost: isOwner,
                  ),
                ),
              );
            },
          );
        } else if (isOwner) {
          return TextButton.icon(
            icon: Icon(Icons.video_call, color: Colors.white),
            label: Text('Go Live', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              await _liveStreamService.startLiveStream(widget.groupId);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LiveStreamScreen(
                    groupId: widget.groupId,
                    isHost: true,
                  ),
                ),
              );
            },
          );
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildVideoCallButton() {
    return FutureBuilder<Group?>(
      future: _groupService.getGroup(widget.groupId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }
        final group = snapshot.data!;
        final isCallActive = group.videoCallId != null;

        if (isCallActive) {
          return TextButton.icon(
            icon: Icon(Icons.video_camera_front, color: Colors.green),
            label: Text('Join Call', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoCallScreen(groupId: widget.groupId),
                ),
              );
            },
          );
        } else {
          return TextButton.icon(
            icon: Icon(Icons.video_call, color: Colors.white),
            label: Text('Video Call', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              await _videoCallService.startVideoCall(widget.groupId);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoCallScreen(groupId: widget.groupId),
                ),
              );
            },
          );
        }
      },
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String url;
  const _VideoPlayerWidget({Key? key, required this.url}) : super(key: key);

  @override
  __VideoPlayerWidgetState createState() => __VideoPlayerWidgetState();
}

class __VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller),
                IconButton(
                  icon: Icon(
                    _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    });
                  },
                )
              ],
            ),
          )
        : CircularProgressIndicator();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
