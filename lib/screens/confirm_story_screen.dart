import 'dart:io';
import 'package:flutter/material.dart';
import 'package:grtoco/services/story_service.dart';
import 'package:grtoco/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class ConfirmStoryScreen extends StatefulWidget {
  final File mediaFile;
  final String groupId;

  const ConfirmStoryScreen({
    Key? key,
    required this.mediaFile,
    required this.groupId,
  }) : super(key: key);

  @override
  _ConfirmStoryScreenState createState() => _ConfirmStoryScreenState();
}

class _ConfirmStoryScreenState extends State<ConfirmStoryScreen> {
  final StoryService _storyService = StoryService();
  VideoPlayerController? _videoController;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.mediaFile.path.endsWith('.mp4') || widget.mediaFile.path.endsWith('.mov')) {
      _videoController = VideoPlayerController.file(widget.mediaFile)
        ..initialize().then((_) {
          setState(() {});
          _videoController?.play();
          _videoController?.setLooping(true);
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _uploadStory() async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (currentUserId == null) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('You must be logged in to post a story.')));
      setState(() {
        _isUploading = false;
      });
      return;
    }

    try {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Uploading story...')));
      await _storyService.uploadStory(
        groupId: widget.groupId,
        authorId: currentUserId,
        mediaFile: widget.mediaFile,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Failed to upload story: $e')));
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Confirm Story', style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          Center(
            child: _videoController != null && _videoController!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  )
                : Image.file(widget.mediaFile),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadStory,
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.send, color: Colors.white),
      ),
    );
  }
}
