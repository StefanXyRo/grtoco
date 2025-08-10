import 'package:flutter/material.dart';
import 'package:grtoco/models/story.dart';
import 'package:grtoco/models/user.dart' as model_user;
import 'package:grtoco/services/auth_service.dart';
import 'package:grtoco/services/story_service.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StoryViewScreen extends StatefulWidget {
  final List<Story> stories;
  final String authorId;

  const StoryViewScreen({
    Key? key,
    required this.stories,
    required this.authorId,
  }) : super(key: key);

  @override
  _StoryViewScreenState createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  final StoryService _storyService = StoryService();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(vsync: this);

    if (widget.stories.isNotEmpty) {
      _loadStory(story: widget.stories.first);
    }

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.stop();
        _animationController.reset();
        setState(() {
          if (_currentIndex + 1 < widget.stories.length) {
            _currentIndex += 1;
            _loadStory(story: widget.stories[_currentIndex]);
          } else {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadStory({required Story story}) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;

    if (currentUserId != null && !story.viewers.contains(currentUserId)) {
      _storyService.markStoryAsViewed(storyId: story.storyId, userId: currentUserId);
    }

    _animationController.stop();
    _animationController.reset();

    // A better implementation would get the duration from the video controller.
    _animationController.duration = const Duration(seconds: 5);
    _animationController.forward();

    _pageController.jumpToPage(_currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text("No stories to show.", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) => _onTapDown(details),
        onLongPress: () => _animationController.stop(),
        onLongPressUp: () => _animationController.forward(),
        child: Stack(
          children: <Widget>[
            PageView.builder(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.stories.length,
              itemBuilder: (context, i) {
                final Story story = widget.stories[i];
                switch (story.mediaType) {
                  case MediaType.image:
                    return CachedNetworkImage(
                      imageUrl: story.mediaUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Center(child: Icon(Icons.error, color: Colors.white)),
                    );
                  case MediaType.video:
                    return _StoryVideoPlayer(
                      videoUrl: story.mediaUrl,
                      animationController: _animationController,
                    );
                }
              },
            ),
            Positioned(
              top: 40.0,
              left: 10.0,
              right: 10.0,
              child: Column(
                children: [
                  Row(
                    children: widget.stories
                        .asMap()
                        .map((i, e) => MapEntry(
                              i,
                              _AnimatedBar(
                                animController: _animationController,
                                position: i,
                                currentIndex: _currentIndex,
                              ),
                            ))
                        .values
                        .toList(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: _UserInfo(authorId: widget.authorId),
                  ),
                ],
              ),
            ),
             Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildReplyInput(context, widget.authorId),
            ),
          ],
        ),
      ),
    );
  }

  void _onTapDown(TapDownDetails details) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dx = details.globalPosition.dx;

    setState(() {
      if (dx < screenWidth / 2) { // Left side
        if (_currentIndex - 1 >= 0) {
          _currentIndex -= 1;
          _loadStory(story: widget.stories[_currentIndex]);
        }
      } else { // Right side
        if (_currentIndex + 1 < widget.stories.length) {
          _currentIndex += 1;
          _loadStory(story: widget.stories[_currentIndex]);
        } else {
          Navigator.of(context).pop();
        }
      }
    });
  }

  Widget _buildReplyInput(BuildContext context, String authorId) {
    final TextEditingController replyController = TextEditingController();
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 8, MediaQuery.of(context).padding.bottom + 8),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: replyController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Send a message...',
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.black.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.white),
            onPressed: () {
              final message = replyController.text;
              if (message.isNotEmpty) {
                 print("Sending message to $authorId: $message");
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text("Reply sent (simulated)."))
                 );
                 replyController.clear();
                 FocusScope.of(context).unfocus();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _AnimatedBar extends StatelessWidget {
  final AnimationController animController;
  final int position;
  final int currentIndex;

  const _AnimatedBar({
    Key? key,
    required this.animController,
    required this.position,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.5),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: <Widget>[
                Container(
                  height: 3.0,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: position < currentIndex ? Colors.white : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(3.0),
                  ),
                ),
                if (position == currentIndex)
                  AnimatedBuilder(
                    animation: animController,
                    builder: (context, child) {
                      return Container(
                        height: 3.0,
                        width: constraints.maxWidth * animController.value,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3.0),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _UserInfo extends StatelessWidget {
  final String authorId;
  const _UserInfo({Key? key, required this.authorId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return FutureBuilder<model_user.User?>(
      future: authService.getUser(authorId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final user = snapshot.data!;
        return Row(
          children: <Widget>[
            CircleAvatar(
              radius: 20.0,
              backgroundColor: Colors.grey[300],
              backgroundImage: user.profileImageUrl != null
                  ? CachedNetworkImageProvider(user.profileImageUrl!)
                  : null,
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Text(
                user.displayName ?? 'Unknown User',
                style: const TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28.0),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      }
    );
  }
}

class _StoryVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final AnimationController animationController;

  const _StoryVideoPlayer({Key? key, required this.videoUrl, required this.animationController}) : super(key: key);

  @override
  _StoryVideoPlayerState createState() => _StoryVideoPlayerState();
}

class _StoryVideoPlayerState extends State<_StoryVideoPlayer> {
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        if (_videoController.value.isInitialized) {
          widget.animationController.duration = _videoController.value.duration;
          widget.animationController.forward();
          _videoController.play();
        }
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _videoController.value.isInitialized
        ? Center(
            child: AspectRatio(
              aspectRatio: _videoController.value.aspectRatio,
              child: VideoPlayer(_videoController),
            ),
          )
        : Center(child: CircularProgressIndicator());
  }
}
