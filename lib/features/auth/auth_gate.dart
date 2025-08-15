// Copyright © 2025 Oliver & Haidar. All rights reserved.

import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:ummaly/config/config.dart'; // ✅ Use central baseUrl/authEndpoint
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
    // Helpful when switching between ngrok / emulator / LAN
    // (Remove if too chatty.)
    // ignore: avoid_print
    debugPrint('🔗 API base = ${AppConfig.baseUrl}');
    _initUserFuture = _prepareUserAndLocale();
  }

  /// Handles logic for:
  /// - Checking if user is logged in and email verified
  /// - Pulling language from backend Neon DB
  /// - Resetting language to English on logout or failure
  Future<User?> _prepareUserAndLocale() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // User is not logged in — force app to LTR English
      await context.setLocale(const Locale('en'));
      return null;
    }

    // Refresh user to ensure emailVerified status is up to date
    await user.reload();
    final refreshedUser = FirebaseAuth.instance.currentUser;

    // If not verified, sign out and revert to English
    if (refreshedUser == null || !refreshedUser.emailVerified) {
      await FirebaseAuth.instance.signOut();
      await context.setLocale(const Locale('en'));

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          SnackbarHelper.show(
            context,
            'Please verify your email before logging in.',
            backgroundColor: Colors.orange,
          );
        });
      }

      return null;
    }

    // If verified, fetch user language from backend Neon DB
    final langCode = await _getUserLanguageFromBackend(refreshedUser);
    if (mounted) {
      await context.setLocale(Locale(langCode));
    }
    return refreshedUser;
  }

  /// Calls backend `/firebase-login` to pull user info (including language)
  Future<String> _getUserLanguageFromBackend(User firebaseUser) async {
    try {
      // Get Firebase ID token for secure backend call
      final idToken = await firebaseUser.getIdToken();

      // Build endpoint from central config (works with emulator/NGROK/LAN)
      final uri = Uri.parse('${AppConfig.authEndpoint}/firebase-login');

      final response = await http
          .post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final code = (data['language_preference'] as String?)?.trim();
        return (code != null && code.isNotEmpty) ? code : 'en';
      }

      // Handle session/auth failures explicitly
      if (response.statusCode == 401 || response.statusCode == 403) {
        // Token invalid/expired or backend rejected — sign out and fall back to EN
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            SnackbarHelper.show(
              context,
              'Session expired. Please log in again.',
              backgroundColor: Colors.orange,
            );
          });
        }
        return 'en';
      }

      // ignore: avoid_print
      print('Backend returned error ${response.statusCode}: ${response.body}');
      return 'en';
    } on TimeoutException {
      // ignore: avoid_print
      print('Error fetching language: request timed out (${AppConfig.baseUrl})');
      return 'en';
    } on SocketException catch (e) {
      // ignore: avoid_print
      print('Network error fetching language: $e (${AppConfig.baseUrl})');
      return 'en';
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching language: $e');
      return 'en';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _initUserFuture,
      builder: (context, snapshot) {
        // Still loading user and language preference
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // Not logged in — show login screen with enforced LTR layout
        if (user == null) {
          return Directionality(
            textDirection: painting.TextDirection.ltr,
            child: const LoginScreen(),
          );
        }

        // Logged in and verified — go to home screen
        return const HomeScreen();
      },
    );
  }
}
