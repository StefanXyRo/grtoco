import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:grtoco/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:grtoco/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:grtoco/screens/home_screen.dart';

// IMPORTANT:
// 1. Create a Firebase project at https://console.firebase.google.com/.
// 2. Add an Android and/or iOS app to your Firebase project.
// 3. Follow the setup instructions to add the necessary configuration files to your project.
//    - For Android, add the `google-services.json` file to the `android/app` directory.
//    - For iOS, add the `GoogleService-Info.plist` file to the `ios/Runner` directory.
// 4. Enable Email/Password authentication in the Firebase console.
// 5. Create a Firestore database and set up the security rules.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: Replace with your own Firebase options.
  // You can get this from your Firebase project settings.
  // See: https://firebase.google.com/docs/flutter/setup
  await Firebase.initializeApp(
     // options: DefaultFirebaseOptions.currentPlatform, // Uncomment this line after setting up firebase_cli
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'Grtoco',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();

    if (firebaseUser != null) {
      return HomeScreen();
    }
    return LoginScreen();
  }
}

extension AuthServiceExtension on AuthService {
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
