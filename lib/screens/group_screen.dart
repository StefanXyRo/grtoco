import 'package:flutter/material.dart';
import 'package:grtoco/models/group.dart';
import 'package:grtoco/models/user.dart' as model_user;
import 'package:grtoco/services/auth_service.dart';
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
  late Future<List<model_user.User>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _groupFuture = GroupService().getGroup(widget.groupId);
    _membersFuture = GroupService().getGroupMembers(widget.groupId);
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

          return Padding(
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
                          builder: (context) => ManageMembersScreen(
                            groupId: widget.groupId,
                          ),
                        ),
                      );
                    },
                    child: Text('Manage Members'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
