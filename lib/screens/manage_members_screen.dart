import 'package:flutter/material.dart';
import 'package:grtoco/models/group.dart';
import 'package:grtoco/models/user.dart' as model_user;
import 'package:grtoco/services/auth_service.dart';
import 'package:grtoco/services/group_service.dart';
import 'package:provider/provider.dart';

class ManageMembersScreen extends StatefulWidget {
  final String groupId;

  const ManageMembersScreen({Key? key, required this.groupId})
      : super(key: key);

  @override
  _ManageMembersScreenState createState() => _ManageMembersScreenState();
}

class _ManageMembersScreenState extends State<ManageMembersScreen> {
  late Future<Group?> _groupFuture;
  late Future<List<model_user.User>> _membersFuture;
  late Future<List<model_user.User>> _pendingRequestsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _groupFuture = GroupService().getGroup(widget.groupId);
    _membersFuture = GroupService().getGroupMembers(widget.groupId);
    _pendingRequestsFuture = GroupService().getPendingRequests(widget.groupId);
  }

  void _refreshMembers() {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Members'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future:
            Future.wait([_groupFuture, _membersFuture, _pendingRequestsFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Error loading data'));
          }

          final group = snapshot.data![0] as Group;
          final members = snapshot.data![1] as List<model_user.User>;
          final pendingRequests = snapshot.data![2] as List<model_user.User>;
          final isOwner = group.ownerId == currentUser?.uid;

          return Column(
            children: [
              if (pendingRequests.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Pending Requests',
                    style: Theme.of(context).textTheme.headline6,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: pendingRequests.length,
                    itemBuilder: (context, index) {
                      final user = pendingRequests[index];
                      return ListTile(
                        title: Text(user.displayName ?? 'No Name'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () async {
                                await GroupService().acceptJoinRequest(
                                    group.groupId, user.userId);
                                _refreshMembers();
                              },
                              child: Text('Accept'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await GroupService().declineJoinRequest(
                                    group.groupId, user.userId);
                                _refreshMembers();
                              },
                              child: Text('Decline'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Divider(),
              ],
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Members',
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final isMemberAdmin = group.adminIds.contains(member.userId);
                    final isMemberOwner = group.ownerId == member.userId;

                    String role = 'Member';
                    if (isMemberOwner) {
                      role = 'Owner';
                    } else if (isMemberAdmin) {
                      role = 'Admin';
                    }

                    return ListTile(
                      title: Text(member.displayName ?? 'No Name'),
                      subtitle: Text(role),
                      trailing: _buildActionButtons(
                        group,
                        member,
                        isOwner,
                        isMemberAdmin,
                        isMemberOwner,
                        currentUser!.uid,
                      ),
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

  Widget _buildActionButtons(
    Group group,
    model_user.User member,
    bool isCurrentUserOwner,
    bool isMemberAdmin,
    bool isMemberOwner,
    String currentUserId,
  ) {
    List<Widget> buttons = [];

    if (isCurrentUserOwner) {
      if (!isMemberOwner) {
        if (isMemberAdmin) {
          buttons.add(
            TextButton(
              onPressed: () async {
                await GroupService()
                    .demoteToMember(group.groupId, member.userId);
                _refreshMembers();
              },
              child: Text('Demote'),
            ),
          );
        } else {
          buttons.add(
            TextButton(
              onPressed: () async {
                await GroupService()
                    .promoteToAdmin(group.groupId, member.userId);
                _refreshMembers();
              },
              child: Text('Promote'),
            ),
          );
        }
        buttons.add(
          TextButton(
            onPressed: () async {
              await GroupService().removeMember(group.groupId, member.userId);
              _refreshMembers();
            },
            child: Text('Remove'),
          ),
        );
      }
    } else { // Current user is an admin
      if (!isMemberOwner && member.userId != currentUserId) {
        buttons.add(
          TextButton(
            onPressed: () async {
              await GroupService().removeMember(group.groupId, member.userId);
              _refreshMembers();
            },
            child: Text('Remove'),
          ),
        );
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: buttons,
    );
  }
}
