import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ummaly/features/home/home_screen.dart';
import 'package:ummaly/features/auth/login_screen.dart';

/// AuthGate determines whether the user is logged in or not.
/// It listens to FirebaseAuth's stream and returns the appropriate screen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Listen to auth state changes (login, logout, registration, etc.)
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While waiting for Firebase to determine the state, show a loading spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is signed in, go to HomeScreen
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // If not signed in, show the login screen
        return const LoginScreen();
      },
    );
  }
}
