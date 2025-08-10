import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:grtoco/models/post.dart';
import 'package:grtoco/services/auth_service.dart';
import 'package:grtoco/services/cache_service.dart';
import 'package:grtoco/services/group_service.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class PostWidget extends StatelessWidget {
  final Post post;
  final CacheService cacheService = CacheService();

  PostWidget({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final groupService = Provider.of<GroupService>(context, listen: false);
    final currentUser = authService.currentUser;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(post.authorId, style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (currentUser != null)
                  FutureProvider<bool>(
                    create: (_) => groupService.isUserAdmin(post.groupId, currentUser.uid),
                    initialData: false,
                    child: Consumer<bool>(
                      builder: (context, isAdmin, child) {
                        if (isAdmin) {
                          return PopupMenuButton<String>(
                            onSelected: (value) async {
                              try {
                                if (value == 'pin') {
                                  await groupService.pinPost(post.groupId, post.postId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Post pinned successfully!')),
                                  );
                                } else if (value == 'unpin') {
                                  await groupService.unpinPost(post.groupId, post.postId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Post unpinned successfully!')),
                                  );
                                }
                                // TODO: Add a way to refresh the feed
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              return [
                                PopupMenuItem<String>(
                                  value: post.isPinned ? 'unpin' : 'pin',
                                  child: Text(post.isPinned ? 'Unpin Post' : 'Pin Post'),
                                ),
                              ];
                            },
                          );
                        }
                        return SizedBox.shrink();
                      },
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8),
            if (post.textContent != null) Text(post.textContent!),
            if (post.postType == PostType.image && post.contentUrl != null)
              CachedNetworkImage(
                imageUrl: post.contentUrl!,
                placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
            if (post.postType == PostType.video && post.contentUrl != null)
              VideoPostWidget(
                videoUrl: post.contentUrl!,
                cacheService: cacheService,
              ),
          ],
        ),
      ),
    );
  }
}

class VideoPostWidget extends StatefulWidget {
  final String videoUrl;
  final CacheService cacheService;

  const VideoPostWidget({Key? key, required this.videoUrl, required this.cacheService}) : super(key: key);

  @override
  _VideoPostWidgetState createState() => _VideoPostWidgetState();
}

class _VideoPostWidgetState extends State<VideoPostWidget> {
  late VideoPlayerController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    final cachedVideo = await widget.cacheService.getCachedVideo(widget.videoUrl);
    if (cachedVideo != null) {
      _controller = VideoPlayerController.file(cachedVideo);
    } else {
      _controller = VideoPlayerController.network(widget.videoUrl);
    }

    await _controller.initialize();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          );
  }
}
