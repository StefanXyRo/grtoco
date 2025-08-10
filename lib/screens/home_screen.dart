import 'package:flutter/material.dart';
import 'package:grtoco/services/auth_service.dart';
import 'package:grtoco/screens/login_screen.dart';
import 'package:grtoco/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  final AuthService _auth = AuthService();

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
              await _auth.signOut();
              // The AuthWrapper will handle navigation to the LoginScreen
            },
          )
        ],
      ),
      body: Center(
        child: Text('Welcome to Grtoco!'),
      ),
    );
  }
}
