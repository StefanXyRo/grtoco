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
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isRecording = false;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _initPlayer();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
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
        title: Text('Chat with User ${widget.otherUserId}'), // Replace with actual user name
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
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
    return Container(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Card(
        color: isMe ? Colors.blue[100] : Colors.grey[300],
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: message.mediaType == 'voice'
              ? IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => _playVoiceMessage(message.mediaUrl!),
                )
              : Text(message.textContent ?? ''),
        ),
      ),
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
