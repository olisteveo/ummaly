// Copyright © 2025 Oliver & Haidar. All rights reserved.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
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

  /// ✅ Handles logic for:
  /// - Checking if user is logged in + email verified
  /// - Pulling language from backend Neon DB
  /// - Resetting language to English on logout or failure
  Future<User?> _prepareUserAndLocale() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // 🟥 Not logged in — force app to LTR English
      await context.setLocale(const Locale('en'));
      return null;
    }

    // 🔁 Refresh user (ensures emailVerified status is up to date)
    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    // ❌ If not verified, sign out + revert to English
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

    // ✅ If verified, fetch user language from backend Neon DB
    final langCode = await _getUserLanguageFromBackend(refreshedUser);
    await context.setLocale(Locale(langCode));

    return refreshedUser;
  }

  /// ✅ Calls backend `/firebase-login` to pull user info (including language)
  Future<String> _getUserLanguageFromBackend(User firebaseUser) async {
    try {
      // ✅ Get Firebase ID token for secure backend call
      final idToken = await firebaseUser.getIdToken();

      // ✅ Call backend to retrieve Neon DB user details
      final response = await http.post(
        Uri.parse("http://10.0.2.2:5000/api/auth/firebase-login"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $idToken",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['language_preference'] ?? 'en';
      } else {
        print("⚠️ Backend returned error: ${response.body}");
        return 'en';
      }
    } catch (e) {
      print("⚠️ Error fetching language: $e");
      return 'en';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _initUserFuture,
      builder: (context, snapshot) {
        // ⏳ Still loading user + language preference
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

        // 🏠 Logged in + verified — go to home screen
        return const HomeScreen();
      },
    );
  }
}
