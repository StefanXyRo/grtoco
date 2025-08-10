import 'package:flutter/material.dart';
import 'package:grtoco/models/group.dart';
import 'package:grtoco/models/post.dart';
import 'package:grtoco/screens/group_screen.dart';
import 'package:grtoco/services/auth_service.dart';
import 'package:grtoco/screens/create_group_screen.dart';
import 'package:grtoco/screens/profile_screen.dart';
import 'package:grtoco/services/group_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _auth = AuthService();
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

      setState(() {
        _recommendedGroups = results[0] as List<Group>;
        _posts = results[1] as List<Post>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load data: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<User?>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              if (currentUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfileScreen(userId: currentUser.uid),
                  ),
                );
              }
            },
          ),
          TextButton.icon(
            icon: Icon(Icons.person),
            label: Text('Logout'),
            onPressed: () async {
              await _auth.signOut();
            },
          )
        ],
      ),
      body: _isLoading
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
                        child: Text('Feed',
                            style: Theme.of(context).textTheme.headline6),
                      ),
                      Expanded(
                        child: _buildPostsFeed(),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateGroupScreen()),
          ).then((_) => _loadData());
        },
        child: Icon(Icons.add),
        tooltip: 'Create Group',
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
          child: Text('Recommended Groups',
              style: Theme.of(context).textTheme.headline6),
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
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            title: Text(post.authorId), // Ideally, show author's name
            subtitle: Text(post.textContent ?? ''),
            // You can add more details, like group name, timestamp, etc.
          ),
        );
      },
    );
  }
}
