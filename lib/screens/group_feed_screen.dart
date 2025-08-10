import 'package:flutter/material.dart';
import 'package:grtoco/models/group.dart';
import 'package:grtoco/models/post.dart';
import 'package:grtoco/services/group_service.dart';
import 'package:grtoco/widgets/post_widget.dart';

class GroupFeedScreen extends StatefulWidget {
  final String groupId;

  const GroupFeedScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _GroupFeedScreenState createState() => _GroupFeedScreenState();
}

class _GroupFeedScreenState extends State<GroupFeedScreen> {
  final GroupService _groupService = GroupService();
  late Future<Map<String, dynamic>> _feedData;

  @override
  void initState() {
    super.initState();
    _feedData = _loadFeedData();
  }

  Future<Map<String, dynamic>> _loadFeedData() async {
    final group = await _groupService.getGroup(widget.groupId);
    final posts = await _groupService.getPostsForGroup(widget.groupId);

    Post? pinnedPost;
    if (group?.pinnedPostId != null) {
      // Find the pinned post in the list of posts
      try {
        pinnedPost = posts.firstWhere((p) => p.postId == group.pinnedPostId);
        // Remove it from the main list to avoid duplication
        posts.removeWhere((p) => p.postId == group.pinnedPostId);
      } catch (e) {
        // Pinned post not found in the recent posts list, might be older
        // Or it was deleted. For now, we ignore the error.
        print('Pinned post with id ${group.pinnedPostId} not found in fetched posts.');
      }
    }

    return {
      'group': group,
      'posts': posts,
      'pinnedPost': pinnedPost,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Feed'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _feedData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(child: Text('Group not found.'));
          }

          final group = snapshot.data!['group'] as Group?;
          final posts = snapshot.data!['posts'] as List<Post>;
          final pinnedPost = snapshot.data!['pinnedPost'] as Post?;

          if (group == null) {
            return Center(child: Text('Group could not be loaded.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _feedData = _loadFeedData();
              });
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(group.groupName, style: Theme.of(context).textTheme.headline5),
                  ),
                ),
                if (pinnedPost != null)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.push_pin, size: 16, color: Colors.grey[600]),
                              SizedBox(width: 8),
                              Text('PINNED POST', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        PostWidget(post: pinnedPost),
                        Divider(),
                      ],
                    ),
                  ),
                if (posts.isEmpty && pinnedPost == null)
                  SliverFillRemaining(
                    child: Center(child: Text('No posts in this group yet.')),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = posts[index];
                        return PostWidget(post: post);
                      },
                      childCount: posts.length,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
