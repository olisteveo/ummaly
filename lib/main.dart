// Copyright © 2025 Oliver & Haidar. All rights reserved.
// This file is part of the Ummaly project and may not be reused,
// modified, or distributed without express written permission.

import 'package:flutter/material.dart';

// Firebase core setup
import 'package:firebase_core/firebase_core.dart';

// Auto-generated file containing platform-specific Firebase config
import 'package:ummaly/firebase_options.dart';

// Entry point for auth logic — decides if user is logged in or not
import 'package:ummaly/features/auth/auth_gate.dart';

// Your Forgot Password screen (make sure the file name matches)
import 'package:ummaly/features/auth/forgot_password.dart';

void main() async {
  // Ensures binding is initialized before Firebase is called
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options (web, Android, etc.)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Launch the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ummaly',

      // Remove debug banner from top-right corner
      debugShowCheckedModeBanner: false,

      // Theme configuration (Material 3 turned off for flutterfire_ui compatibility)
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: false,
      ),

      // Entry point screen, controlled by AuthGate
      home: const AuthGate(),

      // Add routes for named navigation
      routes: {
        '/forgot-password': (context) => const ForgotPasswordPage(), // ✅ Added route
      },
    );
  }
}
