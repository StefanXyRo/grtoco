import 'package:flutter/material.dart';
import 'package:grtoco/models/group.dart';
import 'package:grtoco/models/post.dart';
import 'package:grtoco/screens/conversations_screen.dart';
import 'package:grtoco/screens/create_group_screen.dart';
import 'package:grtoco/screens/group_screen.dart';
import 'package:grtoco/screens/post_reel_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grtoco/models/interactive_post.dart';
import 'package:grtoco/screens/create_post_screen.dart';
import 'package:grtoco/screens/profile_screen.dart';
import 'package:grtoco/screens/reels_screen.dart';
import 'package:grtoco/services/auth_service.dart';
import 'package:grtoco/services/group_service.dart';
import 'package:grtoco/widgets/event_widget.dart';
import 'package:grtoco/widgets/poll_widget.dart';
import 'package:grtoco/widgets/qa_widget.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    HomeFeed(),
    ReelsScreen(),
    ConversationsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget? _buildFab(BuildContext context) {
    if (_selectedIndex == 0) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePostScreen()),
          ).then((value) {
            if (mounted) {
              // Refresh the feed after creating a post
              // This is a simple way to do it. A more sophisticated
              // approach might use a stream or a state management solution.
              setState(() {});
            }
          });
        },
        child: Icon(Icons.add),
        tooltip: 'Create Post',
      );
    } else if (_selectedIndex == 1) {
      return FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PostReelScreen()),
          );
        },
        child: Icon(Icons.video_call),
        tooltip: 'Post Reel',
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<User?>();
    final authService = Provider.of<AuthService>(context, listen: false);

    final List<PreferredSizeWidget?> appBars = [
      AppBar(
        title: Text('Home'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              if (currentUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(userId: currentUser.uid),
                  ),
                );
              }
            },
          ),
          TextButton.icon(
            icon: Icon(Icons.person),
            label: Text('Logout'),
            onPressed: () async {
              await authService.signOut();
            },
          )
        ],
      ),
      AppBar(
        title: Text('Reels'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      AppBar(
        title: Text('Conversations'),
      )
    ];

    return Scaffold(
      extendBodyBehindAppBar: _selectedIndex == 1,
      appBar: appBars[_selectedIndex],
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Reels',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
      floatingActionButton: _buildFab(context),
    );
  }
}

class HomeFeed extends StatefulWidget {
  @override
  _HomeFeedState createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  final GroupService _groupService = GroupService();
  bool _isLoading = true;
  List<Group> _recommendedGroups = [];
  List<Post> _posts = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _groupService.getGroupRecommendations(),
        _groupService.getPostsForUserGroups(),
      ]);

      if (mounted) {
        setState(() {
          _recommendedGroups = results[0] as List<Group>;
          _posts = results[1] as List<Post>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load data: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Text(_error!))
            : RefreshIndicator(
                onRefresh: _loadData,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRecommendedGroupsSection(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Feed', style: Theme.of(context).textTheme.headline6),
                    ),
                    Expanded(
                      child: _buildPostsFeed(),
                    ),
                  ],
                ),
              );
  }

  Widget _buildRecommendedGroupsSection() {
    if (_recommendedGroups.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Recommended Groups', style: Theme.of(context).textTheme.headline6),
        ),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recommendedGroups.length,
            itemBuilder: (context, index) {
              final group = _recommendedGroups[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupScreen(groupId: group.groupId),
                    ),
                  ).then((_) => _loadData());
                },
                child: Container(
                  width: 150,
                  child: Card(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          group.groupName,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPostsFeed() {
    if (_posts.isEmpty) {
      return Center(child: Text('No posts in your groups yet.'));
    }

    return ListView.builder(
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        if (post.postType == PostType.interactive) {
          return FutureBuilder<DocumentSnapshot?>(
            future: _groupService.getInteractivePost(post.postId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return Card(
                  child: ListTile(
                    title: Text('Interactive post not found.'),
                  ),
                );
              }
              final interactivePost = InteractivePost.fromJson(
                  snapshot.data!.data() as Map<String, dynamic>);
              switch (interactivePost.postType) {
                case InteractivePostType.poll:
                  return PollWidget(poll: interactivePost);
                case InteractivePostType.event:
                  return EventWidget(event: interactivePost);
                case InteractivePostType.qa:
                  return QaWidget(qaPost: interactivePost);
              }
            },
          );
        } else {
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              title: Text(post.authorId),
              subtitle: Text(post.textContent ?? 'This is a standard post.'),
            ),
          );
        }
      },
    );
  }
}
