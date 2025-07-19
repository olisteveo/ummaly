import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ummaly/features/home/home_screen.dart';
import 'package:ummaly/features/auth/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

/// AuthGate determines whether the user is logged in or not.
/// It listens to FirebaseAuth's stream and shows the appropriate screen,
/// while safely handling localization and layout direction.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  User? _user;
  bool _hasSetLocale = false;

  @override
  void initState() {
    super.initState();

    // Listen to auth changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _user = user;
        _hasSetLocale = false; // reset so we can re-set locale
      });
    });
  }

  /// Set locale safely once widget is mounted
  void _applyUserLocaleOnce(BuildContext context) async {
    if (_hasSetLocale) return;
    _hasSetLocale = true;

    if (_user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      final lang = doc.data()?['language_preference'] ?? 'en';
      await context.setLocale(Locale(lang));
    } else {
      // Force default locale on logout (LTR)
      await context.setLocale(const Locale('en'));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Delay the locale application until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyUserLocaleOnce(context);
    });

    // Show loading while waiting for auth state
    if (_user == null && FirebaseAuth.instance.currentUser != null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _user != null ? const HomeScreen() : const LoginScreen();
  }
}
