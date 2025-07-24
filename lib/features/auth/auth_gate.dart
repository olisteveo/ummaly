// Copyright © 2025 Oliver & Haidar. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as painting;
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
  late Future<User?> _initUserFuture;

  @override
  void initState() {
    super.initState();
    _initUserFuture = _prepareUserAndLocale();
  }

  /// Handles logic for:
  /// - Checking if a user is logged in and verified
  /// - Resetting language to English on logout or unverified user
  /// - Applying saved language on login
  Future<User?> _prepareUserAndLocale() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // 🟥 Not logged in — force app to LTR English
      await context.setLocale(const Locale('en'));
      return null;
    }

    // 🔁 Refresh user in case verification was done just now
    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    // ❌ If not verified, sign them out and revert to English
    if (refreshedUser == null || !refreshedUser.emailVerified) {
      await FirebaseAuth.instance.signOut();
      await context.setLocale(const Locale('en'));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SnackbarHelper.show(
          context,
          'Please verify your email before logging in.',
          backgroundColor: Colors.orange,
        );
      });
      return null;
    }

    // ✅ Verified: apply saved language
    final langCode = await _getUserLanguage(user.uid);
    if (langCode != null) {
      await context.setLocale(Locale(langCode));
    }

    return user;
  }

  /// Fetches the user's saved language preference from Firestore
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
    return FutureBuilder<User?>(
      future: _initUserFuture,
      builder: (context, snapshot) {
        // ⏳ Still loading user and language data
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // 👤 Not logged in — show login screen with enforced LTR layout
        if (user == null) {
          return Directionality(
            textDirection: painting.TextDirection.ltr,
            child: const LoginScreen(),
          );
        }

        // 🏠 Logged in and verified — proceed to home screen
        return const HomeScreen();
      },
    );
  }
}
