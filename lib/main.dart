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

// Your Forgot Password screen
import 'package:ummaly/features/auth/forgot_password.dart';

// EasyLocalization for multi-language support
import 'package:easy_localization/easy_localization.dart';

// LocaleManager handles language detection, loading, and saving
import 'package:ummaly/core/locale/locale_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Initialize locale manager (handles device/user language logic)
  await LocaleManager().init();

  // Launch the app with localization support
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'), // English
        Locale('fr'), // French
        Locale('ar'), // Arabic
        Locale('ur'), // Urdu
      ],
      path: 'translations', // ✅ Corrected path for Flutter web
      fallbackLocale: const Locale('en'),
      startLocale: LocaleManager().currentLocale,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ummaly',
      debugShowCheckedModeBanner: false,

      // Load translations from EasyLocalization
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // Theme (Material 3 turned off for flutterfire_ui compatibility)
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: false,
      ),

      // App entry point
      home: const AuthGate(),

      // Named routes
      routes: {
        '/forgot-password': (context) => const ForgotPasswordPage(),
      },
    );
  }
}
