import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ummaly/features/home/home_screen.dart';
import 'package:ummaly/features/auth/login_screen.dart';
import 'package:ummaly/core/widgets/snackbar_helper.dart';
import 'package:easy_localization/easy_localization.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  User? _user;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _handleAuthChanges();
  }

  void _handleAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (!mounted) return;

      _user = user;

      if (user == null) {
        await context.setLocale(const Locale('en')); // Reset to default on logout
        setState(() => _isInitializing = false);
        return;
      }

      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser == null || !refreshedUser.emailVerified) {
        await FirebaseAuth.instance.signOut();
        await context.setLocale(const Locale('en'));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            SnackbarHelper.show(
              context,
              'Please verify your email before logging in.',
              backgroundColor: Colors.orange,
            );
          }
        });
        setState(() {
          _user = null;
          _isInitializing = false;
        });
        return;
      }

      final langCode = await _getUserLanguage(user.uid);
      if (langCode != null && mounted) {
        await context.setLocale(Locale(langCode));
      }

      setState(() => _isInitializing = false);
    });
  }

  Future<String?> _getUserLanguage(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.data()?['language_preference'] ?? 'en';
    } catch (_) {
      return 'en';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return const LoginScreen();
    }

    return const HomeScreen();
  }
}
