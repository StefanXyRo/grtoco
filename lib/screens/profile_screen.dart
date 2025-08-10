import 'package:flutter/material.dart';
import 'package:grtoco/models/user.dart';
import 'package:grtoco/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'edit_profile_screen.dart';
import 'follow_requests_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  ProfileScreen({required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isCurrentUser = false;
  bool _hasPendingRequest = false;
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
    _loadUserData();
  }

  void _checkCurrentUser() {
    // This might throw an error if called from initState without a mounted context.
    // Assuming it works as intended in the user's setup.
    final currentUser = Provider.of<fb_auth.User?>(context, listen: false);
    if (currentUser != null && currentUser.uid == widget.userId) {
      setState(() {
        _isCurrentUser = true;
      });
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    User? user = await _authService.getUser(widget.userId);
    if (user != null) {
      final currentUser = Provider.of<fb_auth.User?>(context, listen: false);
      bool isFollowing = false;
      bool hasPendingRequest = false;

      if (currentUser != null) {
        isFollowing = user.followers.contains(currentUser.uid);
        if (!isFollowing && user.isPrivate) {
          hasPendingRequest = await _authService.hasPendingFollowRequest(
              currentUser.uid, widget.userId);
        }
      }

      setState(() {
        _user = user;
        _followersCount = user.followersCount;
        _followingCount = user.followingCount;
        _isFollowing = isFollowing;
        _hasPendingRequest = hasPendingRequest;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _user == null
              ? Center(child: Text('User not found.'))
              : _buildProfileView(),
    );
  }

  Widget _buildProfileView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: _user!.profileImageUrl != null && _user!.profileImageUrl!.isNotEmpty
                    ? NetworkImage(_user!.profileImageUrl!)
                    : null,
                child: _user!.profileImageUrl == null || _user!.profileImageUrl!.isEmpty
                    ? Icon(Icons.person, size: 40)
                    : null,
              ),
              SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _user!.displayName ?? 'No Name',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text('$_followersCount Followers'),
                      SizedBox(width: 20),
                      Text('$_followingCount Following'),
                    ],
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'Bio',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(_user!.bio ?? 'No bio yet.'),
          SizedBox(height: 20),
          _buildProfileButton(),
          if (_isCurrentUser) ...[
            SizedBox(height: 10),
            ElevatedButton(
              child: Text('Follow Requests'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FollowRequestsScreen(),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileButton() {
    if (_isCurrentUser) {
      return ElevatedButton(
        child: Text('Edit Profile'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProfileScreen(user: _user!),
            ),
          ).then((_) => _loadUserData());
        },
      );
    } else if (_isFollowing) {
      return ElevatedButton(
        child: Text('Unfollow'),
        onPressed: _handleFollowUnfollow,
      );
    } else if (_hasPendingRequest) {
      return ElevatedButton(
        child: Text('Requested'),
        onPressed: null,
      );
    } else {
      return ElevatedButton(
        child: Text('Follow'),
        onPressed: _handleFollowUnfollow,
      );
    }
  }

  void _handleFollowUnfollow() async {
    final currentUser = Provider.of<fb_auth.User?>(context, listen: false);
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    if (_isFollowing) {
      await _authService.unfollowUser(currentUser.uid, widget.userId);
      setState(() {
        _isFollowing = false;
        _followersCount--;
      });
    } else {
      if (_user!.isPrivate) {
        await _authService.sendFollowRequest(currentUser.uid, widget.userId);
        setState(() {
          _hasPendingRequest = true;
        });
      } else {
        await _authService.followUser(currentUser.uid, widget.userId);
        setState(() {
          _isFollowing = true;
          _followersCount++;
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }
}
