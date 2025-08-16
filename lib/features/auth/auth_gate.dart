// Copyright © 2025 Oliver & Haidar. All rights reserved.

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:ummaly/config/config.dart';        // ✅ Use AppConfig
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

  /// Handles:
  /// - Check login + emailVerified
  /// - Pull language from backend
  /// - Reset to English on logout/failure
  Future<User?> _prepareUserAndLocale() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      await context.setLocale(const Locale('en'));
      return null;
    }

    // refresh verification state
    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

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

    // Fetch language from backend; default to EN on any issue
    final langCode = await _getUserLanguageFromBackend(refreshedUser);
    await context.setLocale(Locale(langCode));

    return refreshedUser;
  }

  /// Calls backend `/firebase-login` to pull user info (including language)
  Future<String> _getUserLanguageFromBackend(User firebaseUser) async {
    try {
      final idToken = await firebaseUser.getIdToken();
      final uri = Uri.parse("${AppConfig.authEndpoint}/firebase-login");

      final response = await http
          .post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $idToken",
        },
      )
          .timeout(const Duration(seconds: 8)); // ⏱️ be snappy on cold start

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final code = (data['language_preference'] as String?)?.trim();
        debugPrint("[AuthGate] language from backend = ${code ?? 'en'}");
        return (code == null || code.isEmpty) ? 'en' : code;
      } else {
        debugPrint("[AuthGate] backend error: ${response.statusCode} ${response.body}");
        _toastOnce('Signed in, but couldn’t load language. Using English.');
        return 'en';
      }
    } on TimeoutException {
      debugPrint("[AuthGate] language fetch timed out");
      _toastOnce('Network slow. Using English for now.');
      return 'en';
    } catch (e) {
      debugPrint("[AuthGate] language fetch error: $e");
      _toastOnce('Problem loading your settings. Using English.');
      return 'en';
    }
  }

  bool _toasted = false;
  void _toastOnce(String msg) {
    if (_toasted) return;
    _toasted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SnackbarHelper.show(context, msg, backgroundColor: Colors.orange);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _initUserFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          // force LTR for login
          return Directionality(
            textDirection: painting.TextDirection.ltr,
            child: const LoginScreen(),
          );
        }

        return const HomeScreen();
      },
    );
  }
}
