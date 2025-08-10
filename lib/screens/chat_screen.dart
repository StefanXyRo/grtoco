import 'dart:io';
import 'package:flutter/material.dart';
import 'package:grtoco/models/message.dart';
import 'package:grtoco/services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isRecording = false;
  String? _recordingPath;
  bool _isSearching = false;
  List<Message> _allMessages = [];
  List<Message> _filteredMessages = [];

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _initPlayer();
    _searchController.addListener(_filterMessages);
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterMessages() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredMessages = _allMessages;
      });
    } else {
      setState(() {
        _filteredMessages = _allMessages
            .where((message) =>
                message.textContent?.toLowerCase().contains(query) ?? false)
            .toList();
      });
    }
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
  }

    Future<void> _initPlayer() async {
    await _player.openPlayer();
  }

  Future<void> _startRecording() async {
    final tempDir = await getTemporaryDirectory();
    _recordingPath = '${tempDir.path}/flutter_sound.aac';
    await _recorder.startRecorder(toFile: _recordingPath);
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    _sendVoiceMessage();
  }

  Future<void> _sendVoiceMessage() async {
    if (_recordingPath == null) return;

    final file = File(_recordingPath!);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.aac';
    final storageRef = FirebaseStorage.instance.ref().child('voice_messages/$fileName');

    try {
      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      final message = Message(
        messageId: '',
        conversationId: widget.conversationId,
        senderId: _auth.currentUser!.uid,
        timestamp: DateTime.now(),
        isMedia: true,
        mediaUrl: downloadUrl,
        mediaType: 'voice',
      );

      await _chatService.sendMessage(widget.conversationId, message);
    } catch (e) {
      print("Error uploading voice message: $e");
    }
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      final message = Message(
        messageId: '', // Firestore will generate this
        conversationId: widget.conversationId,
        senderId: _auth.currentUser!.uid,
        textContent: _messageController.text,
        timestamp: DateTime.now(),
      );
      _chatService.sendMessage(widget.conversationId, message);
      _messageController.clear();
    }
  }

  Future<void> _playVoiceMessage(String url) async {
    await _player.startPlayer(fromURI: url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search messages...',
                  hintStyle: TextStyle(color: Colors.white),
                ),
                style: const TextStyle(color: Colors.white),
                autofocus: true,
              )
            : Text('Chat'), // Replace with actual user/group name
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPinnedMessages(),
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                _allMessages = snapshot.data ?? [];
                _filterMessages(); // Initial filter
                return ListView.builder(
                  reverse: true,
                  itemCount: _filteredMessages.length,
                  itemBuilder: (context, index) {
                    final message = _filteredMessages[index];
                    final isMe = message.senderId == _auth.currentUser!.uid;
                    return _buildMessageBubble(message, isMe);
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

  Widget _buildMessageBubble(Message message, bool isMe) {
    return GestureDetector(
      onLongPress: () {
        _showMessageOptions(context, message);
      },
      child: Container(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Card(
          color: isMe ? Colors.blue[100] : Colors.grey[300],
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                message.mediaType == 'voice'
                    ? IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _playVoiceMessage(message.mediaUrl!),
                      )
                    : Text(message.textContent ?? ''),
                if (message.isEdited)
                  const Text(
                    ' (edited)',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                _buildReactions(message.reactions),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinnedMessages() {
    return StreamBuilder<List<Message>>(
      stream: _chatService.getPinnedMessages(widget.conversationId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final pinnedMessages = snapshot.data!;
        // Simple UI for pinned messages, could be a carousel or a single line
        return Container(
          padding: const EdgeInsets.all(8.0),
          color: Colors.amber[100],
          child: Text(
            'Pinned: ${pinnedMessages.first.textContent}', // Shows the first pinned message
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }

  Widget _buildReactions(Map<String, List<String>> reactions) {
    if (reactions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 4.0,
      children: reactions.entries.map((entry) {
        return Chip(
          label: Text('${entry.key} ${entry.value.length}'),
          padding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  void _showMessageOptions(BuildContext context, Message message) {
    final isMe = message.senderId == _auth.currentUser!.uid;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  // TODO: Implement reply functionality
                  Navigator.of(context).pop();
                },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showEditDialog(message);
                  },
                ),
              if (isMe &&
                  DateTime.now().difference(message.timestamp).inMinutes < 5)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Delete'),
                  onTap: () {
                    _chatService.deleteMessage(
                        widget.conversationId, message.messageId);
                    Navigator.of(context).pop();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.push_pin),
                title: Text(message.isPinned ? 'Unpin' : 'Pin'),
                onTap: () {
                  if (message.isPinned) {
                    _chatService.unpinMessage(
                        widget.conversationId, message.messageId);
                  } else {
                    _chatService.pinMessage(
                        widget.conversationId, message.messageId);
                  }
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.emoji_emotions),
                title: const Text('React'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showReactionPicker(message.messageId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(Message message) {
    final editController = TextEditingController(text: message.textContent);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: editController,
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              _chatService.editMessage(
                  widget.conversationId, message.messageId, editController.text);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showReactionPicker(String messageId) {
    // A simple reaction bar
    final reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Container(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: reactions.map((reaction) {
                return IconButton(
                  icon: Text(reaction, style: const TextStyle(fontSize: 24)),
                  onPressed: () {
                    _chatService.toggleReaction(widget.conversationId,
                        messageId, reaction, _auth.currentUser!.uid);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
              ),
            ),
          ),
          IconButton(
            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
            onPressed: _isRecording ? _stopRecording : _startRecording,
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
