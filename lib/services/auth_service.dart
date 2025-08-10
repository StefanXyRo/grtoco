import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword(
      String email, String password, String displayName) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create a new user document in Firestore
      await _createUserDocument(userCredential.user, displayName);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle errors
      print(e.message);
      return null;
    }
  }

  // Create a user document in Firestore
  Future<void> _createUserDocument(User? user, String displayName) async {
    if (user == null) return;

    UserModel newUser = UserModel(
      uid: user.uid,
      email: user.email,
      displayName: displayName,
    );

    await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Handle errors
      print(e.message);
      return null;
    }
  }

  // Reset password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // Handle errors
      print(e.message);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
