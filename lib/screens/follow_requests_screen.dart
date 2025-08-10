import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grtoco/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:grtoco/models/user.dart';

class FollowRequestsScreen extends StatefulWidget {
  @override
  _FollowRequestsScreenState createState() => _FollowRequestsScreenState();
}

class _FollowRequestsScreenState extends State<FollowRequestsScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<User?>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Follow Requests'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _authService.getFollowRequests(currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No follow requests.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              return FutureBuilder<UserModel?>(
                future: _authService.getUser(document.id),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return ListTile(title: Text('Loading...'));
                  }
                  final requester = userSnapshot.data!;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: requester.photoURL != null && requester.photoURL!.isNotEmpty
                          ? NetworkImage(requester.photoURL!)
                          : null,
                      child: requester.photoURL == null || requester.photoURL!.isEmpty
                          ? Icon(Icons.person)
                          : null,
                    ),
                    title: Text(requester.displayName ?? 'No Name'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          child: Text('Accept'),
                          onPressed: () {
                            _authService.acceptFollowRequest(currentUser.uid, requester.uid);
                          },
                        ),
                        SizedBox(width: 8),
                        TextButton(
                          child: Text('Decline'),
                          onPressed: () {
                            _authService.declineFollowRequest(currentUser.uid, requester.uid);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
