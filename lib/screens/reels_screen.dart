import 'package:flutter/material.dart';
import 'package:grtoco/models/reel.dart';
import 'package:grtoco/services/cache_service.dart';
import 'package:grtoco/services/reel_service.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReelsScreen extends StatefulWidget {
  @override
  _ReelsScreenState createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final ReelService _reelService = ReelService();
  final CacheService _cacheService = CacheService();
  final PageController _pageController = PageController();
  List<Reel> _reels = [];
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int newPage = _pageController.page!.round();
      if (_currentPage != newPage) {
        _currentPage = newPage;
        _preloadNextReels(newPage);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<User?>();

    return StreamBuilder<List<Reel>>(
      stream: _reelService.getReels(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No reels available.'));
        }

        _reels = snapshot.data!;
        if (_reels.isNotEmpty) {
          _preloadNextReels(0);
        }
        return PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: _reels.length,
          itemBuilder: (context, index) {
            final reel = _reels[index];
            return ReelCard(
              reel: reel,
              isActive: index == _currentPage,
              reelService: _reelService,
              cacheService: _cacheService,
              userId: currentUser?.uid,
            );
          },
        );
      },
    );
  }

  void _preloadNextReels(int currentIndex) {
    if (currentIndex + 1 < _reels.length) {
      _cacheService.preloadVideo(_reels[currentIndex + 1].videoUrl);
    }
    if (currentIndex + 2 < _reels.length) {
      _cacheService.preloadVideo(_reels[currentIndex + 2].videoUrl);
    }
  }
}

class ReelCard extends StatefulWidget {
  final Reel reel;
  final bool isActive;
  final ReelService reelService;
  final CacheService cacheService;
  final String? userId;

  const ReelCard({
    Key? key,
    required this.reel,
    required this.isActive,
    required this.reelService,
    required this.cacheService,
    this.userId,
  }) : super(key: key);

  @override
  _ReelCardState createState() => _ReelCardState();
}

class _ReelCardState extends State<ReelCard> {
  late VideoPlayerController _controller;
  bool _isLiked = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _isLiked = widget.userId != null && widget.reel.likes.contains(widget.userId);
  }

  Future<void> _initializeController() async {
    final cachedVideo = await widget.cacheService.getCachedVideo(widget.reel.videoUrl);
    if (cachedVideo != null) {
      _controller = VideoPlayerController.file(cachedVideo);
    } else {
      _controller = VideoPlayerController.network(widget.reel.videoUrl);
    }

    await _controller.initialize();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (widget.isActive) {
        _controller.play();
        _controller.setLooping(true);
      }
    }
  }

  @override
  void didUpdateWidget(ReelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.play();
        _controller.setLooping(true);
      } else {
        _controller.pause();
      }
    }
    if (widget.reel.videoUrl != oldWidget.reel.videoUrl) {
      _controller.dispose();
      _initializeController();
    }
    if (widget.userId != oldWidget.userId) {
      setState(() {
        _isLiked = widget.userId != null && widget.reel.likes.contains(widget.userId);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleLike() {
    if (widget.userId == null) return;
    setState(() {
      _isLiked = !_isLiked;
    });
    if (_isLiked) {
      widget.reelService.likeReel(widget.reel.reelId, widget.userId!);
    } else {
      widget.reelService.unlikeReel(widget.reel.reelId, widget.userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _isLoading
            ? Container(
                color: Colors.black,
                child: Center(child: CircularProgressIndicator()),
              )
            : _controller.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : Container(
                    color: Colors.black,
                    child: Center(child: CircularProgressIndicator()),
                  ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${widget.reel.authorId}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.reel.caption ?? '',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.red : Colors.white,
                      size: 30,
                    ),
                    onPressed: _toggleLike,
                  ),
                  Text(
                    '${widget.reel.likes.length}',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  IconButton(
                    icon: Icon(Icons.comment, color: Colors.white, size: 30),
                    onPressed: () {
                      print('Comment button pressed');
                    },
                  ),
                  Text(
                    '${widget.reel.commentCount}',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  IconButton(
                    icon: Icon(Icons.share, color: Colors.white, size: 30),
                    onPressed: () {
                      print('Share button pressed');
                    },
                  ),
                  Text(
                    '${widget.reel.shares.length}',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
