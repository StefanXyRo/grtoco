import 'package:flutter/material.dart';
import 'package:grtoco/models/group.dart';
import 'package:grtoco/models/post.dart';
import 'package:grtoco/models/user.dart' as model_user;
import 'package:grtoco/services/auth_service.dart';
import 'package:grtoco/services/database_service.dart';
import 'package:grtoco/services/group_service.dart';
import 'package:provider/provider.dart';
import 'manage_members_screen.dart';

class GroupScreen extends StatefulWidget {
  final String groupId;

  const GroupScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _GroupScreenState createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  late Future<Group?> _groupFuture;
  late Future<List<Post>> _postsFuture;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _groupFuture = GroupService().getGroup(widget.groupId);
    _postsFuture = GroupService().getPostsForGroup(widget.groupId);
  }

  void _showReportDialog(String itemId, String itemType) {
    final TextEditingController _reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Report $itemType'),
          content: TextField(
            controller: _reasonController,
            decoration: InputDecoration(hintText: 'Reason for reporting...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final authService =
                    Provider.of<AuthService>(context, listen: false);
                final currentUser = authService.currentUser;
                if (currentUser != null) {
                  await _databaseService.reportItem(
                    itemId: itemId,
                    itemType: itemType,
                    reporterId: currentUser.uid,
                    reason: _reasonController.text,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Report submitted')),
                  );
                  setState(() {
                    _postsFuture =
                        GroupService().getPostsForGroup(widget.groupId);
                  });
                }
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Group Details'),
      ),
      body: FutureBuilder<Group?>(
        future: _groupFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Group not found'));
          }

          final group = snapshot.data!;
          final isOwner = group.ownerId == currentUser?.uid;
          final isAdmin = group.adminIds.contains(currentUser?.uid);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.groupName,
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    SizedBox(height: 8),
                    Text(group.description ?? ''),
                    SizedBox(height: 16),
                    if (isOwner || isAdmin)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ManageMembersScreen(groupId: widget.groupId),
                            ),
                          ).then((_) => setState(() {
                                _groupFuture =
                                    GroupService().getGroup(widget.groupId);
                              }));
                        },
                        child: Text('Manage Members'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Post>>(
                  future: _postsFuture,
                  builder: (context, postSnapshot) {
                    if (postSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!postSnapshot.hasData || postSnapshot.data!.isEmpty) {
                      return Center(child: Text('No posts in this group yet.'));
                    }

                    final posts = postSnapshot.data!
                        .where((post) => !post.isFlagged)
                        .toList();

                    return ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return Card(
                          margin:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(post.textContent ?? ''),
                            subtitle: Text('Author: ${post.authorId}'),
                            trailing: IconButton(
                              icon: Icon(Icons.report),
                              onPressed: () =>
                                  _showReportDialog(post.postId, 'post'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
